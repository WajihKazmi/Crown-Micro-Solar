import 'package:crown_micro_solar/core/network/api_client.dart';
import 'package:flutter/foundation.dart';
import '../repositories/auth_repository.dart';
import '../models/account/account_info_model.dart';
import '../repositories/account/account_repository.dart';

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
  AccountInfo? _userInfo;
  late final AccountRepository _accountRepository;
  // ApiService is used via ApiClient; direct field removed
  final ApiClient _apiClient = ApiClient();

  AuthViewModel(this._repository) {
    _accountRepository = AccountRepository();
    _initializeViewModel();
  }

  Future<void> _initializeViewModel() async {
    print('AuthViewModel: Initializing...');
    // First sync credentials from storage
    await _apiClient.syncCredentialsFromStorage();

    // Then sync state from repository
    _syncStateFromRepository();

    print('AuthViewModel: Initial login state: ${isLoggedIn}');

    // Fetch user info on app start if already logged in
    if (isLoggedIn) {
      print('AuthViewModel: User is logged in, fetching user info...');
      await fetchUserInfo();
    }

    notifyListeners();
    print('AuthViewModel: Initialization complete');
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
  AccountInfo? get userInfo => _userInfo;

  void setInstallerMode(bool value) {
    _isInstaller = value;
    if (!value) {
      // Clearing any lingering installer state when switching off
      _agentsList = null;
    }
    notifyListeners();
  }

  Future<bool> login(String userId, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Attempting login for user: $userId');
      print('Installer mode: $_isInstaller');

      // Proactively clear any stale persisted auth before a fresh login
      await _repository.clearAllPersistedAuth();

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
        // Ensure installer flag remains true so UI can show swap button
        _isInstaller = true;
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

      // Set credentials in ApiClient
      if (_token != null && _secret != null) {
        _apiClient.setCredentials(_token!, _secret!);
        print('AuthViewModel: Set credentials in ApiClient');
      }

      // Save credentials if not in installer mode
      if (!_isInstaller) {
        await saveCredentials(userId, password);
      }

      await fetchUserInfo();

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
      // Clear stale persisted auth (switching context)
      await _repository.clearAllPersistedAuth();
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

      // Preserve installer context so swap button remains accessible
      if (_agentsList != null && _agentsList!.isNotEmpty) {
        _isInstaller = true;
      }

      // Set credentials in ApiClient
      if (_token != null && _secret != null) {
        _apiClient.setCredentials(_token!, _secret!);
        print('AuthViewModel: Set credentials in ApiClient for agent login');
      }

      // Fetch account info for the newly logged-in agent user to avoid stale profile display
      await fetchUserInfo();

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

      // Ensure all persisted auth keys wiped even if repository logout is partial
      await _repository.clearAllPersistedAuth();

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
      _isInstaller = false;
      _isAgent = false;
      _userInfo = null; // reset cached account info

      // Clear credentials from ApiClient
      _apiClient.setCredentials('', '');
      print('AuthViewModel: Cleared credentials from ApiClient');

      // Double safety: clear again to be absolutely sure
      await _repository.clearAllPersistedAuth();
      _userInfo = null;

      print('AuthViewModel: Local state cleared');

      // Force notify listeners to update UI
      notifyListeners();
      print('AuthViewModel: Notify listeners called');

      // Double-check that logout was successful
      final stillLoggedIn = _repository.isLoggedIn();
      print(
          'AuthViewModel: Repository isLoggedIn check after logout: $stillLoggedIn');

      if (stillLoggedIn) {
        print(
            'AuthViewModel: WARNING - Repository still shows logged in after logout!');
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

      // Set credentials in ApiClient if available
      if (_token != null && _secret != null) {
        _apiClient.setCredentials(_token!, _secret!);
        print('AuthViewModel: Synced credentials to ApiClient from repository');
      }
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

  Future<void> clearInstallerState() async {
    await _repository.clearInstallerState();
    _agentsList = null;
    _isInstaller = false;
    notifyListeners();
  }

  Future<void> fetchUserInfo() async {
    _userInfo = await _accountRepository.fetchAccountInfo();
    notifyListeners();
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    return await _accountRepository.changePassword(oldPassword, newPassword);
  }

  Future<bool> forgotPassword(String email) async {
    return await _accountRepository.forgotPassword(email);
  }

  Future<String?> forgotUserId(String email) async {
    return await _accountRepository.forgotUserId(email);
  }

  Future<bool> register({
    required String email,
    required String mobileNo,
    required String username,
    required String password,
    required String sn,
  }) async {
    return await _repository.register(
      email: email,
      mobileNo: mobileNo,
      username: username,
      password: password,
      sn: sn,
    );
  }

  Future<bool> verifyOtp(String email, String code) async {
    return await _accountRepository.verifyOtp(email, code);
  }

  // Add installer code flow
  Future<bool> addInstallerCode(String code) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final ok = await _accountRepository.addInstallerCode(code);
      _isLoading = false;
      if (!ok) {
        _error = 'Invalid or rejected installer code';
      }
      notifyListeners();
      return ok;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
