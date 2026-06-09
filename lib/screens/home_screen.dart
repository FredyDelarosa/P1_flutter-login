import 'package:flutter/material.dart';
import '../secure_storage_service.dart';
import '../notification_service.dart';
import 'login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SecureStorageService _secureStorage = SecureStorageService();
  Map<String, String> _sensitiveData = {};
  bool _isLoading = true;
  String _username = '';

  @override
  void initState() {
    super.initState();
    NotificationService.wipeNotifier.addListener(_loadData);
    _loadInitialInfo();
  }

  @override
  void dispose() {
    NotificationService.wipeNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadInitialInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('current_logged_in_user') ?? 'Usuario';
    });
    await _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    // Ya no inicializamos automáticamente aquí para permitir pruebas de borrado real
    
    final apiKey = await _secureStorage.readData(SecureStorageService.keyApiKey);
    final token = await _secureStorage.readData(SecureStorageService.keySecretToken);
    final pin = await _secureStorage.readData(SecureStorageService.keyUserPin);
    final backup = await _secureStorage.readData(SecureStorageService.keyBackupCode);

    if (mounted) {
      setState(() {
        _sensitiveData = {
          'API Key': apiKey ?? 'ELIMINADO',
          'Secret Token': token ?? 'ELIMINADO',
          'User PIN': pin ?? 'ELIMINADO',
          'Backup Code': backup ?? 'ELIMINADO',
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _manualInitialize() async {
    setState(() => _isLoading = true);
    await _secureStorage.initializeSensitiveData();
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Datos inicializados para pruebas.')),
      );
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_logged_in_user');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Hola, $_username',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Inicializar datos',
            icon: const Icon(Icons.add_moderator_rounded, color: Colors.blueAccent),
            onPressed: _manualInitialize,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black54),
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  const Text(
                    'Panel de Seguridad',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gestiona tus credenciales sensibles cifradas.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  ..._sensitiveData.entries.map((e) => _buildDataCard(e.key, e.value)),
                  const SizedBox(height: 32),
                  _buildWipeInfoCard(),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadData,
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        label: const Text('ACTUALIZAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDataCard(String title, String value) {
    final bool isDeleted = value == 'ELIMINADO';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (isDeleted ? Colors.red : Colors.green).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isDeleted ? Icons.no_encryption_gmailerrorred_rounded : Icons.lock_outline_rounded,
            color: isDeleted ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            color: isDeleted ? Colors.red[700] : Colors.green[700],
            fontFamily: 'monospace',
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildWipeInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).primaryColor, const Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Wipe Remoto Activo',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Si tu dispositivo se pierde o es comprometido, podemos borrar estos datos remotamente mediante una señal cifrada.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
