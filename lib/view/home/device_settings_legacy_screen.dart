import 'package:flutter/material.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/device_view_model.dart';
import 'package:crown_micro_solar/core/di/service_locator.dart';

// Legacy-style device settings list (mirrors old app DataControl logic)
class DeviceSettingsLegacyScreen extends StatefulWidget {
  final Device device;
  const DeviceSettingsLegacyScreen({super.key, required this.device});

  @override
  State<DeviceSettingsLegacyScreen> createState() =>
      _DeviceSettingsLegacyScreenState();
}

class _DeviceSettingsLegacyScreenState
    extends State<DeviceSettingsLegacyScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _fields = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final vm = getIt<DeviceViewModel>();
      final dat = await vm.fetchDeviceControlFields(
        sn: widget.device.sn,
        pn: widget.device.pn,
        devcode: widget.device.devcode,
        devaddr: widget.device.devaddr,
      );
      if (dat == null) throw Exception('No data');
      final list = (dat['field'] as List?)?.whereType<Map>().toList() ?? [];
      _fields = list.map((f) => Map<String, dynamic>.from(f)).toList();
      // Basic ordering: by name/id
      _fields.sort((a, b) =>
          (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));
      print('LegacySettings: loaded ${_fields.length} fields');
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Settings'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _err()
              : _fields.isEmpty
                  ? const Center(child: Text('No fields'))
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _fields.length,
                        itemBuilder: (c, i) {
                          final f = _fields[i];
                          final name = f['name']?.toString() ??
                              f['id']?.toString() ??
                              'Field';
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: const Icon(Icons.tune),
                              title: Text(name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                await Navigator.of(context)
                                    .push(MaterialPageRoute(
                                  builder: (_) => _LegacyFieldDetailScreen(
                                      device: widget.device, field: f),
                                ));
                                await _fetch();
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _err() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _fetch, child: const Text('Retry'))
          ],
        ),
      );
}

class _LegacyFieldDetailScreen extends StatefulWidget {
  final Device device;
  final Map<String, dynamic> field;
  const _LegacyFieldDetailScreen({required this.device, required this.field});
  @override
  State<_LegacyFieldDetailScreen> createState() =>
      _LegacyFieldDetailScreenState();
}

class _LegacyFieldDetailScreenState extends State<_LegacyFieldDetailScreen> {
  bool _loading = true;
  String? _error;
  String? _currentVal; // remote fetched current value
  String? _selectedVal; // user selected (key or entered)
  late final DeviceViewModel _vm;
  late final List<Map<String, dynamic>> _options;
  final TextEditingController _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm = getIt<DeviceViewModel>();
    _options =
        ((widget.field['item'] as List?)?.whereType<Map>().toList() ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id =
          widget.field['id']?.toString() ?? widget.field['name']?.toString();
      if (id == null || id.isEmpty) throw Exception('Missing field id');
      final fetched = await _vm.fetchSingleControlValue(
        sn: widget.device.sn,
        pn: widget.device.pn,
        devcode: widget.device.devcode,
        devaddr: widget.device.devaddr,
        fieldId: id,
      );
      _currentVal = fetched;
      _selectedVal = fetched;
      _textCtrl.text = fetched ?? '';
      print('LegacyField: fetched id=$id currentVal=$_currentVal');
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.field['name']?.toString() ??
        widget.field['id']?.toString() ??
        'Field';
    final unit = widget.field['unit']?.toString();
    final hint = widget.field['hint']?.toString();
    final hasOptions = _options.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        actions: [
          TextButton(
            onPressed: (_selectedVal == null || _selectedVal!.isEmpty) &&
                    !hasOptions &&
                    _textCtrl.text.isEmpty
                ? null
                : _save,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _err()
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('Current: ',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        Expanded(
                            child: Text(_currentVal ?? '-',
                                style: const TextStyle(color: Colors.black87))),
                        if (unit != null && unit.isNotEmpty)
                          Text('  $unit',
                              style: const TextStyle(color: Colors.black54))
                      ]),
                      const SizedBox(height: 12),
                      if (hasOptions)
                        Expanded(
                          child: ListView.builder(
                            itemCount: _options.length,
                            itemBuilder: (c, i) {
                              final o = _options[i];
                              final keyTxt = o['key']?.toString();
                              final alt = o['name']?.toString();
                              final rawVal = o['val']?.toString();
                              final display = _optionLabel(keyTxt, alt, rawVal);
                              final writeVal =
                                  keyTxt?.isNotEmpty == true ? keyTxt : rawVal;
                              return RadioListTile<String>(
                                value: writeVal ?? '',
                                groupValue: _selectedVal,
                                onChanged: (v) {
                                  setState(() => _selectedVal = v);
                                },
                                title: Text(display),
                                dense: true,
                              );
                            },
                          ),
                        )
                      else ...[
                        if (hint != null && hint.isNotEmpty)
                          Text('Example: $hint',
                              style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _textCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Enter Value',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            setState(() => _selectedVal = v);
                          },
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed:
                              _selectedVal == null || _selectedVal!.isEmpty
                                  ? null
                                  : _save,
                          child: const Text('Save'),
                        ),
                      ]
                    ],
                  ),
                ),
    );
  }

  String _optionLabel(String? key, String? name, String? val) {
    for (final s in [name, key, val]) {
      if (s != null && s.trim().isNotEmpty && s.toLowerCase() != 'null')
        return s.trim();
    }
    return 'Option';
  }

  Future<void> _save() async {
    final id =
        widget.field['id']?.toString() ?? widget.field['name']?.toString();
    if (id == null || id.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Missing field id')));
      return;
    }
    final valueToSend = _selectedVal ?? _textCtrl.text.trim();
    if (valueToSend.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No value')));
      return;
    }
    setState(() => _loading = true);
    final res = await _vm.setDeviceControlField(
      sn: widget.device.sn,
      pn: widget.device.pn,
      devcode: widget.device.devcode,
      devaddr: widget.device.devaddr,
      fieldId: id,
      value: valueToSend,
    );
    setState(() => _loading = false);
    if (res['err'] == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Updated')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${res['desc'] ?? 'error'}')));
    }
  }

  Widget _err() => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Error: $_error', style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _init, child: const Text('Retry'))
      ]));
}
