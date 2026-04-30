import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/pedido.dart';
import '../../viewmodels/pedidos_viewmodel.dart';

/// BottomSheet de acciones para un pedido.
///
/// Muestra dinámicamente solo las transiciones de estado válidas desde
/// el estado actual del pedido, apoyándose en `transicionesPermitidas`
/// del viewmodel.
///
/// Se invoca con el helper estático [show]:
///
/// ```dart
/// PedidoAccionesSheet.show(context, pedido: p);
/// ```
class PedidoAccionesSheet extends ConsumerWidget {
  final Pedido pedido;

  const PedidoAccionesSheet({super.key, required this.pedido});

  /// Helper para invocar el sheet desde cualquier pantalla.
  /// Retorna el nuevo estado elegido si hubo cambio, o null si se canceló.
  static Future<EstadoPedido?> show(
    BuildContext context, {
    required Pedido pedido,
  }) {
    return showModalBottomSheet<EstadoPedido>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PedidoAccionesSheet(pedido: pedido),
    );
  }

  // --------------------------------------------------------------------------
  // PALETA (consistente con pedido_card.dart y el resto del proyecto)
  // --------------------------------------------------------------------------
  static const _colorPrimary = Color(0xFF1B396A);
  static const _colorSecondary = Color(0xFF117533);
  static const _colorTextoSecundario = Color(0xFF807E82);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.read(pedidosViewModelProvider);
    final transiciones = vm.transicionesPermitidas(pedido.estado);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        // Respetamos el área segura inferior del dispositivo.
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHandle(),
          const SizedBox(height: 8),
          _buildEncabezado(),
          const SizedBox(height: 16),
          ...transiciones.map((dest) => _buildAccion(context, ref, dest)),
          const SizedBox(height: 8),
          _buildCancelar(context),
        ],
      ),
    );
  }

  /// Handle visual (barra horizontal gris), indicador de que es arrastrable.
  Widget _buildHandle() {
    return Center(
      child: Container(
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  /// Encabezado: etiqueta "OPCIONES DE PEDIDO" y título con folio y cliente.
  Widget _buildEncabezado() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OPCIONES DE PEDIDO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: _colorTextoSecundario,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${pedido.folio} - ${pedido.nombreCliente}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _colorPrimary,
          ),
        ),
      ],
    );
  }

  /// Botón de acción para una transición específica.
  /// El texto, icono y color se derivan del estado de destino.
  Widget _buildAccion(
    BuildContext context,
    WidgetRef ref,
    EstadoPedido destino,
  ) {
    final info = _metadatosAccion(destino);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: info.colorFondo,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _ejecutarAccion(context, ref, destino),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(info.icono, color: info.colorTexto, size: 20),
                const SizedBox(width: 14),
                Text(
                  info.texto,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: info.colorTexto,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Botón neutro "CANCELAR" — cierra el sheet sin realizar cambios.
  Widget _buildCancelar(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).pop(),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              'CANCELAR',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _colorTextoSecundario,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // LÓGICA: ejecutar acción y cerrar con feedback
  // --------------------------------------------------------------------------
  Future<void> _ejecutarAccion(
    BuildContext context,
    WidgetRef ref,
    EstadoPedido destino,
  ) async {
    // Cerramos el sheet primero para que se vea el snackbar detrás.
    Navigator.of(context).pop(destino);

    try {
      await ref
          .read(pedidosViewModelProvider)
          .cambiarEstado(pedido, destino);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pedido ${pedido.folio} movido a ${destino.label}',
          ),
          backgroundColor: _colorSecondary,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // --------------------------------------------------------------------------
  // METADATOS: texto, icono y colores de cada acción según el estado destino.
  // Centralizar esto aquí evita decisiones dispersas por el widget.
  // --------------------------------------------------------------------------
  _AccionInfo _metadatosAccion(EstadoPedido destino) {
    switch (destino) {
      case EstadoPedido.imprimiendo:
        // Puede venir desde "en cola" (Iniciar) o "terminado" (Reabrir).
        final esReapertura = pedido.estado == EstadoPedido.terminado;
        return _AccionInfo(
          texto: esReapertura ? 'Regresar a Impresión' : 'Iniciar Impresión',
          icono: esReapertura ? Icons.replay : Icons.play_arrow,
          colorFondo: const Color(0xFFE8F0F9), // azul muy pálido
          colorTexto: _colorPrimary,
        );
      case EstadoPedido.terminado:
        return const _AccionInfo(
          texto: 'Marcar como Terminado',
          icono: Icons.check_circle,
          colorFondo: Color(0xFFE7F1EB), // verde muy pálido
          colorTexto: _colorSecondary,
        );
      case EstadoPedido.enCola:
        return const _AccionInfo(
          texto: 'Regresar a Cola',
          icono: Icons.undo,
          colorFondo: Color(0xFFF0F0F0), // gris muy pálido
          colorTexto: _colorTextoSecundario,
        );
    }
  }
}

// ============================================================================
// Tipo privado para los metadatos visuales de cada acción.
// ============================================================================
class _AccionInfo {
  final String texto;
  final IconData icono;
  final Color colorFondo;
  final Color colorTexto;

  const _AccionInfo({
    required this.texto,
    required this.icono,
    required this.colorFondo,
    required this.colorTexto,
  });
}