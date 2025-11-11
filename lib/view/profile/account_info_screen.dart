import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/presentation/viewmodels/auth_viewmodel.dart';

class AccountInfoScreen extends StatelessWidget {
  const AccountInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthViewModel>(context).userInfo;

    // Extract username after underscore (e.g., "Crown213_bilal" -> "bilal")
    String displayUsername = user?.usr ?? '';
    if (displayUsername.contains('_')) {
      displayUsername =
          displayUsername.substring(displayUsername.indexOf('_') + 1);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account Info')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _infoCard('Username', displayUsername, Icons.person),
                _infoCard('Email', user.email, Icons.email),
                _infoCard('Mobile', user.mobile, Icons.phone),
                _infoCard('Role', _roleLabel(user.role), Icons.badge),
                _infoCard('Active', user.enable ? 'Yes' : 'No', Icons.check),
                _infoCard('Since', user.gts.toLocal().toString(), Icons.event),
              ],
            ),
    );
  }

  String _roleLabel(int role) {
    switch (role) {
      case 0:
        return 'Plant Owner';
      case 1:
        return 'Installer';
      case 2:
        return 'Agent';
      case 3:
        return 'Viewer';
      default:
        return 'User';
    }
  }

  Widget _infoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
