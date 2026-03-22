import 'package:flutter/material.dart';
import 'configuracion_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _indiceActual = 0; 

  final List<Widget> _pantallas = [
    // const CotizacionScreen(),
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
        unselectedItemColor: Color(0xFF807E82),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: 'Cotizar',
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