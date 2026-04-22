import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/registro_pedido_viewmodel.dart';

class RegistroPedidoScreen extends ConsumerStatefulWidget {
  const RegistroPedidoScreen({super.key});

  @override
  ConsumerState<RegistroPedidoScreen> createState() => _RegistroPedidoScreenState();
}

class _RegistroPedidoScreenState extends ConsumerState<RegistroPedidoScreen> {
  final _formKey = GlobalKey<FormState>();

  final nombreCtr = TextEditingController();
  final telefonoCtr = TextEditingController();
  final descripcionCtr = TextEditingController();

  final Map<String, bool> _interactuados = {
    'Nombre del cliente': false,
    'Teléfono': false,
    'Color': false,
    'Fecha de entrega': false,
  };

  // Colores disponibles (mockup del PDF)
  final List<String> _coloresMock = const [
    'Blanco', 'Negro', 'Rojo', 'Azul', 'Verde', 'Amarillo',
  ];

  @override
  void dispose() {
    nombreCtr.dispose();
    telefonoCtr.dispose();
    descripcionCtr.dispose();
    super.dispose();
  }

  // ==========================================================================
  // VALIDACIONES DE CAMPOS DE TEXTO
  // ==========================================================================
  String? _errorNombre(String v) {
    if (v.trim().isEmpty) return 'Ingrese el nombre del cliente.';
    if (v.trim().length < 2) return 'El nombre es demasiado corto.';
    return null;
  }

  String? _errorTelefono(String v) {
    if (v.trim().isEmpty) return 'Ingrese un teléfono de contacto.';
    final soloDigitos = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (soloDigitos.length != 10) return 'El teléfono debe tener 10 dígitos.';
    return null;
  }

  // ==========================================================================
  // SELECTOR DE FECHA Y HORA
  // ==========================================================================
  Future<void> _seleccionarFechaEntrega() async {
    final vm = ref.read(registroPedidoViewModelProvider.notifier);
    final estado = ref.read(registroPedidoViewModelProvider);
    final ahora = DateTime.now();

    final fechaElegida = await showDatePicker(
      context: context,
      initialDate: estado.fechaEntrega ?? ahora,
      firstDate: ahora,
      lastDate: DateTime(ahora.year + 2),
    );
    if (fechaElegida == null) return;

    if (!mounted) return;
    final horaElegida = await showTimePicker(
      context: context,
      initialTime: estado.fechaEntrega != null
          ? TimeOfDay.fromDateTime(estado.fechaEntrega!)
          : const TimeOfDay(hour: 14, minute: 0),
    );

    final fechaFinal = DateTime(
      fechaElegida.year,
      fechaElegida.month,
      fechaElegida.day,
      horaElegida?.hour ?? 0,
      horaElegida?.minute ?? 0,
    );

    vm.setFechaEntrega(fechaFinal);
    setState(() => _interactuados['Fecha de entrega'] = true);
  }

  // ==========================================================================
  // GUARDAR
  // ==========================================================================
  Future<void> _guardar() async {
    // Forzamos interacción en todos los campos para que se muestren errores.
    setState(() => _interactuados.updateAll((_, __) => true));
    FocusScope.of(context).unfocus();

    final formOk = _formKey.currentState?.validate() ?? false;
    final estado = ref.read(registroPedidoViewModelProvider);
    final vm = ref.read(registroPedidoViewModelProvider.notifier);

    final errorFecha = vm.validarFechaEntrega();
    final colorOk = estado.color != null;

    if (!formOk || !colorOk || errorFecha != null) {
      // El error de fecha es el único que no se muestra inline;
      // lo mostramos como SnackBar para que el operador lo vea.
      if (errorFecha != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorFecha), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      final folio = await vm.guardarPedido(
        nombreCliente: nombreCtr.text,
        telefonoCliente: telefonoCtr.text,
        descripcion: descripcionCtr.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido $folio registrado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final mensaje = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
      );
    }
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final datos = ref.watch(datosCotizadosProvider);
    final estado = ref.watch(registroPedidoViewModelProvider);
    final vm = ref.read(registroPedidoViewModelProvider.notifier);
    final currency = NumberFormat.simpleCurrency(locale: 'en_US', decimalDigits: 2);

    // Si por algún motivo se llegó aquí sin pasar por cotización, protegemos.
    if (datos == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: _buildAppBar(),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'Primero debes realizar una cotización.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF1B396A)),
            ),
          ),
        ),
      );
    }

    final total = vm.calcularTotal(datos.precioUnitario);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSeccionCliente(),
              const SizedBox(height: 16),
              _buildSeccionDetallesOrden(datos, estado, vm),
              const SizedBox(height: 16),
              _buildSeccionConfiguracion(estado, vm),
              const SizedBox(height: 16),
              _buildSeccionFechaEntrega(estado),
              const SizedBox(height: 16),
              _buildSeccionToggles(estado, vm),
              const SizedBox(height: 24),
              _buildFooterTotal(currency, total, estado.guardando),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Registro de Pedido',
          style: TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFF1B396A),
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }

  // --------------------------------------------------------------------------
  // SECCIÓN: DATOS DEL CLIENTE
  // --------------------------------------------------------------------------
  Widget _buildSeccionCliente() {
    return _buildSeccionCard(
      titulo: 'DATOS DEL CLIENTE',
      children: [
        _buildTextField(
          controller: nombreCtr,
          label: 'Nombre del cliente',
          icon: Icons.person_outline,
          validator: _errorNombre,
          keyboard: TextInputType.name,
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: telefonoCtr,
          label: 'Teléfono',
          icon: Icons.phone_outlined,
          validator: _errorTelefono,
          keyboard: TextInputType.phone,
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // SECCIÓN: DETALLES DE LA ORDEN
  // --------------------------------------------------------------------------
  Widget _buildSeccionDetallesOrden(
    DatosCotizados datos,
    RegistroPedidoState estado,
    RegistroPedidoViewModel vm,
  ) {
    return _buildSeccionCard(
      titulo: 'DETALLES DE LA ORDEN',
      children: [
        // Material (read-only, viene de cotización)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF117533), width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.view_in_ar_outlined, color: Color(0xFF1B396A)),
              const SizedBox(width: 10),
              Text(datos.material,
                  style: const TextStyle(
                      fontSize: 16, color: Color(0xFF1B396A),
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              const Text('(desde cotización)',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: descripcionCtr,
          maxLines: 3,
          decoration: _getCustomDecoration(
            label: 'Descripción de la Orden (opcional)',
            tieneError: false,
          ),
        ),
        const SizedBox(height: 12),
        // Selector de cantidad con - / +
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF117533), width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Text('Cantidad',
                  style: TextStyle(fontSize: 16, color: Color(0xFF1B396A))),
              const Spacer(),
              _iconCuadrado(Icons.remove, vm.decrementarCantidad,
                  habilitado: estado.cantidad > 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('${estado.cantidad}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              _iconCuadrado(Icons.add, vm.incrementarCantidad),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconCuadrado(IconData icon, VoidCallback onTap,
      {bool habilitado = true}) {
    return InkWell(
      onTap: habilitado ? onTap : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: habilitado
              ? const Color(0xFFF5F5F5)
              : const Color(0xFFF5F5F5).withOpacity(0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon,
            size: 18,
            color: habilitado ? const Color(0xFF1B396A) : Colors.grey),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SECCIÓN: CONFIGURACIÓN DE IMPRESIÓN (COLOR)
  // --------------------------------------------------------------------------
  Widget _buildSeccionConfiguracion(
      RegistroPedidoState estado, RegistroPedidoViewModel vm) {
    final errorColor = estado.color == null ? 'Seleccione un color.' : null;
    final tieneError =
        _interactuados['Color'] == true && errorColor != null;

    return _buildSeccionCard(
      titulo: 'CONFIGURACIÓN DE IMPRESIÓN',
      children: [
        DropdownButtonFormField<String>(
          value: estado.color,
          decoration: _getCustomDecoration(
            label: 'Color',
            tieneError: tieneError,
          ).copyWith(
            prefixIcon:
                const Icon(Icons.circle_outlined, color: Color(0xFF1B396A)),
          ),
          icon: const Icon(Icons.arrow_drop_down),
          items: _coloresMock
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (v) {
            vm.setColor(v);
            setState(() => _interactuados['Color'] = true);
          },
          validator: (_) => errorColor,
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // SECCIÓN: FECHA DE ENTREGA
  // --------------------------------------------------------------------------
  Widget _buildSeccionFechaEntrega(RegistroPedidoState estado) {
    final fechaFmt = estado.fechaEntrega != null
        ? DateFormat('dd/MM/yyyy').format(estado.fechaEntrega!)
        : 'dd/mm/aaaa';
    final horaFmt = estado.fechaEntrega != null
        ? DateFormat('HH:mm').format(estado.fechaEntrega!)
        : '--:--';

    return _buildSeccionCard(
      titulo: estado.esUrgente
          ? 'FECHA DE ENTREGA *'
          : 'FECHA DE ENTREGA (opcional)',
      children: [
        InkWell(
          onTap: _seleccionarFechaEntrega,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Expanded(child: _pillFecha(Icons.calendar_today_outlined, fechaFmt)),
              const SizedBox(width: 10),
              Expanded(child: _pillFecha(Icons.access_time, horaFmt)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pillFecha(IconData icon, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF117533), width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1B396A)),
          const SizedBox(width: 8),
          Text(texto, style: const TextStyle(color: Color(0xFF1B396A))),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SECCIÓN: TOGGLES (DESCUENTO / URGENTE)
  // --------------------------------------------------------------------------
  Widget _buildSeccionToggles(
      RegistroPedidoState estado, RegistroPedidoViewModel vm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: estado.esEstudiante,
            onChanged: vm.toggleEstudiante,
            activeColor: const Color(0xFF1B396A),
            title: Row(
              children: const [
                Icon(Icons.school_outlined, color: Color(0xFF1B396A), size: 20),
                SizedBox(width: 10),
                Text('Descuento Estudiante'),
              ],
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: estado.esUrgente,
            onChanged: vm.toggleUrgente,
            activeColor: const Color(0xFF1B396A),
            title: Row(
              children: const [
                Icon(Icons.bolt_outlined, color: Color(0xFF1B396A), size: 20),
                SizedBox(width: 10),
                Text('Pedido Urgente'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // FOOTER: TOTAL + BOTONES
  // --------------------------------------------------------------------------
  Widget _buildFooterTotal(NumberFormat currency, double total, bool guardando) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total:',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Text(currency.format(total),
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B396A))),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1B396A)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: guardando ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancelar',
                        style: TextStyle(
                            color: Color(0xFF1B396A),
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B396A),
                      disabledBackgroundColor:
                          const Color(0xFF1B396A).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: guardando ? null : _guardar,
                    child: guardando
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('Guardar Pedido',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // HELPERS DE ESTILO
  // --------------------------------------------------------------------------
  /// Tarjeta contenedora con título pequeño azul (como el mockup del PDF).
  Widget _buildSeccionCard({
    required String titulo,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B396A),
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String) validator,
    TextInputType? keyboard,
  }) {
    final errorActual = validator(controller.text);
    final tieneError =
        _interactuados[label] == true && errorActual != null;

    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: _getCustomDecoration(label: label, tieneError: tieneError)
          .copyWith(prefixIcon: Icon(icon, color: const Color(0xFF1B396A))),
      onChanged: (_) {
        setState(() => _interactuados[label] = true);
      },
      validator: (v) => validator(v ?? ''),
    );
  }

  /// Reutilizamos la misma decoración que cotizacion_screen.dart
  /// para mantener consistencia visual en todo el app.
  InputDecoration _getCustomDecoration({
    required String label,
    required bool tieneError,
  }) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFF117533), width: 1.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFF1B396A), width: 2)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2)),
      errorStyle: const TextStyle(color: Colors.red, fontSize: 13),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: tieneError
          ? Container(
              width: 44,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                    left: BorderSide(color: Colors.red, width: 1.5)),
              ),
              child: const Icon(Icons.error, color: Colors.red),
            )
          : null,
    );
  }
}