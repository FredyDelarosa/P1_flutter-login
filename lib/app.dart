import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'security_gatekeeper.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Login App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      builder: (context, child) {
        return GlobalSecurityGatekeeper(child: child!);
      },
      home: const LoginScreen(),
    );
  }
}
