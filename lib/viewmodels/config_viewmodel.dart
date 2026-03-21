import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/financial_config.dart';
import '../data/config_repository.dart';

final configRepositoryProvider = Provider((ref) => ConfigRepository());

final configViewModelProvider =
    AsyncNotifierProvider<ConfigViewModel, FinancialConfig?>(() {
      return ConfigViewModel();
    });

class ConfigViewModel extends AsyncNotifier<FinancialConfig?> {
  @override
  Future<FinancialConfig?> build() async {
    return ref.read(configRepositoryProvider).getConfig();
  }

  Future<void> updateConfig({
    required String gramoStr,
    required String luzStr,
    required String depreciacionStr,
    required String margenStr,
  }) async {
    final newConfig = FinancialConfig(
      costoGramo: double.tryParse(gramoStr) ?? 0.0,
      costoElectricidad: double.tryParse(luzStr) ?? 0.0,
      depreciacion: double.tryParse(depreciacionStr) ?? 0.0,
      margen: double.tryParse(margenStr) ?? 0.0,
    );

    state = const AsyncValue.loading();
    try {
      await ref.read(configRepositoryProvider).saveConfig(newConfig);
      state = AsyncValue.data(newConfig);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
