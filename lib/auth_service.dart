import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userKeyPrefix = 'user_';

  Future<bool> register(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (prefs.containsKey('$_userKeyPrefix$username')) {
      return false;
    }
    
    return await prefs.setString('$_userKeyPrefix$username', password);
  }

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
