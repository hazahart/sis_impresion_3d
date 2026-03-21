import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/config_viewmodel.dart';

class ConfiguracionScreen extends ConsumerStatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  ConsumerState<ConfiguracionScreen> createState() =>
      _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends ConsumerState<ConfiguracionScreen> {
  final _formKey = GlobalKey<FormState>();
  final gramoCtr = TextEditingController();
  final luzCtr = TextEditingController();
  final depreciacionCtr = TextEditingController();
  final margenCtr = TextEditingController();

  bool _datosCargados = false;

  @override
  void dispose() {
    gramoCtr.dispose();
    luzCtr.dispose();
    depreciacionCtr.dispose();
    margenCtr.dispose();
    super.dispose();
  }

  void _guardarDatos() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref
            .read(configViewModelProvider.notifier)
            .updateConfig(
              gramoStr: gramoCtr.text,
              luzStr: luzCtr.text,
              depreciacionStr: depreciacionCtr.text,
              margenStr: margenCtr.text,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuración guardada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar en Firebase'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configState = ref.watch(configViewModelProvider);

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Costos financieros',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color(0xFF1B396A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: configState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (config) {
          if (config != null && !_datosCargados) {
            gramoCtr.text = config.costoGramo.toString();
            luzCtr.text = config.costoElectricidad.toString();
            depreciacionCtr.text = config.depreciacion.toString();
            margenCtr.text = config.margen.toString();
            _datosCargados = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInputField(
                    controller: gramoCtr,
                    label: 'Costo por Gramo (\$)',
                    hint: '0.00',
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: luzCtr,
                    label: 'Electricidad (\$)',
                    hint: '0.00',
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: depreciacionCtr,
                    label: 'Depreciación (\$)',
                    hint: '0.00',
                  ),
                  const SizedBox(height: 20),
                  _buildInputField(
                    controller: margenCtr,
                    label: 'Margen (%)',
                    hint: '0',
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF117533),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _guardarDatos,
                      child: const Text(
                        'Guardar',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Ingrese un valor válido.';
            }

            final numero = double.tryParse(value);

            if (numero == null) {
              return 'Solo se admiten números.';
            } else if (numero < 0) {
              return 'El valor no puede ser negativo.';
            }

            return null; 
          },
        ),
      ],
    );
  }
}
