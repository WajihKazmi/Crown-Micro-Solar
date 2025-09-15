import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:crown_micro_solar/l10n/app_localizations.dart' as gen;
import 'package:crown_micro_solar/core/di/service_locator.dart';
import 'package:crown_micro_solar/core/services/realtime_data_service.dart';
import 'package:crown_micro_solar/core/services/report_download_service.dart';
import 'package:crown_micro_solar/presentation/repositories/device_repository.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/auth_viewmodel.dart';
import 'package:crown_micro_solar/presentation/viewmodels/plant_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/dashboard_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/device_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/overview_graph_view_model.dart';
import '../common/bordered_icon_button.dart';
import '../profile/profile_screen.dart';
import 'app_bottom_nav_bar.dart';
import 'devices_screen.dart';
import 'alarm_notification_screen.dart';
import 'plant_info_screen.dart';
import 'dart:ui' as ui;
import 'package:crown_micro_solar/core/utils/navigation_service.dart';
// MetricAggregatorViewModel not directly used here; metric resolution handled via repository.

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PlantViewModel _plantViewModel;
  late DashboardViewModel _dashboardViewModel;
  late RealtimeDataService _realtimeDataService;

  @override
  void initState() {
    super.initState();
    _plantViewModel = getIt<PlantViewModel>();
    _dashboardViewModel = getIt<DashboardViewModel>();
    _realtimeDataService = getIt<RealtimeDataService>();
    _realtimeDataService.start();
    _plantViewModel.loadPlants().then((_) async {
      if (_plantViewModel.plants.isNotEmpty) {
        final firstPlantId = _plantViewModel.plants.first.id;
        try {
          final deviceVM = getIt<DeviceViewModel>();
          await deviceVM.loadDevicesAndCollectors(firstPlantId);
        } catch (_) {}
      }
    });
    _dashboardViewModel.loadDashboardData();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    if (index == 2) _plantViewModel.loadPlants();
  }

  void _onDrawerNavigate(int index) {
    setState(() => _currentIndex = index);
    Navigator.pop(context);
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final auth = Provider.of<AuthViewModel>(context, listen: false);
                await auth.logout();
                if (mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (r) => false);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: $e',
                          style: const TextStyle(color: Colors.black)),
                      backgroundColor: Colors.white,
                    ),
                  );
                }
              }
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showUserSwitcherDialog(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final agents = authViewModel.agentsList;
    if (agents == null || agents.isEmpty) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tap to login'),
        content: SizedBox(
          width: 260,
          height: 320,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: agents.length,
            itemBuilder: (ctx, index) {
              final agent = agents[index];
              return ListTile(
                trailing: const Icon(Icons.arrow_right),
                title: Text('SN: ${agent['SNNumber']}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold)),
                subtitle: Text('Username: ${agent['Username']}'.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold)),
                onTap: () async {
                  Navigator.of(dialogContext).pop();
                  final success = await authViewModel.loginAgent(
                      agent['Username'], agent['Password']);
                  if (success) {
                    await _refreshDataForNewUser();
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Failed to switch: ${authViewModel.error ?? 'Unknown'}',
                            style: const TextStyle(color: Colors.black)),
                        backgroundColor: Colors.white,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel')),
        ],
      ),
    );
  }

  // Old _performLogout merged into _onLogout simplified
  @override
  void dispose() {
    _realtimeDataService.stop();
    super.dispose();
  }

  Future<void> _refreshDataForNewUser() async {
    try {
      // Refresh plant data
      await _plantViewModel.loadPlants();

      // Refresh dashboard data
      await _dashboardViewModel.loadDashboardData();

      // Restart real-time data service with new user context
      _realtimeDataService.stop();
      await Future.delayed(const Duration(milliseconds: 500));
      _realtimeDataService.start();

      // Force UI refresh
      setState(() {});
    } catch (e) {
      print('Error refreshing data for new user: $e');
    }
  }

  Widget _getBody() {
    // Create a key for each body to ensure proper widget identity
    switch (_currentIndex) {
      case 0:
        return _OverviewBody(key: PageStorageKey('overview'));
      case 1:
        // Use the first plant's ID for the plant info screen by default
        final firstPlant = _plantViewModel.plants.isNotEmpty
            ? _plantViewModel.plants.first
            : null;
        return firstPlant != null
            ? PlantInfoScreen(
                plantId: firstPlant.id,
                key: PageStorageKey('plant_${firstPlant.id}'),
              )
            : Center(
                child: CircularProgressIndicator(),
                key: PageStorageKey('plant_loading'),
              );
      case 2:
        // For devices tab, use a wrapper to ensure correct constraints
        return DevicesScreen(key: PageStorageKey('devices_screen'));
      case 3:
        return ProfileScreen(key: PageStorageKey('profile'));
      default:
        return _OverviewBody(key: PageStorageKey('overview_default'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context);
    final userInfo = authViewModel.userInfo;
    // Initialize deviceViewModel once for reuse
    final deviceViewModel = getIt<DeviceViewModel>();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _plantViewModel),
        ChangeNotifierProvider.value(value: _dashboardViewModel),
        ChangeNotifierProvider.value(value: _realtimeDataService),
        ChangeNotifierProvider.value(value: deviceViewModel),
        ChangeNotifierProvider(create: (_) => OverviewGraphViewModel()),
      ],
      child: Scaffold(
        key: PageStorageKey('home_scaffold_$_currentIndex'),
        extendBody: true,
        drawer: userInfo == null
            ? const Drawer(child: Center(child: CircularProgressIndicator()))
            : AppDrawer(
                username: userInfo.usr,
                email: userInfo.email,
                onProfileTap: () {
                  Navigator.pop(context);
                  setState(() => _currentIndex = 3);
                },
                onLogout: _onLogout,
                onNavigate: _onDrawerNavigate,
              ),
        appBar: _currentIndex == 2
            ? AppBar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                elevation: 0,
                leading: Builder(
                  builder: (context) => BorderedIconButton(
                    icon: Icons.menu,
                    onTap: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                title: Builder(
                  builder: (context) {
                    final l10n = gen.AppLocalizations.of(context);
                    return Text(l10n.tabs_device);
                  },
                ),
                actions: [
                  if (authViewModel.isInstaller ||
                      (authViewModel.agentsList?.isNotEmpty ?? false))
                    BorderedIconButton(
                      icon: Icons.people,
                      onTap: () => _showUserSwitcherDialog(context),
                      margin: const EdgeInsets.only(right: 8.0),
                    ),
                  BorderedIconButton(
                    icon: Icons.notifications_none,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AlarmNotificationScreen(),
                        ),
                      );
                    },
                    margin: const EdgeInsets.only(right: 16.0),
                  ),
                ],
              )
            : null,
        body: _currentIndex == 2
            ? DevicesScreen(key: const PageStorageKey('devices_screen_body'))
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    floating: true,
                    snap: true,
                    pinned: true,
                    leading: Builder(
                      builder: (context) => BorderedIconButton(
                        icon: Icons.menu,
                        onTap: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    title: Builder(
                      builder: (context) {
                        final l10n = gen.AppLocalizations.of(context);
                        String title;
                        switch (_currentIndex) {
                          case 0:
                            title = l10n.tabs_home;
                            break;
                          case 1:
                            title = l10n.tabs_plant;
                            break;
                          case 3:
                            title = l10n.tabs_user;
                            break;
                          default:
                            title = l10n.tabs_home;
                        }
                        return Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        );
                      },
                    ),
                    centerTitle: true,
                    actions: [
                      // Debug visibility print (single consolidated)
                      Builder(builder: (ctx) {
                        // ignore: avoid_print
                        print(
                            'HomeScreen SliverAppBar actions build: isInstaller=' +
                                authViewModel.isInstaller.toString() +
                                ' agentsListLength=' +
                                ((authViewModel.agentsList?.length)
                                        ?.toString() ??
                                    'null'));
                        return const SizedBox.shrink();
                      }),
                      if (authViewModel.isInstaller ||
                          (authViewModel.agentsList?.isNotEmpty ?? false))
                        BorderedIconButton(
                          icon: Icons.people,
                          onTap: () => _showUserSwitcherDialog(context),
                          margin: const EdgeInsets.only(right: 8.0),
                        ),
                      BorderedIconButton(
                        icon: Icons.notifications_none,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const AlarmNotificationScreen(),
                            ),
                          );
                        },
                        margin: const EdgeInsets.only(right: 16.0),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(child: _getBody()),
                ],
              ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}

// Extracted overview content to a new widget for cleaner switching
class _OverviewBody extends StatefulWidget {
  const _OverviewBody({Key? key}) : super(key: key);
  @override
  State<_OverviewBody> createState() => _OverviewBodyState();
}

class _OverviewBodyState extends State<_OverviewBody> {
  GraphMetric _selectedMetric = GraphMetric.outputPower;
  GraphPeriod _selectedPeriod = GraphPeriod.day;
  bool _initialized = false;
  // Metric resolution state (moved from parent)
  double? _resolvedCurrentPowerKw;
  bool _resolvingMetrics = false;
  // Removed aggregate Load/Grid/Battery cards per request (only in device detail)

  Future<void> _resolveCurrentPower(String plantId) async {
    if (_resolvingMetrics) return;
    _resolvingMetrics = true;
    try {
      final deviceRepo = getIt<DeviceRepository>();
      final bundle = await deviceRepo.getDevicesAndCollectors(plantId);
      final devices = (bundle['allDevices'] as List?) ?? [];
      // New unified aggregation: prioritize energy flow -> paging -> key parameter resolution
      // Device objects already typed; ensure list is List<Device>
      final typedDevices = devices.cast<Device>();
      final sumW = await deviceRepo.aggregateCurrentPvPowerWatts(typedDevices);
      if (mounted) {
        setState(() {
          _resolvedCurrentPowerKw = sumW > 0 ? sumW / 1000.0 : null;
        });
      }
    } catch (_) {
      // ignore errors silently
    } finally {
      _resolvingMetrics = false;
    }
  }

  // Aggregate card resolver removed.

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  String _formatMonth(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sept',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No-op: we'll react to PlantViewModel updates inside build via Consumer
  }

  @override
  Widget build(BuildContext context) {
    return Consumer5<PlantViewModel, DashboardViewModel, RealtimeDataService,
        OverviewGraphViewModel, DeviceViewModel>(
      builder: (
        context,
        plantViewModel,
        dashboardViewModel,
        realtimeService,
        graphVM,
        deviceVM,
        child,
      ) {
        // Trigger graph preloading once plants are available
        if (!_initialized && plantViewModel.plants.isNotEmpty) {
          _initialized = true;
          // Defer to next microtask to avoid doing async work mid-build
          final firstId = plantViewModel.plants.first.id;
          Future.microtask(() async {
            await graphVM.init(firstId);
            await _resolveCurrentPower(firstId);
          });
        }
        if (plantViewModel.isLoading || dashboardViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (plantViewModel.error != null) {
          return Center(child: Text('Error: ${plantViewModel.error}'));
        }
        if (dashboardViewModel.error != null) {
          return Center(child: Text('Error: ${dashboardViewModel.error}'));
        }
        // Use real-time data if available
        final plants = realtimeService.plants.isNotEmpty
            ? realtimeService.plants
            : plantViewModel.plants;
        // Aggregate daily generation across all plants (kWh)
        double totalDailyGenerationKwh = 0.0;
        for (final p in plants) {
          final dg = p.dailyGeneration;
          if (dg.isFinite) totalDailyGenerationKwh += dg;
        }
        // Installed capacity should match Plant Info's Installed Capacity (first plant)
        final installedCapacity =
            plants.isNotEmpty ? plants.first.capacity : 0.0;
        // Current power generation: prefer resolved metric sum, then realtime service, then legacy per-device sum
        double devicesSumLegacy = 0.0;
        if (deviceVM.allDevices.isNotEmpty) {
          for (final d in deviceVM.allDevices) {
            devicesSumLegacy +=
                (d.currentPower.isFinite ? d.currentPower : 0.0);
          }
        }
        final totalOutput = _resolvedCurrentPowerKw != null
            ? _resolvedCurrentPowerKw! *
                1000 // convert kW back to W for consistency below then format
            : (realtimeService.totalCurrentPower > 0
                ? realtimeService.totalCurrentPower
                : (devicesSumLegacy > 0 ? devicesSumLegacy : 0.0));
        final totalCapacity = installedCapacity; // keep old name for UI below
        final totalPlants = plants.length;
        // You can add more aggregations as needed
        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                height: 370, // Slightly taller to allow added spacing
                // decoration: BoxDecoration(
                //   color: const Color(0xFFFFEBEE),
                //   borderRadius: BorderRadius.circular(24),
                // ),
                child: Stack(
                  children: [
                    // Background image with fixed position
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/overview_bg.png',
                          fit: BoxFit.cover, // Cover entire container
                        ),
                      ),
                    ),
                    // Content positioned over the background
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    realtimeService.isRunning
                                        ? gen.AppLocalizations.of(
                                            context,
                                          ).live_data
                                        : (plants.isNotEmpty
                                            ? 'Last updated: ${plants.first.lastUpdate.hour}:${plants.first.lastUpdate.minute.toString().padLeft(2, '0')}'
                                            : ''),
                                    style: TextStyle(
                                      color: Colors
                                          .black, // Changed to black as per requirements
                                      fontSize: 12,
                                      fontWeight: realtimeService.isRunning
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 22,
                              ), // extra padding between image top content and cards
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _InfoCard(
                                          icon: 'assets/icons/home/thunder.svg',
                                          label: 'Total Output Power',
                                          value: totalDailyGenerationKwh
                                              .toStringAsFixed(1),
                                          unit: 'KWH',
                                        ),
                                        const SizedBox(
                                          height: 18,
                                        ), // increased vertical gap between stacked cards
                                        _InfoCard(
                                          icon:
                                              'assets/icons/home/capacity.svg',
                                          label: gen.AppLocalizations.of(
                                            context,
                                          ).total_installed_capacity,
                                          value:
                                              totalCapacity.toStringAsFixed(1),
                                          unit: 'KW',
                                        ),
                                        const SizedBox(height: 18),
                                        // Removed duplicate card per request: previously 'Total Daily Generation'
                                        const SizedBox(height: 18),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 30),
                                  SizedBox(
                                    width: 120, // Fixed width
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors
                                            .white, // Solid white background
                                        borderRadius: BorderRadius.circular(
                                          16,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 10,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              totalOutput > 0
                                                  ? (totalOutput / 1000)
                                                      .toStringAsFixed(2)
                                                  : "0.00",
                                              style: TextStyle(
                                                fontSize: 27,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),
                                            Text(
                                              'kW',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Current Power\n Generation',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const Text(
                                              'All Power Stations',
                                              style: TextStyle(
                                                fontSize: 8,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _SummaryCard(
                      icon: 'assets/icons/home/totalPlants.svg',
                      label: 'Total Plant',
                      value: totalPlants.toString(),
                    ),
                    _SummaryCard(
                      icon: 'assets/icons/home/totalDevices.svg',
                      label: 'Total Device',
                      value: dashboardViewModel.isLoading
                          ? '-'
                          : dashboardViewModel.totalDevices.toString(),
                    ),
                    _SummaryCard(
                      icon: 'assets/icons/home/totalAlarms.svg',
                      label: 'Total Alarm',
                      value: dashboardViewModel.isLoading
                          ? '-'
                          : dashboardViewModel.totalAlarms.toString(),
                    ),
                  ],
                ),
              ),
              // Removed Load/Grid/Battery cards per request
              // Combined parameter dropdown + period chips row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Parameter dropdown (full width)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          value: _selectedMetric.name,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: [
                            DropdownMenuItem(
                              value: GraphMetric.outputPower.name,
                              child: Text(
                                gen.AppLocalizations.of(
                                  context,
                                ).output_power,
                              ),
                            ),
                            DropdownMenuItem(
                              value: GraphMetric.loadPower.name,
                              child: const Text('Load Power'),
                            ),
                            DropdownMenuItem(
                              value: GraphMetric.gridPower.name,
                              child: const Text('Grid Power'),
                            ),
                            DropdownMenuItem(
                              value: GraphMetric.gridVoltage.name,
                              child: const Text('Grid Voltage'),
                            ),
                            DropdownMenuItem(
                              value: GraphMetric.gridFrequency.name,
                              child: const Text('Grid Frequency'),
                            ),
                            DropdownMenuItem(
                              value: GraphMetric.pvInputVoltage.name,
                              child: const Text('PV Input Voltage'),
                            ),
                            DropdownMenuItem(
                              value: GraphMetric.pvInputCurrent.name,
                              child: const Text('PV Input Current'),
                            ),
                            DropdownMenuItem(
                              value: GraphMetric.acOutputVoltage.name,
                              child: const Text('AC Output Voltage'),
                            ),
                            DropdownMenuItem(
                              value: GraphMetric.acOutputCurrent.name,
                              child: const Text('AC Output Current'),
                            ),
                            DropdownMenuItem(
                              value: GraphMetric.batterySoc.name,
                              child: const Text('Battery SOC'),
                            ),
                          ],
                          onChanged: (value) async {
                            if (value == null) return;
                            final plantId = plantViewModel.plants.isNotEmpty
                                ? plantViewModel.plants.first.id
                                : null;
                            if (plantId == null) return;
                            setState(() {
                              _selectedMetric = GraphMetric.values
                                  .firstWhere((e) => e.name == value);
                            });
                            await graphVM.setMetric(
                              _selectedMetric,
                              plantId: plantId,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Device selection dropdown
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          value: graphVM.selectedDeviceKey ?? '__ALL__',
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          items: [
                            DropdownMenuItem(
                              value: '__ALL__',
                              child: Text(
                                  gen.AppLocalizations.of(context).devices),
                            ),
                            ...graphVM.deviceOptions.map(
                              (d) => DropdownMenuItem(
                                value: d.key,
                                child: Text(d.label),
                              ),
                            ),
                          ],
                          onChanged: (val) async {
                            if (val == null) return;
                            final plantId = plantViewModel.plants.isNotEmpty
                                ? plantViewModel.plants.first.id
                                : null;
                            if (plantId == null) return;
                            if (val == '__ALL__') {
                              await graphVM.setSelectedDevice(
                                '',
                                plantId: plantId,
                              );
                            } else {
                              await graphVM.setSelectedDevice(
                                val,
                                plantId: plantId,
                              );
                            }
                            final allowed =
                                graphVM.allowedMetricsForSelectedDevice;
                            if (!allowed.contains(_selectedMetric)) {
                              setState(() {
                                _selectedMetric = allowed.first;
                              });
                              await graphVM.setMetric(
                                _selectedMetric,
                                plantId: plantId,
                              );
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Period chips stacked below
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ChoiceChip(
                          label:
                              Text(gen.AppLocalizations.of(context).range_day),
                          selected: _selectedPeriod == GraphPeriod.day,
                          onSelected: (s) async {
                            if (!s) return;
                            final plantId = plantViewModel.plants.isNotEmpty
                                ? plantViewModel.plants.first.id
                                : null;
                            if (plantId == null) return;
                            setState(
                              () => _selectedPeriod = GraphPeriod.day,
                            );
                            await graphVM.setPeriod(
                              GraphPeriod.day,
                              plantId: plantId,
                            );
                          },
                        ),
                        ChoiceChip(
                          label: Text(
                              gen.AppLocalizations.of(context).range_month),
                          selected: _selectedPeriod == GraphPeriod.month,
                          onSelected: (s) async {
                            if (!s) return;
                            final plantId = plantViewModel.plants.isNotEmpty
                                ? plantViewModel.plants.first.id
                                : null;
                            if (plantId == null) return;
                            setState(
                              () => _selectedPeriod = GraphPeriod.month,
                            );
                            await graphVM.setPeriod(
                              GraphPeriod.month,
                              plantId: plantId,
                            );
                          },
                        ),
                        ChoiceChip(
                          label:
                              Text(gen.AppLocalizations.of(context).range_year),
                          selected: _selectedPeriod == GraphPeriod.year,
                          onSelected: (s) async {
                            if (!s) return;
                            final plantId = plantViewModel.plants.isNotEmpty
                                ? plantViewModel.plants.first.id
                                : null;
                            if (plantId == null) return;
                            setState(
                              () => _selectedPeriod = GraphPeriod.year,
                            );
                            await graphVM.setPeriod(
                              GraphPeriod.year,
                              plantId: plantId,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Date Selector
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_left, color: Colors.black54),
                      onPressed: () async {
                        final plantId = plantViewModel.plants.isNotEmpty
                            ? plantViewModel.plants.first.id
                            : null;
                        if (plantId == null) return;
                        await graphVM.stepDate(-1, plantId: plantId);
                      },
                    ),
                    Text(
                      _selectedPeriod == GraphPeriod.day
                          ? _formatDate(graphVM.anchor)
                          : _selectedPeriod == GraphPeriod.month
                              ? _formatMonth(graphVM.anchor)
                              : graphVM.anchor.year.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final now = DateTime.now();
                        bool canGoNext;
                        switch (_selectedPeriod) {
                          case GraphPeriod.day:
                            final today = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );
                            final anchorDay = DateTime(
                              graphVM.anchor.year,
                              graphVM.anchor.month,
                              graphVM.anchor.day,
                            );
                            canGoNext = anchorDay.isBefore(today);
                            break;
                          case GraphPeriod.month:
                            final thisMonth = DateTime(
                              now.year,
                              now.month,
                              1,
                            );
                            final anchorMonth = DateTime(
                              graphVM.anchor.year,
                              graphVM.anchor.month,
                              1,
                            );
                            canGoNext = anchorMonth.isBefore(thisMonth);
                            break;
                          case GraphPeriod.year:
                            final thisYear = DateTime(now.year, 1, 1);
                            final anchorYear = DateTime(
                              graphVM.anchor.year,
                              1,
                              1,
                            );
                            canGoNext = anchorYear.isBefore(thisYear);
                            break;
                        }
                        return IconButton(
                          icon: Icon(
                            Icons.arrow_right,
                            color: canGoNext ? Colors.black54 : Colors.black26,
                          ),
                          onPressed: canGoNext
                              ? () async {
                                  final plantId =
                                      plantViewModel.plants.isNotEmpty
                                          ? plantViewModel.plants.first.id
                                          : null;
                                  if (plantId == null) return;
                                  await graphVM.stepDate(
                                    1,
                                    plantId: plantId,
                                  );
                                }
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Chart Area
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  // Reduced height to remove excessive bottom whitespace
                  height: 240,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Chart rendering
                      Positioned.fill(
                        child: _OverviewChart(state: graphVM.state),
                      ),
                      // Removed '+ Add Datalogger' button for a cleaner chart card per Figma
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Bottom padding for bottom navigation bar
              const SizedBox(height: 56),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewChart extends StatelessWidget {
  final OverviewGraphState state;
  const _OverviewChart({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            state.error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (state.labels.isEmpty || state.series.isEmpty) {
      return const Center(child: Text('No data'));
    }
    // Return the chart directly to avoid nested boxes/containers
    return _LineChart(state: state);
  }
}

class _LineChart extends StatelessWidget {
  final OverviewGraphState state;
  const _LineChart({required this.state});

  @override
  Widget build(BuildContext context) {
    // Avoid heavy import in this file: use fl_chart types lazily via import at top of file
    final theme = Theme.of(context);
    final Color lineColor = theme.colorScheme.primary;

    // Detect daily by label style (24 entries like 00:00)
    final bool isDaily = state.labels.length == 24 &&
        (state.labels.first.contains(':') || state.labels.last.contains(':'));

    final double minY = state.min;
    final double maxY = state.max == state.min ? state.min + 1 : state.max;
    // range not needed with hidden left axis
    // Choose up to 5 horizontal ticks (min + 3 intervals + max)
    // interval no longer needed since left axis labels removed

    // Custom bottom tick strategy: day => 12AM, 6AM, 12PM, 6PM; month => 1, 15, last; year => Jan, Jun, Dec.
    // Unified graph card + chart to match device detail
    final chart = LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        backgroundColor: Colors.transparent,
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.black.withOpacity(.15), width: 1),
            bottom: BorderSide(color: Colors.black.withOpacity(.15), width: 1),
            right: const BorderSide(color: Colors.transparent),
            top: const BorderSide(color: Colors.transparent),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: Colors.black.withOpacity(.04), strokeWidth: 1),
          getDrawingVerticalLine: (v) =>
              FlLine(color: Colors.black.withOpacity(.04), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              // reduce reserved space to lessen blank area below line graph
              reservedSize: 38,
              interval: isDaily ? 360 : 1,
              getTitlesWidget: (value, meta) {
                String text = '';
                bool isFirst = false;
                if (isDaily) {
                  final minute = value.round();
                  if (minute == 0) {
                    text = '12AM';
                    isFirst = true;
                  } else if (minute == 360)
                    text = '6AM';
                  else if (minute == 720)
                    text = '12PM';
                  else if (minute == 1080) text = '6PM';
                } else {
                  final len = state.labels.length;
                  if (len == 0) return const SizedBox.shrink();
                  final idx = value.round();
                  if (len == 12) {
                    // Year view (12 months)
                    if (idx == 0) {
                      text = state.labels.first; // Jan
                      isFirst = true;
                    } else if (idx == 5)
                      text = state.labels[5]; // Jun
                    else if (idx == 11) text = state.labels.last; // Dec
                  } else {
                    // Month view (days)
                    final lastIdx = len - 1;
                    // Always show day 1
                    if (idx == 0) {
                      text = state.labels.first; // 1
                      isFirst = true;
                    }
                    // Middle (15th) if exists
                    else if (int.tryParse(state.labels[idx]) == 15) {
                      text = '15';
                    } else if (idx == lastIdx) {
                      text = state.labels.last; // 30/31/28/29
                    }
                  }
                }
                if (text.isEmpty) return const SizedBox.shrink();
                final style = const TextStyle(
                  fontSize: 11,
                  height: 1.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                );
                final textDir = Directionality.of(context);
                final tp = TextPainter(
                  text: TextSpan(text: text, style: style),
                  textDirection: textDir,
                )..layout();
                final sign = (textDir == ui.TextDirection.ltr) ? 1.0 : -1.0;
                final dx = isFirst ? sign * (tp.width / 2 + 2) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(top: 8, right: 6),
                  child: Transform.translate(
                    offset: Offset(dx, 2),
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: style,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white,
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            getTooltipItems: (items) => items.map((it) {
              String label;
              if (isDaily) {
                int minute = it.x.round();
                if (minute < 0) minute = 0;
                if (minute > 1439) minute = 1439;
                final h = minute ~/ 60;
                final m = minute % 60;
                final hour12 = ((h + 11) % 12) + 1;
                final ampm = h < 12 ? 'AM' : 'PM';
                label =
                    '${hour12.toString()}:${m.toString().padLeft(2, '0')} $ampm';
              } else {
                final len = state.labels.length;
                int idx = it.x.round();
                if (idx < 0)
                  idx = 0;
                else if (idx >= len) idx = len - 1;
                label = len > 0 ? state.labels[idx] : '';
              }
              return LineTooltipItem(
                '$label\n${it.y.toStringAsFixed(1)} ${state.unit}',
                const TextStyle(color: Colors.black),
              );
            }).toList(),
          ),
        ),
        minX: 0,
        maxX: isDaily ? 1439 : null,
        lineBarsData: state.series.map((s) {
          final spots = isDaily
              ? _spotsDailyPerMinute(s.data)
              : _upsampleSpots(s.data, 16);
          return LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.36,
            color: lineColor,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  lineColor.withOpacity(0.30),
                  lineColor.withOpacity(0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          );
        }).toList(),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        // ensure labels don't touch borders and keep consistent insets
        // reduce bottom padding to balance top/bottom whitespace
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: chart,
      ),
    );
  }

  // Daily per-minute linear interpolation (24 points -> 1440 spots)
  List<FlSpot> _spotsDailyPerMinute(List<double> hourly) {
    if (hourly.isEmpty) return const <FlSpot>[];
    if (hourly.length == 1) {
      // flat line across a day
      return List<FlSpot>.generate(
        1440,
        (i) => FlSpot(i.toDouble(), hourly.first),
      );
    }
    final spots = <FlSpot>[];
    for (int h = 0; h < hourly.length - 1; h++) {
      final y0 = hourly[h];
      final y1 = hourly[h + 1];
      // minutes within the hour: 0..59
      for (int m = 0; m < 60; m++) {
        final r = m / 60.0;
        final y = y0 + (y1 - y0) * r;
        final x = h * 60 + m;
        spots.add(FlSpot(x.toDouble(), y));
      }
    }
    // Add last minute of the day
    spots.add(FlSpot(1439, hourly.last));
    return spots;
  }

  // Linear interpolation upsampling: inserts (factor-1) points between each pair
  List<FlSpot> _upsampleSpots(List<double> data, int factor) {
    if (data.isEmpty) return const <FlSpot>[];
    if (data.length == 1 || factor <= 1) {
      return List<FlSpot>.generate(
        data.length,
        (i) => FlSpot(i.toDouble(), data[i]),
      );
    }
    final spots = <FlSpot>[];
    for (int i = 0; i < data.length - 1; i++) {
      final x0 = i.toDouble();
      final y0 = data[i];
      final x1 = (i + 1).toDouble();
      final y1 = data[i + 1];
      // include start point
      spots.add(FlSpot(x0, y0));
      // add intermediate points (exclude the end to avoid duplicates)
      for (int t = 1; t < factor; t++) {
        final r = t / factor;
        final xr = x0 + (x1 - x0) * r;
        final yr = y0 + (y1 - y0) * r; // linear interp
        spots.add(FlSpot(xr, yr));
      }
    }
    // add last original point
    spots.add(FlSpot((data.length - 1).toDouble(), data.last));
    return spots;
  }
}

class _InfoCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String unit;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      width: 160,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, // themed surface
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(icon, height: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white70,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              width: 28,
              height: 28,
              // Let the original SVG color show; if you need tinting, use theme-friendly assets
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppDrawer extends StatelessWidget {
  final String username;
  final String email;
  final VoidCallback? onProfileTap;
  final VoidCallback? onLogout;
  final ValueChanged<int>? onNavigate;

  const AppDrawer({
    Key? key,
    required this.username,
    required this.email,
    this.onProfileTap,
    this.onLogout,
    this.onNavigate,
  }) : super(key: key);

  void _showContactSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('For support, please contact:'),
            const SizedBox(height: 8),
            const Text('Email: support@crownmicrosolar.com'),
            const SizedBox(height: 4),
            const Text('Phone: +1 (555) 123-4567'),
            const SizedBox(height: 4),
            const Text('Hours: Mon-Fri, 9AM-5PM EST'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(16),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      Text(
                        username,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _DrawerItem(
                  icon: 'assets/icons/home.svg',
                  label: gen.AppLocalizations.of(context).tabs_home,
                  onTap: () => onNavigate?.call(0),
                ),
                _DrawerItem(
                  icon: Icons.eco,
                  label: gen.AppLocalizations.of(context).drawer_plant_info,
                  onTap: () => onNavigate?.call(1),
                ),
                _DrawerItem(
                  icon: 'assets/icons/deviceDetails.svg',
                  label: gen.AppLocalizations.of(context).tabs_device,
                  onTap: () => onNavigate?.call(2),
                ),
                _DrawerItem(
                  icon: 'assets/icons/deviceDataDownload.svg',
                  label: gen.AppLocalizations.of(
                    context,
                  ).drawer_download_report,
                  onTap: () {
                    Navigator.of(context).pop();
                    Future.delayed(const Duration(milliseconds: 120), () {
                      _showCollectorReportDialog();
                    });
                  },
                ),
                _DrawerItem(
                  icon: 'assets/icons/contact.svg',
                  label: gen.AppLocalizations.of(
                    context,
                  ).drawer_contact_support,
                  onTap: () => _showContactSupportDialog(context),
                ),
                _DrawerItem(
                  icon: 'assets/icons/profileInfo.svg',
                  label: gen.AppLocalizations.of(context).tabs_user,
                  onTap: onProfileTap ?? () {},
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0, left: 25),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.power_settings_new),
                    label: Text(gen.AppLocalizations.of(context).drawer_logout),
                    onPressed: onLogout,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: icon is String
          ? SvgPicture.asset(
              icon,
              color: Theme.of(context).colorScheme.onPrimary,
              width: 24,
              height: 24,
            )
          : Icon(
              icon as IconData,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 24,
            ),
      title: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }
}

// Helper: show collector report download dialog using a safe, global context.
void _showCollectorReportDialog() {
  final safeContext = NavigationService.navigatorKey.currentContext;
  if (safeContext == null) return;
  showDialog(
    context: safeContext,
    barrierDismissible: true,
    builder: (ctx) {
      final deviceVM = getIt<DeviceViewModel>();
      final plantVM = getIt<PlantViewModel>();
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (plantVM.plants.isEmpty) {
          await plantVM.loadPlants();
        }
        if (deviceVM.collectors.isEmpty &&
            plantVM.plants.isNotEmpty &&
            !deviceVM.isLoading) {
          await deviceVM.loadDevicesAndCollectors(plantVM.plants.first.id);
        }
      });

      CollectorReportRange range = CollectorReportRange.daily;
      DateTime anchorDate = DateTime.now();
      String? selectedCollectorPn = deviceVM.collectors.isNotEmpty
          ? deviceVM.collectors.first['pn']?.toString()
          : null;

      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setState) {
            Widget rangeChip(CollectorReportRange r, String label) {
              final selected = r == range;
              return Expanded(
                child: InkWell(
                  onTap: () => setState(() => range = r),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.black : Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }

            String formatDate(CollectorReportRange r, DateTime d) {
              switch (r) {
                case CollectorReportRange.daily:
                  return DateFormat('yyyy/MM/dd').format(d);
                case CollectorReportRange.monthly:
                  return DateFormat('yyyy/MM').format(d);
                case CollectorReportRange.yearly:
                  return DateFormat('yyyy').format(d);
              }
            }

            Future<void> onDownload() async {
              if (selectedCollectorPn == null || selectedCollectorPn!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No collector available to export'),
                  ),
                );
                return;
              }
              try {
                final service = ReportDownloadService();
                Navigator.of(context).pop();

                final progressVN = ValueNotifier<double>(0);
                final bottomSheetContext =
                    NavigationService.navigatorKey.currentContext;
                if (bottomSheetContext == null) return;
                showModalBottomSheet(
                  context: bottomSheetContext,
                  isDismissible: false,
                  enableDrag: false,
                  builder: (_) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ValueListenableBuilder<double>(
                        valueListenable: progressVN,
                        builder: (c, value, _) {
                          final pctText = value > 0
                              ? '${(value * 100).clamp(0, 100).toStringAsFixed(0)}%'
                              : 'Starting...';
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gen.AppLocalizations.of(
                                  c,
                                ).report_download_full_title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: value == 0 ? null : value,
                              ),
                              const SizedBox(height: 8),
                              Text(pctText),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(c).pop();
                                },
                                child: Text(
                                  gen.AppLocalizations.of(c).action_cancel,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                );

                await service.downloadFullReportByCollector(
                  collectorPn: selectedCollectorPn!,
                  range: range,
                  anchorDate: anchorDate,
                  onProgress: (r, t) {
                    if (t > 0) {
                      progressVN.value = (r / t).clamp(0, 1);
                    }
                  },
                );

                if (NavigationService.canPop()) {
                  NavigationService.pop();
                }
                final scContext = NavigationService.navigatorKey.currentContext;
                if (scContext != null) {
                  ScaffoldMessenger.of(scContext).showSnackBar(
                    const SnackBar(content: Text('Report saved to Downloads')),
                  );
                }
              } catch (e) {
                if (NavigationService.canPop()) {
                  NavigationService.pop();
                }
                final scContext = NavigationService.navigatorKey.currentContext;
                if (scContext != null) {
                  ScaffoldMessenger.of(scContext).showSnackBar(
                    SnackBar(content: Text('Failed to download: $e')),
                  );
                }
              }
            }

            return AnimatedBuilder(
              animation: deviceVM,
              builder: (_, __) {
                // Ensure a collector is selected once collectors are available
                if (selectedCollectorPn == null &&
                    deviceVM.collectors.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      selectedCollectorPn =
                          deviceVM.collectors.first['pn']?.toString();
                    });
                  });
                }
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        gen.AppLocalizations.of(
                          context,
                        ).report_download_full_title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (deviceVM.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (deviceVM.collectors.isEmpty)
                        Text(
                          gen.AppLocalizations.of(context).report_no_collectors,
                          style: const TextStyle(color: Colors.red),
                        )
                      else
                        InputDecorator(
                          decoration: InputDecoration(
                            labelText: gen.AppLocalizations.of(
                              context,
                            ).report_collector_label,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: selectedCollectorPn,
                              hint: Text(
                                gen.AppLocalizations.of(
                                  context,
                                ).report_select_collector_hint,
                              ),
                              items: deviceVM.collectors
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c['pn']?.toString(),
                                      child: Text(
                                        (c['alias']?.toString().isNotEmpty ==
                                                true
                                            ? c['alias'].toString()
                                            : c['pn'].toString()),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => selectedCollectorPn = v),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          rangeChip(
                            CollectorReportRange.daily,
                            gen.AppLocalizations.of(context).range_day,
                          ),
                          rangeChip(
                            CollectorReportRange.monthly,
                            gen.AppLocalizations.of(context).range_month,
                          ),
                          rangeChip(
                            CollectorReportRange.yearly,
                            gen.AppLocalizations.of(context).range_year,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: anchorDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => anchorDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE0E0E0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 18,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  formatDate(range, anchorDate),
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              gen.AppLocalizations.of(context).action_cancel,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: deviceVM.collectors.isNotEmpty
                                ? onDownload
                                : null,
                            child: Text(
                              gen.AppLocalizations.of(context).action_download,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
    },
  );
}
