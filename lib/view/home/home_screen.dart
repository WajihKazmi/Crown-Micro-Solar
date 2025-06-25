import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/presentation/viewmodels/auth_viewmodel.dart';
import '../common/bordered_icon_button.dart';
import '../profile/profile_screen.dart';
import 'app_bottom_nav_bar.dart';
import 'contact_screen.dart';
import 'devices_screen.dart';
import 'alarm_notification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
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
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _logout(BuildContext context) async {
    await _performLogout();
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _OverviewBody();
      case 1:
        return const ContactScreen();
      case 2:
        return const DevicesScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _OverviewBody();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      drawer: AppDrawer(
        username: 'Azidanir025',
        email: 'azidanir025@gmail.com',
        onProfileTap: () {
          setState(() {
            _currentIndex = 3;
          });
        },
        onLogout: _onLogout,
        onNavigate: _onDrawerNavigate,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Colors.white,
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
                      ? 'Contact'
                      : _currentIndex == 2
                          ? 'Devices'
                          : _currentIndex == 3
                              ? 'Profile'
                              : 'Overview',
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
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
    );
  }
}

// Extracted overview content to a new widget for cleaner switching
class _OverviewBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Light red background container for upper widgets
          Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE), // Light red color
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                // Top Card Section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Last updated : 6:51 PM',
                            style:
                                TextStyle(color: Colors.black54, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoCard(
                                icon: 'assets/icons/home/thunder.svg',
                                label: 'Total Output Power',
                                value: '7767.2',
                                unit: 'KWH',
                              ),
                              const SizedBox(height: 12),
                              _InfoCard(
                                icon: 'assets/icons/home/capacity.svg',
                                label: 'Total Installed Capacity',
                                value: '8.2',
                                unit: 'KW',
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Main Circle
                          Expanded(
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    //SvgPicture.asset('assets/icons/home/circle_bg.svg', width: 120, height: 120),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('3.34',
                                            style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFE53935))),
                                        Text('KW',
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Color(0xFFE53935),
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text('Current Power Generation',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.black)),
                                        Text('All Power Stations',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.black54)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                //SvgPicture.asset('assets/icons/home/house.svg', width: 60),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),
                      // Summary Cards
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _SummaryCard(
                            icon: 'assets/icons/home/totalPlants.svg',
                            label: 'Total Plant',
                            value: '200',
                          ),
                          _SummaryCard(
                            icon: 'assets/icons/home/totalDevices.svg',
                            label: 'Total Device',
                            value: '357',
                          ),
                          _SummaryCard(
                            icon: 'assets/icons/home/totalAlarms.svg',
                            label: 'Total Alarm',
                            value: '266',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  value: 'AC2 Output Voltage',
                  items: [
                    DropdownMenuItem(
                      value: 'AC2 Output Voltage',
                      child: Text('AC2 Output Voltage'),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.arrow_left, color: Colors.black54),
                Text('June 2024',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Icon(Icons.arrow_right, color: Colors.black54),
              ],
            ),
          ),
          // Chart Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
  }
}

class _InfoCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String unit;

  const _InfoCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3), // Glass morphism background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.4), // Glass border
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(icon, height: 28),
              const SizedBox(height: 15),
              Text(label, style: TextStyle(fontSize: 12, color: Colors.black)),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(value,
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(
                    width: 5,
                  ),
                  Text("KW/H",
                      style: TextStyle(fontSize: 10, color: Color(0xFFE53935))),
                ],
              ),
            ],
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFFE53935),
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
                  iconPath: 'assets/icons/home.svg',
                  label: 'Overview',
                  onTap: () => onNavigate?.call(0),
                ),
                _DrawerItem(
                  iconPath: 'assets/icons/contact.svg',
                  label: 'Contact',
                  onTap: () => onNavigate?.call(1),
                ),
                _DrawerItem(
                  iconPath: 'assets/icons/deviceDetails.svg',
                  label: 'Devices',
                  onTap: () => onNavigate?.call(2),
                ),
                _DrawerItem(
                  iconPath: 'assets/icons/deviceDataDownload.svg',
                  label: 'Real-time Device Data',
                  onTap: () {},
                ),
                _DrawerItem(
                  iconPath: 'assets/icons/profileInfo.svg',
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
  final String iconPath;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    Key? key,
    required this.iconPath,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SvgPicture.asset(
        iconPath,
        color: Colors.white,
        width: 24,
        height: 24,
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
