import 'package:flutter/foundation.dart';
import 'package:crown_micro_solar/presentation/models/plant/plant_model.dart';
import 'package:crown_micro_solar/presentation/repositories/plant_repository.dart';
import 'package:crown_micro_solar/presentation/repositories/energy_repository.dart';
import 'package:crown_micro_solar/core/network/api_client.dart';

class PlantInfoViewModel extends ChangeNotifier {
  final PlantRepository _plantRepository;
  final EnergyRepository _energyRepository;

  Plant? _plant;
  Map<String, dynamic>? _profitStats;
  bool _isLoading = false;
  String? _error;

  PlantInfoViewModel()
      : _plantRepository = PlantRepository(ApiClient()),
        _energyRepository = EnergyRepository(ApiClient());

  Plant? get plant => _plant;
  Map<String, dynamic>? get profitStats => _profitStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPlantInfo(String plantId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      print('PlantInfoViewModel: Loading plant info for plant $plantId');
      // Fetch plant details
      _plant = await _plantRepository.getPlantDetails(plantId);
      print('PlantInfoViewModel: Plant loaded successfully');
      
      // Skip profit statistics for now to avoid API errors
      _profitStats = null;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('PlantInfoViewModel: Error loading plant info: $e');
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