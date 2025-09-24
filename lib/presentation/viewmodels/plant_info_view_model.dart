import 'package:flutter/foundation.dart';
import 'package:crown_micro_solar/presentation/models/plant/plant_model.dart';
import 'package:crown_micro_solar/presentation/repositories/plant_repository.dart';
import 'package:crown_micro_solar/core/network/api_client.dart';

class PlantInfoViewModel extends ChangeNotifier {
  final PlantRepository _plantRepository;

  Plant? _plant;
  Map<String, dynamic>? _profitStats;
  bool _isLoading = false;
  String? _error;

  PlantInfoViewModel() : _plantRepository = PlantRepository(ApiClient());

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

  Future<bool> deleteCurrentPlant() async {
    final plantId = _plant?.id;
    if (plantId == null || plantId.isEmpty) return false;
    try {
      final ok = await _plantRepository.deletePlant(plantId);
      if (ok) {
        _plant = null;
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> renameCurrentPlant(String newName) async {
    if (_plant == null) return false;
    try {
      final ok =
          await _plantRepository.editPlant(plant: _plant!, newName: newName);
      if (ok) {
        _plant = Plant(
          id: _plant!.id,
          name: newName,
          location: _plant!.location,
          capacity: _plant!.capacity,
          status: _plant!.status,
          lastUpdate: _plant!.lastUpdate,
          currentPower: _plant!.currentPower,
          dailyGeneration: _plant!.dailyGeneration,
          monthlyGeneration: _plant!.monthlyGeneration,
          yearlyGeneration: _plant!.yearlyGeneration,
          company: _plant!.company,
          plannedPower: _plant!.plannedPower,
          establishmentDate: _plant!.establishmentDate,
          country: _plant!.country,
          province: _plant!.province,
          city: _plant!.city,
          district: _plant!.district,
          town: _plant!.town,
          village: _plant!.village,
          timezone: _plant!.timezone,
          address: _plant!.address,
          latitude: _plant!.latitude,
          longitude: _plant!.longitude,
        );
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCurrentPlant({
    String? name,
    String? capacity,
    String? plannedPower,
    String? company,
    String? establishmentDate,
    String? country,
    String? province,
    String? city,
    String? district,
    String? town,
    String? village,
    String? timezone,
    String? address,
    String? latitude,
    String? longitude,
  }) async {
    if (_plant == null) return false;
    try {
      final updated = Plant(
        id: _plant!.id,
        name: name?.isNotEmpty == true ? name! : _plant!.name,
        location: address?.isNotEmpty == true ? address! : _plant!.location,
        capacity: double.tryParse(capacity ?? '') ?? _plant!.capacity,
        status: _plant!.status,
        lastUpdate: DateTime.now(),
        currentPower: _plant!.currentPower,
        dailyGeneration: _plant!.dailyGeneration,
        monthlyGeneration: _plant!.monthlyGeneration,
        yearlyGeneration: _plant!.yearlyGeneration,
        company: company?.isNotEmpty == true ? company : _plant!.company,
        plannedPower:
            double.tryParse(plannedPower ?? '') ?? _plant!.plannedPower,
        establishmentDate: establishmentDate?.isNotEmpty == true
            ? establishmentDate
            : _plant!.establishmentDate,
        country: country?.isNotEmpty == true ? country : _plant!.country,
        province: province?.isNotEmpty == true ? province : _plant!.province,
        city: city?.isNotEmpty == true ? city : _plant!.city,
        district: district?.isNotEmpty == true ? district : _plant!.district,
        town: town?.isNotEmpty == true ? town : _plant!.town,
        village: village?.isNotEmpty == true ? village : _plant!.village,
        timezone: timezone?.isNotEmpty == true ? timezone : _plant!.timezone,
        address: address?.isNotEmpty == true ? address : _plant!.address,
        latitude: double.tryParse(latitude ?? '') ?? _plant!.latitude,
        longitude: double.tryParse(longitude ?? '') ?? _plant!.longitude,
      );

      final ok = await _plantRepository.editPlant(
          plant: updated, newName: updated.name);
      if (ok) {
        _plant = updated;
        notifyListeners();
      }
      return ok;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
