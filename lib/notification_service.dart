import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'secure_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final SecureStorageService _secureStorage = SecureStorageService();

  // Notificador para avisar a la interfaz que se realizó un wipe
  static final ValueNotifier<int> wipeNotifier = ValueNotifier<int>(0);

  Future<void> initialize() async {
    // Solicitar permisos en iOS
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Permiso de notificaciones concedido');
    }

    // Obtener el token del dispositivo (útil para enviar notificaciones específicas)
    String? token = await _fcm.getToken();
    debugPrint("FCM Token: $token");

    // Manejar mensajes en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleMessage(message);
    });

    // Manejar mensajes cuando la app está en segundo plano o cerrada y es abierta
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });
  }

  void _handleMessage(RemoteMessage message) async {
    debugPrint('Mensaje recibido: ${message.data}');

    // Verificar si es una instrucción de wipe remoto
    // Se espera que la notificación tenga un campo 'action': 'remote_wipe'
    // y opcionalmente el 'username' para asegurar que sea para este usuario específico
    if (message.data['action'] == 'remote_wipe') {
      final targetUser = message.data['username'];
      
      // Obtener el usuario actual logueado desde SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final currentUser = prefs.getString('current_logged_in_user');

      if (targetUser == null || targetUser == currentUser) {
        debugPrint('Comando de Wipe Remoto recibido para el usuario: $currentUser');
        await _secureStorage.remoteWipe();
        
        // Avisar a cualquier pantalla activa que los datos han cambiado
        wipeNotifier.value++;
      }
    }
  }
}

// Handler para mensajes en segundo plano (debe estar fuera de la clase y ser top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Manejando mensaje en segundo plano: ${message.messageId}");
  
  if (message.data['action'] == 'remote_wipe') {
    final secureStorage = SecureStorageService();
    await secureStorage.remoteWipe();
    
    // En segundo plano no tenemos fácil acceso a SharedPreferences del mismo modo
    // pero el wipe del SecureStorage sí se ejecutará.
  }
}
