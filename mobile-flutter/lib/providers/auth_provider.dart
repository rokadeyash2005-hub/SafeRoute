import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null && _currentUser!.token.isNotEmpty;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_session');
    if (userData != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userData));
        notifyListeners();
      } catch (_) {
        await prefs.remove('user_session');
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await ApiService.login(email, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', jsonEncode(_currentUser!.toJson()));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(
    String name,
    String email,
    String password,
    String emergencyContact,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await ApiService.register(name, email, password, emergencyContact);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_session', jsonEncode(_currentUser!.toJson()));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void continueAsGuest() {
    _currentUser = UserModel(
      userId: 'demo-guest',
      name: 'Demo Explorer',
      email: 'guest@saferoute.ai',
      emergencyContact: '+91 98765 43210',
      token: 'guest-session-token',
    );
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    notifyListeners();
  }
}
