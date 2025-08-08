import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/presentation/viewmodels/alarm_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/plant_view_model.dart';
import 'package:crown_micro_solar/core/di/service_locator.dart';
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

  @override
  void initState() {
    super.initState();
    _alarmViewModel = getIt<AlarmViewModel>();
    _plantViewModel = getIt<PlantViewModel>();

    // Load alarms for the first plant
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAlarms();
    });
  }

  void _loadAlarms() {
    if (_plantViewModel.plants.isNotEmpty) {
      final plantId = _plantViewModel.plants.first.id;
      _alarmViewModel.loadAlarms(plantId);
    }
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
                  color: isSelected ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
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

            // Alarm type badge and code
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: alarm.level == 0
                        ? Colors.orange
                        : alarm.level == 1
                            ? Colors.red
                            : Colors.redAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    alarm.severityText.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Code: ${alarm.code}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

            // Device type
            Row(
              children: [
                const Text(
                  'Device type: ',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                Text(
                  alarm.deviceType,
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

            // Action button
            if (!alarm.handle)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () =>
                        _showAlarmActions(context, alarm, viewModel),
                    icon: const Icon(
                      Icons.more_vert,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showAlarmActions(
      BuildContext context, dynamic alarm, AlarmViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Mark as Processed'),
                onTap: () {
                  Navigator.pop(context);
                  viewModel.markAsProcessed(alarm.id, true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Alarm'),
                onTap: () {
                  Navigator.pop(context);
                  // Add delete functionality if needed
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
