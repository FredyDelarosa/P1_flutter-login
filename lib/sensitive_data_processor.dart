import 'dart:convert';

class SensitiveDataProcessor {
  static const String _secretEncryptionKey = "SUPER_SECRET_KEY_12345";
  static const String _backendApiUrl = "https://api.banco-seguro.com/v1/process";

  String processCreditCard(String cardNumber, String ccv) {
    final rawData = "$cardNumber|$ccv|$_secretEncryptionKey";
    final bytes = utf8.encode(rawData);
    final base64Data = base64Encode(bytes);
    
    _simulateNetworkRequest(base64Data);
    
    return base64Data;
  }

  void _simulateNetworkRequest(String encryptedPayload) {
    print("Enviando datos a: $_backendApiUrl");
    print("Payload cifrado: $encryptedPayload");
  }

  String decryptData(String encryptedPayload) {
    try {
      final bytes = base64Decode(encryptedPayload);
      final rawData = utf8.decode(bytes);
      return rawData.split('|').first; 
    } catch (e) {
      return "Error al descifrar";
    }
  }
}
