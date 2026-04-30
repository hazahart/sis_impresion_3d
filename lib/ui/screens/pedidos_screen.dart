import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/pedido.dart';
import '../../viewmodels/pedidos_viewmodel.dart';
import '../widgets/pedido_card.dart';
import '../widgets/pedido_acciones_sheet.dart';
import '../widgets/pedidos_tab_bar.dart';

class PedidosScreen extends ConsumerStatefulWidget {
  const PedidosScreen({super.key});

  @override
  ConsumerState<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends ConsumerState<PedidosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<PedidosTabInfo> _tabs = [
    PedidosTabInfo(label: 'EN COLA', estado: EstadoPedido.enCola),
    PedidosTabInfo(label: 'ACTIVOS', estado: EstadoPedido.imprimiendo),
    PedidosTabInfo(label: 'HISTORIAL', estado: EstadoPedido.terminado),
  ];

  /// Flag para saber si hay un drag en curso. Cuando es true se muestran
  /// las "hint zones" en los bordes de la pantalla.
  bool _arrastrando = false;

  /// Timer que auto-pagina al tab adyacente cuando el dedo permanece
  /// sobre una zona de borde durante un rato. Evita paginaciones instantáneas.
  Timer? _timerAutoPaginar;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _timerAutoPaginar?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Gestión de Pedidos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1B396A),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: PedidosTabBar(
            controller: _tabController,
            tabs: _tabs,
            onDropPedido: _onDropPedido,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Contenido principal: TabBarView con listas por pestaña
          TabBarView(
            controller: _tabController,
            // Desactivamos el swipe horizontal del usuario cuando está
            // arrastrando, para que el gesto de drag no compita con el
            // scroll horizontal de pestañas.
            physics: _arrastrando
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            children: _tabs.map((t) => _buildListaConDropTarget(t)).toList(),
          ),

          // Hint zones: solo visibles durante drag
          if (_arrastrando) ..._buildZonasDePaginacion(),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Lista envuelta en DragTarget — toda el área de la lista acepta drops.
  // --------------------------------------------------------------------------
  Widget _buildListaConDropTarget(PedidosTabInfo info) {
    return DragTarget<Pedido>(
      onWillAcceptWithDetails: (details) {
        final pedido = details.data;
        if (pedido.estado == info.estado) return false;
        return ref
            .read(pedidosViewModelProvider)
            .transicionesPermitidas(pedido.estado)
            .contains(info.estado);
      },
      onAcceptWithDetails: (details) {
        _onDropPedido(details.data, info.estado);
      },
      builder: (context, candidatos, rechazados) {
        final hovered = candidatos.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: hovered
                ? const Color(0xFF117533).withOpacity(0.08)
                : Colors.transparent,
            border: hovered
                ? Border.all(
                    color: const Color(0xFF117533),
                    width: 2,
                    style: BorderStyle.solid,
                  )
                : null,
          ),
          child: _buildContenidoLista(info),
        );
      },
    );
  }

  Widget _buildContenidoLista(PedidosTabInfo info) {
    final asyncPedidos = ref.watch(pedidosPorEstadoProvider(info.estado));

    return asyncPedidos.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No se pudo cargar los pedidos.\n$err',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF807E82)),
          ),
        ),
      ),
      data: (pedidos) {
        if (pedidos.isEmpty) return _buildEstadoVacio(info);
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          physics: const BouncingScrollPhysics(),
          itemCount: pedidos.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _buildTarjetaArrastrable(pedidos[i]),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // Tarjeta arrastrable
  // --------------------------------------------------------------------------
  Widget _buildTarjetaArrastrable(Pedido p) {
    return LongPressDraggable<Pedido>(
      data: p,
      delay: const Duration(milliseconds: 400),
      onDragStarted: () => setState(() => _arrastrando = true),
      onDraggableCanceled: (_, __) => _terminarArrastre(),
      onDragEnd: (_) => _terminarArrastre(),
      onDragCompleted: () => _terminarArrastre(),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 48,
          child: Opacity(
            opacity: 0.92,
            child: Transform.rotate(angle: 0.02, child: PedidoCard(pedido: p)),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: PedidoCard(pedido: p)),
      child: PedidoCard(pedido: p, onTapMenu: () => _onAccionesPedido(p)),
    );
  }

  void _terminarArrastre() {
    _timerAutoPaginar?.cancel();
    _timerAutoPaginar = null;
    // Sin la guarda previa `if (_arrastrando)` nos aseguramos de que,
    // pase lo que pase, el flag quede en false al terminar el gesto.
    if (mounted && _arrastrando) {
      setState(() => _arrastrando = false);
    }
  }

  // --------------------------------------------------------------------------
  // Zonas de paginación: hotspots invisibles en los bordes izquierdo y derecho.
  // Cuando el dedo arrastrado entra en una, tras un delay breve, se pagina
  // al tab adyacente.
  // --------------------------------------------------------------------------
  List<Widget> _buildZonasDePaginacion() {
    const anchoZona = 56.0;
    return [
      // Zona izquierda — pagina al tab anterior
      Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        width: anchoZona,
        child: _buildHotspot(direccion: -1, mostrandoIcono: Icons.chevron_left),
      ),
      // Zona derecha — pagina al tab siguiente
      Positioned(
        right: 0,
        top: 0,
        bottom: 0,
        width: anchoZona,
        child: _buildHotspot(direccion: 1, mostrandoIcono: Icons.chevron_right),
      ),
    ];
  }

  Widget _buildHotspot({
    required int direccion,
    required IconData mostrandoIcono,
  }) {
    return DragTarget<Pedido>(
      // Acepta cualquier pedido — solo sirve para paginar, no para soltar.
      onWillAcceptWithDetails: (_) {
        _iniciarTimerPaginacion(direccion);
        return false; // devolver false evita que se acepte como drop real
      },
      onLeave: (_) {
        _timerAutoPaginar?.cancel();
        _timerAutoPaginar = null;
      },
      builder: (context, candidatos, __) {
        final activo = candidatos.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            gradient: activo
                ? LinearGradient(
                    begin: direccion < 0
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    end: direccion < 0
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    colors: [
                      const Color(0xFF1B396A).withOpacity(0.25),
                      Colors.transparent,
                    ],
                  )
                : null,
          ),
          child: activo
              ? Center(
                  child: Icon(
                    mostrandoIcono,
                    color: const Color(0xFF1B396A),
                    size: 48,
                  ),
                )
              : null,
        );
      },
    );
  }

  void _iniciarTimerPaginacion(int direccion) {
    _timerAutoPaginar?.cancel();
    _timerAutoPaginar = Timer(const Duration(milliseconds: 500), () {
      final actual = _tabController.index;
      final destino = actual + direccion;
      if (destino >= 0 && destino < _tabs.length) {
        _tabController.animateTo(destino);
      }
    });
  }

  // --------------------------------------------------------------------------
  // Estado vacío
  // --------------------------------------------------------------------------
  Widget _buildEstadoVacio(PedidosTabInfo info) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: Color(0xFF807E82)),
          const SizedBox(height: 12),
          Text(
            'No hay pedidos en ${info.label}',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF807E82),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Acciones
  // --------------------------------------------------------------------------
  void _onAccionesPedido(Pedido pedido) {
    PedidoAccionesSheet.show(context, pedido: pedido);
  }

  Future<void> _onDropPedido(Pedido pedido, EstadoPedido destino) async {
    try {
      await ref.read(pedidosViewModelProvider).cambiarEstado(pedido, destino);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido ${pedido.folio} movido a ${destino.label}'),
          backgroundColor: const Color(0xFF117533),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
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
}
