import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/presentation/viewmodels/plant_info_view_model.dart';
import 'package:crown_micro_solar/core/di/service_locator.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:crown_micro_solar/view/common/bordered_icon_button.dart';
import 'dart:ui';

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
              // Background image at the top (no border radius)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Image.asset(
                        'assets/images/plantInfo.png',
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                      // Gradient overlay for fade effect
                      Container(
                        width: double.infinity,
                        height: 300,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.3),
                              Colors.white.withOpacity(0.8),
                              Colors.white,
                            ],
                            stops: const [0.0, 0.6, 0.8, 1.0],
                          ),
                        ),
                      ),
                      // Floating buttons at the top right of the image
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Column(
                          children: [
                            BorderedIconButton(
                              icon: Icons.edit,
                              onTap: () {
                                // TODO: Implement edit action
                              },
                            ),
                            const SizedBox(height: 12),
                            BorderedIconButton(
                              icon: Icons.delete,
                              onTap: () {
                                // TODO: Implement delete action
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Scrollable content that goes directly below the image
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 300),
                    // Cards start immediately below the image
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _GlassMorphismCard(
                            title: 'Plant Information',
                            children: [
                              _infoRow('Plant Name', plant.name),
                              _infoRow('Design Company', plant.company ?? 'N/A'),
                              _infoRow('Installed Capacity', '${plant.capacity.toStringAsFixed(2)} KW'),
                              _infoRow('Annual Planned Power', plant.plannedPower != null ? '${plant.plannedPower!.toStringAsFixed(2)} KW' : 'N/A'),
                              _infoRow('Establishment Date', _formatDate(plant.establishmentDate)),
                              _infoRow('Last Update', _formatDateTime(plant.lastUpdate)),
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
                              _infoRow('Coordinates', '${plant.latitude?.toStringAsFixed(6) ?? 'N/A'}, ${plant.longitude?.toStringAsFixed(6) ?? 'N/A'}'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _GlassMorphismCard(
                            title: 'Energy Statistics',
                            children: [
                              _infoRow('Current Power', '${plant.currentPower.toStringAsFixed(2)} KW'),
                              _infoRow('Daily Generation', '${plant.dailyGeneration.toStringAsFixed(2)} KWH'),
                              _infoRow('Monthly Generation', '${plant.monthlyGeneration.toStringAsFixed(2)} KWH'),
                              _infoRow('Yearly Generation', '${plant.yearlyGeneration.toStringAsFixed(2)} KWH'),
                              _infoRow('Plant Status', _getStatusText(plant.status)),
                            ],
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFFE53935), // Primary red
                  ),
                ),
                const SizedBox(height: 16),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
} 