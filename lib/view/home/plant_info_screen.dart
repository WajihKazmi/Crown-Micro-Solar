import 'package:flutter/material.dart';
// removed unused imports
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/l10n/app_localizations.dart' as gen;
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
  bool _editing = false;
  // Controllers for editable fields
  final _nameCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _plannedPowerCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _establishCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _provinceCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();
  final _townCtrl = TextEditingController();
  final _villageCtrl = TextEditingController();
  final _timezoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();

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

          // Sync controllers when entering edit mode or on first build
          void syncControllers() {
            _nameCtrl.text = plant.name;
            _capacityCtrl.text = plant.capacity.toStringAsFixed(2);
            _plannedPowerCtrl.text =
                (plant.plannedPower ?? 0).toStringAsFixed(2);
            _companyCtrl.text = plant.company ?? '';
            _establishCtrl.text = plant.establishmentDate ?? '';
            _countryCtrl.text = plant.country ?? '';
            _provinceCtrl.text = plant.province ?? '';
            _cityCtrl.text = plant.city ?? '';
            _districtCtrl.text = plant.district ?? '';
            _townCtrl.text = plant.town ?? '';
            _villageCtrl.text = plant.village ?? '';
            _timezoneCtrl.text = plant.timezone ?? '';
            _addressCtrl.text = plant.address ?? '';
            _latCtrl.text = (plant.latitude ?? 0).toStringAsFixed(6);
            _lonCtrl.text = (plant.longitude ?? 0).toStringAsFixed(6);
          }

          if (!_editing) syncControllers();

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
                              title: gen.AppLocalizations.of(context)
                                  .plant_information,
                              children: _editing
                                  ? [
                                      _input('Plant Name', _nameCtrl),
                                      _input('Design Company', _companyCtrl),
                                      _input('Installed Capacity (KW)',
                                          _capacityCtrl,
                                          keyboard: TextInputType.number),
                                      _input('Annual Planned Power (KW)',
                                          _plannedPowerCtrl,
                                          keyboard: TextInputType.number),
                                      _dateInput(context, 'Establishment Date',
                                          _establishCtrl),
                                      _display('Last Update',
                                          _formatDateTime(plant.lastUpdate)),
                                    ]
                                  : [
                                      _infoRow('Plant Name', plant.name),
                                      _infoRow('Design Company',
                                          plant.company ?? 'N/A'),
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
                              title: gen.AppLocalizations.of(context)
                                  .location_details,
                              children: _editing
                                  ? [
                                      _input('Country', _countryCtrl),
                                      _input('Province', _provinceCtrl),
                                      _input('City', _cityCtrl),
                                      _input('District', _districtCtrl),
                                      _input('Town', _townCtrl),
                                      _input('Village', _villageCtrl),
                                      _input('Time Zone', _timezoneCtrl),
                                      _multiline('Address', _addressCtrl),
                                      Row(children: [
                                        Expanded(
                                            child: _input('Latitude', _latCtrl,
                                                keyboard: TextInputType
                                                    .numberWithOptions(
                                                        decimal: true))),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: _input('Longitude', _lonCtrl,
                                                keyboard: TextInputType
                                                    .numberWithOptions(
                                                        decimal: true))),
                                      ]),
                                    ]
                                  : [
                                      _infoRow(
                                          'Country', plant.country ?? 'N/A'),
                                      _infoRow(
                                          'Province', plant.province ?? 'N/A'),
                                      _infoRow('City', plant.city ?? 'N/A'),
                                      _infoRow(
                                          'District', plant.district ?? 'N/A'),
                                      _infoRow('Town', plant.town ?? 'N/A'),
                                      _infoRow(
                                          'Village', plant.village ?? 'N/A'),
                                      _infoRow(
                                          'Time Zone', plant.timezone ?? 'N/A'),
                                      _infoRow(
                                          'Address', plant.address ?? 'N/A'),
                                      _infoRow('Coordinates',
                                          '${plant.latitude?.toStringAsFixed(6) ?? 'N/A'}, ${plant.longitude?.toStringAsFixed(6) ?? 'N/A'}'),
                                    ],
                            ),
                            const SizedBox(height: 16),
                            _GlassMorphismCard(
                              title: 'Energy Statistics',
                              children: [
                                _infoRow(
                                  'Current Power',
                                  '${plant.currentPower.toStringAsFixed(2)} KW',
                                ),
                                _infoRow(
                                  'Daily Generation',
                                  '${plant.dailyGeneration.toStringAsFixed(2)} KWH',
                                ),
                                _infoRow(
                                  'Monthly Generation',
                                  '${plant.monthlyGeneration.toStringAsFixed(2)} KWH',
                                ),
                                _infoRow(
                                  'Yearly Generation',
                                  '${plant.yearlyGeneration.toStringAsFixed(2)} KWH',
                                ),
                                _infoRow(
                                  'Plant Status',
                                  _getStatusText(plant.status),
                                ),
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
                      icon: _editing ? Icons.close : Icons.edit,
                      onTap: () {
                        setState(() {
                          if (_editing) {
                            // cancel edits by resyncing controllers
                            syncControllers();
                            _editing = false;
                          } else {
                            _editing = true;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_editing)
                      BorderedIconButton(
                        icon: Icons.save,
                        onTap: () async {
                          final ok = await _viewModel.updateCurrentPlant(
                            name: _nameCtrl.text.trim(),
                            capacity: _capacityCtrl.text.trim(),
                            plannedPower: _plannedPowerCtrl.text.trim(),
                            company: _companyCtrl.text.trim(),
                            establishmentDate: _establishCtrl.text.trim(),
                            country: _countryCtrl.text.trim(),
                            province: _provinceCtrl.text.trim(),
                            city: _cityCtrl.text.trim(),
                            district: _districtCtrl.text.trim(),
                            town: _townCtrl.text.trim(),
                            village: _villageCtrl.text.trim(),
                            timezone: _timezoneCtrl.text.trim(),
                            address: _addressCtrl.text.trim(),
                            latitude: _latCtrl.text.trim(),
                            longitude: _lonCtrl.text.trim(),
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? 'Plant updated'
                                  : 'Failed to update plant'),
                            ),
                          );
                          if (ok) setState(() => _editing = false);
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
                              'Are you sure you want to delete this plant? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
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
                                        content: Text('Plant deleted'),
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Failed to delete plant'),
                                      ),
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

  Widget _input(String label, TextEditingController c,
      {TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _multiline(String label, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: c,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _display(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(value),
      ),
    );
  }

  Widget _dateInput(
      BuildContext context, String label, TextEditingController c) {
    return GestureDetector(
      onTap: () async {
        final now = DateTime.now();
        final initial =
            c.text.isNotEmpty ? DateTime.tryParse(c.text) ?? now : now;
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) c.text = picked.toIso8601String();
      },
      child: AbsorbPointer(child: _input(label, c)),
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
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 0.5, color: Colors.grey),
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

  const _GlassMorphismCard({required this.title, required this.children});

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
