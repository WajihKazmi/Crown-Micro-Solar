import 'package:flutter/material.dart';
import 'package:crown_micro_solar/legacy/device_ctrl_fields_model.dart';
import 'package:crown_micro_solar/presentation/models/device/device_model.dart';
import 'data_control_old_submenu_screen.dart';

// Exact copy-style of the old app's DataControl list UI, adapted to our project
class DataControlOldScreen extends StatefulWidget {
  final String pn;
  final String sn;
  final int devcode;
  final int devaddr;

  const DataControlOldScreen({
    super.key,
    required this.pn,
    required this.sn,
    required this.devcode,
    required this.devaddr,
  });

  factory DataControlOldScreen.fromDevice(Device device, {Key? key}) =>
      DataControlOldScreen(
        key: key,
        pn: device.pn,
        sn: device.sn,
        devcode: device.devcode,
        devaddr: device.devaddr,
      );

  @override
  State<DataControlOldScreen> createState() => _DataControlOldScreenState();
}

class _DataControlOldScreenState extends State<DataControlOldScreen> {
  bool _loading = true;
  Map<String, dynamic>? _resp;
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    try {
      final data = await DeviceCtrlFieldseModelQuery(
        context,
        SN: widget.sn,
        PN: widget.pn,
        devcode: widget.devcode.toString(),
        devaddr: widget.devaddr.toString(),
      );
      setState(() {
        _resp = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _resp = {'err': 404, 'desc': e.toString()};
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return DefaultTabController(
      length: _effectiveTabsCount(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
          ),
          backgroundColor: Theme.of(context).primaryColor,
          title: Row(
            children: [
              Text(
                'Data Control',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 0.035 * (size.height - size.width),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Fields',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  fontSize: 0.035 * (size.height - size.width),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          ],
          bottom: _loading || _resp == null
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(46),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TabBar(
                      isScrollable: true,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: _buildTabs(),
                    ),
                  ),
                ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(size),
      ),
    );
  }

  Widget _buildBody(Size size) {
    final width = size.width;
    final data = _resp ?? const <String, dynamic>{'err': 404};
    final err = data['err'] as int? ?? 404;
    if (err == 1) return _msg(width, 'Failed (no device protocol)');
    if (err == 6) return _msg(width, 'Parameter error');
    if (err == 12) return _msg(width, 'No record found');
    if (err == 257) return _msg(width, 'Collector not found');
    if (err == 258) return _msg(width, 'Device could not be found');
    if (err == 260) return _msg(width, 'Power station not found');
    if (err == 404) return _msg(width, 'No response from server');

    if (err != 0 || data['dat'] == null || data['dat']['field'] == null) {
      return _msg(width, 'No response from server');
    }

    final model = DeviceCtrlFieldseModel.fromJson(data);
    final fields = model.dat?.field ?? <Field>[];

    // Group by category using simple heuristics on field names
    final grouped = <String, List<Field>>{
      for (final t in _tabsOrder) t: <Field>[]
    };
    for (final f in fields) {
      final c = _categoryFor(f);
      grouped[c]!.add(f);
    }
    final nonEmptyTabs = _tabsOrder.where((t) => grouped[t]!.isNotEmpty).toList();

    if (nonEmptyTabs.length <= 1) {
      // If only one category has items, show a plain list (prettier styling)
      return _categoryList(nonEmptyTabs.isEmpty ? 'Other Settings' : nonEmptyTabs.first, grouped);
    }

    return TabBarView(
      children: [
        for (final tab in nonEmptyTabs) _categoryList(tab, grouped),
      ],
    );
  }

  // Build pretty tabs with counts
  List<Widget> _buildTabs() {
    final data = _resp;
    if (data == null || data['err'] != 0 || data['dat'] == null) {
      return const [];
    }
    final model = DeviceCtrlFieldseModel.fromJson(data);
    final fields = model.dat?.field ?? <Field>[];
    final counts = <String, int>{ for (final t in _tabsOrder) t: 0 };
    for (final f in fields) {
      final c = _categoryFor(f);
      counts[c] = (counts[c] ?? 0) + 1;
    }
    final nonEmpty = _tabsOrder.where((t) => (counts[t] ?? 0) > 0).toList();
    return [
      for (final t in nonEmpty)
        Tab(text: '$t (${counts[t]})')
    ];
  }

  int _effectiveTabsCount() {
    final data = _resp;
    if (data == null || data['err'] != 0 || data['dat'] == null) return 0;
    final model = DeviceCtrlFieldseModel.fromJson(data);
    final fields = model.dat?.field ?? <Field>[];
    final counts = <String, int>{ for (final t in _tabsOrder) t: 0 };
    for (final f in fields) {
      final c = _categoryFor(f);
      counts[c] = (counts[c] ?? 0) + 1;
    }
    return counts.values.where((n) => n > 0).length;
  }

  String _categoryFor(Field f) {
    final n = (f.name ?? '').toLowerCase();
    bool hasAny(List<String> keys) => keys.any((k) => n.contains(k));

    if (hasAny(['battery', 'charge', 'discharge', 'soc'])) {
      return 'Battery Settings';
    }
    if (hasAny(['grid', 'ac input', 'backflow', 'frequency', 'utility'])) {
      return 'System Settings';
    }
    if (hasAny(['pv', 'solar', 'load', 'output', 'ac output', 'ac2'])) {
      return 'Basic Settings';
    }
    if (hasAny(['standard', 'mode', 'priority'])) {
      return 'Standard Settings';
    }
    return 'Other Settings';
  }

  Widget _categoryList(String category, Map<String, List<Field>> grouped) {
    final list = grouped[category] ?? const <Field>[];
    if (list.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final f = list[index];
        final items = (f.item ?? <Item>[]);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 18),
            ),
            title: Text(
              f.name ?? '',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            subtitle: _buildSubtitle(f),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DataControlOldSubmenuScreen(
                    pn: widget.pn,
                    sn: widget.sn,
                    devaddr: widget.devaddr,
                    devcode: widget.devcode,
                    id: f.id ?? '',
                    fieldname: f.name ?? '',
                    unit: f.unit,
                    hint: f.hint,
                    items: items,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget? _buildSubtitle(Field f) {
    final hasUnit = (f.unit != null && f.unit!.trim().isNotEmpty);
    final hasHint = (f.hint != null && f.hint!.trim().isNotEmpty);
    if (!hasUnit && !hasHint) return null;
    final pieces = <String>[];
    if (hasUnit) pieces.add('Unit: ${f.unit}');
    if (hasHint) pieces.add('Hint: ${f.hint}');
    return Text(
      pieces.join(' · '),
      style: const TextStyle(fontSize: 11, color: Colors.black54),
    );
  }

  Widget _msg(double width, String text) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 0.035 * width,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
}
