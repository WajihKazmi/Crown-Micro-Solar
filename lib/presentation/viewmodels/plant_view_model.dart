import 'package:flutter/foundation.dart';
import 'package:crown_micro_solar/presentation/models/plant/plant_model.dart';
import 'package:crown_micro_solar/presentation/repositories/plant_repository.dart';

class PlantViewModel extends ChangeNotifier {
  final PlantRepository _plantRepository;
  bool _isLoading = false;
  String? _error;
  List<Plant> _plants = [];
  DateTime? _lastFetchTime;
  static const _cacheDuration =
      Duration(minutes: 30); // Plant data rarely changes

  PlantViewModel(this._plantRepository);

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Plant> get plants => _plants;

  bool get _isCacheValid {
    if (_lastFetchTime == null || _plants.isEmpty) return false;
    return DateTime.now().difference(_lastFetchTime!) < _cacheDuration;
  }

  Future<void> loadPlants({bool force = false}) async {
    // Return cached data if valid and not forced
    if (!force && _isCacheValid) {
      print(
          'PlantViewModel: Using cached plant data (${_plants.length} plants)');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      print('PlantViewModel: Fetching plants from API...');
      _plants = await _plantRepository.getPlants();
      _lastFetchTime = DateTime.now();
      _isLoading = false;
      notifyListeners();
      print('PlantViewModel: Loaded ${_plants.length} plants');
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Force refresh from API
  Future<void> refreshPlants() async {
    await loadPlants(force: true);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Invalidate cache when plant is added/deleted/modified
  void invalidateCache() {
    _lastFetchTime = null;
    print('PlantViewModel: Cache invalidated');
  }
}
