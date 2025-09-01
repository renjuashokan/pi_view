import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class LoginViewModel extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  static const String SERVER_IP_KEY = 'server_ip';
  static const String SERVER_PORT_KEY = 'server_port';

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<String?> getLastServerIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SERVER_IP_KEY);
  }

  Future<String?> getLastServerPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(SERVER_PORT_KEY);
  }

  Future<void> saveServerIp(String serverIp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SERVER_IP_KEY, serverIp);
  }

  Future<void> saveServerPort(String serverIp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SERVER_PORT_KEY, serverIp);
  }

  Future<bool> login(
      String server, String port, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await http.get(Uri.parse('http://${server}:${port}/api/v1/files'));
      debugPrint('Status code is ${response.statusCode}');
      if (response.statusCode == 200) {
        _user = User(email: email, password: password);
        await saveServerIp(server); // Save server IP on successful login
        await saveServerPort(port);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Server returned status code: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Unable to connect to the server: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
