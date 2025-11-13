import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/presentation/viewmodels/alarm_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/plant_view_model.dart';
import 'package:crown_micro_solar/core/di/service_locator.dart';
import 'package:crown_micro_solar/core/services/realtime_data_service.dart';
import 'package:crown_micro_solar/presentation/repositories/plant_repository.dart';
import '../common/bordered_icon_button.dart';

class AlarmNotificationScreen extends StatefulWidget {
  const AlarmNotificationScreen({Key? key}) : super(key: key);

  @override
  State<AlarmNotificationScreen> createState() =>
      _AlarmNotificationScreenState();
}

class _AlarmNotificationScreenState extends State<AlarmNotificationScreen> {
  late AlarmViewModel _alarmViewModel;
  late PlantViewModel _plantViewModel;
  bool _requestedOnce = false;

  @override
  void initState() {
    super.initState();
    _alarmViewModel = getIt<AlarmViewModel>();
    _plantViewModel = getIt<PlantViewModel>();

    // Load alarms for the first plant
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlarms();
    });

    // Listen for plants loading later and trigger once
    _plantViewModel.addListener(_onPlantsUpdated);
  }

  void _loadAlarms() {
    String? plantId;
    if (_plantViewModel.plants.isNotEmpty) {
      plantId = _plantViewModel.plants.first.id;
    } else {
      // Try realtime service singleton
      final realtime = getIt<RealtimeDataService>();
      if (realtime.plants.isNotEmpty) {
        plantId = realtime.plants.first.id;
      }
    }

    if (plantId != null) {
      _requestedOnce = true;
      _alarmViewModel.loadAlarms(plantId);
    } else {
      // Last resort: fetch plants directly once
      getIt<PlantRepository>().getPlants().then((plants) {
        if (mounted && plants.isNotEmpty && !_requestedOnce) {
          _requestedOnce = true;
          _alarmViewModel.loadAlarms(plants.first.id);
        }
      }).catchError((_) {});
    }
  }

  void _onPlantsUpdated() {
    if (!_requestedOnce && _plantViewModel.plants.isNotEmpty) {
      _loadAlarms();
    }
  }

  @override
  void dispose() {
    _plantViewModel.removeListener(_onPlantsUpdated);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BorderedIconButton(
          icon: Icons.arrow_back,
          onTap: () => Navigator.of(context).pop(),
          margin: const EdgeInsets.only(left: 16.0),
        ),
        title: const Text(
          'Alarm Management > Plant',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        centerTitle: false,
      ),
      body: ChangeNotifierProvider.value(
        value: _alarmViewModel,
        child: Consumer<AlarmViewModel>(
          builder: (context, viewModel, child) {
            return Column(
              children: [
                // Filter tabs
                _buildFilterTabs(viewModel),

                // Filter dropdowns
                _buildFilterDropdowns(viewModel),

                // Content
                Expanded(
                  child: _buildContent(viewModel),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterTabs(AlarmViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: viewModel.periodOptions.map((period) {
          final isSelected = viewModel.selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                viewModel.updatePeriodFilter(period);
                _loadAlarms(); // Reload with new filter
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.grey[200] : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.black87 : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterDropdowns(AlarmViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Alarm Type Filter
          Expanded(
            child: _buildDropdown(
              value: viewModel.selectedAlarmType,
              items: viewModel.alarmTypeOptions,
              onChanged: (value) {
                viewModel.updateAlarmTypeFilter(value!);
                _loadAlarms(); // Reload with new filter
              },
            ),
          ),
          const SizedBox(width: 8),
          // Device Filter
          Expanded(
            child: _buildDropdown(
              value: viewModel.selectedDevice,
              items: viewModel.deviceOptions,
              onChanged: (value) {
                viewModel.updateDeviceFilter(value!);
                _loadAlarms(); // Reload with new filter
              },
            ),
          ),
          const SizedBox(width: 8),
          // Status Filter
          Expanded(
            child: _buildDropdown(
              value: viewModel.selectedStatus,
              items: viewModel.statusOptions,
              onChanged: (value) {
                viewModel.updateStatusFilter(value!);
                _loadAlarms(); // Reload with new filter
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18),
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildContent(AlarmViewModel viewModel) {
    if (viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              viewModel.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAlarms,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final alarmItems = viewModel.getFilteredAlarmItems();

    if (alarmItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No alarms found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alarmItems.length,
      itemBuilder: (context, index) {
        final item = alarmItems[index];
        return _buildAlarmCard(item, viewModel);
      },
    );
  }

  Widget _buildAlarmCard(dynamic alarm, AlarmViewModel viewModel) {
    // alarm is now a Warning object
    final statusText = alarm.handle ? 'Processed' : 'Untreated';
    final statusColor = alarm.handle ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SN: ${alarm.sn}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Alarm type badge (outlined) and code
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: alarm.level == 0
                          ? Colors.orange
                          : alarm.level == 1
                              ? Colors.red
                              : Colors.redAccent,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    alarm.severityText.toUpperCase(),
                    style: TextStyle(
                      color: alarm.level == 0
                          ? Colors.orange
                          : alarm.level == 1
                              ? Colors.red
                              : Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Code: ${alarm.code}',
                  style: const TextStyle(
                    color: Color(0xFF2F80ED),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Occurrence time
            Row(
              children: [
                const Text(
                  'Occurrence time: ',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _formatDateTime(alarm.gts),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Device PN
            Row(
              children: [
                const Text(
                  'Device PN: ',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  alarm.pn,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Device type (numeric code in green)
            Row(
              children: [
                const Text(
                  'Device Type: ',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  alarm.devcode.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Description: ',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Text(
                    alarm.desc,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Action icons at bottom-right
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Mark as processed',
                  onPressed: alarm.handle
                      ? null
                      : () => viewModel.markAsProcessed(alarm.id, true),
                  icon: Icon(
                    Icons.check_circle,
                    color: alarm.handle ? Colors.grey[300] : Colors.green,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () => _showDeleteConfirm(context, () {
                    Navigator.of(context).pop();
                    viewModel.deleteAlarm(alarm.id, true);
                  }),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Removed overflow sheet; actions now inline on each card

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirm(BuildContext context, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete, color: Colors.red, size: 36),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Delete Alarm',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Are you sure you want to delete this alarm?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: Colors.black54, height: 1.3),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.white,
                        ),
                        onPressed: onConfirm,
                        child: const Text('Yes, Delete',
                            style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
