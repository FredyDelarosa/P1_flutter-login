import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safe_device/safe_device.dart';
import 'package:geolocator/geolocator.dart';
import 'package:detect_fake_location/detect_fake_location.dart';
import 'screens/security_blocked_screen.dart';
import 'screens/adb_blocked_screen.dart';

class GlobalSecurityGatekeeper extends StatefulWidget {
  final Widget child;
  const GlobalSecurityGatekeeper({super.key, required this.child});

  // Notificador para forzar la simulación del bloqueo en modo debug/desarrollo
  static final ValueNotifier<bool> forceBlockNotifier = ValueNotifier<bool>(false);

  @override
  State<GlobalSecurityGatekeeper> createState() => _GlobalSecurityGatekeeperState();
}

class _GlobalSecurityGatekeeperState extends State<GlobalSecurityGatekeeper> with WidgetsBindingObserver {
  bool _isMockLocation = false;
  bool _isAdbEnabled = false;
  bool _isLoading = true;
  int _securityCheckToken = 0;

  static const MethodChannel _securityChannel = MethodChannel('com.example.p1/security');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    GlobalSecurityGatekeeper.forceBlockNotifier.addListener(_onForceBlockChanged);
    _checkSecurity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GlobalSecurityGatekeeper.forceBlockNotifier.removeListener(_onForceBlockChanged);
    super.dispose();
  }

  void _onForceBlockChanged() {
    if (mounted) {
      _checkSecurity();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _checkSecurity();
      });
    }
  }

  // Comprobación de Depuración USB (ADB) usando MethodChannels (Opción B) y SafeDevice (Opción A)
  Future<bool> _checkAdbStatus() async {
    if (!Platform.isAndroid) return false;

    // Opción B (Principal): Consulta directa mediante MethodChannel a Settings.Global
    try {
      final bool? adbEnabled = await _securityChannel.invokeMethod<bool>('isAdbEnabled');
      if (adbEnabled != null) {
        debugPrint('ADB detectado mediante MethodChannel (Opción B): $adbEnabled');
        return adbEnabled;
      }
    } catch (e) {
      debugPrint('Error al invocar MethodChannel para ADB: $e');
    }

    // Opción A (Fallback): Consulta mediante paquete de la comunidad
    try {
      final bool isDevMode = await SafeDevice.isDevelopmentModeEnable;
      debugPrint('Modo de desarrollo detectado mediante SafeDevice (Opción A): $isDevMode');
      return isDevMode;
    } catch (e) {
      debugPrint('Error al consultar SafeDevice.isDevelopmentModeEnable: $e');
    }

    return false;
  }

  Future<void> _checkSecurity() async {
    final int currentToken = ++_securityCheckToken;

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // 1. Verificación de depuración USB
      final bool adbActive = await _checkAdbStatus();

      // 2. Verificación de ubicación falsa
      PermissionStatus status = await Permission.location.status;
      if (status.isDenied) {
        status = await Permission.location.request();
      }

      bool isMockSafeDevice = false;
      bool isMockGeolocator = false;
      bool isMockDetectFake = false;

      if (status.isGranted) {
        final results = await _collectMockLocationSignals();

        isMockSafeDevice = results.$1;
        isMockGeolocator = results.$2;
        isMockDetectFake = results.$3;

        debugPrint('--- RESULTADOS DE SEGURIDAD ---');
        debugPrint('USB Debugging (ADB) Activo: $adbActive');
        debugPrint('SafeDevice Mock: $isMockSafeDevice');
        debugPrint('Geolocator Mock: $isMockGeolocator');
        debugPrint('DetectFake Mock: $isMockDetectFake');
        debugPrint('Real Device: ${await SafeDevice.isRealDevice}');
        debugPrint('-------------------------------');

        if (!mounted || currentToken != _securityCheckToken) {
          return;
        }

        setState(() {
          _isAdbEnabled = adbActive;
          _isMockLocation = isMockSafeDevice || isMockGeolocator || isMockDetectFake;
          _isLoading = false;
        });
      } else {
        isMockSafeDevice = await SafeDevice.isMockLocation;

        if (!mounted || currentToken != _securityCheckToken) {
          return;
        }

        setState(() {
          _isAdbEnabled = adbActive;
          _isMockLocation = isMockSafeDevice;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted || currentToken != _securityCheckToken) {
        return;
      }

      debugPrint('Error en verificación: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<(bool, bool, bool)> _collectMockLocationSignals() async {
    final firstPass = await Future.wait([
      SafeDevice.isMockLocation,
      _getGeolocatorMock(),
      _getDetectFakeLocationMock(),
    ]);

    final firstPassMock = firstPass[0] || firstPass[1] || firstPass[2];
    if (!firstPassMock) {
      return (firstPass[0], firstPass[1], firstPass[2]);
    }

    await Future.delayed(const Duration(milliseconds: 800));

    final secondPass = await Future.wait([
      SafeDevice.isMockLocation,
      _getGeolocatorMock(),
      _getDetectFakeLocationMock(),
    ]);

    return (secondPass[0], secondPass[1], secondPass[2]);
  }

  Future<bool> _getGeolocatorMock() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;
      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      return position.isMocked;
    } catch (e) {
      debugPrint('Error Geolocator: $e');
      return false;
    }
  }

  Future<bool> _getDetectFakeLocationMock() async {
    try {
      return await DetectFakeLocation().detectFakeLocation();
    } catch (e) {
      debugPrint('Error DetectFakeLocation: $e');
      return false;
    }
  }

  // Evalúa si se debe bloquear la aplicación por depuración USB.
  // No aplica si está en modo de desarrollo local (kDebugMode), a menos que
  // se fuerce manualmente mediante el notificador para fines de prueba/evaluación.
  bool get _shouldBlockAdb {
    final bool isProductionOrForced = !kDebugMode || GlobalSecurityGatekeeper.forceBlockNotifier.value;
    return _isAdbEnabled && isProductionOrForced;
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldBlockAdb) {
      return const AdbBlockedScreen();
    }

    if (_isMockLocation) {
      return const SecurityBlockedScreen();
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Verificando seguridad...'),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}

