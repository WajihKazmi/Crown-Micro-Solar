import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crown_micro_solar/core/config/app_config.dart';

class WhatsAppSupportScreen extends StatelessWidget {
  const WhatsAppSupportScreen({Key? key}) : super(key: key);

  Future<void> _openWhatsApp() async {
    final phone = AppConfig.supportWhatsAppNumber;
    final text = Uri.encodeComponent(AppConfig.supportWhatsAppMessage);
    final uri = Uri.parse('https://wa.me/$phone?text=$text');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch WhatsApp');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WhatsApp Support')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: _openWhatsApp,
          icon: const Icon(Icons.chat),
          label: const Text('Chat on WhatsApp'),
        ),
      ),
    );
  }
}
