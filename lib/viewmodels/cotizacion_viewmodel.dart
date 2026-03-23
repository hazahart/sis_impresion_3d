import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'config_viewmodel.dart';

class ResultadoCotizacion {
  final double total;

  ResultadoCotizacion({
    required this.total
  });
}

final precioFinalCalculadoProvider = StateProvider<ResultadoCotizacion?>((ref) => null);
final cotizacionViewModelProvider = Provider((ref) => CotizacionViewModel(ref));

class CotizacionViewModel {
  final Ref ref;

  CotizacionViewModel(this.ref);

  void ejecutarAlgoritmoCosteo({
    required double w,
    required int h,
    required int min,
  }) {
    final configState = ref.read(configViewModelProvider);

    configState.whenData((config) {
      if (config == null) {
        ref.read(precioFinalCalculadoProvider.notifier).state = null;
        return;
      }

      double cG = config.costoGramo;
      double cE = config.costoElectricidad;
      double d = config.depreciacion;
      double m = config.margen;

      double t = h + (min / 60.0);

      double cBase = (w * cG) + (t * cE * 0.15) + (t * d);

      double precioFinal = cBase * (1 + (m / 100.0));

      precioFinal = (precioFinal * 100).truncateToDouble() / 100;

      ref.read(precioFinalCalculadoProvider.notifier).state = ResultadoCotizacion(
        total: precioFinal
      );
    });
  }

  void resetearCalculo() {
    ref.read(precioFinalCalculadoProvider.notifier).state = null;
  }
}