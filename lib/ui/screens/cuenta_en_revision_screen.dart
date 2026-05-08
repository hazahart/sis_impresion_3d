import 'package:flutter/material.dart';

class CuentaEnRevisionScreen extends StatelessWidget {
  const CuentaEnRevisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE65100).withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.hourglass_top_outlined,
                    size: 38,
                    color: Color(0xFFE65100),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Solicitud enviada',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B396A),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tu cuenta está en proceso de validación.\n\n'
                  'El acceso a la plataforma será habilitado '
                  'una vez que un administrador apruebe tu solicitud.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF807E82),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
