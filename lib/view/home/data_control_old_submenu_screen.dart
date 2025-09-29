import 'package:flutter/material.dart';
import 'package:crown_micro_solar/legacy/device_ctrl_fields_model.dart';

class DataControlOldSubmenuScreen extends StatefulWidget {
  final String pn;
  final String sn;
  final String id;
  final String fieldname;
  final String? unit;
  final String? hint;
  final int devcode;
  final int devaddr;
  final List<Item> items;

  const DataControlOldSubmenuScreen({
    super.key,
    required this.pn,
    required this.sn,
    required this.devcode,
    required this.devaddr,
    required this.id,
    required this.fieldname,
    this.unit,
    this.hint,
    required this.items,
  });

  @override
  State<DataControlOldSubmenuScreen> createState() => _DataControlOldSubmenuScreenState();
}

class _DataControlOldSubmenuScreenState extends State<DataControlOldSubmenuScreen> {
  List<bool> _checked = [];
  String? _selectedValue; // will store backend 'key' or the typed numeric
  bool _loading = false;
  String? _currentVal; // backend code current value
  final TextEditingController _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final resp = await DevicecTRLvalueQuery(
        context,
        PN: widget.pn,
        SN: widget.sn,
        devaddr: widget.devaddr.toString(),
        devcode: widget.devcode.toString(),
        id: widget.id,
      );
      if (resp['err'] == 0) {
        _currentVal = resp['dat']?['val']?.toString();
      }
      _checked = List<bool>.generate(widget.items.length, (i) => false);
      if (_currentVal != null) {
        for (int i = 0; i < widget.items.length; i++) {
          if (widget.items[i].val?.toString() == _currentVal) {
            _checked[i] = true;
            _selectedValue = widget.items[i].key?.toString();
          }
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if ((_selectedValue == null || _selectedValue!.isEmpty) && _textCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No value selected.')));
      return;
    }
    setState(() => _loading = true);
    try {
      final valToSend = (_selectedValue ?? _textCtrl.text.trim());
      final res = await UpdateDeviceFieldQuery(
        context,
        SN: widget.sn,
        PN: widget.pn,
        ID: widget.id,
        Value: valToSend,
        devcode: widget.devcode.toString(),
        devaddr: widget.devaddr.toString(),
      );
      if (res['err'] == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          backgroundColor: Colors.green,
          content: Text('Value Updated Successfully'),
        ));
        Navigator.pop(context);
      } else {
        final msg = (res['desc']?.toString() ?? 'Update failed');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text(msg.toUpperCase()),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('ERROR: $e'),
      ));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final isEnum = widget.items.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(widget.fieldname, style: TextStyle(
          fontSize: 0.035 * (size.height - size.width),
          color: Colors.white,
        )),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Card(
              elevation: 5,
              child: SizedBox(
                width: 0.2 * width,
                child: OutlinedButton(
                  onPressed: _loading ? null : _save,
                  child: Text('Set', style: TextStyle(
                    fontSize: 0.035 * (size.height - size.width),
                    color: const Color(0xFF3A3A3A),
                  )),
                ),
              ),
            ),
          )
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : isEnum
              ? ListView.builder(
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    final it = widget.items[index];
                    return CheckboxListTile(
                      secondary: Icon(Icons.edit_attributes, color: Colors.greenAccent.shade400),
                      controlAffinity: ListTileControlAffinity.trailing,
                      title: Text(
                        '${it.val}',
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w300, fontSize: 15),
                      ),
                      value: _checked[index],
                      onChanged: (v) {
                        setState(() {
                          for (int i = 0; i < _checked.length; i++) {
                            _checked[i] = false;
                          }
                          _checked[index] = (v ?? false);
                          _selectedValue = it.key?.toString();
                        });
                      },
                    );
                  },
                )
              : _numberEditor(size),
    );
  }

  Widget _numberEditor(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 2,
          margin: const EdgeInsets.all(10),
          color: Colors.blueGrey.shade900,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.fieldname, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400, fontSize: 0.035 * (size.height - size.width))),
                if (widget.unit != null)
                  Text(' ( ${widget.unit} )', style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w300, fontSize: 0.032 * (size.height - size.width))),
              ],
            ),
          ),
        ),
        if (widget.hint != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(' Input Example: ${widget.hint}', style: TextStyle(color: Colors.black87, fontSize: 0.038 * (size.height - size.width))),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(' Current Value: ${_currentVal ?? '--'}', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w400, fontSize: 0.035 * (size.height - size.width))),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _textCtrl,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(15),
              filled: true,
              fillColor: Color(0xFFEFF3F6),
              hintText: 'Enter Value Here',
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ),
        )
      ],
    );
  }
}
