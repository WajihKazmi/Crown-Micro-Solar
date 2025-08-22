import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';

import 'wifi_module_webview.dart';

class CollectorDetailScreen extends StatelessWidget {
  final Map<String, dynamic> collector;

  const CollectorDetailScreen({super.key, required this.collector});

  @override
  Widget build(BuildContext context) {
    final alias = collector['alias']?.toString() ?? '';
    final pn = collector['pn']?.toString() ?? '';
    final status = (collector['status'] ?? 0) as int;
    final signal = double.tryParse(collector['signal']?.toString() ?? '0') ?? 0;
    final firmware =
        (collector['fireware'] ?? collector['firmware'])?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Datalogger Details',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),

            // Alias, PN and Status
            _infoCard(
              context,
              children: [
                _kv('ALIAS', alias, isBoldValue: true),
                _kv('PN', pn),
                _kv('STATUS', status == 0 ? 'Online' : 'Offline',
                    valueColor: status == 0 ? Colors.green : Colors.red),
              ],
            ),

            // Description and Signal
            _infoCard(
              context,
              children: [
                _kv('Description', 'Wi‑Fi Kit', isBoldValue: true),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Signal:',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600),
                    ),
                    Row(
                      children: [
                        _signalDots(signal),
                        const SizedBox(width: 8),
                        Text('${signal.toStringAsFixed(1)} %',
                            style: TextStyle(
                              fontSize: 12,
                              color: _signalColor(signal),
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Firmware
            _infoCard(
              context,
              children: [
                _kv('Firmware Version', firmware.isEmpty ? '—' : firmware,
                    isBoldValue: true),
              ],
            ),

            const Spacer(),

            // Wi‑Fi Configuration button
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => _showWifiConfigPrompt(context),
              child: const Text(
                'Wi‑Fi Configuration',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context, {required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            children.expand((w) => [w, const SizedBox(height: 8)]).toList()
              ..removeLast(),
      ),
    );
  }

  Widget _kv(String k, String v,
      {bool isBoldValue = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(k + (k.endsWith(':') ? '' : ':'),
            style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                fontWeight: FontWeight.w600)),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? Colors.black,
              fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Color _signalColor(double s) {
    if (s <= 20) return Colors.red;
    if (s <= 60) return Colors.orange;
    return Colors.green;
  }

  Widget _signalDots(double s) {
    final level = (s / 20).clamp(0, 5).floor();
    return Row(
      children: List.generate(5, (i) {
        final active = i < level;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.5),
          child: Icon(
            Icons.circle,
            size: 10,
            color: active ? _signalColor(s) : Colors.grey.withOpacity(0.3),
          ),
        );
      }),
    );
  }

  void _showWifiConfigPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Wi‑Fi Configuration',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '1) Connect your phone to the Wi‑Fi whose SSID matches the module PN.\n'
                '2) Open Wi‑Fi Module network page to set STA Wi‑Fi and restart.\n',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await AppSettings.openAppSettings(asAnotherTask: true);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.black12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Open Wi‑Fi Settings',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const WifiModuleWebView()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Open Network Page',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
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
