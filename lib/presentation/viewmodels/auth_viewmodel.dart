import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth/auth_response_model.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  bool _isLoading = false;
  String? _error;
  bool _isAgent = false;
  bool _isInstaller = false;
  List<dynamic>? _agentsList;
  String? _token;
  String? _secret;
  String? _userId;

  AuthViewModel(this._repository) {
    // Sync local state with repository on initialization
    _syncStateFromRepository();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn {
    // Check both local state and repository state
    final repositoryLoggedIn = _repository.isLoggedIn();
    final localLoggedIn = _token != null && _secret != null && _userId != null;
    
    // If there's a mismatch, sync the local state with repository
    if (repositoryLoggedIn != localLoggedIn) {
      if (repositoryLoggedIn) {
        // Repository says logged in but local state doesn't match, sync from repository
        _token = _repository.getToken();
        _secret = _repository.getSecret();
        _userId = _repository.getUserId();
      } else {
        // Repository says not logged in but local state has data, clear local state
        _token = null;
        _secret = null;
        _userId = null;
        _agentsList = null;
      }
    }
    
    return repositoryLoggedIn && localLoggedIn;
  }
  bool get isAgent => _isAgent;
  bool get isInstaller => _isInstaller;
  List<dynamic>? get agentsList => _agentsList;
  String? get token => _token;
  String? get secret => _secret;
  String? get userId => _userId;

  void setInstallerMode(bool value) {
    _isInstaller = value;
    notifyListeners();
  }

  Future<bool> login(String userId, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Attempting login for user: $userId');
      print('Installer mode: $_isInstaller');

      final response =
          await _repository.login(userId, password, isAgent: _isInstaller);
      _isLoading = false;

      if (!response.isSuccess) {
        print('Login failed: ${response.description}');
        _error = response.description ?? 'Login failed';
        notifyListeners();
        return false;
      }

      if (response.agentsList != null) {
        print('Agent list received with ${response.agentsList!.length} agents');
        _agentsList = response.agentsList;
        notifyListeners();
        return true;
      }

      print('Login successful for user: $userId');
      print('Token: ${response.token}');
      print('Secret: ${response.secret}');
      print('UserID: ${response.userId}');

      // Store the token and secret
      _token = response.token;
      _secret = response.secret;
      _userId = response.userId;

      // Save credentials if not in installer mode
      if (!_isInstaller) {
        await saveCredentials(userId, password);
      }

      notifyListeners();
      return true;
    } catch (e) {
      print('Login error: $e');
      _isLoading = false;
      _error = 'An error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginAgent(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Attempting agent login for user: $username');
      final response = await _repository.loginAgent(username, password);
      _isLoading = false;

      if (!response.isSuccess) {
        print('Agent login failed: ${response.description}');
        _error = response.description ?? 'Agent login failed';
        notifyListeners();
        return false;
      }

      print('Agent login successful for user: $username');
      print('Token: ${response.token}');
      print('Secret: ${response.secret}');
      print('UserID: ${response.userId}');

      // Store the token and secret
      _token = response.token;
      _secret = response.secret;
      _userId = response.userId;

      notifyListeners();
      return true;
    } catch (e) {
      print('Agent login error: $e');
      _isLoading = false;
      _error = 'An error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }

  Future<void> saveCredentials(String userId, String password) async {
    await _repository.saveCredentials(userId, password);
  }

  Future<Map<String, String?>> getSavedCredentials() async {
    return await _repository.getSavedCredentials();
  }

  Future<void> clearCredentials() async {
    await _repository.clearCredentials();
  }

  Future<void> logout() async {
    try {
      print('AuthViewModel: Starting logout...');
      
      // Clear repository state first
      await _repository.logout();
      print('AuthViewModel: Repository logout completed');
      
      // Clear local state
      _token = null;
      _secret = null;
      _userId = null;
      _agentsList = null;
      _error = null;
      _isLoading = false;
      
      print('AuthViewModel: Local state cleared');
      
      // Force notify listeners to update UI
      notifyListeners();
      print('AuthViewModel: Notify listeners called');
      
      // Double-check that logout was successful
      final stillLoggedIn = _repository.isLoggedIn();
      print('AuthViewModel: Repository isLoggedIn check after logout: $stillLoggedIn');
      
      if (stillLoggedIn) {
        print('AuthViewModel: WARNING - Repository still shows logged in after logout!');
        // Force clear again
        await _repository.logout();
        notifyListeners();
      }
    } catch (e) {
      print('AuthViewModel: Error during logout: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _syncStateFromRepository() {
    if (_repository.isLoggedIn()) {
      _token = _repository.getToken();
      _secret = _repository.getSecret();
      _userId = _repository.getUserId();
      _agentsList = _repository.getAgentsList();
    } else {
      _token = null;
      _secret = null;
      _userId = null;
      _agentsList = null;
    }
  }

  void refreshAuthState() {
    _syncStateFromRepository();
    notifyListeners();
  }
}
