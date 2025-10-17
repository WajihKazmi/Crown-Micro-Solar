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
    // Build a searchable text from label + name + id for broader matching
    final label = (f['__label']?.toString() ?? '').toLowerCase();
    final name = (f['name']?.toString() ?? '').toLowerCase();
    final id = (f['id']?.toString() ?? '').toLowerCase();
    final text = ('$label $name $id').trim();

    bool hasAny(Iterable<String> keys) =>
        keys.any((k) => k.isNotEmpty && text.contains(k));

    // First, explicit mapping for Standard Settings requested items
    const standardExplicit = [
      // LCD Auto-return to Main Screen
      'lcd auto-return to main screen',
      'lcd auto return to main screen',
      'lcd auto-return',
      'lcd auto return',
      'auto return to main',
      'return to main screen',
      'auto home screen',
      'home screen auto return',
      'lcd return time',
      // Overload Auto Restart
      'overload auto restart',
      'overload restart',
      'restart after overload',
      // Buzzer / Beeps
      'buzzer',
      'beep',
      'beeps',
      'beeping',
      'audio alarm',
      // Fault Code Record
      'fault code record',
      'fault record',
      'fault log',
      'error code record',
      'error log',
      'alarm log',
      // Backlight
      'backlight',
      'back light',
      'lcd light',
      'screen light',
      'display backlight',
      'lcd brightness',
      // Bypass Function
      'bypass function',
      'bypass enable',
      'bypass mode',
      'bypass',
      // Solar Feed to Grid
      'solar feed to grid',
      'feed to grid',
      'grid feed',
      'pv to grid',
      'pv feed to grid',
      'solar to grid',
      'export to grid',
      'grid export',
      // Beeps While Primary Source Interrupt
      'beeps while primary source interrupt',
      'beep on primary source interrupt',
      'beep when primary source interrupt',
      'beep on source interrupt',
      'beep when source interrupt',
      'beep when ac lost',
      'beep on ac input lost',
      'beep on grid fail',
      // Over Temperature Auto Restart
      'over temperature auto restart',
      'over-temperature auto restart',
      'over temperature restart',
      'over temp auto restart',
      'over temp restart',
      // Power Saving Function / Eco
      'power saving function',
      'power saving',
      'energy saving',
      'eco mode',
      'eco',
      'sleep mode',
    ];
    const standardIdHints = [
      'std_', // vendor ids for this group often start with std_
      'lcd_auto', 'auto_return', 'return_main',
      'overload_auto', 'overload_restart',
      'buzzer', 'beep',
      'fault_record', 'fault_log', 'error_log',
      'backlight', 'lcd_brightness',
      'bypass',
      'feed_to_grid', 'export_grid', 'pv_to_grid', 'solar_to_grid',
      'primary_source_alarm', 'primary_source_interrupt', 'ac_lost',
      'grid_fail',
      'temperature_restart', 'over_temp', 'overtemperature', 'temp_restart',
      'power_saving', 'eco'
    ];
    // Force-ids for Standard Settings
    const standardIds = {
      'std_lcd_display_ctrl_k',
      'std_overload_restart_ctrl_u',
      'std_buzzer_ctrl_a',
      'std_fault_code_record_ctrl_z',
      'std_backlight_function_ctrl_x',
      'std_bypass_function_ctrl_b',
      'std_solar_feed_to_grid_ctrl_d',
      'std_primary_source_alarm_ctrl_y',
      'std_temperature_restart_ctrl_v',
      'std_power_saving_function_ctrl_j',
    };
    if (standardExplicit.any((s) => text.contains(s)) ||
        standardIdHints.any((s) => id.contains(s)) ||
        standardIds.contains(id) ||
        id.startsWith('std_')) {
      return 'Standard Settings';
    }

    // Battery Settings
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

    // System Settings (keep generic UI/system items here; the above explicit mapping overrides for targeted fields)
    const systemKeys = [
      'system',
      'language',
      'date',
      'time',
      'rtc',
      'address',
      'addr',
      'lcd',
      'display',
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

    // Basic Settings (time windows and simple schedules)
    const basicKeys = [
      'time', 'start', 'end', 'schedule', 'period', 'window', 'slot', 'tou',
      // Often paired with charge/discharge context
      'charge time', 'discharge time', 'grid charge time', 'pv charge time',
      'min reserve', 'reserve capacity'
    ];
    if (hasAny(basicKeys)) return 'Basic Settings';

    // Standard Settings (operating modes, electrical parameters)
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
                // Special handling: System Settings should show only the Restore to Default dialog.
                if (cat == 'System Settings') {
                  await _showRestoreToDefaultDialog(context);
                  return;
                }
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

  Future<void> _showRestoreToDefaultDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        title: const Text('System Settings'),
        content: const Text(
            'Restore to Default Settings?\nThis will restore the settings to default.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes')),
        ],
      ),
    );
    if (confirmed != true) return;
    // Attempt to write the restore field using known id and value variants.
    try {
      final vm = getIt<DeviceViewModel>();
      final device = widget.device;
      // Find the field id from loaded fields if available; fallback to known id
      String fieldId = 'sys_set_default';
      for (final f in _fields) {
        final id = f['id']?.toString() ?? '';
        final label = (f['__label']?.toString() ?? f['name']?.toString() ?? '')
            .toLowerCase();
        if (id == 'sys_set_default' ||
            (label.contains('restore') && label.contains('default'))) {
          fieldId = id.isNotEmpty ? id : 'sys_set_default';
          break;
        }
      }
      Future<Map<String, dynamic>> _send(String v) => vm.setDeviceControlField(
            sn: device.sn,
            pn: device.pn,
            devcode: device.devcode,
            devaddr: device.devaddr,
            fieldId: fieldId,
            value: v,
          );
      final tries = ['1', '69', '49', 'true'];
      Map<String, dynamic>? last;
      for (final t in tries) {
        last = await _send(t);
        if ((last['err'] ?? 1) == 0) {
          // Success
          _showSmallSnack(context,
              success: true, message: 'Restored to default');
          await _load();
          return;
        }
      }
      _showSmallSnack(context,
          success: false,
          message: (last?['desc']?.toString() ?? 'Restore failed'));
    } catch (e) {
      _showSmallSnack(context, success: false, message: 'Restore failed: $e');
    }
  }
}

class _SettingTile extends StatefulWidget {
  final Map<String, dynamic> field;
  final VoidCallback onChanged;
  const _SettingTile({required this.field, required this.onChanged});

  @override
  State<_SettingTile> createState() => _SettingTileState();
}

class _SettingTileState extends State<_SettingTile> {
  String _currentDisplay = '';
  bool _fetching = false;

  Map<String, dynamic> get field => widget.field;

  @override
  void initState() {
    super.initState();
    _currentDisplay = field['__displayVal']?.toString() ?? '';
    // Fetch fresh current value from backend like legacy screen does
    _ensureFreshCurrentValue();
  }

  Future<void> _ensureFreshCurrentValue() async {
    // Try only if we have an id we can query
    final id = (field['id'] ?? field['par'] ?? field['key'] ?? field['name'])
            ?.toString() ??
        '';
    if (id.isEmpty) return;
    if (_fetching) return;
    setState(() => _fetching = true);
    try {
      // Find device via ancestor state
      final root =
          context.findAncestorStateOfType<_DeviceSettingsScreenState>();
      final cat = context.findAncestorStateOfType<_CategoryDetailScreenState>();
      final device = cat?.widget.device ?? root?.widget.device;
      if (device == null) return;
      final vm = getIt<DeviceViewModel>();
      final fetched = await vm.fetchSingleControlValue(
        sn: device.sn,
        pn: device.pn,
        devcode: device.devcode,
        devaddr: device.devaddr,
        fieldId: id,
      );
      if (!mounted) return;
      if (fetched != null && fetched.isNotEmpty) {
        // Update field raw values and recompute display like legacy
        field['val'] = fetched;
        field['value'] = fetched;
        field['current'] = fetched;
        field['cur'] = fetched;
        field['curVal'] = fetched;
        field['curval'] = fetched;
        field['set'] = fetched;
        field['now'] = fetched;
        field['__displayVal'] = _currentDisplayValue(field);
        setState(
            () => _currentDisplay = field['__displayVal']?.toString() ?? '');
      }
    } catch (_) {
      // ignore fetch errors, keep existing
    } finally {
      if (mounted) setState(() => _fetching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  child: Text(
                    _currentDisplay,
                    style: const TextStyle(color: Colors.black54),
                  ),
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
    // Determine effective unit for this field (infer if backend unit is missing/misleading)
    final effectiveUnit = _inferUnitForField(field);
    List<Map<String, dynamic>> items = rawItems.map<Map<String, dynamic>>((e) {
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
          fieldName: name, rawValue: val?.toString(), unit: effectiveUnit);
      // Prefer sending 'key' when present (legacy behavior), otherwise 'val'
      final write = ((keyTxt != null && keyTxt.isNotEmpty)
          ? keyTxt
          : (val?.toString() ?? ''));
      return <String, dynamic>{
        'text': text,
        'val': val?.toString(),
        'key': keyTxt,
        'write': write
      };
    }).toList();
    // Deduplicate by label to avoid double labels; prefer preserving currently-selected value
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
      final allPercent = effectiveUnit == '%';
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
    // Try to determine a selected value even when backend returns a label instead of code
    String? groupValCandidate = currentVal;
    if (groupValCandidate == null ||
        !items.any((e) => (e['val']?.toString() ?? '') == groupValCandidate)) {
      final normalizedCurrent = _normalizeOptionLabel(
        (currentVal ?? '').toString(),
        fieldName: name,
        rawValue: currentVal,
      ).toLowerCase();
      for (final it in items) {
        final itLabel = (it['text'] ?? '').toString().toLowerCase();
        if (itLabel.isNotEmpty && itLabel == normalizedCurrent) {
          groupValCandidate = it['val']?.toString();
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
                          final isSel =
                              (groupValCandidate ?? currentVal) == optValStr;
                          return InkWell(
                            onTap: () => Navigator.pop(
                                context, opt['write'] ?? opt['val']),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: optValStr ?? '',
                                    groupValue:
                                        (groupValCandidate ?? currentVal) ?? '',
                                    onChanged: (_) => Navigator.pop(
                                        context, opt['write'] ?? opt['val']),
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
            onPressed: () {
              Navigator.pop(context, ctrl.text);
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
    if (entered != null && (entered as String).isNotEmpty) {
      // Validate numeric and clamp to min/max if provided
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
      // Send as trimmed string; keep decimals if any
      await _writeValue(context, finalVal.toString());
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
    // Resolve the field id across multiple possible keys from API variants
    final id = (field['id'] ??
                field['par'] ??
                field['key'] ??
                field['name'] ??
                field['param'] ??
                field['code'] ??
                field['par_no'])
            ?.toString() ??
        '';
    if (id.isEmpty) return;
    print('DeviceSettings: write id=$id value=$value for pn=' +
        device.pn +
        ' sn=' +
        device.sn +
        ' devcode=${device.devcode} devaddr=${device.devaddr}');
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
      _showSmallSnack(context,
          success: true,
          message: (res['desc']?.toString().isNotEmpty ?? false)
              ? res['desc'].toString()
              : 'Updated');
      print('DeviceSettings: write success field=$id value=$value');
      // Update local field map immediately so UI reflects change without waiting for reload
      try {
        field['val'] = value;
        field['value'] = value;
        field['current'] = value;
        field['cur'] = value;
        field['curVal'] = value;
        field['curval'] = value;
        field['set'] = value;
        field['now'] = value;
        field['__displayVal'] = _currentDisplayValue(field);
      } catch (_) {}
      // Verify from backend to ensure persistence reflects
      try {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        final fresh = await vm.fetchSingleControlValue(
          sn: device.sn,
          pn: device.pn,
          devcode: device.devcode,
          devaddr: device.devaddr,
          fieldId: id,
        );
        if (fresh != null && fresh.isNotEmpty) {
          field['val'] = fresh;
          field['value'] = fresh;
          field['current'] = fresh;
          field['cur'] = fresh;
          field['curVal'] = fresh;
          field['curval'] = fresh;
          field['set'] = fresh;
          field['now'] = fresh;
          field['__displayVal'] = _currentDisplayValue(field);
          print('DeviceSettings: verified remote value for ' +
              id +
              ' -> ' +
              fresh);
        }
      } catch (e) {
        print('DeviceSettings: verification fetch failed for ' +
            id +
            ' : ' +
            e.toString());
      }
      await element._load();
      // Update local trailing value as well
      try {
        setState(() {
          _currentDisplay =
              field['__displayVal']?.toString() ?? _currentDisplay;
        });
      } catch (_) {}
      widget.onChanged();
    } else {
      _showSmallSnack(context,
          success: false,
          message: (res['desc']?.toString().isNotEmpty ?? false)
              ? res['desc'].toString()
              : 'Unknown error');
      print(
          'DeviceSettings: write FAILED field=$id value=$value error=${res['desc']}');
    }
  }

  bool _looksBoolean(List<Map> options) {
    final texts = options
        .map((o) => (o['key'] ?? o['name'] ?? '').toString().toLowerCase())
        .toList();
    final values = options.map((o) => o['val']?.toString()).toSet();
    if (values.length == 2 && values.containsAll({'0', '1'})) return true;
    if (values.length == 2 && values.containsAll({'48', '49'})) return true;
    if (values.length == 2 && values.containsAll({'68', '69'})) return true;
    if (texts.any((t) => t.contains('on')) &&
        texts.any((t) => t.contains('off'))) return true;
    if (texts.any((t) => t.contains('enable')) &&
        texts.any((t) => t.contains('disable'))) return true;
    return false;
  }

  bool _currentBoolValue(Map field, List<Map> options) {
    final v = (_extractCurrentRawValue(field) ?? field['val']?.toString())
            ?.trim()
            .toLowerCase() ??
        '';
    // Direct numeric encodings (legacy): 69=Enabled, 68=Disabled
    if (v == '1' || v == '49' || v == '69') return true;
    if (v == '0' || v == '48' || v == '68') return false;
    // Textual encodings
    if (v == 'on' || v == 'enable' || v == 'enabled' || v == 'true')
      return true;
    if (v == 'off' || v == 'disable' || v == 'disabled' || v == 'false')
      return false;

    // Try infer from option labels
    // Normalize options type for safe access
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
    if (lbl.contains('on') ||
        lbl.contains('enable') ||
        lbl.contains('enabled')) {
      return true;
    }
    if (lbl.contains('off') ||
        lbl.contains('disable') ||
        lbl.contains('disabled')) {
      return false;
    }

    // Fallback: assume second option means true if there are exactly two options
    if (options.length == 2) {
      final idx = options.indexWhere((o) => o['val']?.toString() == v);
      return idx == 1;
    }
    return false;
  }

  Future<void> _toggleBoolean(
      BuildContext context, Map field, bool newVal) async {
    // Determine the correct value to send based on available options for this field
    final List<Map<String, dynamic>> options =
        ((field['item'] as List?)?.whereType<Map>().toList() ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
    String resolveBoolVal(bool v) {
      if (options.length == 2) {
        // Prefer mapping by label text first
        Map<String, dynamic>? onOpt;
        Map<String, dynamic>? offOpt;
        for (final Map<String, dynamic> o in options) {
          final t = (o['key'] ?? o['name'] ?? '').toString().toLowerCase();
          if (t.contains('on') ||
              t.contains('enable') ||
              t.contains('enabled')) {
            onOpt ??= o;
          } else if (t.contains('off') ||
              t.contains('disable') ||
              t.contains('disabled')) {
            offOpt ??= o;
          }
        }
        if (onOpt != null && offOpt != null) {
          String codeFor(Map<String, dynamic> o) {
            final k = o['key']?.toString();
            final val = o['val']?.toString();
            return (k != null && k.isNotEmpty) ? k : (val ?? '');
          }

          return v ? codeFor(onOpt) : codeFor(offOpt);
        }
        // Next, map by known numeric pairs
        final vals = options.map((o) => o['val']?.toString()).toSet();
        bool hasAll(Set<String> s) => s.every(vals.contains);
        if (hasAll({'0', '1'})) return v ? '1' : '0';
        if (hasAll({'48', '49'})) return v ? '49' : '48';
        if (hasAll({'68', '69'})) return v ? '69' : '68';
        // Fallback: assume order off/on
        final chosen = v ? options[1] : options[0];
        final k = chosen['key']?.toString();
        final val = chosen['val']?.toString();
        return (k != null && k.isNotEmpty) ? k : (val ?? '');
      }
      // No options: try known enum mapping by field label first
      final fieldLabel = (field['__label']?.toString() ?? '').toLowerCase();
      final enumMap = _knownEnumMapForField(fieldLabel);
      if (enumMap.isNotEmpty) {
        // Build inverse map from label->code
        final Map<String, String> inv = {};
        enumMap.forEach((code, label) {
          inv[label.toLowerCase()] = code;
        });
        // Preferred labels in order
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
      // Fallback default to 0/1 if nothing else applies
      return v ? '1' : '0';
    }

    final newValue = resolveBoolVal(newVal);
    print('DeviceSettings: toggle boolean -> sending $newValue');
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
  // Fallback to normalized raw value (map 0/1 to Off/On when appropriate)
  return _normalizeOptionLabel(raw.toString(),
      fieldName: f['__label']?.toString(),
      rawValue: raw.toString(),
      unit: unit);
}

// --- Option label normalization helpers ---
String _normalizeOptionLabel(String text,
    {String? fieldName, String? rawValue, String? unit}) {
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
      // Generic boolean encodings observed in old app and API
      if (t == '0' || t == '48' || t == '68') {
        t = 'Off';
      } else if (t == '1' || t == '49' || t == '69') {
        t = 'On';
      }
    }
  }

  // Strip enclosing parentheses if leftover
  if (t.startsWith('(') && t.endsWith(')')) {
    final inner = t.substring(1, t.length - 1).trim();
    if (_looksMeaningful(inner)) t = inner;
  }

  // Units formatting:
  // 1) Only render % when unit is explicitly '%'.
  if (unit != null && unit.trim() == '%') {
    final n = int.tryParse(t);
    if (n != null) return '$n%';
  }
  // 2) Append common physical units for pure numbers (avoid enums/codes).
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
  // Backlight / LCD brightness toggle (various firmwares use 68/69 or 0/1)
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
  // Buzzer / Alarm toggle
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
      '68': 'Disabled', // legacy toggle variant
      '69': 'Enabled',
    };
  }
  return const {};
}

// Infer a more accurate unit based on field name and values when backend unit is missing or misleading.
String? _inferUnitForField(Map f) {
  final backendUnit = f['unit']?.toString();
  final u = backendUnit?.trim();
  final name =
      (f['__label']?.toString() ?? f['name']?.toString() ?? '').toLowerCase();
  // If backend explicitly sets a sensible unit, keep it (except bare '%').
  if (u != null && u.isNotEmpty && u != '%') return u;
  // Heuristics by field name
  if (name.contains('voltage') ||
      name.contains('volt') ||
      name.contains('vdc') ||
      name.contains('vac')) return 'V';
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
      name.contains('brightness')) return '%';
  // Look at values: if all look like 0..100 and name suggests percentage-ish, return '%'
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

// Unified small snackbar for success/error messages
void _showSmallSnack(BuildContext context,
    {required bool success, required String message}) {
  final Color bg = success ? Colors.green.shade600 : Colors.red.shade600;
  final IconData icon = success ? Icons.check_circle : Icons.error;
  final String prefix = success ? 'Success' : 'Error';
  final String text = '$prefix: $message';
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
    backgroundColor: bg,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    duration: const Duration(seconds: 2),
  ));
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
  List<Map<String, dynamic>> _fields = [];
  // Explicit whitelist for Battery Settings (match by id, fallback by label when id varies)
  static const Set<String> _batteryIds = {
    'bat_battery_type',
    'bat_charging_bulk_voltage',
    'bat_charging_float_voltage',
    'bat_max_charging_current',
    'bat_maximum_battery_discharge_current',
    'bat_ac_charging_current',
    'bat_charging_source',
    'bat_battery_equalization',
    'bat_activate_battery_equalization',
    'bat_equalization_time_out',
    'bat_equalization_time',
    'bat_equalization_period',
    'bat_equalization_voltage',
    'bat_battery_recharge_capacity',
    'bat_battery_redischarge_capacity',
    'bat_battery_under_capacity',
  };
  static const List<String> _batteryLabelWhitelist = [
    // Ordered to match the UI provided
    'battery type',
    'bulk charging voltage',
    'float charging voltage',
    'maximum charging current',
    'maximum battery discharge current',
    'maximum ac charging current',
    'charging source priority',
    'battery equalization',
    'real-time activate battery equalization',
    'battery equalization time-out',
    'battery equalization time',
    'equalization period',
    'equalization voltage',
    'back to grid capacity',
    'back to discharge capacity',
    'battery cut-off capacity',
  ];
  @override
  void initState() {
    super.initState();
    // Initialize with provided fields, then fetch fresh state from backend
    _fields = widget.fields.map((e) => Map<String, dynamic>.from(e)).toList();
    _reloadCategoryFields();
  }

  Future<void> _reloadCategoryFields() async {
    try {
      final vm = getIt<DeviceViewModel>();
      final dat = await vm.fetchDeviceControlFields(
        sn: widget.device.sn,
        pn: widget.device.pn,
        devcode: widget.device.devcode,
        devaddr: widget.device.devaddr,
      );
      if (dat == null) return;
      final list = (dat['field'] as List?)?.whereType<Map>().toList() ?? [];
      final parsed = <Map<String, dynamic>>[];
      for (final raw in list) {
        final f = Map<String, dynamic>.from(raw);
        f['__label'] = _fieldLabel(f);
        f['__displayVal'] = _currentDisplayValue(f);
        // Re-derive category locally using same heuristics as parent
        final label = (f['__label']?.toString() ?? '').toLowerCase();
        final name = (f['name']?.toString() ?? '').toLowerCase();
        final id = (f['id']?.toString() ?? '').toLowerCase();
        final text = ('$label $name $id').trim();
        bool hasAny(Iterable<String> keys) =>
            keys.any((k) => k.isNotEmpty && text.contains(k));
        String cat;
        // Explicit mapping for Standard Settings requested items (take precedence)
        const standardExplicit = [
          // LCD Auto-return to Main Screen
          'lcd auto-return to main screen',
          'lcd auto return to main screen',
          'lcd auto-return',
          'lcd auto return',
          'auto return to main',
          'return to main screen',
          'auto home screen',
          'home screen auto return',
          'lcd return time',
          // Overload Auto Restart
          'overload auto restart',
          'overload restart',
          'restart after overload',
          // Buzzer / Beeps
          'buzzer',
          'beep',
          'beeps',
          'beeping',
          'audio alarm',
          // Fault Code Record
          'fault code record',
          'fault record',
          'fault log',
          'error code record',
          'error log',
          'alarm log',
          // Backlight
          'backlight',
          'back light',
          'lcd light',
          'screen light',
          'display backlight',
          'lcd brightness',
          // Bypass Function
          'bypass function',
          'bypass enable',
          'bypass mode',
          'bypass',
          // Solar Feed to Grid
          'solar feed to grid',
          'feed to grid',
          'grid feed',
          'pv to grid',
          'pv feed to grid',
          'solar to grid',
          'export to grid',
          'grid export',
          // Beeps While Primary Source Interrupt
          'beeps while primary source interrupt',
          'beep on primary source interrupt',
          'beep when primary source interrupt',
          'beep on source interrupt',
          'beep when source interrupt',
          'beep when ac lost',
          'beep on ac input lost',
          'beep on grid fail',
          // Over Temperature Auto Restart
          'over temperature auto restart',
          'over-temperature auto restart',
          'over temperature restart',
          'over temp auto restart',
          'over temp restart',
          // Power Saving Function / Eco
          'power saving function',
          'power saving',
          'energy saving',
          'eco mode',
          'eco',
          'sleep mode',
        ];
        const standardIdHints = [
          // observed std_* ids
          'std_',
          'std_lcd_display',
          'std_overload_restart',
          'std_buzzer',
          'std_fault_code_record',
          'std_backlight',
          'std_bypass_function',
          'std_solar_feed_to_grid',
          'std_primary_source_alarm',
          'std_temperature_restart',
          'std_power_saving_function',
          // generic fragments
          'lcd_auto', 'auto_return', 'return_main',
          'overload_auto', 'overload_restart',
          'buzzer', 'beep',
          'fault_record', 'fault_log', 'error_log',
          'backlight', 'lcd_brightness',
          'bypass',
          'feed_to_grid', 'export_grid', 'pv_to_grid', 'solar_to_grid',
          'primary_source_alarm', 'primary_source_interrupt', 'ac_lost',
          'grid_fail',
          'temperature_restart', 'over_temp', 'overtemperature', 'temp_restart',
          'power_saving', 'eco',
        ];
        // Add the same force-id set used by the parent screen
        const standardIds = {
          'std_lcd_display_ctrl_k',
          'std_overload_restart_ctrl_u',
          'std_buzzer_ctrl_a',
          'std_fault_code_record_ctrl_z',
          'std_backlight_function_ctrl_x',
          'std_bypass_function_ctrl_b',
          'std_solar_feed_to_grid_ctrl_d',
          'std_primary_source_alarm_ctrl_y',
          'std_temperature_restart_ctrl_v',
          'std_power_saving_function_ctrl_j',
        };
        if (standardExplicit.any((s) => text.contains(s)) ||
            standardIdHints.any((s) => id.contains(s)) ||
            standardIds.contains(id) ||
            id.startsWith('std_')) {
          cat = 'Standard Settings';
        } else {
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
          const systemKeys = [
            'system',
            'language',
            'date',
            'time',
            'rtc',
            'address',
            'addr',
            'lcd',
            'display',
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
          if (hasAny(batteryKeys))
            cat = 'Battery Settings';
          else if (hasAny(systemKeys))
            cat = 'System Settings';
          else if (hasAny(basicKeys))
            cat = 'Basic Settings';
          else if (hasAny(standardKeys))
            cat = 'Standard Settings';
          else
            cat = 'Other Settings';
        }
        f['__category'] = cat;
        if (cat == widget.title) {
          // If Battery Settings, apply strict whitelist to match design
          if (cat == 'Battery Settings') {
            final id = f['id']?.toString().toLowerCase() ?? '';
            final lname = (f['__label']?.toString() ?? '').toLowerCase();
            final allow = _batteryIds.contains(id) ||
                _batteryLabelWhitelist.contains(lname);
            if (!allow) {
              // Skip extra battery fields not in whitelist
              continue;
            }
          }
          parsed.add(f);
        }
      }
      if (!mounted) return;
      setState(() {
        _fields = parsed;
        if (widget.title == 'Battery Settings') {
          final order = _CategoryDetailScreenState._batteryLabelWhitelist;
          _fields.sort((a, b) {
            final ai =
                order.indexOf((a['__label']?.toString() ?? '').toLowerCase());
            final bi =
                order.indexOf((b['__label']?.toString() ?? '').toLowerCase());
            final aa = ai == -1 ? 999 : ai;
            final bb = bi == -1 ? 999 : bi;
            return aa.compareTo(bb);
          });
        }
      });
    } catch (e) {
      // Silent; keep existing fields
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiles = _fields
        .map((f) => _SettingTile(
            field: f,
            onChanged: () async {
              // Refresh both parent and this category to reflect latest state
              await widget.reloadParent();
              await _reloadCategoryFields();
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
