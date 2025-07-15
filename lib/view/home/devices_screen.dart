import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/presentation/viewmodels/plant_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/device_view_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({Key? key}) : super(key: key);

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  late DeviceViewModel _deviceViewModel;
  String? _lastPlantId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final plantViewModel = Provider.of<PlantViewModel>(context);
    if (plantViewModel.plants.isNotEmpty) {
      final plantId = plantViewModel.plants.first.id;
      if (_lastPlantId != plantId) {
        _deviceViewModel = DeviceViewModel();
        _deviceViewModel.loadDevices(plantId);
        _lastPlantId = plantId;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantViewModel = Provider.of<PlantViewModel>(context);
    if (plantViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (plantViewModel.error != null) {
      return Center(child: Text('Error: ${plantViewModel.error}'));
    }
    if (plantViewModel.plants.isEmpty) {
      return const Center(child: Text('No plants found'));
    }
    return ChangeNotifierProvider<DeviceViewModel>.value(
      value: _deviceViewModel,
      child: Consumer<DeviceViewModel>(
        builder: (context, deviceVM, child) {
          if (deviceVM.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (deviceVM.error != null) {
            return Center(child: Text('Error: ${deviceVM.error}'));
          }
          if (deviceVM.devices.isEmpty) {
            return const Center(child: Text('No devices found'));
          }
          final devices = deviceVM.devices;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                // Main device card
                _DeviceCard(
                  device: devices.first,
                  isMain: true,
                ),
                const SizedBox(height: 24),
                // Sub-devices/dataloggers
                ...devices.skip(1).map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _DeviceCard(device: d, isMain: false),
                )),
                const SizedBox(height: 72),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final Device device;
  final bool isMain;
  const _DeviceCard({required this.device, required this.isMain, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isMain ? 8 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: isMain ? Colors.white : Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(isMain ? 16 : 8),
              child: Image.asset(
                isMain ? 'assets/images/device1.png' : 'assets/images/device_sub.png',
                width: isMain ? 80 : 56,
                height: isMain ? 80 : 56,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name.isNotEmpty ? device.name : 'Device',
                    style: TextStyle(
                      fontSize: isMain ? 20 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        device.status == 'online' ? Icons.check_circle : Icons.error,
                        color: device.status == 'online' ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        device.status.capitalize(),
                        style: TextStyle(
                          color: device.status == 'online' ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _infoRow('Current Power', '${device.currentPower.toStringAsFixed(2)} kW'),
                  _infoRow('Daily Gen.', '${device.dailyGeneration.toStringAsFixed(2)} kWh'),
                  _infoRow('Monthly Gen.', '${device.monthlyGeneration.toStringAsFixed(2)} kWh'),
                  _infoRow('Yearly Gen.', '${device.yearlyGeneration.toStringAsFixed(2)} kWh'),
                  _infoRow('Last Update', _formatDateTime(device.lastUpdate)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black54), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

extension _Capitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
} 