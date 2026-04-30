import 'package:flutter/material.dart';
import 'package:sis_impresion_3d/ui/screens/cotizacion_screen.dart';
import 'configuracion_screen.dart';
import 'pedidos_screen.dart'; // <-- NUEVO

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceActual = 0;

  final List<Widget> _pantallas = [
    const CotizacionScreen(),
    const PedidosScreen(),      // <-- NUEVO
    const ConfiguracionScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pantallas[_indiceActual],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        onTap: (index) {
          setState(() {
            _indiceActual = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1B365D),
        unselectedItemColor: const Color(0xFF807E82),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        type: BottomNavigationBarType.fixed, // <-- NUEVO
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: 'Cotizar',
          ),
          BottomNavigationBarItem(            // <-- NUEVO
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Pedidos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}