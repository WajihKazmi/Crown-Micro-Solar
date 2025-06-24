import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/presentation/viewmodels/auth_viewmodel.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const lightGrey = Color(0xFFF3F4F6);
    const green = Color(0xFF22C55E);
    const red = Color(0xFFEF4444);
    return SingleChildScrollView(
      child: Column(
        children: [
          // User Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Azidanir025',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Role Power Station Owner',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.6))),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: theme.iconTheme.color?.withOpacity(0.3),
                    size: 18),
              ],
            ),
          ),
          // Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _ProfileSummaryCard(
                  icon: 'assets/icons/home/totalPlants.svg',
                  label: 'Total Plant',
                  value: '200',
                ),
                _ProfileSummaryCard(
                  icon: 'assets/icons/home/totalDevices.svg',
                  label: 'Total Device',
                  value: '357',
                ),
                _ProfileSummaryCard(
                  icon: 'assets/icons/home/totalAlarms.svg',
                  label: 'Total Alarm',
                  value: '266',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Settings/Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              children: [
                _ProfileActionTile(
                  icon: Icons.lock_outline,
                  label: 'Change Password',
                  onTap: () {},
                  backgroundColor: lightGrey,
                  iconColor: red,
                ),
                _ProfileActionTile(
                  icon: Icons.palette_outlined,
                  label: 'Interface Theme',
                  onTap: () {},
                  backgroundColor: lightGrey,
                  iconColor: Color(0xFFF59E42),
                ),
                _ProfileActionTile(
                  icon: Icons.info_outline,
                  label: 'About App',
                  onTap: () {},
                  backgroundColor: lightGrey,
                  iconColor: red,
                ),
                _ProfileActionTile(
                  icon: Icons.language,
                  label: 'Change Language',
                  onTap: () {},
                  backgroundColor: lightGrey,
                  iconColor: Color(0xFF3B82F6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: () {},
                    child: Text('Add Installer',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: () {},
                    child: Text('Delete Account',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B7280), // Grey color
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                    ),
                    onPressed: () => _showLogoutDialog(context),
                    child: Text('Logout',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Bottom padding for bottom navigation bar
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
              await _performLogout(context);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      print('Starting logout process from profile screen...');
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      
      // Check initial state
      print('Initial isLoggedIn state from profile: ${authViewModel.isLoggedIn}');
      
      // Perform logout
      await authViewModel.logout();
      print('Logout completed successfully from profile screen');
      
      // Refresh auth state
      authViewModel.refreshAuthState();
      print('Auth state refreshed from profile');
      
      // Check final state
      print('Final isLoggedIn state from profile: ${authViewModel.isLoggedIn}');
      
      // Add a small delay to ensure all state changes are processed
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Navigate to login screen
      if (context.mounted) {
        print('Navigating to login screen from profile screen...');
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      print('Error during logout from profile screen: $e');
      // Show error message if needed
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _ProfileSummaryCard(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(icon, height: 28),
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
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;

  const _ProfileActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios,
            size: 16, color: Colors.grey.withOpacity(0.4)),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        minLeadingWidth: 0,
      ),
    );
  }
}
