import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../data/pedidos_repository.dart';
import '../models/pedido.dart';

// ============================================================================
// CONSTANTES DE NEGOCIO
// ============================================================================
const double kDescuentoEstudiante = 0.20; // 20%
const double kRecargoUrgente = 0.20;      // 20%

// ============================================================================
// DATOS QUE VIAJAN DESDE LA COTIZACIÓN AL FORMULARIO DE REGISTRO
// ============================================================================
/// Snapshot de los datos calculados en la pantalla de Cotización.
/// Cuando el usuario presiona "Aceptar" en el modal de resultado, estos
/// datos se guardan aquí y el formulario de registro los lee para
/// pre-llenarse (peso, tiempo, material, precio unitario).
class DatosCotizados {
  final double pesoGramos;
  final int horas;
  final int minutos;
  final String material;
  final double precioUnitario;

  DatosCotizados({
    required this.pesoGramos,
    required this.horas,
    required this.minutos,
    required this.material,
    required this.precioUnitario,
  });
}

final datosCotizadosProvider = StateProvider<DatosCotizados?>((ref) => null);

// ============================================================================
// PROVIDERS DEL REPOSITORIO Y DEL VIEWMODEL
// ============================================================================
final pedidosRepositoryProvider = Provider((ref) => PedidosRepository());

final registroPedidoViewModelProvider =
    NotifierProvider<RegistroPedidoViewModel, RegistroPedidoState>(() {
      return RegistroPedidoViewModel();
    });

// ============================================================================
// ESTADO DEL FORMULARIO
// ============================================================================
class RegistroPedidoState {
  final int cantidad;
  final String? color;
  final DateTime? fechaEntrega;
  final bool esEstudiante;
  final bool esUrgente;
  final bool guardando;

  const RegistroPedidoState({
    this.cantidad = 1,
    this.color,
    this.fechaEntrega,
    this.esEstudiante = false,
    this.esUrgente = false,
    this.guardando = false,
  });

  RegistroPedidoState copyWith({
    int? cantidad,
    String? color,
    DateTime? fechaEntrega,
    bool limpiarFechaEntrega = false,
    bool? esEstudiante,
    bool? esUrgente,
    bool? guardando,
  }) {
    return RegistroPedidoState(
      cantidad: cantidad ?? this.cantidad,
      color: color ?? this.color,
      fechaEntrega: limpiarFechaEntrega ? null : (fechaEntrega ?? this.fechaEntrega),
      esEstudiante: esEstudiante ?? this.esEstudiante,
      esUrgente: esUrgente ?? this.esUrgente,
      guardando: guardando ?? this.guardando,
    );
  }
}

// ============================================================================
// VIEWMODEL
// ============================================================================
class RegistroPedidoViewModel extends Notifier<RegistroPedidoState> {
  @override
  RegistroPedidoState build() => const RegistroPedidoState();

  // --------------------------------------------------------------------------
  // MUTADORES DEL FORMULARIO
  // --------------------------------------------------------------------------
  void setCantidad(int valor) {
    if (valor < 1) valor = 1;
    state = state.copyWith(cantidad: valor);
  }

  void incrementarCantidad() => setCantidad(state.cantidad + 1);
  void decrementarCantidad() => setCantidad(state.cantidad - 1);

  void setColor(String? color) {
    state = state.copyWith(color: color);
  }

  void setFechaEntrega(DateTime? fecha) {
    if (fecha == null) {
      state = state.copyWith(limpiarFechaEntrega: true);
    } else {
      state = state.copyWith(fechaEntrega: fecha);
    }
  }

  void toggleEstudiante(bool valor) {
    state = state.copyWith(esEstudiante: valor);
  }

  void toggleUrgente(bool valor) {
    state = state.copyWith(esUrgente: valor);
  }

  void resetear() {
    state = const RegistroPedidoState();
  }

  // --------------------------------------------------------------------------
  // CÁLCULO DEL TOTAL
  // --------------------------------------------------------------------------
  /// Calcula el total con los ajustes aplicados.
  /// Orden: (unitario × cantidad) → descuento estudiante → recargo urgente.
  double calcularTotal(double precioUnitario) {
    double total = precioUnitario * state.cantidad;
    if (state.esEstudiante) total *= (1 - kDescuentoEstudiante);
    if (state.esUrgente) total *= (1 + kRecargoUrgente);
    // Truncar a 2 decimales, igual que el sprint 1 de cotización.
    return (total * 100).truncateToDouble() / 100;
  }

  // --------------------------------------------------------------------------
  // VALIDACIÓN DE FECHA DE ENTREGA
  // --------------------------------------------------------------------------
  /// Retorna un mensaje de error si la fecha es inválida, o null si está OK.
  /// Reglas:
  ///   - Si esUrgente: fecha es OBLIGATORIA y no puede ser pasada.
  ///   - Si NO esUrgente: fecha es OPCIONAL pero si se especifica, no puede ser pasada.
  String? validarFechaEntrega() {
    final fecha = state.fechaEntrega;

    if (state.esUrgente && fecha == null) {
      return 'La fecha de entrega es obligatoria para pedidos urgentes.';
    }

    if (fecha != null) {
      final ahora = DateTime.now();
      final hoyInicio = DateTime(ahora.year, ahora.month, ahora.day);
      final fechaSoloDia = DateTime(fecha.year, fecha.month, fecha.day);
      if (fechaSoloDia.isBefore(hoyInicio)) {
        return 'La fecha de entrega no puede ser anterior a hoy.';
      }
    }

    return null;
  }

  // --------------------------------------------------------------------------
  // GUARDAR PEDIDO
  // --------------------------------------------------------------------------
  /// Ejecuta la inserción en Firestore.
  /// Retorna el folio generado si todo salió bien.
  /// Lanza excepción con mensaje descriptivo si falla.
  Future<String> guardarPedido({
    required String nombreCliente,
    required String telefonoCliente,
    required String? descripcion,
  }) async {
    final datos = ref.read(datosCotizadosProvider);
    if (datos == null) {
      throw Exception('No hay datos de cotización. Regrese a cotizar.');
    }
    if (state.color == null) {
      throw Exception('Seleccione un color.');
    }
    final errorFecha = validarFechaEntrega();
    if (errorFecha != null) {
      throw Exception(errorFecha);
    }

    state = state.copyWith(guardando: true);
    try {
      final pedido = Pedido(
        folio: '', // el repositorio lo asigna en la transacción
        nombreCliente: nombreCliente.trim(),
        telefonoCliente: telefonoCliente.trim(),
        material: datos.material,
        color: state.color!,
        descripcion: (descripcion == null || descripcion.trim().isEmpty)
            ? null
            : descripcion.trim(),
        cantidad: state.cantidad,
        pesoGramos: datos.pesoGramos,
        horasEstimadas: datos.horas,
        minutosEstimados: datos.minutos,
        precioUnitario: datos.precioUnitario,
        total: calcularTotal(datos.precioUnitario),
        esEstudiante: state.esEstudiante,
        esUrgente: state.esUrgente,
        fechaRegistro: DateTime.now(),
        fechaEntrega: state.fechaEntrega,
        estado: EstadoPedido.enCola,
      );

      final creado = await ref.read(pedidosRepositoryProvider).crearPedido(pedido);

      // Limpiamos estado local y datos cotizados tras éxito.
      resetear();
      ref.read(datosCotizadosProvider.notifier).state = null;

      return creado.folio;
    } finally {
      // Siempre quitamos el spinner, haya éxito o error.
      if (state.guardando) {
        state = state.copyWith(guardando: false);
      }
    }
  }
}