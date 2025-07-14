import 'package:flutter/foundation.dart';
import 'package:crown_micro_solar/presentation/models/plant/plant_model.dart';
import 'package:crown_micro_solar/presentation/repositories/plant_repository.dart';

class PlantViewModel extends ChangeNotifier {
  final PlantRepository _plantRepository;
  bool _isLoading = false;
  String? _error;
  List<Plant> _plants = [];

  PlantViewModel(this._plantRepository);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Plant> get plants => _plants;

  Future<void> loadPlants() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _plants = await _plantRepository.getPlants();
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