import 'package:crownmonitor/pages/devices.dart';
import 'package:crownmonitor/pages/home.dart';
import 'package:crownmonitor/pages/list.dart';
// import 'package:crownmonitor/pages/maps.dart';
import 'package:crownmonitor/pages/plant.dart';
import 'package:crownmonitor/pages/user.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MainScreen extends StatefulWidget {
  int? passed_index = 0;
  MainScreen({Key? key, this.passed_index}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  static const TextStyle optionStyle = TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  late List<Widget> _widgetOptions = <Widget>[Home(), Plant(), Devices(), Users()]; //Map(),

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _selectedIndex = widget.passed_index ?? 0;
  }

  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        unselectedFontSize: 12,
        selectedFontSize: 14,
        type: BottomNavigationBarType.fixed,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home_outlined,
            ),
            label: AppLocalizations.of(context)!.tabs_home,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.list,
            ),
            label: AppLocalizations.of(context)!.tabs_plant, // oldname 'List'
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.devices,
            ),
            label: AppLocalizations.of(context)!.tabs_device,
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(
          //     Icons.map,
          //   ),
          //   label: 'Map',
          // ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
            ),
            label: AppLocalizations.of(context)!.tabs_user,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
        onTap: _onItemTapped,
      ),
    );
  }
}
