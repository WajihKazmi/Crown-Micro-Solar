import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/presentation/viewmodels/auth_viewmodel.dart';
import 'package:crown_micro_solar/presentation/viewmodels/plant_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/dashboard_view_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/device_view_model.dart';
import '../common/bordered_icon_button.dart';
import '../profile/profile_screen.dart';
import 'app_bottom_nav_bar.dart';
import 'devices_screen.dart'; // Use the original version
import 'alarm_notification_screen.dart';
import 'package:crown_micro_solar/core/di/service_locator.dart';
import 'package:crown_micro_solar/view/home/plant_info_screen.dart';
import 'package:crown_micro_solar/core/services/realtime_data_service.dart';

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

    // Start real-time data service
    _realtimeDataService.start();

    // Load initial data
    _plantViewModel.loadPlants();
    _dashboardViewModel.loadDashboardData();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Reload data when switching to specific tabs
    if (index == 2) {
      // Device tab
      // Make sure plant data is loaded
      _plantViewModel.loadPlants();
    }
  }

  void _onDrawerNavigate(int index) {
    setState(() {
      _currentIndex = index;
    });
    Navigator.pop(context);
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog first
              await _performLogout();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      print('Starting logout process...');
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // Check initial state
      print('Initial isLoggedIn state: ${authViewModel.isLoggedIn}');

      // Perform logout
      await authViewModel.logout();
      print('Logout completed successfully');

      // Refresh auth state
      authViewModel.refreshAuthState();
      print('Auth state refreshed');

      // Check final state
      print('Final isLoggedIn state: ${authViewModel.isLoggedIn}');

      // Add a small delay to ensure all state changes are processed
      await Future.delayed(const Duration(milliseconds: 100));

      // Navigate to login screen
      if (mounted) {
        print('Navigating to login screen...');
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      print('Error during logout: $e');
      // Show error message if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Logout failed: $e',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    // Stop real-time data service when widget is disposed
    _realtimeDataService.stop();
    super.dispose();
  }

  void _showUserSwitcherDialog(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch User'),
        content: SizedBox(
          width: double.maxFinite,
          height:
              MediaQuery.of(context).size.height * 0.6, // 60% of screen height
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (authViewModel.agentsList != null &&
                  authViewModel.agentsList!.isNotEmpty) ...[
                const Text(
                  'Available Agents:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: authViewModel.agentsList!.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final agent = authViewModel.agentsList![index];
                      return ListTile(
                        title: Text(
                          agent['Username'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          agent['SNNumber'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          Navigator.of(context).pop();
                          // Handle agent switching
                          _switchToAgent(agent);
                        },
                      );
                    },
                  ),
                ),
              ] else ...[
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No other users available',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _switchToAgent(Map<String, dynamic> agent) async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Switching to agent...'),
            ],
          ),
        ),
      );

      // Perform login with the selected agent
      final success = await authViewModel.loginAgent(
        agent['Username'],
        agent['Password'],
      );

      // Close loading dialog
      Navigator.of(context).pop();

      if (success) {
        // Refresh all data for the new user
        await _refreshDataForNewUser();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Switched to ${agent['Username']} successfully',
                style: const TextStyle(color: Colors.black),
              ),
              backgroundColor: Colors.white,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to switch to ${agent['Username']}: ${authViewModel.error ?? 'Unknown error'}',
                style: const TextStyle(color: Colors.black),
              ),
              backgroundColor: Colors.white,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error switching agent: ${e.toString()}',
              style: const TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
                key: PageStorageKey('plant_${firstPlant.id}'))
            : Center(
                child: CircularProgressIndicator(),
                key: PageStorageKey('plant_loading'));
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
                  // First close the drawer
                  Navigator.pop(context);
                  // Then update the current index to show profile
                  setState(() {
                    _currentIndex = 3;
                  });
                },
                onLogout: _onLogout,
                onNavigate: _onDrawerNavigate,
              ),
        // For the devices tab, we use DevicesScreen directly
        body: _currentIndex == 2
            ? SafeArea(child: _getBody())
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Colors.transparent,
                    floating: true,
                    snap: true,
                    pinned: true,
                    leading: Builder(
                      builder: (context) => BorderedIconButton(
                        icon: Icons.menu,
                        onTap: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    title: Text(
                      _currentIndex == 0
                          ? 'Overview'
                          : _currentIndex == 1
                              ? 'Plant Info'
                              : _currentIndex == 2
                                  ? 'Devices'
                                  : _currentIndex == 3
                                      ? 'Profile'
                                      : 'Overview',
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                    centerTitle: true,
                    actions: [
                      if (authViewModel.isInstaller)
                        BorderedIconButton(
                          icon: Icons.people,
                          onTap: () {
                            // Show user switcher dialog
                            _showUserSwitcherDialog(context);
                          },
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
                  SliverToBoxAdapter(
                    child: _getBody(),
                  ),
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
class _OverviewBody extends StatelessWidget {
  const _OverviewBody({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Consumer3<PlantViewModel, DashboardViewModel, RealtimeDataService>(
      builder: (context, plantViewModel, dashboardViewModel, realtimeService,
          child) {
        if (plantViewModel.isLoading || dashboardViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (plantViewModel.error != null) {
          return Center(child: Text('Error: ${plantViewModel.error}'));
        }
        if (dashboardViewModel.error != null) {
          return Center(child: Text('Error: ${dashboardViewModel.error}'));
        }
        // Use real-time data if available, otherwise fall back to plant view model data
        final plants = realtimeService.plants.isNotEmpty
            ? realtimeService.plants
            : plantViewModel.plants;
        final totalOutput = realtimeService.totalCurrentPower > 0
            ? realtimeService.totalCurrentPower
            : 0.0; // No fallback, use zero
        final totalCapacity =
            plants.fold<double>(0, (sum, p) => sum + p.capacity);
        final totalPlants = plants.length;
        // You can add more aggregations as needed
        return SingleChildScrollView(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(10),
                height: 360, // Fixed height for consistent layout
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
                              horizontal: 30, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    realtimeService.isRunning
                                        ? 'Live Data'
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
                              const SizedBox(height: 10),
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
                                          value: totalOutput.toStringAsFixed(1),
                                          unit: 'KWH',
                                        ),
                                        const SizedBox(height: 12),
                                        _InfoCard(
                                          icon:
                                              'assets/icons/home/capacity.svg',
                                          label: 'Total Installed Capacity',
                                          value:
                                              totalCapacity.toStringAsFixed(1),
                                          unit: 'KW',
                                        ),
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
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 10),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                totalOutput > 0
                                                    ? totalOutput
                                                        .toStringAsFixed(2)
                                                    : "0.00",
                                                style: const TextStyle(
                                                    fontSize: 27,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFE53935))),
                                            const Text('KW',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    color: Color(0xFFE53935),
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 4),
                                            const Text(
                                              'Current Power\n Generation',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w700),
                                              textAlign: TextAlign.center,
                                            ),
                                            const Text('All Power Stations',
                                                style: TextStyle(
                                                    fontSize: 8,
                                                    color: Colors.black54)),
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
              // Dropdown
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      value: 'OUTPUT_POWER',
                      items: [
                        DropdownMenuItem(
                          value: 'OUTPUT_POWER',
                          child: Text('Output Power'),
                        ),
                        DropdownMenuItem(
                          value: 'GRID_VOLTAGE',
                          child: Text('Grid Voltage'),
                        ),
                        DropdownMenuItem(
                          value: 'GRID_FREQUENCY',
                          child: Text('Grid Frequency'),
                        ),
                      ],
                      onChanged: (value) {},
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
                ),
              ),
              // Date Selector
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(Icons.arrow_left, color: Colors.black54),
                    Text('June 2024',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Icon(Icons.arrow_right, color: Colors.black54),
                  ],
                ),
              ),
              // Chart Area
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 180,
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
                      // Placeholder for chart SVG
                      // Center(
                      //   child: SvgPicture.asset('assets/icons/home/chart.svg',
                      //       height: 120),
                      // ),
                      // Add Datalogger Button
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 16,
                        child: Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFE53935),
                              shape: StadiumBorder(),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 10),
                            ),
                            onPressed: () {},
                            child: Text('+ Add Datalogger',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Bottom padding for bottom navigation bar
              const SizedBox(height: 72),
            ],
          ),
        );
      },
    );
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
        color: Colors.white, // Solid white background instead of glassmorphism
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
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black)),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                value,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(width: 5),
              Text(
                unit,
                style: const TextStyle(fontSize: 10, color: Color(0xFFE53935)),
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

  const _SummaryCard(
      {required this.icon, required this.label, required this.value});

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
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.black)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black)),
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
          color: const Color(0xFFE53935),
          borderRadius: BorderRadius.horizontal(right: Radius.circular(16)),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _DrawerItem(
                  icon: 'assets/icons/home.svg',
                  label: 'Overview',
                  onTap: () => onNavigate?.call(0),
                ),
                _DrawerItem(
                  icon: Icons.eco,
                  label: 'Plant Info',
                  onTap: () => onNavigate?.call(1),
                ),
                _DrawerItem(
                  icon: 'assets/icons/deviceDetails.svg',
                  label: 'Devices',
                  onTap: () => onNavigate?.call(2),
                ),
                _DrawerItem(
                  icon: 'assets/icons/deviceDataDownload.svg',
                  label: 'Real-time Device Data',
                  onTap: () {},
                ),
                _DrawerItem(
                  icon: 'assets/icons/contact.svg',
                  label: 'Contact Support',
                  onTap: () => _showContactSupportDialog(context),
                ),
                _DrawerItem(
                  icon: 'assets/icons/profileInfo.svg',
                  label: 'Profile',
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
                          horizontal: 24, vertical: 12),
                    ),
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text('Log Out'),
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
              color: Colors.white,
              width: 24,
              height: 24,
            )
          : Icon(
              icon as IconData,
              color: Colors.white,
              size: 24,
            ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: onTap,
    );
  }
}
