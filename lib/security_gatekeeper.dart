import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safe_device/safe_device.dart';
import 'package:geolocator/geolocator.dart';
import 'package:detect_fake_location/detect_fake_location.dart';
import 'screens/security_blocked_screen.dart';

class GlobalSecurityGatekeeper extends StatefulWidget {
  final Widget child;
  const GlobalSecurityGatekeeper({super.key, required this.child});

  @override
  State<GlobalSecurityGatekeeper> createState() => _GlobalSecurityGatekeeperState();
}

class _GlobalSecurityGatekeeperState extends State<GlobalSecurityGatekeeper> with WidgetsBindingObserver {
  bool _isMockLocation = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkSecurity();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _checkSecurity();
      });
    }
  }

  Future<void> _checkSecurity() async {
    if (!_isMockLocation) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      PermissionStatus status = await Permission.location.status;
      if (status.isDenied) {
        status = await Permission.location.request();
      }

      bool isMockSafeDevice = false;
      bool isMockGeolocator = false;
      bool isMockDetectFake = false;

      if (status.isGranted) {
        final results = await Future.wait([
          SafeDevice.isMockLocation,
          _getGeolocatorMock(),
          _getDetectFakeLocationMock(),
        ]);

        isMockSafeDevice = results[0];
        isMockGeolocator = results[1];
        isMockDetectFake = results[2];

        debugPrint('--- RESULTADOS DE SEGURIDAD ---');
        debugPrint('SafeDevice Mock: $isMockSafeDevice');
        debugPrint('Geolocator Mock: $isMockGeolocator');
        debugPrint('DetectFake Mock: $isMockDetectFake');
        debugPrint('Real Device: ${await SafeDevice.isRealDevice}');
        debugPrint('-------------------------------');

        setState(() {
          _isMockLocation = isMockSafeDevice || isMockGeolocator || isMockDetectFake;
          _isLoading = false;
        });
      } else {
        isMockSafeDevice = await SafeDevice.isMockLocation;
        setState(() {
          _isMockLocation = isMockSafeDevice;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error en verificación: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _getGeolocatorMock() async {
    try {
      // Geolocator requiere que el servicio de GPS esté activo
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

  @override
  Widget build(BuildContext context) {
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
