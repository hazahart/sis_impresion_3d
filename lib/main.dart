import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sis_impresion_3d/ui/screens/cotizacion_screen.dart';
import 'package:sis_impresion_3d/ui/screens/home_screen.dart';

import 'firebase_options.dart';
import 'ui/screens/configuracion_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // #########################
  // #      IMPORTANTE       #
  // #    uso de riverpod    #
  // #########################
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
        textTheme: GoogleFonts.notoSansTextTheme(
          Theme.of(context).textTheme
        ),
      ),
      initialRoute: "/home",
      routes: {
        "/home": (context) => const HomeScreen(),
        "/config_financiera": (context) => const ConfiguracionScreen(),
        "/cotizacion": (context) => const CotizacionScreen(),
      },
    );
  }
}
