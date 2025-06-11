import 'package:flutter/foundation.dart';
import 'package:crown_micro_solar/data/repositories/auth_repository.dart';
import 'package:crown_micro_solar/data/models/auth/auth_response.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  bool _isLoading = false;
  String? _error;
  AuthResponse? _authResponse;

  AuthViewModel(this._authRepository);

  bool get isLoading => _isLoading;
  String? get error => _error;
  AuthResponse? get authResponse => _authResponse;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _authResponse = await _authRepository.login(username, password);
      _isLoading = false;
      notifyListeners();
      return _authResponse?.success ?? false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String password, String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _authResponse = await _authRepository.register(username, password, email);
      _isLoading = false;
      notifyListeners();
      return _authResponse?.success ?? false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verify(String username, String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _authResponse = await _authRepository.verify(username, code);
      _isLoading = false;
      notifyListeners();
      return _authResponse?.success ?? false;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 