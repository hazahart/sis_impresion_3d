import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pedido.dart';
import 'registro_pedido_viewmodel.dart' show pedidosRepositoryProvider;

// ============================================================================
// STREAM MAESTRO
// ============================================================================
/// Stream de TODOS los pedidos, sin filtrar, tal como llegan de Firestore.
/// Ordenados por fecha de registro descendente (lo hace el repo).
/// Todos los providers filtrados derivan de aquí.
final pedidosStreamProvider = StreamProvider<List<Pedido>>((ref) {
  return ref.read(pedidosRepositoryProvider).streamPedidos();
});

// ============================================================================
// PROVIDERS FILTRADOS POR ESTADO
// ============================================================================
/// Retorna la lista de pedidos del estado pedido, ya ordenada:
///   1. Urgentes primero, por fecha de entrega más próxima.
///   2. Luego no urgentes, por fecha de registro (FIFO: más viejo arriba).
final pedidosPorEstadoProvider =
    Provider.family<AsyncValue<List<Pedido>>, EstadoPedido>((ref, estado) {
  final asyncPedidos = ref.watch(pedidosStreamProvider);
  return asyncPedidos.whenData((lista) {
    final filtrados = lista.where((p) => p.estado == estado).toList();
    filtrados.sort(_comparadorPedidos);
    return filtrados;
  });
});

/// Contador de pedidos por estado (útil para el badge de cada pestaña).
final conteoPorEstadoProvider =
    Provider.family<int, EstadoPedido>((ref, estado) {
  final async = ref.watch(pedidosPorEstadoProvider(estado));
  return async.maybeWhen(data: (lista) => lista.length, orElse: () => 0);
});

// ============================================================================
// VIEWMODEL PARA ACCIONES
// ============================================================================
final pedidosViewModelProvider = Provider((ref) => PedidosViewModel(ref));

class PedidosViewModel {
  final Ref ref;
  PedidosViewModel(this.ref);

  /// Cambia el estado de un pedido. Lanza excepción si falla.
  Future<void> cambiarEstado(Pedido pedido, EstadoPedido nuevoEstado) async {
    if (pedido.id == null) {
      throw Exception('El pedido no tiene ID, no se puede actualizar.');
    }
    await ref
        .read(pedidosRepositoryProvider)
        .actualizarEstado(pedido.id!, nuevoEstado);
  }

  /// Transiciones permitidas desde un estado dado.
  /// Se usa en el BottomSheet para mostrar únicamente las acciones válidas.
  List<EstadoPedido> transicionesPermitidas(EstadoPedido actual) {
    switch (actual) {
      case EstadoPedido.enCola:
        return [EstadoPedido.imprimiendo];
      case EstadoPedido.imprimiendo:
        return [EstadoPedido.terminado, EstadoPedido.enCola];
      case EstadoPedido.terminado:
        return [EstadoPedido.imprimiendo];
    }
  }
}

// ============================================================================
// COMPARADOR DE ORDEN
// ============================================================================
int _comparadorPedidos(Pedido a, Pedido b) {
  // 1) Urgentes antes que no urgentes.
  if (a.esUrgente != b.esUrgente) {
    return a.esUrgente ? -1 : 1;
  }

  // 2) Entre urgentes: por fecha de entrega ascendente (más próxima arriba).
  //    Si alguno no tiene fecha de entrega, va al final del grupo urgente.
  if (a.esUrgente && b.esUrgente) {
    final fa = a.fechaEntrega;
    final fb = b.fechaEntrega;
    if (fa == null && fb == null) return 0;
    if (fa == null) return 1;
    if (fb == null) return -1;
    return fa.compareTo(fb);
  }

  // 3) Entre no urgentes: FIFO — más antiguo primero.
  return a.fechaRegistro.compareTo(b.fechaRegistro);
}