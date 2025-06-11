import 'package:flutter/foundation.dart';

abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  @protected
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @protected
  void setError(String? value) {
    _error = value;
    notifyListeners();
  }

  @protected
  Future<T> handleApiCall<T>(Future<T> Function() apiCall) async {
    setLoading(true);
    setError(null);
    try {
      final result = await apiCall();
      setLoading(false);
      return result;
    } catch (e) {
      setError(e.toString());
      setLoading(false);
      rethrow;
    }
  }

  void clearError() {
    setError(null);
  }
} 