import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/pedido.dart';
import '../../viewmodels/pedidos_viewmodel.dart';

/// TabBar personalizada del tablero de pedidos.
///
/// Reemplaza al `TabBar` nativo de Flutter porque necesitamos envolver
/// cada tab en un `DragTarget<Pedido>` para aceptar tarjetas arrastradas
/// desde otras pestañas.
///
/// Replica el indicador inferior animado del `TabBar` nativo, que se
/// mueve progresivamente con el swipe del usuario en lugar de saltar
/// al final.
class PedidosTabBar extends StatelessWidget {
  final TabController controller;
  final List<PedidosTabInfo> tabs;
  final void Function(Pedido pedido, EstadoPedido destino) onDropPedido;

  const PedidosTabBar({
    super.key,
    required this.controller,
    required this.tabs,
    required this.onDropPedido,
  });

  @override
  Widget build(BuildContext context) {
    // Usamos controller.animation en lugar de controller directamente.
    // .animation es un Animation<double> que cambia CONTINUAMENTE durante
    // el swipe (valores como 0.37, 0.84, 1.5...), mientras que
    // controller.index solo cambia cuando la animación termina.
    return AnimatedBuilder(
      animation: controller.animation!,
      builder: (context, _) {
        final posicion = controller.animation!.value;
        return Container(
          color: const Color(0xFF1B396A),
          height: 52,
          child: Stack(
            children: [
              // Capa 1: los tabs (drop targets + tap + contenido)
              Row(
                children: List.generate(tabs.length, (i) {
                  return Expanded(
                    child: _TabConDropTarget(
                      info: tabs[i],
                      // Un tab se considera "activo" visualmente si la posición
                      // animada está más cerca de su índice que de cualquier otro.
                      activo: posicion.round() == i,
                      onTap: () => controller.animateTo(i),
                      onDropPedido: onDropPedido,
                    ),
                  );
                }),
              ),
              // Capa 2: el indicador animado, pintado encima de los tabs.
              // Se posiciona según el valor continuo de la animación.
              _buildIndicador(context, posicion),
            ],
          ),
        );
      },
    );
  }

  /// Indicador inferior blanco que se mueve continuamente con el swipe.
  ///
  /// [posicion] es un double entre 0.0 y (tabs.length - 1).
  /// El ancho de cada tab es 1/tabs.length del ancho total de la barra.
  Widget _buildIndicador(BuildContext context, double posicion) {
    // Convertimos la posición (0.0 a tabs.length-1) a alineación horizontal
    // (-1.0 izquierda, 0.0 centro, 1.0 derecha).
    // Si hay 3 tabs, posicion=0 → izq, posicion=1 → centro, posicion=2 → der.
    final alineacionX = tabs.length == 1
        ? 0.0
        : (posicion / (tabs.length - 1)) * 2 - 1;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 3,
      child: Align(
        alignment: Alignment(alineacionX, 0),
        child: FractionallySizedBox(
          widthFactor: 1 / tabs.length,
          child: Container(color: Colors.white),
        ),
      ),
    );
  }
}

/// Información de un tab (label visible + estado que representa).
class PedidosTabInfo {
  final String label;
  final EstadoPedido estado;
  const PedidosTabInfo({required this.label, required this.estado});
}

// ============================================================================
// Tab individual con DragTarget
// ============================================================================
class _TabConDropTarget extends ConsumerWidget {
  final PedidosTabInfo info;
  final bool activo;
  final VoidCallback onTap;
  final void Function(Pedido, EstadoPedido) onDropPedido;

  const _TabConDropTarget({
    required this.info,
    required this.activo,
    required this.onTap,
    required this.onDropPedido,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conteo = ref.watch(conteoPorEstadoProvider(info.estado));
    final vm = ref.read(pedidosViewModelProvider);

    return DragTarget<Pedido>(
      onWillAcceptWithDetails: (details) {
        final pedido = details.data;
        if (pedido.estado == info.estado) return false;
        return vm.transicionesPermitidas(pedido.estado).contains(info.estado);
      },
      onAcceptWithDetails: (details) {
        onDropPedido(details.data, info.estado);
      },
      builder: (context, candidatos, rechazados) {
        final hovered = candidatos.isNotEmpty;
        final rechazado = rechazados.isNotEmpty;

        return InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: _colorFondo(hovered: hovered, rechazado: rechazado),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    info.label,
                    style: TextStyle(
                      color: activo ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (conteo > 0) ...[
                    const SizedBox(width: 6),
                    _Badge(
                      conteo: conteo,
                      gris: info.estado == EstadoPedido.terminado,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Color de fondo del tab durante drag:
  ///   - rojo suave si el pedido NO puede moverse aquí
  ///   - blanco semitransparente si SÍ puede
  ///   - transparente en reposo
  Color _colorFondo({required bool hovered, required bool rechazado}) {
    if (rechazado) return const Color(0xFFD32F2F).withOpacity(0.25);
    if (hovered) return Colors.white.withOpacity(0.15);
    return Colors.transparent;
  }
}

// ============================================================================
// Badge de conteo
// ============================================================================
class _Badge extends StatelessWidget {
  final int conteo;
  final bool gris;
  const _Badge({required this.conteo, required this.gris});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: gris ? const Color(0xFF807E82) : const Color(0xFF117533),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$conteo',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}