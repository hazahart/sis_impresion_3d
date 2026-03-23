import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sis_impresion_3d/viewmodels/cotizacion_viewmodel.dart';

class CotizacionScreen extends ConsumerStatefulWidget {
  const CotizacionScreen({super.key});

  @override
  ConsumerState<CotizacionScreen> createState() => _CotizacionScreenState();
}

class _CotizacionScreenState extends ConsumerState<CotizacionScreen> {
  final _formKey = GlobalKey<FormState>();

  final pesoCtr = TextEditingController();
  final horasCtr = TextEditingController();
  final minutosCtr = TextEditingController();

  String? _filamentoSeleccionado;
  bool _isFormValid = false;
  
  final Map<String, bool> _interactuados = {
    'Peso (g)': false,
    'Horas': false,
    'Minutos': false,
    'Tipo de filamento': false,
  };

  final List<String> _filamentosMock = ['PLA', 'PETG', 'ABS', 'TPU'];

  @override
  void dispose() {
    pesoCtr.dispose();
    horasCtr.dispose();
    minutosCtr.dispose();
    super.dispose();
  }

  void _validarFormularioEnTiempoReal() {
    setState(() {
      final p = double.tryParse(pesoCtr.text);
      final h = int.tryParse(horasCtr.text);
      final m = int.tryParse(minutosCtr.text);

      bool isValid = true;
      if (p == null || p <= 0) isValid = false;
      if (h == null || h < 0) isValid = false;
      if (m == null || m < 0 || m > 59) isValid = false;
      if (h != null && m != null && h == 0 && m == 0) isValid = false;
      if (_filamentoSeleccionado == null) isValid = false;

      _isFormValid = isValid;
    });
  }

  void _mostrarModalResultado(BuildContext context, ResultadoCotizacion resultado) {
    final currencyFormatter = NumberFormat.simpleCurrency(locale: 'en_US', decimalDigits: 2);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (BuildContext bc) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cotización Estimada',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B396A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'El precio sugerido al cliente es:',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1B396A), width: 2),
                ),
                child: Text(
                  currencyFormatter.format(resultado.total),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1B396A),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF117533),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(cotizacionViewModelProvider).resetearCalculo();

                    setState(() {
                      pesoCtr.clear();
                      horasCtr.clear();
                      minutosCtr.clear();
                      _filamentoSeleccionado = null;
                      _isFormValid = false;
                      _interactuados.updateAll((key, value) => false);
                    });
                  },
                  child: const Text(
                    'Nueva Cotización',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ResultadoCotizacion?>(precioFinalCalculadoProvider, (previous, next) {
      if (next != null) {
        _mostrarModalResultado(context, next);
      }
    });

    final errorDropdown = _filamentoSeleccionado == null ? 'Seleccione un tipo de filamento.' : null;
    final dropdownTieneError = _interactuados['Tipo de filamento'] == true && errorDropdown != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Cotización', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1B396A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildInputField(controller: pesoCtr, label: 'Peso (g)', hint: '0.00', isDecimal: true),
              const SizedBox(height: 20),
              _buildInputField(controller: horasCtr, label: 'Horas', hint: '0', isDecimal: false),
              const SizedBox(height: 20),
              _buildInputField(controller: minutosCtr, label: 'Minutos', hint: '0', isDecimal: false),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _filamentoSeleccionado,
                decoration: _getCustomDecoration(label: 'Tipo de filamento', tieneError: dropdownTieneError),
                icon: const Icon(Icons.arrow_drop_down),
                items: _filamentosMock.map((String filamento) {
                  return DropdownMenuItem<String>(value: filamento, child: Text(filamento));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _filamentoSeleccionado = value;
                    _interactuados['Tipo de filamento'] = true;
                  });
                  _validarFormularioEnTiempoReal();
                },
                validator: (value) => errorDropdown,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF117533),
                    disabledBackgroundColor: const Color(0xFF117533).withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _isFormValid ? () {
                    FocusScope.of(context).unfocus();
                    ref.read(cotizacionViewModelProvider).ejecutarAlgoritmoCosteo(
                      w: double.parse(pesoCtr.text),
                      h: int.parse(horasCtr.text),
                      min: int.parse(minutosCtr.text)
                    );
                  } : null,
                  child: const Text('Calcular', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDecimal,
  }) {
    String? obtenerError(String value) {
      if (value.isEmpty) return 'Ingrese un valor válido.';
      if (isDecimal) {
        final numero = double.tryParse(value);
        if (numero == null || numero <= 0) return 'Ingrese un valor válido.';
      } else {
        final numero = int.tryParse(value);
        if (numero == null) return 'Ingrese un valor válido.';
        if (label == 'Horas' && numero < 0) return 'Ingrese un valor válido.';
        if (label == 'Minutos' && (numero < 0 || numero > 59)) return 'Ingrese un valor válido.';
      }
      if (label == 'Horas' || label == 'Minutos') {
        final h = int.tryParse(horasCtr.text) ?? 0;
        final m = int.tryParse(minutosCtr.text) ?? 0;
        if (h == 0 && m == 0 && (horasCtr.text.isNotEmpty || minutosCtr.text.isNotEmpty)) {
          return 'El tiempo no puede ser cero.';
        }
      }
      return null;
    }

    final errorActual = obtenerError(controller.text);
    final tieneError = _interactuados[label] == true && errorActual != null;

    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      decoration: _getCustomDecoration(label: label, tieneError: tieneError).copyWith(hintText: hint),
      onChanged: (value) {
        setState(() {
          _interactuados[label] = true;
        });
        _validarFormularioEnTiempoReal();
      },
      validator: (value) => obtenerError(value ?? ''),
    );
  }

  InputDecoration _getCustomDecoration({required String label, required bool tieneError}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF117533), width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF1B396A), width: 2)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red, width: 2)),
      errorStyle: const TextStyle(color: Colors.red, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: tieneError
        ? Container(
            width: 44, margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(border: Border(left: BorderSide(color: Colors.red, width: 1.5))),
            child: const Icon(Icons.error, color: Colors.red),
          ) : null,
    );
  }
}