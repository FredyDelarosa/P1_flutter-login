import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:device_preview/device_preview.dart';
import 'app.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final notificationService = NotificationService();
    await notificationService.initialize();
  } catch (e) {
    debugPrint('Error inicializando Firebase: $e');
  }

  runApp(
    DevicePreview(
      enabled: true, // Siempre habilitado para este ejercicio
      builder: (context) => const MyApp(),
    ),
  );
}
