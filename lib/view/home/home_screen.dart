import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Overview',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(Icons.notifications_none),
          ),
        ],
      ),
      drawer: AppDrawer(
        username: 'Azidanir025',
        email: 'azidanir025@gmail.com',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Card Section
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              margin: const EdgeInsets.all(0),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 0),
              child: Stack(
                children: [
                  SvgPicture.asset(
                    'assets/icons/home/homebackground.svg',
                    fit: BoxFit.fill,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Last updated : 6:51 PM',
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 12),
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
                        const SizedBox(height: 80),
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
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFFE53935),
        unselectedItemColor: Colors.black54,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/home.svg',
                height: 24, color: Colors.black54),
            activeIcon: SvgPicture.asset('assets/icons/home.svg',
                height: 24, color: Color(0xFFE53935)),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/contact.svg',
                height: 24, color: Colors.black54),
            activeIcon: SvgPicture.asset('assets/icons/contact.svg',
                height: 24, color: Color(0xFFE53935)),
            label: 'Contact',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/deviceDetails.svg',
                height: 24, color: Colors.black54),
            activeIcon: SvgPicture.asset('assets/icons/deviceDetails.svg',
                height: 24, color: Color(0xFFE53935)),
            label: 'Devices',
          ),
          BottomNavigationBarItem(
            icon: SvgPicture.asset('assets/icons/profileInfo.svg',
                height: 24, color: Colors.black54),
            activeIcon: SvgPicture.asset('assets/icons/profileInfo.svg',
                height: 24, color: Color(0xFFE53935)),
            label: 'Profile',
          ),
        ],
        currentIndex: 0,
        onTap: (index) {},
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(
                width: 5,
              ),
              Text("KW/H",
                  style: TextStyle(fontSize: 10, color: Color(0xFFE53935))),
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
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
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

  const AppDrawer({
    Key? key,
    required this.username,
    required this.email,
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
                  onTap: () {},
                ),
                _DrawerItem(
                  iconPath: 'assets/icons/contact.svg',
                  label: 'Contact',
                  onTap: () {},
                ),
                _DrawerItem(
                  iconPath: 'assets/icons/deviceDetails.svg',
                  label: 'Devices',
                  onTap: () {},
                ),
                _DrawerItem(
                  iconPath: 'assets/icons/deviceDataDownload.svg',
                  label: 'Real-time Device Data',
                  onTap: () {},
                ),
                _DrawerItem(
                  iconPath: 'assets/icons/profileInfo.svg',
                  label: 'Profile',
                  onTap: () {},
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
                    onPressed: () {},
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
