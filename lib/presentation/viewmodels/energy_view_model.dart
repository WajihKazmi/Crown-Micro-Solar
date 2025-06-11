import 'package:flutter/foundation.dart';
import 'package:crown_micro_solar/data/repositories/energy_repository.dart';
import 'package:crown_micro_solar/data/models/energy/energy_data_model.dart';

class EnergyViewModel extends ChangeNotifier {
  final EnergyRepository _energyRepository;
  bool _isLoading = false;
  String? _error;
  EnergySummary? _dailyEnergy;
  EnergySummary? _monthlyEnergy;
  EnergySummary? _yearlyEnergy;
  List<EnergyData> _realTimeData = [];

  EnergyViewModel(this._energyRepository);

  bool get isLoading => _isLoading;
  String? get error => _error;
  EnergySummary? get dailyEnergy => _dailyEnergy;
  EnergySummary? get monthlyEnergy => _monthlyEnergy;
  EnergySummary? get yearlyEnergy => _yearlyEnergy;
  List<EnergyData> get realTimeData => _realTimeData;

  Future<void> loadDailyEnergy(String deviceId, String date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dailyEnergy = await _energyRepository.getDailyEnergy(deviceId, date);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMonthlyEnergy(String deviceId, String year, String month) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _monthlyEnergy = await _energyRepository.getMonthlyEnergy(deviceId, year, month);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadYearlyEnergy(String deviceId, String year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _yearlyEnergy = await _energyRepository.getYearlyEnergy(deviceId, year);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadRealTimeData(String deviceId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _realTimeData = await _energyRepository.getRealTimeData(deviceId);
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