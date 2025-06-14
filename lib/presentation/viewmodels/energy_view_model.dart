import 'package:flutter/foundation.dart';

class EnergyViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _energyData = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get energyData => _energyData;

  Future<void> loadEnergyData(String date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Mock loading energy data
      await Future.delayed(const Duration(seconds: 1));
      _energyData = {
        'totalGeneration': 1500.0,
        'dailyGeneration': 75.0,
        'monthlyGeneration': 2250.0,
        'yearlyGeneration': 27000.0,
        'efficiency': 85.5,
        'savings': 2500.0,
      };
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