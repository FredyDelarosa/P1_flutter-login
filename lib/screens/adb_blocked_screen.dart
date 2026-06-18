import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdbBlockedScreen extends StatelessWidget {
  const AdbBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // RASP (Runtime Application Self-Protection) Block Screen for USB Debugging
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.75), // Bloqueo visual del fondo
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: WillPopScope(
            onWillPop: () async => false, // Deshabilita el botón nativo de "Atrás" en Android
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.report_problem_rounded,
                  color: Colors.red.shade800,
                  size: 40,
                ),
              ),
              title: const Text(
                'Depuración USB Detectada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87,
                ),
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Por motivos de seguridad y políticas de protección de datos (RASP), esta aplicación no puede ejecutarse mientras la Depuración USB esté activa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 12),
                  Text(
                    'Instrucciones para continuar:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Ingrese a los Ajustes de su dispositivo.\n'
                    '2. Busque las Opciones de Desarrollador.\n'
                    '3. Desactive la opción Depuración por USB.\n'
                    '4. Reinicie esta aplicación.',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Cierra de manera limpia y segura la aplicación
                      SystemNavigator.pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade800,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'CERRAR APLICACIÓN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
