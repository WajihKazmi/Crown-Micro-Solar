import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/presentation/viewmodels/plant_info_view_model.dart';
import 'package:crown_micro_solar/core/di/service_locator.dart';
import 'package:crown_micro_solar/view/common/bordered_icon_button.dart';

class PlantInfoScreen extends StatefulWidget {
  final String plantId;
  const PlantInfoScreen({Key? key, required this.plantId}) : super(key: key);

  @override
  State<PlantInfoScreen> createState() => _PlantInfoScreenState();
}

class _PlantInfoScreenState extends State<PlantInfoScreen> {
  late PlantInfoViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = getIt<PlantInfoViewModel>();
    _viewModel.loadPlantInfo(widget.plantId);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<PlantInfoViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.error != null) {
            return Center(child: Text('Error: ${vm.error}'));
          }
          final plant = vm.plant;
          if (plant == null) {
            return const Center(child: Text('No plant data'));
          }

          return Stack(
            children: [
              // Background image at top
              SizedBox(
                height: 300,
                width: double.infinity,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/images/plantInfo.png',
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              // Content scroll below image
              SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  // Increase top padding so cards don't overlap the image
                  padding: const EdgeInsets.only(top: 320),
                  child: Column(
                    children: [
                      // Content area with rounded top corners
                      Container(
                        decoration: const BoxDecoration(
                          // Solid white background to clearly separate from the header image
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        padding: const EdgeInsets.only(
                          top: 16.0,
                          left: 16.0,
                          right: 16.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Extra gap below the image
                            const SizedBox(height: 8),
                            _GlassMorphismCard(
                              title: 'Plant Information',
                              children: [
                                _infoRow('Plant Name', plant.name),
                                _infoRow(
                                    'Design Company', plant.company ?? 'N/A'),
                                _infoRow('Installed Capacity',
                                    '${plant.capacity.toStringAsFixed(2)} KW'),
                                _infoRow(
                                    'Annual Planned Power',
                                    plant.plannedPower != null
                                        ? '${plant.plannedPower!.toStringAsFixed(2)} KW'
                                        : 'N/A'),
                                _infoRow('Establishment Date',
                                    _formatDate(plant.establishmentDate)),
                                _infoRow('Last Update',
                                    _formatDateTime(plant.lastUpdate)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _GlassMorphismCard(
                              title: 'Location Details',
                              children: [
                                _infoRow('Country', plant.country ?? 'N/A'),
                                _infoRow('Province', plant.province ?? 'N/A'),
                                _infoRow('City', plant.city ?? 'N/A'),
                                _infoRow('District', plant.district ?? 'N/A'),
                                _infoRow('Town', plant.town ?? 'N/A'),
                                _infoRow('Village', plant.village ?? 'N/A'),
                                _infoRow('Time Zone', plant.timezone ?? 'N/A'),
                                _infoRow('Address', plant.address ?? 'N/A'),
                                _infoRow('Coordinates',
                                    '${plant.latitude?.toStringAsFixed(6) ?? 'N/A'}, ${plant.longitude?.toStringAsFixed(6) ?? 'N/A'}'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _GlassMorphismCard(
                              title: 'Energy Statistics',
                              children: [
                                _infoRow('Current Power',
                                    '${plant.currentPower.toStringAsFixed(2)} KW'),
                                _infoRow('Daily Generation',
                                    '${plant.dailyGeneration.toStringAsFixed(2)} KWH'),
                                _infoRow('Monthly Generation',
                                    '${plant.monthlyGeneration.toStringAsFixed(2)} KWH'),
                                _infoRow('Yearly Generation',
                                    '${plant.yearlyGeneration.toStringAsFixed(2)} KWH'),
                                _infoRow('Plant Status',
                                    _getStatusText(plant.status)),
                              ],
                            ),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Floating buttons above everything for reliable taps
              Positioned(
                top: 16,
                right: 16,
                child: Column(
                  children: [
                    BorderedIconButton(
                      icon: Icons.edit,
                      onTap: () {
                        final nameController =
                            TextEditingController(text: plant.name);
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Edit Plant'),
                            content: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Plant Name',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final newName = nameController.text.trim();
                                  if (newName.isEmpty) return;
                                  Navigator.pop(ctx);
                                  final ok = await _viewModel
                                      .renameCurrentPlant(newName);
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(ok
                                          ? 'Plant updated'
                                          : 'Failed to update plant'),
                                    ),
                                  );
                                },
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    BorderedIconButton(
                      icon: Icons.delete,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete Plant'),
                            content: const Text(
                                'Are you sure you want to delete this plant? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  final ok =
                                      await _viewModel.deleteCurrentPlant();
                                  if (!mounted) return;
                                  if (ok) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Plant deleted')),
                                    );
                                    Navigator.of(context).pop();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Failed to delete plant')),
                                    );
                                  }
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        const Divider(
          height: 1,
          thickness: 0.5,
          color: Colors.grey,
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(String status) {
    switch (status) {
      case '1':
        return 'Active';
      case '0':
        return 'Inactive';
      default:
        return status;
    }
  }
}

class _GlassMorphismCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _GlassMorphismCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    // Changed to solid white background as per client requirements
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Solid white background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
