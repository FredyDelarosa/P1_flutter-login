import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userKeyPrefix = 'user_';

  // Registrar un usuario: guarda la contraseña asociada al nombre de usuario
  Future<bool> register(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Verificar si el usuario ya existe
    if (prefs.containsKey('$_userKeyPrefix$username')) {
      return false;
    }
    
    return await prefs.setString('$_userKeyPrefix$username', password);
  }

  // Iniciar sesión: verifica si el usuario existe y la contraseña coincide
  Future<bool> login(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString('$_userKeyPrefix$username');
    
    final success = storedPassword != null && storedPassword == password;
    if (success) {
      await prefs.setString('current_logged_in_user', username);
    }
    return success;
  }
}
