import 'package:flutter/foundation.dart';
import 'package:crown_micro_solar/data/repositories/plant_repository.dart';
import 'package:crown_micro_solar/data/models/plant/plant_model.dart';

class PlantViewModel extends ChangeNotifier {
  final PlantRepository _plantRepository;
  bool _isLoading = false;
  String? _error;
  List<Plant> _plants = [];
  Plant? _selectedPlant;

  PlantViewModel(this._plantRepository);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Plant> get plants => _plants;
  Plant? get selectedPlant => _selectedPlant;

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

  Future<void> loadPlantDetails(String plantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedPlant = await _plantRepository.getPlantDetails(plantId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPlant({
    required String name,
    required String location,
    required double capacity,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _plantRepository.createPlant(
        name: name,
        location: location,
        capacity: capacity,
      );
      _isLoading = false;
      notifyListeners();
      return success;
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