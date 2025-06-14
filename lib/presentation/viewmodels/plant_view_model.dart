import 'package:flutter/foundation.dart';

class PlantViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  List<dynamic> _plants = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<dynamic> get plants => _plants;

  Future<void> loadPlants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Mock loading plants
      await Future.delayed(const Duration(seconds: 1));
      _plants = [
        {'id': '1', 'name': 'Plant 1', 'status': 'active'},
        {'id': '2', 'name': 'Plant 2', 'status': 'inactive'},
      ];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 