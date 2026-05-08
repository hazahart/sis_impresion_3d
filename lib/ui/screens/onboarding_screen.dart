import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/usuario.dart';
import '../../viewmodels/registro_viewmodel.dart';
import 'cuenta_en_revision_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  final Usuario usuario;

  const OnboardingScreen({super.key, required this.usuario});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _paginaActual = 0;

  bool _esExterno = false;
  final _controlCtr = TextEditingController();
  String? _carreraSeleccionada;
  int? _semestreSeleccionado;

  final _nombreCtr = TextEditingController();
  final _infoCtr = TextEditingController();

  File? _fotoSeleccionada;
  final _picker = ImagePicker();

  static const List<String> _carreras = [
    'Ing. en Sistemas Computacionales',
    'Ing. Industrial',
    'Ing. Mecatrónica',
    'Ing. Electrónica',
    'Ing. en Gestión Empresarial',
    'Ing. Civil',
    'Ing. Química',
    'Ing. Bioquímica',
    'Ing. Ambiental',
    'Administración',
  ];

  static const List<int> _semestres = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  @override
  void initState() {
    super.initState();
    _infoCtr.text = '¡Hola! Estoy usando SisImpresión 3D.';
  }

  @override
  void dispose() {
    _pageController.dispose();
    _controlCtr.dispose();
    _nombreCtr.dispose();
    _infoCtr.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto(ImageSource source) async {
    Navigator.of(context).pop();
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _fotoSeleccionada = File(picked.path));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo acceder a la cámara o galería.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _mostrarOpcionesFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Foto de perfil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: Color(0xFF1B396A),
              ),
              title: const Text('Cámara'),
              onTap: () => _seleccionarFoto(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Color(0xFF1B396A),
              ),
              title: const Text('Galería'),
              onTap: () => _seleccionarFoto(ImageSource.gallery),
            ),
            if (_fotoSeleccionada != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Eliminar foto',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() => _fotoSeleccionada = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  bool _validarPagina1() {
    if (_esExterno) return true;
    return _controlCtr.text.trim().length == 8 &&
        _carreraSeleccionada != null &&
        _semestreSeleccionado != null;
  }

  bool _validarPagina2() => _nombreCtr.text.trim().length >= 3;

  void _siguiente() {
    FocusScope.of(context).unfocus();
    if (_paginaActual == 0) {
      _irAPagina(1);
      return;
    }
    if (_paginaActual == 1) {
      if (!_validarPagina1()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completa todos los datos escolares.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      _irAPagina(2);
      return;
    }
    if (_paginaActual == 2) _finalizar();
  }

  void _anterior() {
    FocusScope.of(context).unfocus();
    _irAPagina(_paginaActual - 1);
  }

  void _irAPagina(int pagina) {
    _pageController.animateToPage(
      pagina,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finalizar() async {
    if (!_validarPagina2()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre completo es obligatorio.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final vm = ref.read(onboardingViewModelProvider.notifier);
    final uid = widget.usuario.id!;

    try {
      if (_esExterno) {
        await vm.guardarExterno(
          uid: uid,
          nombreCompleto: _nombreCtr.text.trim(),
          info: _infoCtr.text.trim(),
          foto: _fotoSeleccionada,
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CuentaEnRevisionScreen()),
        );
      } else {
        await vm.guardarInstitucional(
          uid: uid,
          nombreCompleto: _nombreCtr.text.trim(),
          numeroControl: _controlCtr.text.trim(),
          carrera: _carreraSeleccionada!,
          semestre: _semestreSeleccionado!,
          info: _infoCtr.text.trim(),
          foto: _fotoSeleccionada,
        );
        if (!mounted) return;
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardando = ref.watch(onboardingViewModelProvider).guardando;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: _paginaActual > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF1B396A)),
                onPressed: _anterior,
              )
            : null,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  3,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 8),
                    width: _paginaActual == i ? 24 : 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _paginaActual == i
                          ? const Color(0xFF1B396A)
                          : const Color(0xFFCCCCCC),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF117533),
                    disabledBackgroundColor: const Color(
                      0xFF117533,
                    ).withOpacity(0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  onPressed: guardando ? null : _siguiente,
                  child: guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _paginaActual == 2 ? 'Finalizar' : 'Siguiente',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _paginaActual == 2
                                  ? Icons.check
                                  : Icons.arrow_forward,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (p) => setState(() => _paginaActual = p),
        children: [
          _buildPaginaBienvenida(),
          _buildPaginaDatosEscolares(),
          _buildPaginaIdentidad(),
        ],
      ),
    );
  }

  Widget _buildPaginaBienvenida() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👋', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 24),
          const Text(
            'Bienvenido',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B396A),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Configura tu perfil para empezar a gestionar tus impresiones 3D de manera fácil y rápida.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF807E82),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginaDatosEscolares() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Datos Escolares',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B396A),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1B396A).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              value: _esExterno,
              onChanged: (v) => setState(() => _esExterno = v),
              activeColor: const Color(0xFF1B396A),
              title: const Text(
                'Soy Externo / Servicio Social',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('No soy estudiante activo.'),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _esExterno
                ? const SizedBox.shrink()
                : Column(
                    children: [
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _controlCtr,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _deco(
                          label: 'Número de control',
                          icon: Icons.badge_outlined,
                        ).copyWith(counterText: ''),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _carreraSeleccionada,
                        isExpanded: true,
                        decoration: _deco(
                          label: 'Carrera',
                          icon: Icons.school_outlined,
                        ),
                        items: _carreras
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _carreraSeleccionada = v),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<int>(
                        value: _semestreSeleccionado,
                        decoration: _deco(
                          label: 'Semestre',
                          icon: Icons.format_list_numbered_outlined,
                        ),
                        items: _semestres
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text('Semestre $s'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _semestreSeleccionado = v),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPaginaIdentidad() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Tu Identidad',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B396A),
            ),
          ),
          const SizedBox(height: 32),

          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _mostrarOpcionesFoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3EAF4),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF1B396A).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: _fotoSeleccionada != null
                              ? Image.file(
                                  _fotoSeleccionada!,
                                  fit: BoxFit.cover,
                                  width: 110,
                                  height: 110,
                                )
                              : const Icon(
                                  Icons.person_outline,
                                  size: 50,
                                  color: Color(0xFF807E82),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF117533),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _fotoSeleccionada != null
                      ? 'Foto seleccionada ✓'
                      : 'Foto de perfil (opcional)',
                  style: TextStyle(
                    fontSize: 12,
                    color: _fotoSeleccionada != null
                        ? const Color(0xFF117533)
                        : const Color(0xFF807E82),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          TextFormField(
            controller: _nombreCtr,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            decoration: _deco(
              label: 'Nombre completo',
              icon: Icons.person_outline,
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _infoCtr,
            decoration: _deco(
              label: 'Info (Estado)',
              icon: Icons.edit_outlined,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Este mensaje será visible en tu perfil.',
            style: TextStyle(fontSize: 12, color: Color(0xFF807E82)),
          ),

          if (_esExterno) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                border: Border.all(color: const Color(0xFFFFCC80)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFE65100), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Al finalizar, tu solicitud quedará pendiente de aprobación por un administrador.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF5D4037)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  InputDecoration _deco({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon, color: const Color(0xFF1B396A)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF117533), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1B396A), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
