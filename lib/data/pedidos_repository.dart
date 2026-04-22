import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pedido.dart';

class PedidosRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Crea un pedido nuevo generando el folio de forma atómica.
  ///
  /// Usa una transacción de Firestore para:
  ///   1. Leer el contador actual en `counters/pedidos`.
  ///   2. Incrementarlo en 1.
  ///   3. Escribir el nuevo pedido con el folio formateado (ORD-001).
  ///
  /// Si dos operadores intentan crear un pedido al mismo tiempo, la
  /// transacción garantiza que cada uno reciba un folio único.
  ///
  /// Retorna el [Pedido] creado (con su id y folio ya asignados).
  Future<Pedido> crearPedido(Pedido pedido) async {
    try {
      final counterRef = _firestore.collection('counters').doc('pedidos');
      final nuevoPedidoRef = _firestore.collection('pedidos').doc();

      final pedidoCreado = await _firestore.runTransaction<Pedido>((tx) async {
        final counterSnap = await tx.get(counterRef);

        final int ultimoNum = counterSnap.exists
            ? ((counterSnap.data()?['last_num'] ?? 0) as num).toInt()
            : 0;
        final int nuevoNum = ultimoNum + 1;

        final folioGenerado = 'ORD-${nuevoNum.toString().padLeft(3, '0')}';

        final pedidoConFolio = pedido.copyWith(
          folio: folioGenerado,
          estado: EstadoPedido.enCola,
          fechaRegistro: DateTime.now(),
        );

        tx.set(counterRef, {'last_num': nuevoNum}, SetOptions(merge: true));
        tx.set(nuevoPedidoRef, pedidoConFolio.toMap());

        return pedidoConFolio.copyWith(id: nuevoPedidoRef.id);
      });

      return pedidoCreado;
    } catch (e) {
      throw Exception('Error al registrar el pedido en la base de datos.');
    }
  }

  /// Stream de todos los pedidos ordenados por fecha de registro descendente.
  /// Se usará en el tablero del siguiente feature para listar en tiempo real.
  Stream<List<Pedido>> streamPedidos() {
    return _firestore
        .collection('pedidos')
        .orderBy('fecha_registro', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Pedido.fromMap(doc.data(), id: doc.id))
            .toList());
  }

  /// Actualiza únicamente el estado de un pedido.
  /// Se usará en el BottomSheet / drag & drop del tablero.
  Future<void> actualizarEstado(String pedidoId, EstadoPedido nuevoEstado) async {
    try {
      await _firestore
          .collection('pedidos')
          .doc(pedidoId)
          .update({'estado': nuevoEstado.key});
    } catch (e) {
      throw Exception('Error al actualizar el estado del pedido.');
    }
  }
}