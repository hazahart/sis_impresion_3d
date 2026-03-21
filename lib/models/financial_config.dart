class FinancialConfig {
  final double costoGramo;
  final double costoElectricidad;
  final double depreciacion;
  final double margen;

  FinancialConfig({
    required this.costoGramo,
    required this.costoElectricidad,
    required this.depreciacion,
    required this.margen,
  });

  factory FinancialConfig.fromMap(Map<String, dynamic> map) {
    return FinancialConfig(
      costoGramo: (map['costo_gramo'] ?? 0).toDouble(),
      costoElectricidad: (map['costo_electricidad'] ?? 0).toDouble(),
      depreciacion: (map['depreciacion'] ?? 0).toDouble(),
      margen: (map['margen'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'costo_gramo': costoGramo,
      'costo_electricidad': costoElectricidad,
      'depreciacion': depreciacion,
      'margen': margen,
      'ultima_actualizacion': DateTime.now(),
    };
  }
}
