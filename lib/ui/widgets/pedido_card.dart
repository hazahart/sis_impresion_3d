import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pedido.dart';

/// Tarjeta visual de un pedido.
///
/// Se adapta automáticamente a la variante "urgente" (borde rojo tenue,
/// badge URGENTE, banner de fecha de entrega límite) cuando el pedido
/// lo requiere.
///
/// No maneja interacciones de estado por sí misma; expone callbacks para
/// que el contenedor (la pantalla) decida qué hacer:
///   - [onTapMenu]     → abre el BottomSheet de acciones.
///   - [onLongPress]   → abre el BottomSheet (alternativa del PDF).
class PedidoCard extends StatelessWidget {
  final Pedido pedido;
  final VoidCallback? onTapMenu;
  final VoidCallback? onLongPress;

  const PedidoCard({
    super.key,
    required this.pedido,
    this.onTapMenu,
    this.onLongPress,
  });

  // Paleta reutilizada del resto del proyecto (Sprint 1 + mockup HTML).
  static const _colorPrimary = Color(0xFF1B396A);
  static const _colorSecondary = Color(0xFF117533);
  static const _colorTextoSecundario = Color(0xFF807E82);
  static const _colorError = Color(0xFFD32F2F);
  static const _colorErrorContainer = Color(0xFFFFEBEE);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: pedido.esUrgente
                ? _colorError.withOpacity(0.3)
                : const Color(0xFFE0E0E0),
            width: pedido.esUrgente ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x26000000), // negro 15%
              offset: Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEncabezado(),
            const SizedBox(height: 8),
            _buildCliente(),
            const SizedBox(height: 10),
            _buildBloqueTecnico(),
            if (pedido.esUrgente && pedido.fechaEntrega != null) ...[
              const SizedBox(height: 8),
              _buildBannerEntrega(),
            ],
            const SizedBox(height: 8),
            _buildPieRegistro(),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // ENCABEZADO: folio + badge URGENTE + botón ⋮
  // --------------------------------------------------------------------------
  Widget _buildEncabezado() {
    return Row(
      children: [
        // Folio (píldora azul pálido)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFE3EDF7),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            pedido.folio,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _colorPrimary,
            ),
          ),
        ),
        if (pedido.esUrgente) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _colorError,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text(
              'URGENTE',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
        const Spacer(),
        InkWell(
          onTap: onTapMenu,
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.more_vert,
              size: 20,
              color: _colorTextoSecundario,
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // NOMBRE DEL CLIENTE
  // --------------------------------------------------------------------------
  Widget _buildCliente() {
    return Text(
      pedido.nombreCliente,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF212121),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // BLOQUE TÉCNICO 2x2: material, color, tiempo, peso
  // --------------------------------------------------------------------------
  Widget _buildBloqueTecnico() {
    final tiempo = _formatearTiempo(pedido.horasEstimadas, pedido.minutosEstimados);
    final peso = '${pedido.pesoGramos.toStringAsFixed(pedido.pesoGramos % 1 == 0 ? 0 : 1)}g';

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _dato(Icons.view_in_ar_outlined, pedido.material)),
              Expanded(child: _dato(Icons.circle_outlined, pedido.color)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _dato(Icons.access_time, tiempo)),
              Expanded(child: _dato(Icons.scale_outlined, peso)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dato(IconData icon, String texto) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _colorTextoSecundario),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF424242),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // BANNER "ENTREGA LÍMITE" — solo pedidos urgentes con fecha
  // --------------------------------------------------------------------------
  Widget _buildBannerEntrega() {
    final fecha = DateFormat('d MMM, HH:mm', 'es').format(pedido.fechaEntrega!);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _colorErrorContainer,
        border: Border.all(color: _colorError.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available, size: 14, color: _colorError),
          const SizedBox(width: 6),
          const Text(
            'ENTREGA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _colorError,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Text(
            fecha,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _colorError,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // PIE: fecha de registro en el sistema
  // --------------------------------------------------------------------------
  Widget _buildPieRegistro() {
    final fecha = DateFormat('d MMM', 'es').format(pedido.fechaRegistro);
    return Row(
      children: [
        const Icon(Icons.event_outlined, size: 12, color: _colorTextoSecundario),
        const SizedBox(width: 4),
        Text(
          'Registro: $fecha',
          style: const TextStyle(
            fontSize: 11,
            color: _colorTextoSecundario,
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // HELPER: formato "4h 30m", "2h 15m", "45m"
  // --------------------------------------------------------------------------
  String _formatearTiempo(int horas, int minutos) {
    if (horas == 0) return '${minutos}m';
    if (minutos == 0) return '${horas}h';
    return '${horas}h ${minutos}m';
  }
}