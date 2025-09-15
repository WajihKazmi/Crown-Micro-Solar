import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/presentation/viewmodels/auth_viewmodel.dart';
import 'package:crown_micro_solar/l10n/app_localizations.dart' as gen;
import 'package:crown_micro_solar/main.dart';
import 'package:crown_micro_solar/core/utils/app_text_fields.dart';
import 'package:crown_micro_solar/core/utils/app_buttons.dart';
// Removed unused imports
import 'package:crown_micro_solar/presentation/viewmodels/dashboard_view_model.dart';
import 'package:crown_micro_solar/core/theme/theme_notifier.dart';
import 'package:crown_micro_solar/core/theme/app_theme.dart';
import 'package:crown_micro_solar/routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // No need to call loadDashboardData here; HomeScreen handles it globally.
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ChangePasswordDialog(),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LanguageSelectorDialog(),
    );
  }

  void _showAddInstallerDialog(BuildContext context) {
    final theme = Theme.of(context);
    final codeController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final authViewModel = Provider.of<AuthViewModel>(dialogCtx);
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Installer Code',
                    style: theme.textTheme.titleLarge?.copyWith(
                        color: const Color(0xFFEF4444), // red title like Figma
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                  controller: codeController,
                  decoration: InputDecoration(
                    hintText: 'Enter Code',
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.black12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: authViewModel.isLoading
                            ? null
                            : () => Navigator.of(dialogCtx).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFFEF4444), // red submit like Figma
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        onPressed: authViewModel.isLoading
                            ? null
                            : () async {
                                final code = codeController.text.trim();
                                if (code.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Please enter installer code',
                                          style:
                                              TextStyle(color: Colors.black)),
                                      backgroundColor: Colors.white,
                                    ),
                                  );
                                  return;
                                }
                                final ok =
                                    await authViewModel.addInstallerCode(code);
                                if (!mounted) return;
                                if (ok) {
                                  Navigator.of(dialogCtx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Installer code added',
                                          style:
                                              TextStyle(color: Colors.black)),
                                      backgroundColor: Colors.white,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        authViewModel.error ?? 'Wrong code',
                                        style: const TextStyle(
                                            color: Colors.black),
                                      ),
                                      backgroundColor: Colors.white,
                                    ),
                                  );
                                }
                              },
                        child: authViewModel.isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Submit',
                                style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authViewModel = Provider.of<AuthViewModel>(context);
    final dashboardViewModel =
        Provider.of<DashboardViewModel>(context); // Use the global instance
    final userInfo = authViewModel.userInfo;
    const lightGrey = Color(0xFFF3F4F6);
    final green = const Color(0xFF22C55E);
    final red = Theme.of(context).colorScheme.primary;
    if (userInfo == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          // User Info Card
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.accountInfo),
            child: Container(
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
                        Text(userInfo.usr,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Email: ${userInfo.email}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.6))),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      color: theme.iconTheme.color?.withOpacity(0.3), size: 18),
                ],
              ),
            ),
          ),
          // Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ProfileSummaryCard(
                  icon: 'assets/icons/home/totalPlants.svg',
                  label: 'Total Plant',
                  value: dashboardViewModel.isLoading
                      ? '-'
                      : dashboardViewModel.totalPlants.toString(),
                ),
                _ProfileSummaryCard(
                  icon: 'assets/icons/home/totalDevices.svg',
                  label: 'Total Device',
                  value: dashboardViewModel.isLoading
                      ? '-'
                      : dashboardViewModel.totalDevices.toString(),
                ),
                _ProfileSummaryCard(
                  icon: 'assets/icons/home/totalAlarms.svg',
                  label: 'Total Alarm',
                  value: dashboardViewModel.isLoading
                      ? '-'
                      : dashboardViewModel.totalAlarms.toString(),
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
                  label: gen.AppLocalizations.of(context).change_password,
                  onTap: () => _showChangePasswordDialog(context),
                  backgroundColor: lightGrey,
                  iconColor: red,
                ),
                _ProfileActionTile(
                  icon: Icons.palette_outlined,
                  label: gen.AppLocalizations.of(context).interface_theme,
                  onTap: () => _showThemeSelector(context),
                  backgroundColor: lightGrey,
                  iconColor: Color(0xFFF59E42),
                ),
                _ProfileActionTile(
                  icon: Icons.info_outline,
                  label: gen.AppLocalizations.of(context).about_us,
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.about),
                  backgroundColor: lightGrey,
                  iconColor: red,
                ),
                _ProfileActionTile(
                  icon: Icons.language,
                  label: gen.AppLocalizations.of(context).change_language,
                  onTap: () => _showLanguageSelector(context),
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
                  child: Builder(
                    builder: (context) {
                      final authViewModel = Provider.of<AuthViewModel>(context);
                      final theme = Theme.of(context);
                      final buttonColor = green; // Keep green as unique CTA
                      final label = authViewModel.isInstaller
                          ? 'Add Agent'
                          : 'Add Installer';
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                        ),
                        onPressed: () => _showAddInstallerDialog(context),
                        child: Text(label,
                            style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      );
                    },
                  ),
                ),
                // Delete Account removed per requirement
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
                            color: Colors.white, fontWeight: FontWeight.bold)),
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
      print(
          'Initial isLoggedIn state from profile: ${authViewModel.isLoggedIn}');

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
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      print('Error during logout from profile screen: $e');
      // Show error message if needed
      if (context.mounted) {
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
}

void _showThemeSelector(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) {
      final themeNotifier = Provider.of<ThemeNotifier>(ctx, listen: false);
      final palette = <Color>[
        AppTheme.basePrimary, // default
        const Color(0xFF2563EB), // blue
        const Color(0xFF0891B2), // teal
        const Color(0xFF10B981), // green
        const Color(0xFFF59E0B), // amber
        const Color(0xFFEC4899), // pink
        const Color(0xFF6366F1), // indigo
      ];
      final current = themeNotifier.primaryColor;
      return AlertDialog(
        title: const Text('Primary Color'),
        content: SizedBox(
          width: 320,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final c in palette)
                _ColorChoice(
                  color: c,
                  isSelected: c.value == current.value,
                  label: c == AppTheme.basePrimary ? 'Default' : null,
                  onTap: () {
                    themeNotifier.setPrimaryColor(c);
                    Navigator.of(ctx).pop();
                  },
                ),
              // Reset button if not on default
              if (current != AppTheme.basePrimary)
                TextButton(
                  onPressed: () {
                    themeNotifier.resetToDefault();
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Reset to Default'),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _ColorChoice extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final String? label;
  const _ColorChoice({
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.label,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
              ],
              border: Border.all(
                color: isSelected ? Colors.black : Colors.black12,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 24)
                : null,
          ),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(label!, style: const TextStyle(fontSize: 11)),
          ]
        ],
      ),
    );
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
    final theme = Theme.of(context);
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface)),
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

class ChangePasswordDialog extends StatefulWidget {
  @override
  _ChangePasswordDialogState createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final success =
        await authViewModel.changePassword(oldPassword, newPassword);
    setState(() {
      _isLoading = false;
    });
    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            gen.AppLocalizations.of(context).password_changed_success,
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
        ),
      );
    } else {
      setState(() {
        _error = gen.AppLocalizations.of(context).password_change_failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(gen.AppLocalizations.of(context).change_password,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              AppTextField(
                controller: _oldPasswordController,
                labelText: gen.AppLocalizations.of(context).old_password,
                isPassword: true,
                validator: (val) => val == null || val.isEmpty
                    ? gen.AppLocalizations.of(context).enter_old_password
                    : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _newPasswordController,
                labelText: gen.AppLocalizations.of(context).new_password,
                isPassword: true,
                validator: (val) => val == null || val.length < 6
                    ? gen.AppLocalizations.of(context).password_must_be_6
                    : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                controller: _confirmPasswordController,
                labelText:
                    gen.AppLocalizations.of(context).confirm_new_password,
                isPassword: true,
                validator: (val) => val != _newPasswordController.text
                    ? gen.AppLocalizations.of(context).passwords_do_not_match
                    : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error)),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AppButtons.primaryButton(
                      context: context,
                      onTap:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      text: 'Cancel',
                      isFilled: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButtons.primaryButton(
                      context: context,
                      onTap: _isLoading ? null : _submit,
                      text: gen.AppLocalizations.of(context).change_password,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LanguageSelectorDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final supportedLocales = gen.AppLocalizations.supportedLocales;
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    return AlertDialog(
      title: Text(gen.AppLocalizations.of(context).select_language),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: supportedLocales.map((locale) {
          return ListTile(
            title: Text(_getLanguageName(locale.languageCode)),
            onTap: () {
              localeProvider.setLocale(locale);
              Navigator.of(context).pop();
            },
          );
        }).toList(),
      ),
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'ar':
        return 'Arabic';
      case 'es':
        return 'Spanish';
      case 'fr':
        return 'French';
      case 'ru':
        // Display in English per requirement
        return 'Russian';
      default:
        return code;
    }
  }
}
