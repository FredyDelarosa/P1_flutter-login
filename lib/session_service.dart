import 'dart:async';
import 'package:flutter/material.dart';
import 'app.dart';
import 'screens/login_screen.dart';

class SessionService extends ChangeNotifier {
  Timer? _timer;
  final int _timeoutInSeconds;
  bool _isSessionExpired = false;
  bool _isActive = false;

  SessionService({int timeoutInSeconds = 10}) : _timeoutInSeconds = timeoutInSeconds;

  bool get isSessionExpired => _isSessionExpired;
  bool get isActive => _isActive;

  void startSession() {
    _isActive = true;
    _isSessionExpired = false;
    _startTimer();
    debugPrint('Sesión iniciada. Temporizador activado.');
  }

  void stopSession() {
    _isActive = false;
    _stopTimer();
    debugPrint('Sesión finalizada. Temporizador detenido.');
  }

  void resetTimer() {
    if (!_isActive || _isSessionExpired) return;
    _startTimer();
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer(Duration(seconds: _timeoutInSeconds), _onSessionTimeout);
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _onSessionTimeout() {
    if (!_isActive) return;
    _isSessionExpired = true;
    _isActive = false;
    _stopTimer();
    notifyListeners();
    _handleLogout();
  }

  void _handleLogout() {
    final context = MyApp.navigatorKey.currentContext;
    if (context != null) {
      debugPrint('Sesión expirada por inactividad.');
      
      // Redirigir al login y limpiar el historial
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      // Mostrar notificación de expiración persistente
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 10),
              Text('Sesión Expirada'),
            ],
          ),
          content: const Text(
            'Por su seguridad, la sesión ha sido cerrada debido a un periodo prolongado de inactividad.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ENTENDIDO', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
