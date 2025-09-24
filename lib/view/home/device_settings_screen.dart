import 'package:flutter/material.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'package:crown_micro_solar/presentation/viewmodels/device_view_model.dart';
import 'package:crown_micro_solar/core/di/service_locator.dart';

class DeviceSettingsScreen extends StatefulWidget {
  final Device device;
  const DeviceSettingsScreen({super.key, required this.device});

  @override
  State<DeviceSettingsScreen> createState() => _DeviceSettingsScreenState();
}

class _DeviceSettingsScreenState extends State<DeviceSettingsScreen> {
  List<Map<String, dynamic>> _fields = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Use service locator to avoid Provider scope issues
      final vm = getIt<DeviceViewModel>();
      final dat = await vm.fetchDeviceControlFields(
        sn: widget.device.sn,
        pn: widget.device.pn,
        devcode: widget.device.devcode,
        devaddr: widget.device.devaddr,
      );
      if (!mounted) return;
      setState(() {
        _fields = _parseFields(dat);
        _loading = false;
      });
      if (dat != null) {
        final rawFields = (dat['field'] as List?) ?? [];
        print('DeviceSettings: Loaded ${rawFields.length} fields');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Device Settings',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : _fields.isEmpty
                  ? const Center(child: Text('No settings available'))
                  : _buildCategoryList(),
    );
  }

  Widget _errorView() => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error: $_error',
                    style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );

  List<Map<String, dynamic>> _parseFields(Map<String, dynamic>? dat) {
    if (dat == null) return [];
    final list = (dat['field'] as List?)?.whereType<Map>().toList() ?? [];
    final res = <Map<String, dynamic>>[];
    for (final raw in list) {
      final f = Map<String, dynamic>.from(raw);
      f['__label'] = _fieldLabel(f);
      f['__displayVal'] = _currentDisplayValue(f);
      f['__category'] = _settingsCategory(f);
      res.add(f);
    }
    return res;
  }

  // Determine high-level category card
  String _settingsCategory(Map f) {
    final n = (f['__label']?.toString() ?? '').toLowerCase();
    if (n.contains('battery')) return 'Battery Settings';
    if (n.contains('system') ||
        n.contains('fault') ||
        n.contains('restore') ||
        n.contains('default') ||
        n.contains('factory')) {
      return 'System Settings';
    }
    if (n.contains('time') || n.contains('charge') || n.contains('discharge'))
      return 'Basic Settings';
    if (n.contains('voltage') ||
        n.contains('capacity') ||
        n.contains('frequency') ||
        n.contains('current') ||
        n.contains('range') ||
        n.contains('work mode') ||
        n.contains('eco')) {
      return 'Standard Settings';
    }
    return 'Other Settings';
  }

  Widget _buildCategoryList() {
    const order = [
      'Battery Settings',
      'System Settings',
      'Basic Settings',
      'Standard Settings',
      'Other Settings'
    ];
    final byCat = <String, List<Map<String, dynamic>>>{};
    for (final o in order) {
      byCat[o] = [];
    }
    for (final f in _fields) {
      byCat[f['__category']]?.add(f);
    }
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        for (final cat in order)
          if ((byCat[cat] ?? []).isNotEmpty)
            _CategoryCard(
              title: cat,
              count: byCat[cat]!.length,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => _CategoryDetailScreen(
                    device: widget.device,
                    title: cat,
                    fields: byCat[cat]!,
                    reloadParent: _load,
                  ),
                ));
              },
            ),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  final Map<String, dynamic> field;
  final VoidCallback onChanged;
  const _SettingTile({required this.field, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final name = field['__label']?.toString() ?? '—';
    final current = field['__displayVal']?.toString() ?? '';
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
        } else if (hasRange || current.isNotEmpty) {
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    isBoolean
                        ? (boolValue! ? 'On' : 'Off')
                        : (current.isEmpty ? 'Tap to edit' : current),
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (isBoolean)
              Switch(
                value: boolValue!,
                onChanged: (v) async => await _toggleBoolean(context, field, v),
              )
            else
              const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  Future<void> _showOptions(BuildContext context) async {
    final name = field['__label']?.toString() ?? '';
    // Determine current raw value using multiple possible field keys
    String? currentVal = _extractCurrentRawValue(field);
    print('DeviceSettings: open "$name" rawCurrent=$currentVal rawFieldKeys='
        '${[
      'val',
      'value',
      'current',
      'cur',
      'curVal',
      'curval',
      'set',
      'now'
    ].map((k) => field[k]).toList()}');
    // If no current value locally, attempt a direct single-field query (old app parity)
    if (currentVal == null || currentVal.isEmpty) {
      final rootState =
          context.findAncestorStateOfType<_DeviceSettingsScreenState>();
      if (rootState != null) {
        final device = rootState.widget.device;
        final vm = getIt<DeviceViewModel>();
        final fieldId = field['id']?.toString() ?? field['name']?.toString();
        if (fieldId != null && fieldId.isNotEmpty) {
          try {
            final fetched = await vm.fetchSingleControlValue(
              sn: device.sn,
              pn: device.pn,
              devcode: device.devcode,
              devaddr: device.devaddr,
              fieldId: fieldId,
            );
            if (fetched != null && fetched.isNotEmpty) {
              currentVal = fetched;
              print(
                  'DeviceSettings: fetched remote current value for "$name" id=$fieldId -> $currentVal');
            }
          } catch (e) {
            print(
                'DeviceSettings: single value fetch failed for $fieldId : $e');
          }
        }
      }
    }
    final rawItems = (field['item'] as List?)?.whereType<Map>().toList() ?? [];
    var items = rawItems.map((e) {
      final keyTxt = e['key']?.toString();
      final alt = e['name']?.toString();
      final val = e['val'];
      String text = '';
      if (alt != null && alt.isNotEmpty) {
        text = alt;
      } else if (keyTxt != null && keyTxt.isNotEmpty) {
        text = keyTxt;
      } else if (val != null) {
        text = val.toString();
      }
      text = _normalizeOptionLabel(text,
          fieldName: name, rawValue: val?.toString());
      return {'text': text, 'val': val};
    }).toList();
    // Battery Type: remove any option that has no proper name (pure numeric or previous custom/vendor placeholder)
    final lname = name.toLowerCase();
    if (lname.contains('battery') && lname.contains('type')) {
      final before = items.length;
      final filtered = items.where((it) {
        final txt = (it['text'] ?? '').toString().trim();
        if (txt.isEmpty) return false; // drop empties
        if (RegExp(r'^(custom \d+|vendor \d+|\d+)$', caseSensitive: false)
            .hasMatch(txt)) {
          return false; // remove plain numeric or placeholder labels
        }
        return true;
      }).toList();
      if (filtered.isNotEmpty) {
        items = filtered;
        print(
            'DeviceSettings: filtered battery type options $before -> ${items.length}');
      }
      if (currentVal != null &&
          !items.any((e) => e['val']?.toString() == currentVal)) {
        items.insert(0, {'text': 'Current', 'val': currentVal});
        print(
            'DeviceSettings: inserted placeholder for current battery type value=$currentVal (not found among options)');
      }
    }
    // Sort percent-like options ascending for capacity / cut-off lists
    if (lname.contains('capacity') ||
        lname.contains('cut off') ||
        lname.contains('turn off')) {
      final allPercent = items.isNotEmpty &&
          items.every((e) => (e['text'] ?? '').toString().trim().endsWith('%'));
      if (allPercent) {
        items.sort((a, b) {
          final ax =
              int.tryParse((a['text'] as String).replaceAll('%', '').trim()) ??
                  0;
          final bx =
              int.tryParse((b['text'] as String).replaceAll('%', '').trim()) ??
                  0;
          return ax.compareTo(bx);
        });
      }
    }
    print(
        'DeviceSettings: options for "$name" -> count=${items.length} values=' +
            items.map((e) => '${e['val']}=>${e['text']}').join(', '));
    if (items.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('No options available')));
      return;
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
              currentVal ??= _extractCurrentRawValue(field);
              return SafeArea(
                top: false,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(2))),
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
                          final isSel = currentVal == optValStr;
                          return InkWell(
                            onTap: () => Navigator.pop(context, opt['val']),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: optValStr ?? '',
                                    groupValue: currentVal,
                                    onChanged: (_) =>
                                        Navigator.pop(context, opt['val']),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                      child: Text(opt['text']?.toString() ?? '',
                                          style: TextStyle(
                                              fontWeight: isSel
                                                  ? FontWeight.w600
                                                  : FontWeight.w400))),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            });
      },
    );
    if (selected != null) await _writeValue(context, selected.toString());
  }

  Future<void> _showNumberEditor(BuildContext context) async {
    final name = field['name']?.toString() ?? '';
    final ctrl = TextEditingController(text: field['val']?.toString() ?? '');
    final min = field['min'];
    final max = field['max'];
    final entered = await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(name),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: min != null || max != null
                ? 'Value (${min ?? '-'} ~ ${max ?? '-'})'
                : 'Value',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, ctrl.text);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
    if (entered != null && (entered as String).isNotEmpty) {
      await _writeValue(context, entered);
    }
  }

  Future<void> _writeValue(BuildContext context, String value) async {
    // Need device context; climb to inherited widget and ask ViewModel
    final vm = getIt<DeviceViewModel>();
    // To call set, we need pn/sn/devcode/devaddr; they are not in field, so get from arguments:
    // The settings screen holds Device in its widget; access via ModalRoute.of(context) is brittle.
    // Instead, pass a callback via InheritedWidget in a next refactor. For now, try Owner widget.
    final element =
        context.findAncestorStateOfType<_DeviceSettingsScreenState>();
    if (element == null) return;
    final device = element.widget.device;
    final id = field['id']?.toString() ?? field['name']?.toString() ?? '';
    if (id.isEmpty) return;
    final res = await vm.setDeviceControlField(
      sn: device.sn,
      pn: device.pn,
      devcode: device.devcode,
      devaddr: device.devaddr,
      fieldId: id,
      value: value,
    );
    if (!element.mounted) return;
    if (res['err'] == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
      print('DeviceSettings: write success field=$id value=$value');
      await element._load();
      onChanged();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: ${res['desc'] ?? 'Unknown error'}')),
      );
      print(
          'DeviceSettings: write FAILED field=$id value=$value error=${res['desc']}');
    }
  }

  bool _looksBoolean(List<Map> options) {
    final texts = options
        .map((o) => (o['key'] ?? o['name'] ?? '').toString().toLowerCase())
        .toList();
    final values = options.map((o) => o['val']?.toString()).toSet();
    if (values.length == 2 && values.contains('0') && values.contains('1'))
      return true;
    if (texts.any((t) => t.contains('on')) &&
        texts.any((t) => t.contains('off'))) return true;
    return false;
  }

  bool _currentBoolValue(Map field, List<Map> options) {
    final v = field['val']?.toString();
    if (v == '1') return true;
    if (v == '0') return false;
    // fallback: first option false, second true
    if (options.length == 2) {
      return options.indexWhere((o) => o['val']?.toString() == v) == 1;
    }
    return false;
  }

  Future<void> _toggleBoolean(
      BuildContext context, Map field, bool newVal) async {
    final newValue = newVal ? '1' : '0';
    await _writeValue(context, newValue);
  }
}

// Extract current raw value from field using multiple possible keys
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

// Helper to extract a human readable label
String _fieldLabel(Map f) {
  for (final k in ['name', 'par', 'title', 'label', 'desc']) {
    final v = f[k];
    if (v != null) {
      final s = v.toString().trim();
      if (s.isNotEmpty && s.toLowerCase() != 'null') return _beautifyLabel(s);
    }
  }
  // Secondary fallbacks: id, key
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
  // Replace underscores / dashes with spaces
  s = s.replaceAll(RegExp(r'[._-]+'), ' ');
  // Collapse multiple spaces
  s = s.replaceAll(RegExp(r'\s{2,}'), ' ');
  // Capitalize words
  s = s.split(' ').map((w) {
    if (w.isEmpty) return w;
    if (w.toUpperCase() == w && w.length > 1) return w; // keep acronyms
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
  return s;
}

// Compute current display string (for enumerations prefer option textual key)
String _currentDisplayValue(Map f) {
  final val = f['val'];
  if (val == null) return '';
  if (f['item'] is List) {
    for (final opt in (f['item'] as List).whereType<Map>()) {
      if (opt['val']?.toString() == val.toString()) {
        final keyTxt = opt['key']?.toString();
        final alt = opt['name']?.toString();
        String chosen = '';
        if (alt != null && alt.isNotEmpty) {
          chosen = alt;
        } else if (keyTxt != null && keyTxt.isNotEmpty) {
          chosen = keyTxt;
        } else {
          chosen = val.toString();
        }
        return _normalizeOptionLabel(chosen,
            fieldName: f['__label']?.toString(), rawValue: val.toString());
      }
    }
  }
  return val.toString();
}

// --- Option label normalization helpers ---
String _normalizeOptionLabel(String text,
    {String? fieldName, String? rawValue}) {
  String t = text.trim();
  if (t.isEmpty) return t;
  final lowerField = (fieldName ?? '').toLowerCase();

  // Pattern: "48 (AGM)" -> AGM
  final reParen = RegExp(r'^(\d+)\s*\(([^)]+)\)$');
  final mParen = reParen.firstMatch(t);
  if (mParen != null) {
    final inside = mParen.group(2)!.trim();
    if (_looksMeaningful(inside)) t = inside; // drop numeric code
  }

  // Pattern: leading digits + separator + label: "48 AGM", "48-AGM", "48: AGM"
  final reLead = RegExp(r'^(\d{1,4})[\s:._-]+(.+)$');
  final mLead = reLead.firstMatch(t);
  if (mLead != null) {
    final rest = mLead.group(2)!.trim();
    if (_looksMeaningful(rest)) t = rest;
  }

  // Pattern: label followed by numeric code in parentheses e.g. "AGM (48)"
  final reTrailParen = RegExp(r'^(.+?)\s*\((\d{1,4})\)$');
  final mTrailParen = reTrailParen.firstMatch(t);
  if (mTrailParen != null) {
    final head = mTrailParen.group(1)!.trim();
    if (_looksMeaningful(head)) t = head;
  }

  // Pattern: numeric code appended after dash or space: "AGM - 48" or "AGM 48"
  final reTrailNum = RegExp(r'^(.+?)[\s:._-]+(\d{1,4})$');
  final mTrailNum = reTrailNum.firstMatch(t);
  if (mTrailNum != null) {
    final head = mTrailNum.group(1)!.trim();
    if (_looksMeaningful(head)) t = head;
  }

  // If still purely numeric and we have known mapping (e.g., Battery Type), map it.
  // Purely numeric OR classic 0/1 codes? Attempt mapping via known enums for this field.
  if (RegExp(r'^\d+$').hasMatch(t)) {
    final map = _knownEnumMapForField(lowerField);
    if (map.isNotEmpty) {
      final mapped = map[t] ?? map[rawValue ?? ''];
      if (mapped != null) t = mapped;
    } else {
      if (t == '0')
        t = 'Off';
      else if (t == '1') t = 'On';
    }
  }

  // Strip enclosing parentheses if leftover
  if (t.startsWith('(') && t.endsWith(')')) {
    final inner = t.substring(1, t.length - 1).trim();
    if (_looksMeaningful(inner)) t = inner;
  }

  // Special formatting: pure 2-3 digit numbers that plausibly represent percent (e.g. 35, 035, 100)
  if (RegExp(r'^0?\d{2,3}$').hasMatch(t)) {
    final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
    final intVal = int.tryParse(digits);
    if (intVal != null && intVal <= 100) {
      // Avoid converting known enum code numbers (e.g. 48,49 battery type) by checking field context
      final isBatteryType =
          lowerField.contains('battery') && lowerField.contains('type');
      if (!isBatteryType) {
        t = '$intVal%';
      }
    }
  }

  return t;
}

bool _looksMeaningful(String s) =>
    s.isNotEmpty && RegExp(r'[A-Za-z]').hasMatch(s);

Map<String, String> _knownEnumMapForField(String fieldNameLower) {
  // Battery Type
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
  // Work / Operation Mode
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
  // Charge Priority / Charge Mode
  if (fieldNameLower.contains('charge') && fieldNameLower.contains('mode')) {
    return const {
      '0': 'PV & Grid',
      '1': 'PV Only',
      '2': 'Grid First',
      '3': 'PV First',
    };
  }
  // Output / Load Priority
  if (fieldNameLower.contains('output priority') ||
      fieldNameLower.contains('load priority')) {
    return const {
      '0': 'Load First',
      '1': 'Battery First',
      '2': 'Grid First',
    };
  }
  // Grid Mode / Grid Priority
  if (fieldNameLower.contains('grid mode') ||
      fieldNameLower.contains('grid priority')) {
    return const {
      '0': 'Grid',
      '1': 'Off-Grid',
      '2': 'Hybrid',
    };
  }
  // Eco Mode
  if (fieldNameLower.contains('eco')) {
    return const {
      '0': 'Disabled',
      '1': 'Enabled',
    };
  }
  // UPS Mode
  if (fieldNameLower.contains('ups')) {
    return const {
      '0': 'Normal',
      '1': 'UPS',
    };
  }
  // Generic enable/disable fields
  if (fieldNameLower.contains('enable') || fieldNameLower.contains('switch')) {
    return const {
      '0': 'Disabled',
      '1': 'Enabled',
      '48': 'Disabled', // alternate numeric codes observed
      '49': 'Enabled',
      '67': 'Disabled',
      '68': 'Enabled',
    };
  }
  return const {};
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onTap;
  const _CategoryCard(
      {required this.title, required this.count, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              Text('$count', style: const TextStyle(color: Colors.black54)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDetailScreen extends StatefulWidget {
  final Device device;
  final String title;
  final List<Map<String, dynamic>> fields;
  final Future<void> Function() reloadParent;
  const _CategoryDetailScreen(
      {required this.device,
      required this.title,
      required this.fields,
      required this.reloadParent});
  @override
  State<_CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<_CategoryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final tiles = widget.fields
        .map((f) => _SettingTile(
            field: f,
            onChanged: () async {
              await widget.reloadParent();
              setState(() {});
            }))
        .toList();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        title: Text(widget.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        itemBuilder: (_, i) => tiles[i],
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: tiles.length,
      ),
    );
  }
}
