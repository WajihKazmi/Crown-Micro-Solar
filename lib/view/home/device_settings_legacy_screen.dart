import 'package:flutter/material.dart';
import 'dart:async';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:crown_micro_solar/legacy/device_ctrl_fields_model.dart';

// Figma-styled legacy settings screen with 5 tab categories, using legacy APIs
class DeviceSettingsLegacyScreen extends StatefulWidget {
  final Device device;
  const DeviceSettingsLegacyScreen({super.key, required this.device});

  @override
  State<DeviceSettingsLegacyScreen> createState() => _LegacyTabbedState();
}

class _LegacyTabbedState extends State<DeviceSettingsLegacyScreen> {
  bool _loading = true;
  String? _errorText;
  List<Map<String, dynamic>> _fields = [];
  // Cache fetched current values by field id for quick lookup
  final Map<String, String> _valueCache = <String, String>{};

  static const List<String> _tabsOrder = <String>[
    'Battery Settings',
    'System Settings',
    'Basic Settings',
    'Standard Settings',
    'Other Settings',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Map<String, List<Map<String, dynamic>>> _groupByCategory() {
    final map = {for (final t in _tabsOrder) t: <Map<String, dynamic>>[]};
    for (final f in _fields) {
      final cat = (f['__category'] as String?) ?? 'Other Settings';
      (map[cat] ?? map['Other Settings']!).add(f);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final byCat = _groupByCategory();
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back)),
          title: const Text('Device Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_errorText != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back)),
          title: const Text('Device Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          actions: [
            IconButton(
              tooltip: 'Refresh Values',
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  _refreshMissingValues(forceAll: true, concurrency: 48),
            )
          ],
        ),
        body: _errorView(_errorText!),
      );
    }
    final categories = _tabsOrder
        .where((t) => (byCat[t] ?? const <Map<String, dynamic>>[]).isNotEmpty)
        .toList(growable: false);
    if (categories.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back)),
          title: const Text('Device Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        ),
        body: const Center(child: Text('No settings available')),
      );
    }
    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back)),
          title: const Text('Device Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          actions: [
            IconButton(
              tooltip: 'Refresh Values',
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  _refreshMissingValues(forceAll: true, concurrency: 48),
            )
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [for (final c in categories) Tab(text: c)],
          ),
        ),
        body: TabBarView(
          children: [for (final c in categories) _buildCategoryList(byCat[c]!)],
        ),
      ),
    );
  }

  Widget _errorView(String message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );

  Widget _buildCategoryList(List<Map<String, dynamic>> fields) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: fields.length,
      itemBuilder: (_, i) => Column(
        children: [
          _LegacySettingTile(
            device: widget.device,
            field: fields[i],
            onChanged: _load,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // After initial load, refresh current values (concurrently) for fields missing a value.
  // Use a higher concurrency to converge quickly.
  Future<void> _refreshMissingValues(
      {bool forceAll = false, int concurrency = 24}) async {
    if (!mounted) return;
    // Collect ids to refresh
    final List<Map<String, dynamic>> toRefresh = [];
    for (final f in _fields) {
      final id = (f['id'] ?? f['name'])?.toString() ?? '';
      if (id.isEmpty) continue;
      final raw = _extractCurrentRawValue(f);
      if (forceAll ||
          raw == null ||
          raw.isEmpty ||
          raw.toLowerCase() == 'null') {
        toRefresh.add(f);
      }
    }
    if (toRefresh.isEmpty) return;
    // Concurrency-limited parallel fetch
    int idx = 0;
    final int limit = concurrency.clamp(1, 64);
    Future<void> worker() async {
      while (true) {
        if (idx >= toRefresh.length) break;
        final int myIndex = idx++;
        if (myIndex >= toRefresh.length) break;
        final f = toRefresh[myIndex];
        final id = (f['id'] ?? f['name'])?.toString() ?? '';
        if (id.isEmpty) continue;
        try {
          final resp = await DevicecTRLvalueQuery(context,
                  PN: widget.device.pn,
                  SN: widget.device.sn,
                  devaddr: widget.device.devaddr.toString(),
                  devcode: widget.device.devcode.toString(),
                  id: id)
              .timeout(const Duration(seconds: 4));
          if ((resp['err'] ?? 1) == 0) {
            final val = resp['dat']?['val']?.toString();
            if (val != null) {
              _valueCache[id] = val;
              f['val'] = val;
              f['__displayVal'] = _currentDisplayValue(f);
            }
          }
        } on TimeoutException {
          // skip on timeout; leave value for next manual refresh
        } catch (_) {}
      }
    }

    final List<Future<void>> workers = List.generate(limit, (_) => worker());
    await Future.wait(workers);
    if (!mounted) return;
    setState(() {});
  }

  // Called after loading the fields list
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorText = null;
    });
    try {
      final data = await DeviceCtrlFieldseModelQuery(context,
          SN: widget.device.sn,
          PN: widget.device.pn,
          devcode: widget.device.devcode.toString(),
          devaddr: widget.device.devaddr.toString());
      final err = data['err'];
      if (err != 0) {
        String msg = 'Failed to load';
        switch (err) {
          case 1:
            msg = 'Failed (no device protocol)';
            break;
          case 6:
            msg = 'Parameter error';
            break;
          case 12:
            msg = 'No record found';
            break;
          case 257:
            msg = 'Collector not found';
            break;
          case 258:
            msg = 'Device not found';
            break;
          case 260:
            msg = 'Power station not found';
            break;
          case 404:
          default:
            msg = 'No response from server';
        }
        setState(() {
          _loading = false;
          _errorText = msg;
        });
        return;
      }
      final model = DeviceCtrlFieldseModel.fromJson(data);
      final fields = model.dat?.field ?? <Field>[];
      final mapped = fields.map<Map<String, dynamic>>((f) {
        final items = (f.item ?? <Item>[])
            .map((e) => {'key': e.key, 'val': e.val})
            .toList();
        final m = <String, dynamic>{
          'id': f.id ?? '',
          'name': f.name ?? '',
          'unit': f.unit,
          'hint': f.hint,
          'item': items,
        };
        m['__label'] = _fieldLabel(m);
        m['__displayVal'] = _currentDisplayValue(m);
        m['__category'] = _settingsCategory(m);
        return m;
      }).toList();
      // Set fields first so refresh can populate them, keep spinner until values converge
      setState(() {
        _fields = mapped;
      });
      // Aggressively refresh all values concurrently before showing the screen
      await _refreshMissingValues(forceAll: true, concurrency: 48);
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _errorText = e.toString();
      });
    }
  }
}

// (Old _CategoryList removed; now using a single categorized ListView)

class _LegacySettingTile extends StatefulWidget {
  final Device device;
  final Map<String, dynamic> field;
  final Future<void> Function() onChanged;
  const _LegacySettingTile(
      {required this.device, required this.field, required this.onChanged});

  @override
  State<_LegacySettingTile> createState() => _LegacySettingTileState();
}

class _LegacySettingTileState extends State<_LegacySettingTile> {
  late Map<String, dynamic> field;
  String _currentDisplay = '';

  @override
  void initState() {
    super.initState();
    field = Map<String, dynamic>.from(widget.field);
    _currentDisplay = field['__displayVal']?.toString() ?? '';
    // Avoid per-tile auto fetch to keep initial screen fast; parent triggers a batched refresh.
    // _ensureFreshCurrentValue();
  }

  // Per-tile current value fetch removed; parent handles batched refresh.

  @override
  Widget build(BuildContext context) {
    // Sync with latest parent-provided field map on rebuild
    field = widget.field;
    _currentDisplay = field['__displayVal']?.toString() ?? _currentDisplay;
    final name = field['__label']?.toString() ?? '—';
    final options = (field['item'] as List?)?.whereType<Map>().toList() ?? [];
    final hasOptions = options.isNotEmpty;
    final hasRange = field['min'] != null || field['max'] != null;
    final isBoolean =
        hasOptions && options.length == 2 && _looksBoolean(options);
    final boolValue = isBoolean ? _currentBoolValue(field, options) : null;

    return InkWell(
      onTap: () async {
        if (isBoolean) {
          await _toggleBoolean(context, field, !boolValue!);
        } else if (hasOptions) {
          await _showOptions(context);
        } else if (hasRange || _currentDisplay.isNotEmpty) {
          await _showNumberEditor(context);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (isBoolean)
              Switch(
                value: boolValue!,
                onChanged: (v) async => await _toggleBoolean(context, field, v),
              )
            else ...[
              if (_currentDisplay.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text(_currentDisplay,
                      style: const TextStyle(color: Colors.black54)),
                ),
              const Icon(Icons.chevron_right),
            ]
          ],
        ),
      ),
    );
  }

  Future<void> _showOptions(BuildContext context) async {
    final name = field['__label']?.toString() ?? '';
    String? currentVal = _extractCurrentRawValue(field);
    // If empty, fetch directly
    if (currentVal == null || currentVal.isEmpty) {
      final id = (field['id'] ?? field['name'])?.toString() ?? '';
      if (id.isNotEmpty) {
        try {
          final resp = await DevicecTRLvalueQuery(context,
              PN: widget.device.pn,
              SN: widget.device.sn,
              devaddr: widget.device.devaddr.toString(),
              devcode: widget.device.devcode.toString(),
              id: id);
          if ((resp['err'] ?? 1) == 0) {
            currentVal = resp['dat']?['val']?.toString();
          }
        } catch (_) {}
      }
    }
    final rawItems = (field['item'] as List?)?.whereType<Map>().toList() ?? [];
    final unit = _inferUnitForField(field);
    List<Map<String, dynamic>> items = rawItems.map<Map<String, dynamic>>((e) {
      final keyTxt = e['key']?.toString();
      final val = e['val'];
      String text = keyTxt ?? val?.toString() ?? '';
      text = _normalizeOptionLabel(text,
          fieldName: name, rawValue: val?.toString(), unit: unit);
      // Always write the backend "val" code to the API (not the human label)
      final write = val?.toString() ?? '';
      return {
        'text': text,
        'val': val?.toString(),
        'key': keyTxt,
        'write': write
      };
    }).toList();
    // Deduplicate by text
    if (items.isNotEmpty) {
      final Map<String, Map<String, dynamic>> byText = {};
      for (final it in items) {
        final t = (it['text'] ?? '').toString();
        if (t.isEmpty) continue;
        if (!byText.containsKey(t)) {
          byText[t] = it;
        } else {
          final curStr = currentVal?.toString();
          if (curStr != null && it['val']?.toString() == curStr) {
            byText[t] = it;
          }
        }
      }
      items = byText.values.toList();
    }
    // Pre-select by value or normalized label
    String? groupVal = currentVal;
    if (groupVal == null ||
        !items.any((e) => (e['val']?.toString() ?? '') == groupVal)) {
      final normalized =
          _normalizeOptionLabel(currentVal ?? '', fieldName: name)
              .toLowerCase();
      for (final it in items) {
        final itLabel = (it['text'] ?? '').toString().toLowerCase();
        if (itLabel == normalized) {
          groupVal = it['val']?.toString();
          break;
        }
      }
    }
    final selected = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) {
        return DraggableScrollableSheet(
            expand: false,
            maxChildSize: 0.85,
            initialChildSize: 0.6,
            minChildSize: 0.4,
            builder: (context, scroll) {
              return SafeArea(
                top: false,
                child: Column(children: [
                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 12),
                  Text(name,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const Divider(height: 24),
                  Expanded(
                    child: ListView.builder(
                      controller: scroll,
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final opt = items[i];
                        final optValStr = opt['val']?.toString();
                        return InkWell(
                          onTap: () => Navigator.pop(
                              context, opt['val'] ?? opt['write']),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(children: [
                              Radio<String>(
                                value: optValStr ?? '',
                                groupValue: (groupVal ?? currentVal) ?? '',
                                onChanged: (_) => Navigator.pop(
                                    context, opt['val'] ?? opt['write']),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                  child: Text(opt['text']?.toString() ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500))),
                            ]),
                          ),
                        );
                      },
                    ),
                  )
                ]),
              );
            });
      },
    );
    if (selected != null) await _writeValue(context, selected.toString());
  }

  Future<void> _showNumberEditor(BuildContext context) async {
    final name =
        field['__label']?.toString() ?? field['name']?.toString() ?? '';
    final ctrl = TextEditingController(
        text: _extractCurrentRawValue(field) ?? field['val']?.toString() ?? '');
    final min = field['min'];
    final max = field['max'];
    final unit = _inferUnitForField(field);
    final entered = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: () {
              final range = (min != null || max != null)
                  ? ' (${min ?? '-'} ~ ${max ?? '-'})'
                  : '';
              final u = (unit != null && unit.isNotEmpty && unit != '%')
                  ? ' [$unit]'
                  : '';
              return 'Value$range$u';
            }(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            child: const Text('Save'),
          )
        ],
      ),
    );
    if (entered != null && (entered as String).isNotEmpty) {
      final raw = entered.trim();
      final numVal = double.tryParse(raw);
      if (numVal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid number')));
        return;
      }
      double finalVal = numVal;
      if (min != null) {
        final dmin = double.tryParse(min.toString());
        if (dmin != null && finalVal < dmin) finalVal = dmin;
      }
      if (max != null) {
        final dmax = double.tryParse(max.toString());
        if (dmax != null && finalVal > dmax) finalVal = dmax;
      }
      await _writeValue(context, finalVal.toString());
    }
  }

  Future<void> _writeValue(BuildContext context, String value) async {
    final id = (field['id'] ?? field['name'])?.toString() ?? '';
    if (id.isEmpty) return;
    final res = await UpdateDeviceFieldQuery(context,
        SN: widget.device.sn,
        PN: widget.device.pn,
        ID: id,
        Value: value,
        devcode: widget.device.devcode.toString(),
        devaddr: widget.device.devaddr.toString());
    if (!mounted) return;
    final err = res['err'];
    if (err == 0) {
      _showSmallSnack(context, success: true, message: 'Updated');
      try {
        field['val'] = value;
        field['__displayVal'] = _currentDisplayValue(field);
        setState(
            () => _currentDisplay = field['__displayVal'] ?? _currentDisplay);
      } catch (_) {}
      // Verify
      try {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        final vres = await DevicecTRLvalueQuery(context,
            PN: widget.device.pn,
            SN: widget.device.sn,
            devaddr: widget.device.devaddr.toString(),
            devcode: widget.device.devcode.toString(),
            id: id);
        if ((vres['err'] ?? 1) == 0) {
          final fresh = vres['dat']?['val']?.toString();
          if (fresh != null && fresh.isNotEmpty) {
            field['val'] = fresh;
            field['__displayVal'] = _currentDisplayValue(field);
            if (mounted)
              setState(() => _currentDisplay = field['__displayVal'] ?? '');
          }
        }
      } catch (_) {}
      await widget.onChanged();
    } else {
      String msg = res['desc']?.toString() ?? 'Unknown error';
      if (err == 263) msg = 'Collector offline';
      if (err == 3) msg = 'System exception';
      if (err == 1) msg = 'No device protocol';
      if (err == 6) msg = 'Parameter error';
      _showSmallSnack(context, success: false, message: msg);
    }
  }
}

// ---- Helpers: categories, labels, value normalization (ported from modern screen) ----
String _settingsCategory(Map f) {
  final label = (f['__label']?.toString() ?? '').toLowerCase();
  final name = (f['name']?.toString() ?? '').toLowerCase();
  final id = (f['id']?.toString() ?? '').toLowerCase();
  final text = ('$label $name $id').trim();
  bool hasAny(Iterable<String> keys) =>
      keys.any((k) => k.isNotEmpty && text.contains(k));
  const batteryKeys = [
    'battery',
    'batt',
    'bms',
    'soc',
    'capacity',
    'equal',
    'float',
    'bulk',
    'absorb',
    'charge current',
    'discharge current',
    'battery type',
    'cell',
    'pack',
    'soh'
  ];
  if (hasAny(batteryKeys)) return 'Battery Settings';
  const systemKeys = [
    'system',
    'language',
    'date',
    'time',
    'rtc',
    'address',
    'addr',
    'backlight',
    'lcd',
    'display',
    'buzzer',
    'alarm',
    'restore',
    'default',
    'factory',
    'password',
    'pwd',
    'comm',
    'modbus',
    'wifi',
    'network',
    'ethernet'
  ];
  if (hasAny(systemKeys)) return 'System Settings';
  const basicKeys = [
    'time',
    'start',
    'end',
    'schedule',
    'period',
    'window',
    'slot',
    'tou',
    'charge time',
    'discharge time',
    'grid charge time',
    'pv charge time',
    'min reserve',
    'reserve capacity'
  ];
  if (hasAny(basicKeys)) return 'Basic Settings';
  const standardKeys = [
    'voltage',
    'current',
    'frequency',
    'power',
    'range',
    'threshold',
    'cut off',
    'cutoff',
    'turn off',
    'turn-on',
    'turn on',
    'work mode',
    'operation mode',
    'run mode',
    'output mode',
    'grid mode',
    'priority',
    'eco',
    'ups',
    'ac input range',
    'pv only',
    'grid only'
  ];
  if (hasAny(standardKeys)) return 'Standard Settings';
  return 'Other Settings';
}

String? _extractCurrentRawValue(Map field) {
  for (final k in [
    'val',
    'value',
    'current',
    'cur',
    'curVal',
    'curval',
    'set',
    'now'
  ]) {
    final v = field[k];
    if (v != null &&
        v.toString().trim().isNotEmpty &&
        v.toString().toLowerCase() != 'null') {
      return v.toString();
    }
  }
  return null;
}

String _fieldLabel(Map f) {
  for (final k in ['name', 'par', 'title', 'label', 'desc']) {
    final v = f[k];
    if (v != null) {
      final s = v.toString().trim();
      if (s.isNotEmpty && s.toLowerCase() != 'null') return _beautifyLabel(s);
    }
  }
  for (final k in ['id', 'key']) {
    final v = f[k];
    if (v != null) {
      final s = v.toString().trim();
      if (s.isNotEmpty && s.toLowerCase() != 'null') return _beautifyLabel(s);
    }
  }
  return 'Setting';
}

String _beautifyLabel(String raw) {
  String s = raw.trim();
  if (s.isEmpty) return s;
  s = s.replaceAll(RegExp(r'[._-]+'), ' ');
  s = s.replaceAll(RegExp(r'\s{2,}'), ' ');
  s = s.split(' ').map((w) {
    if (w.isEmpty) return w;
    if (w.toUpperCase() == w && w.length > 1) return w;
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
  return s;
}

String _currentDisplayValue(Map f) {
  final raw = _extractCurrentRawValue(f) ?? f['val']?.toString();
  if (raw == null) return '';
  final unit = _inferUnitForField(f);
  if (f['item'] is List) {
    for (final opt in (f['item'] as List).whereType<Map>()) {
      if (opt['val']?.toString() == raw.toString()) {
        final keyTxt = opt['key']?.toString();
        final alt = opt['name']?.toString();
        String chosen = '';
        if (alt != null && alt.isNotEmpty) {
          chosen = alt;
        } else if (keyTxt != null && keyTxt.isNotEmpty) {
          chosen = keyTxt;
        } else {
          chosen = raw.toString();
        }
        return _normalizeOptionLabel(chosen,
            fieldName: f['__label']?.toString(),
            rawValue: raw.toString(),
            unit: unit);
      }
    }
  }
  return _normalizeOptionLabel(raw.toString(),
      fieldName: f['__label']?.toString(),
      rawValue: raw.toString(),
      unit: unit);
}

String _normalizeOptionLabel(String text,
    {String? fieldName, String? rawValue, String? unit}) {
  String t = text.trim();
  if (t.isEmpty) return t;
  final lowerField = (fieldName ?? '').toLowerCase();
  final reParen = RegExp(r'^(\d+)\s*\(([^)]+)\)$');
  final mParen = reParen.firstMatch(t);
  if (mParen != null) {
    final inside = mParen.group(2)!.trim();
    if (_looksMeaningful(inside)) t = inside;
  }
  final reLead = RegExp(r'^(\d{1,4})[\s:._-]+(.+)$');
  final mLead = reLead.firstMatch(t);
  if (mLead != null) {
    final rest = mLead.group(2)!.trim();
    if (_looksMeaningful(rest)) t = rest;
  }
  final reTrailParen = RegExp(r'^(.+?)\s*\((\d{1,4})\)$');
  final mTrailParen = reTrailParen.firstMatch(t);
  if (mTrailParen != null) {
    final head = mTrailParen.group(1)!.trim();
    if (_looksMeaningful(head)) t = head;
  }
  final reTrailNum = RegExp(r'^(.+?)[\s:._-]+(\d{1,4})$');
  final mTrailNum = reTrailNum.firstMatch(t);
  if (mTrailNum != null) {
    final head = mTrailNum.group(1)!.trim();
    if (_looksMeaningful(head)) t = head;
  }
  if (RegExp(r'^\d+$').hasMatch(t)) {
    final map = _knownEnumMapForField(lowerField);
    if (map.isNotEmpty) {
      final mapped = map[t] ?? map[rawValue ?? ''];
      if (mapped != null) t = mapped;
    } else {
      if (t == '0' || t == '48' || t == '68') {
        t = 'Off';
      } else if (t == '1' || t == '49' || t == '69') {
        t = 'On';
      }
    }
  }
  if (t.startsWith('(') && t.endsWith(')')) {
    final inner = t.substring(1, t.length - 1).trim();
    if (_looksMeaningful(inner)) t = inner;
  }
  if (unit != null && unit.trim() == '%') {
    final n = int.tryParse(t);
    if (n != null) return '$n%';
  }
  if (RegExp(r'^-?\d+(?:\.\d+)?$').hasMatch(t)) {
    final u = unit?.trim();
    if (u != null && u.isNotEmpty && u != '%') {
      const inlineUnits = {'V', 'A', 'Hz', 'W', 'kW', 'kWh', 'Wh'};
      if (inlineUnits.contains(u)) {
        return '$t $u';
      }
    }
  }
  return t;
}

bool _looksMeaningful(String s) =>
    s.isNotEmpty && RegExp(r'[A-Za-z]').hasMatch(s);

Map<String, String> _knownEnumMapForField(String fieldNameLower) {
  if (fieldNameLower.contains('battery') && fieldNameLower.contains('type')) {
    return const {
      '48': 'AGM',
      '49': 'Flooded',
      '50': 'User',
      '51': 'Pylon',
      '52': 'Dyness',
      '53': 'Weco',
      '54': 'Soltaro',
      '55': 'Lia',
      '56': 'Lithium',
      '57': 'Other',
    };
  }
  if (fieldNameLower.contains('equalization')) {
    return const {
      '48': 'Off',
      '49': 'On',
    };
  }
  if (fieldNameLower.contains('backlight') || fieldNameLower.contains('lcd')) {
    return const {
      '0': 'Disabled',
      '1': 'Enabled',
      '48': 'Disabled',
      '49': 'Enabled',
      '68': 'Disabled',
      '69': 'Enabled',
    };
  }
  if (fieldNameLower.contains('buzzer') || fieldNameLower.contains('alarm')) {
    return const {
      '0': 'Disabled',
      '1': 'Enabled',
      '48': 'Disabled',
      '49': 'Enabled',
      '68': 'Disabled',
      '69': 'Enabled',
    };
  }
  if (fieldNameLower.contains('work mode') ||
      fieldNameLower.contains('operation mode') ||
      fieldNameLower.contains('run mode')) {
    return const {
      '0': 'Self Use',
      '1': 'Feed-in First',
      '2': 'Backup',
      '3': 'Eco',
      '4': 'Peak Shaving',
    };
  }
  if (fieldNameLower.contains('charge') && fieldNameLower.contains('mode')) {
    return const {
      '0': 'PV & Grid',
      '1': 'PV Only',
      '2': 'Grid First',
      '3': 'PV First',
    };
  }
  if (fieldNameLower.contains('output priority') ||
      fieldNameLower.contains('load priority')) {
    return const {
      '0': 'Load First',
      '1': 'Battery First',
      '2': 'Grid First',
    };
  }
  if (fieldNameLower.contains('grid mode') ||
      fieldNameLower.contains('grid priority')) {
    return const {
      '0': 'Grid',
      '1': 'Off-Grid',
      '2': 'Hybrid',
    };
  }
  if (fieldNameLower.contains('eco')) {
    return const {
      '0': 'Disabled',
      '1': 'Enabled',
    };
  }
  if (fieldNameLower.contains('ups')) {
    return const {
      '0': 'Normal',
      '1': 'UPS',
    };
  }
  if (fieldNameLower.contains('enable') || fieldNameLower.contains('switch')) {
    return const {
      '0': 'Disabled',
      '1': 'Enabled',
      '48': 'Disabled',
      '49': 'Enabled',
      '68': 'Disabled',
      '69': 'Enabled',
    };
  }
  return const {};
}

String? _inferUnitForField(Map f) {
  final backendUnit = f['unit']?.toString();
  final u = backendUnit?.trim();
  final name =
      (f['__label']?.toString() ?? f['name']?.toString() ?? '').toLowerCase();
  if (u != null && u.isNotEmpty && u != '%') return u;
  if (name.contains('voltage') ||
      name.contains('volt') ||
      name.contains('vdc') ||
      name.contains('vac')) {
    return 'V';
  }
  if (name.contains('frequency') ||
      name.contains('freq') ||
      name.contains('hz')) return 'Hz';
  if (name.contains('current') || name.contains('amp')) return 'A';
  if (name.contains('power') || name.contains('watt')) return 'W';
  if (name.contains('energy') || name.contains('kwh') || name.contains('wh'))
    return 'kWh';
  if (name.contains('capacity') ||
      name.contains('soc') ||
      name.contains('percentage') ||
      name.contains('brightness')) {
    return '%';
  }
  final items = (f['item'] as List?)?.whereType<Map>().toList() ?? [];
  if (items.isNotEmpty) {
    final vals = items.map((e) => (e['val'] ?? '').toString()).toList();
    final nums = vals.map((v) => int.tryParse(v)).whereType<int>().toList();
    final allPct = nums.isNotEmpty && nums.every((n) => n >= 0 && n <= 100);
    if (allPct &&
        (name.contains('capacity') ||
            name.contains('soc') ||
            name.contains('brightness'))) {
      return '%';
    }
  }
  return u; // could be null or '%'
}

void _showSmallSnack(BuildContext context,
    {required bool success, required String message}) {
  final Color bg = success ? Colors.green.shade600 : Colors.red.shade600;
  final IconData icon = success ? Icons.check_circle : Icons.error;
  final String prefix = success ? 'Success' : 'Error';
  final String text = '$prefix: $message';
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Row(children: [
      Icon(icon, color: Colors.white, size: 18),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    ]),
    backgroundColor: bg,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    duration: const Duration(seconds: 2),
  ));
}

bool _looksBoolean(List<Map> options) {
  final texts = options
      .map((o) => (o['key'] ?? o['name'] ?? '').toString().toLowerCase())
      .toList();
  final values = options.map((o) => o['val']?.toString()).toSet();
  if (values.length == 2 && values.containsAll({'0', '1'})) return true;
  if (values.length == 2 && values.containsAll({'48', '49'})) return true;
  if (values.length == 2 && values.containsAll({'68', '69'})) return true;
  if (texts.any((t) => t.contains('on')) && texts.any((t) => t.contains('off')))
    return true;
  if (texts.any((t) => t.contains('enable')) &&
      texts.any((t) => t.contains('disable'))) return true;
  return false;
}

bool _currentBoolValue(Map field, List<Map> options) {
  final v = (_extractCurrentRawValue(field) ?? field['val']?.toString())
          ?.trim()
          .toLowerCase() ??
      '';
  if (v == '1' || v == '49' || v == '69') return true;
  if (v == '0' || v == '48' || v == '68') return false;
  final List<Map<String, dynamic>> opts =
      options.map((o) => Map<String, dynamic>.from(o)).toList();
  String labelForVal(String? val) {
    final Map<String, dynamic> match = opts.firstWhere(
        (o) => (o['val']?.toString() ?? '').toLowerCase() == (val ?? ''),
        orElse: () => <String, dynamic>{});
    final t = (match['key'] ?? match['name'] ?? '').toString().toLowerCase();
    return t;
  }

  final lbl = labelForVal(v);
  if (lbl.contains('on') || lbl.contains('enable') || lbl.contains('enabled')) {
    return true;
  }
  if (lbl.contains('off') ||
      lbl.contains('disable') ||
      lbl.contains('disabled')) {
    return false;
  }
  if (options.length == 2) {
    final idx = options.indexWhere((o) => o['val']?.toString() == v);
    return idx == 1;
  }
  return false;
}

Future<void> _toggleBoolean(
    BuildContext context, Map field, bool newVal) async {
  final List<Map<String, dynamic>> options =
      ((field['item'] as List?)?.whereType<Map>().toList() ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
  String resolveBoolVal(bool v) {
    // Prefer sending backend "val" codes for reliability
    if (options.length == 2) {
      Map<String, dynamic>? onOpt;
      Map<String, dynamic>? offOpt;
      for (final Map<String, dynamic> o in options) {
        final t = (o['key'] ?? o['name'] ?? '').toString().toLowerCase();
        if (t.contains('on') || t.contains('enable') || t.contains('enabled')) {
          onOpt ??= o;
        } else if (t.contains('off') ||
            t.contains('disable') ||
            t.contains('disabled')) {
          offOpt ??= o;
        }
      }
      if (onOpt != null && offOpt != null) {
        String codeFor(Map<String, dynamic> o) {
          final val = o['val']?.toString();
          final k = o['key']?.toString();
          return (val != null && val.isNotEmpty)
              ? val
              : ((k != null && k.isNotEmpty) ? k : '');
        }

        return v ? codeFor(onOpt) : codeFor(offOpt);
      }
      final vals = options.map((o) => o['val']?.toString()).toSet();
      bool hasAll(Set<String> s) => s.every(vals.contains);
      if (hasAll({'0', '1'})) return v ? '1' : '0';
      if (hasAll({'48', '49'})) return v ? '49' : '48';
      if (hasAll({'68', '69'})) return v ? '69' : '68';
      final chosen = v ? options[1] : options[0];
      final val = chosen['val']?.toString();
      final k = chosen['key']?.toString();
      return (val != null && val.isNotEmpty)
          ? val
          : ((k != null && k.isNotEmpty) ? k : '');
    }
    // Fallback for known enum-like fields
    final fieldLabel = (field['__label']?.toString() ?? '').toLowerCase();
    final enumMap = _knownEnumMapForField(fieldLabel);
    if (enumMap.isNotEmpty) {
      final Map<String, String> inv = {};
      enumMap.forEach((code, label) {
        inv[label.toLowerCase()] = code;
      });
      final onLabels = ['enabled', 'on'];
      final offLabels = ['disabled', 'off'];
      if (v) {
        for (final l in onLabels) {
          final code = inv[l];
          if (code != null) return code;
        }
      } else {
        for (final l in offLabels) {
          final code = inv[l];
          if (code != null) return code;
        }
      }
    }
    return v ? '1' : '0';
  }

  final newValue = resolveBoolVal(newVal);
  // Call the enclosing tile state's writer when available
  final state = context.findAncestorStateOfType<_LegacySettingTileState>();
  if (state != null) {
    await state._writeValue(context, newValue);
  }
}
