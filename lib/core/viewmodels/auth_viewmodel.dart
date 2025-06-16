import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../models/auth_model.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  bool _isLoading = false;
  String? _error;

  AuthViewModel(this._authRepository);

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> login(String username, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _authRepository.login(username, password);
      
      _isLoading = false;
      notifyListeners();

      if (response.err == 0 && response.dat != null) {
        return true;
      } else {
        _error = response.desc;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authRepository.logout();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 