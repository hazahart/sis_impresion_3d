import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/financial_config.dart';

class ConfigRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<FinancialConfig?> getConfig() async {
    try {
      final doc = await _firestore
          .collection('settings')
          .doc('financiero')
          .get();
      if (doc.exists && doc.data() != null) {
        return FinancialConfig.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Error de conexión con la base de datos.');
    }
  }

  Future<void> saveConfig(FinancialConfig config) async {
    try {
      await _firestore
          .collection('settings')
          .doc('financiero')
          .set(config.toMap());
    } catch (e) {
      throw Exception('Error al guardar en la nube.');
    }
  }
}
