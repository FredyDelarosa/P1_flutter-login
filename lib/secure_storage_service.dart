import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

class SecureStorageService {
  // Configuración para mayor seguridad en Android
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      // encryptedSharedPreferences está depreciado en v10+ y se maneja automáticamente
    ),
  );

  static const String keyApiKey = 'api_key';
  static const String keySecretToken = 'secret_token';
  static const String keyUserPin = 'user_pin';
  static const String keyBackupCode = 'backup_code';

  // Inicializa datos sensibles si no existen (simulación automática)
  Future<void> initializeSensitiveData() async {
    if (await _storage.read(key: keyApiKey) == null) {
      await _storage.write(key: keyApiKey, value: 'sk_live_51MszH8SJ...');
      await _storage.write(key: keySecretToken, value: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...');
      await _storage.write(key: keyUserPin, value: '1234');
      await _storage.write(key: keyBackupCode, value: 'A1B2-C3D4-E5F6');
      debugPrint('Datos sensibles inicializados en almacenamiento seguro.');
    }
  }

  // Elimina todos los datos sensibles (Remote Wipe)
  Future<void> remoteWipe() async {
    await _storage.deleteAll();
    debugPrint('WIPE REMOTO EJECUTADO: Todos los datos sensibles han sido eliminados.');
  }

  // Leer un dato específico
  Future<String?> readData(String key) async {
    return await _storage.read(key: key);
  }

  // Verificar si hay datos
  Future<bool> hasSensitiveData() async {
    final all = await _storage.readAll();
    return all.isNotEmpty;
  }
}
