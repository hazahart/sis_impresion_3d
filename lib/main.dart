import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'ui/screens/auth_wrapper.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/registro_screen.dart';
import 'ui/screens/configuracion_screen.dart';
import 'ui/screens/cotizacion_screen.dart';
import 'ui/screens/registro_pedido_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', '');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: SisImpresion3DApp()));
}

class SisImpresion3DApp extends StatelessWidget {
  const SisImpresion3DApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SisImpresion3D',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1B365D),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF117533)),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansTextTheme(Theme.of(context).textTheme),
      ),
      home: const AuthWrapper(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/registro': (context) => const RegistroScreen(),
        '/config_financiera': (context) => const ConfiguracionScreen(),
        '/cotizacion': (context) => const CotizacionScreen(),
        '/registro_pedido': (context) => const RegistroPedidoScreen(),
      },
    );
  }
}
