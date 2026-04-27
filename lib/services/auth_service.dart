import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  // Register new user
  Future<bool> register(String email, String password,
      {String phoneNumber = ''}) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('user_email') != null) {
      return false; // already exists
    }
    await prefs.setString('user_email', email);
    await prefs.setString('user_password', password);
    await prefs.setString('user_phone', phoneNumber);
    await prefs.setBool('is_logged_in', true);
    return true;
  }

  // Login existing user
  Future<bool> login(String emailOrPhone, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('user_email');
    final savedPhone = prefs.getString('user_phone');
    final savedPassword = prefs.getString('user_password');
    if ((savedEmail == emailOrPhone || savedPhone == emailOrPhone) &&
        savedPassword == password) {
      await prefs.setBool('is_logged_in', true);
      return true;
    }
    return false;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
  }

  // Check if user is already logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // Get user email
  Future<String> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') ?? '';
  }

  // Get user phone
  Future<String> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_phone') ?? '';
  }
}