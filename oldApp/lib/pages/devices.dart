import 'package:crownmonitor/Models/CollectorDevicesStatus.dart';
import 'package:crownmonitor/Models/CollectorsinfoofPlant.dart';
import 'package:crownmonitor/Models/DevicesofPlant.dart';
import 'package:crownmonitor/pages/CollectorInformationscreen.dart';
import 'package:crownmonitor/pages/plant.dart' as plantspage;
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'deviceinformation.dart';

class Devices extends StatefulWidget {
  String? Plantname;
  String? Plant_status;
  String? PlantID;
  String? PNfromQRcan;
  //for collector callback on this screen
  bool? collector_callback;
  Devices(
      {Key? key,
      this.collector_callback,
      this.PNfromQRcan,
      this.Plantname,
      this.Plant_status = '5',
      this.PlantID = 'all'})
      : super(key: key);

  @override
  _DevicesState createState() => _DevicesState();
}

class _DevicesState extends State<Devices> {
  //collectorcallback
  bool Collector_Callback = false;

  ////
  late TextEditingController name = new TextEditingController();
  late TextEditingController Pn_number = new TextEditingController();
  late TextEditingController search = new TextEditingController();

  late List<String> _list;
  String? _selectedItem = '';
  late List<String> _list1;
  String? _selectedItem1 = '';

  ///for all plants we used 5
  String _selectedItem_converted = '0101';
  String _selectedItem1_converted = '0101';

  var collector_ps_info = null;
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    Collector_Callback = widget.collector_callback ?? true;
    _list = [
      AppLocalizations.of(context)!.all_type,
      AppLocalizations.of(context)!.inverter,
      AppLocalizations.of(context)!.datalogger,
      AppLocalizations.of(context)!.env_monitor,
      AppLocalizations.of(context)!.smart_meters,
      AppLocalizations.of(context)!.energy_storage_machine,
    ];

    _selectedItem = Collector_Callback ? _list[2] : _list[0];
    _list1 = [
      AppLocalizations.of(context)!.all_types,
      AppLocalizations.of(context)!.online,
      AppLocalizations.of(context)!.offline,
      AppLocalizations.of(context)!.fault,
      AppLocalizations.of(context)!.standby,
      AppLocalizations.of(context)!.alarm
    ];
    _selectedItem1 = _list1[0];

    _selectedItem_converted = Collector_Callback ? '0110' : '0101';
  }

  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    /////////////alert dialog/////////////////////

    // set up addcollector  button
    Widget AddCollectorButton = ElevatedButton(
        child: Text(AppLocalizations.of(context)!.btn_add),
        onPressed: () async {
          var json = await AddCollectortoplant(
              PN: Pn_number.text, name: name.text, PID: widget.PlantID!);

          if (json['err'] == 6) {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.parameter_error,
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
          } else if (json['err'] == 259) {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.invalid_pn,
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
          } else if (json['err'] == 3) {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.error_system_exception,
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
          } else if (json['err'] == 11) {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!
                    .no_permissions_possible_reason_only_the_plant_owner_can_add,
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
          } else if (json['err'] == 260) {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.power_station_not_found,
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
          } else if (json['err'] == 4) {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.signature_error,
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
          } else if (json['err'] == 522) {
            Fluttertoast.showToast(
                msg: "${json['desc']}",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
          } else {
            Fluttertoast.showToast(
                msg:
                    AppLocalizations.of(context)!.datalogger_added_successfully,
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => plantspage.Plant(
                        passedindex: 3,
                        collector_callback: true,
                        PlantID: widget.PlantID,
                      )),
            );
          }
        });

    Widget CancelButton = ElevatedButton(
      child: Text(AppLocalizations.of(context)!.btn_cancel),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop();
      },
    );
    AlertDialog addcollector_alert = AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.enter_datalogger_name_and_pn_number,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      ),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          onSubmitted: (String value) {
            setState(() {
              name.text = value;
            });
          },
          controller: name,
          decoration: new InputDecoration(
            contentPadding: EdgeInsets.all(10),
            fillColor: Colors.white,
            filled: true,
            hintText: AppLocalizations.of(context)!.enter_datalogger_name,
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
              borderSide: const BorderSide(
                color: Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
              // borderSide: BorderSide(color: Colo),
            ),
          ),
          style: Theme.of(context).textTheme.displaySmall,
          textAlignVertical: TextAlignVertical.center,
        ),
        SizedBox(
          height: 5,
        ),
        TextField(
          onSubmitted: (String value) {
            setState(() {
              name.text = value;
            });
          },
          controller: Pn_number,
          decoration: new InputDecoration(
            contentPadding: EdgeInsets.all(10),
            fillColor: Colors.white,
            filled: true,
            hintText: AppLocalizations.of(context)!.enter_pn_number_14_digits,
            enabledBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
              borderSide: const BorderSide(
                color: Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
              // borderSide: BorderSide(color: Colo),
            ),
          ),
          style: Theme.of(context).textTheme.displaySmall,
          textAlignVertical: TextAlignVertical.center,
        ),
      ]),
      actions: [
        AddCollectorButton,
        CancelButton,
      ],
    );

    return Scaffold(
      appBar: AppBar(
          // leading: IconButton(
          //     onPressed: () {
          //       // Navigator.pop(context);
          //       Navigator.pushAndRemoveUntil(
          //           context,
          //           MaterialPageRoute(
          //               builder: (context) => MainScreen(passed_index: 1)),
          //           (route) => false);
          //     },
          //     icon: Icon(Icons.arrow_back, color: Colors.white, size: 25)),
          backgroundColor: Theme.of(context).primaryColor,
          centerTitle: false,
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
                onPressed: () async {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return addcollector_alert;
                    },
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 22,
                    ),
                    SizedBox(height: 0.002 * height),
                    Text(AppLocalizations.of(context)!.add_datalogger,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 0.025 * (height - width),
                            fontWeight: FontWeight.bold)),
                  ],
                )),
          ],
          title: Text(AppLocalizations.of(context)!.devices,
              style: TextStyle(
                  fontSize: 0.045 * (height - width),
                  fontWeight: FontWeight.bold,
                  color: Colors.white))),
      body: Container(
        height: height,
        child: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    width: width / 2.2,
                    // color: Colors.white,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        hint: const Row(
                          children: [
                            Icon(
                              Icons.arrow_circle_down,
                              size: 16,
                              color: Colors.yellow,
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            Expanded(
                              child: Text(
                                'Select Item',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        items: _list
                            .map((String item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        value: _selectedItem,
                        onChanged: (String? selectedItem) {
                          print(selectedItem);

                          setState(() {
                            _selectedItem = selectedItem;
                            switch (_list.indexOf(selectedItem.toString())) {
                              case 0: // "All Type"
                                _selectedItem_converted = '0101';
                                break;
                              case 1: // "Inverter"
                                _selectedItem_converted = '512';
                                break;
                              case 2: // "Datalogger"
                                _selectedItem_converted = '0110';
                                break;
                              case 3: // "Env-monitor"
                                _selectedItem_converted = '768';
                                break;
                              case 4: // "Energy Storage Machine"
                                _selectedItem_converted = '2452';
                                break;
                              case 5: // "Smart meters"
                                _selectedItem_converted = '1024';
                                break;
                            }
                          });
                        },
                        buttonStyleData: ButtonStyleData(
                          height: 30,
                          padding: const EdgeInsets.only(left: 14, right: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            // border: Border.all(
                            //   color: Colors.black26,
                            // ),
                            color: Theme.of(context).primaryColor,
                          ),
                          elevation: 2,
                        ),
                        iconStyleData: const IconStyleData(
                          icon: Icon(
                            Icons.arrow_drop_down,
                          ),
                          iconSize: 14,
                          iconEnabledColor: Colors.yellow,
                          iconDisabledColor: Colors.grey,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Theme.of(context).primaryColor,
                          ),
                          offset: const Offset(-20, 0),
                          scrollbarTheme: ScrollbarThemeData(
                            radius: const Radius.circular(40),
                            thickness: WidgetStateProperty.all<double>(6),
                            thumbVisibility:
                                WidgetStateProperty.all<bool>(true),
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 40,
                          padding: EdgeInsets.only(left: 14, right: 14),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: width / 2.2,
                    // color: Colors.white,
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton2<String>(
                        isExpanded: true,
                        hint: const Row(
                          children: [
                            Icon(
                              Icons.arrow_circle_down,
                              size: 16,
                              color: Colors.yellow,
                            ),
                            SizedBox(
                              width: 4,
                            ),
                            Expanded(
                              child: Text(
                                'Select Item',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        items: _list1
                            .map((String item) => DropdownMenuItem<String>(
                                  value: item,
                                  child: Text(
                                    item,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        value: _selectedItem1,
                        onChanged: (String? selectedItem1) {
                          print(selectedItem1);
                          setState(() {
                            _selectedItem1 = selectedItem1;
                            switch (_list1.indexOf(_selectedItem1.toString())) {
                              case 0: // "All Types"
                                _selectedItem1_converted = '0101';
                                break;
                              case 1: // "Online"
                                _selectedItem1_converted = '0';
                                break;
                              case 2: // "Offline"
                                _selectedItem1_converted = '1';
                                break;
                              case 3: // "Fault"
                                _selectedItem1_converted = '2';
                                break;
                              case 4: // "Standby"
                                _selectedItem1_converted = '3';
                                break;
                              case 5: // "Alarm"
                                _selectedItem1_converted = '4';
                                break;
                            }
                          });
                        },
                        buttonStyleData: ButtonStyleData(
                          height: 30,
                          padding: const EdgeInsets.only(left: 14, right: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(7),
                            // border: Border.all(
                            //   color: Colors.black26,
                            // ),
                            color: Theme.of(context).primaryColor,
                          ),
                          elevation: 2,
                        ),
                        iconStyleData: const IconStyleData(
                          icon: Icon(
                            Icons.arrow_drop_down,
                          ),
                          iconSize: 14,
                          iconEnabledColor: Colors.yellow,
                          iconDisabledColor: Colors.grey,
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Theme.of(context).primaryColor,
                          ),
                          offset: const Offset(-20, 0),
                          scrollbarTheme: ScrollbarThemeData(
                            radius: const Radius.circular(40),
                            thickness: WidgetStateProperty.all<double>(6),
                            thumbVisibility:
                                WidgetStateProperty.all<bool>(true),
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(
                          height: 40,
                          padding: EdgeInsets.only(left: 14, right: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            widget.PlantID != null
                ? Padding(
                    padding: const EdgeInsets.only(top: 50.0),
                    child: FutureBuilder<Map<String, dynamic>>(
                        future: DevicesofplantQuery(context,
                            status: _selectedItem1_converted,
                            devicetype: _selectedItem_converted,
                            PID: widget.PlantID!),
                        builder: (BuildContext context, snapshot) {
                          final PSinfo = snapshot.data;

                          // var Data = snapshot.data;
                          //Response PSinfo = Response.fromJson(snapshot.data!);

                          switch (snapshot.connectionState) {
                            case ConnectionState.waiting:
                              return Center(child: CircularProgressIndicator());
                            default:
                              if (snapshot.hasError) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                      child: Text('Error',
                                          style: TextStyle(
                                              fontSize: 0.025 * width,
                                              fontWeight: FontWeight.bold))),
                                );
                              } else if (PSinfo?['err'] == 8) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                      child: Text(
                                          'Rejection (Try from the plant owner or distributor or equipment manufacturer account, other roles rejected)}',
                                          maxLines: 2,
                                          style: TextStyle(
                                              fontSize: 0.025 * width,
                                              fontWeight: FontWeight.bold))),
                                );
                              } else if (PSinfo?['err'] == 260) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                      child: Text(
                                          AppLocalizations.of(context)!
                                              .power_station_not_found,
                                          style: TextStyle(
                                              fontSize: 0.025 * width,
                                              fontWeight: FontWeight.bold))),
                                );
                              } else if (PSinfo?['err'] == 404) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                      child: Text(
                                          AppLocalizations.of(context)!
                                              .no_response_from_server,
                                          style: TextStyle(
                                              fontSize: 0.025 * width,
                                              fontWeight: FontWeight.bold))),
                                );
                              } else if (PSinfo?['err'] == 504) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                      child: Text(
                                          AppLocalizations.of(context)!
                                              .no_response_from_server,
                                          style: TextStyle(
                                              fontSize: 0.025 * width,
                                              fontWeight: FontWeight.bold))),
                                );
                              } else if (PSinfo?['err'] == 258) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                      child: Text(
                                          AppLocalizations.of(context)!
                                              .device_not_found,
                                          style: TextStyle(
                                              fontSize: 0.025 * width,
                                              fontWeight: FontWeight.bold))),
                                );
                              } else if (PSinfo?['err'] == 260) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                      child: Text(
                                          AppLocalizations.of(context)!
                                              .power_station_not_found,
                                          style: TextStyle(
                                              fontSize: 0.025 * width,
                                              fontWeight: FontWeight.bold))),
                                );
                              } else if (PSinfo?['err'] == 257) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                      child: Text(
                                          AppLocalizations.of(context)!
                                              .collector_not_found,
                                          style: TextStyle(
                                              fontSize: 0.025 * width,
                                              fontWeight: FontWeight.bold))),
                                );
                              } else if (PSinfo?['err'] == 12) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                      child: Text(
                                          AppLocalizations.of(context)!
                                              .no_record_found,
                                          style: TextStyle(
                                              fontSize: 0.025 * width,
                                              fontWeight: FontWeight.bold))),
                                );
                              } else if (PSinfo?['dat']['device'] != null) {
                                /// If response is from Devices Query
                                DevicesofPlant DevicesQueryResponse =
                                    DevicesofPlant.fromJson(PSinfo!);
                                return buildDevicesList(
                                    DevicesQueryResponse, width, height);
                              } else if (PSinfo?['dat']['collector'] != null) {
                                CollectorsinfoofPlant CINFO =
                                    CollectorsinfoofPlant.fromJson(PSinfo!);
                                return buildCollectorsList(
                                    CINFO, width, height);
                              } else {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                      child: Text(
                                          'Unhandled Exception'.toUpperCase(),
                                          style: TextStyle(
                                              fontSize: 0.025 * width,
                                              fontWeight: FontWeight.bold))),
                                );
                              }
                          }
                        }))
                : Container()
          ],
        ),
      ),
    );
  }

  Widget buildDevicesList(DevicesofPlant psinfo, double width, double height) {
    return ListView.builder(
        physics: BouncingScrollPhysics(),
        itemCount: psinfo.dat!.device?.length,
        itemBuilder: (context, index) {
          final PSINFO = psinfo.dat?.device?[index];

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            decoration: new BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset('assets/controller.png',
                    height: 80, width: 70, fit: BoxFit.fill),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('PN: ${PSINFO?.pn}',
                      style: TextStyle(
                        fontSize: 0.025 * (height - width),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      )),
                  Text('SN: ${PSINFO?.sn}',
                      style: TextStyle(
                        fontSize: 0.025 * (height - width),
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      )),
                ],
              ),
              subtitle: Column(
                children: [
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.device_type,
                          style: TextStyle(
                            fontSize: 0.022 * (height - width),
                            fontWeight: FontWeight.normal,
                            color: Colors.black87,
                          )),
                      Text(
                          '${(PSINFO?.devcode == 530) ? 'Inverter' : (PSINFO?.devcode == 768) ? 'Env-monitor' : (PSINFO?.devcode == 1024) ? 'Smart meter' : (PSINFO?.devcode == 1280) ? 'Combining manifolds' : (PSINFO?.devcode == 1536) ? 'Camera' : (PSINFO?.devcode == 1792) ? 'Battery' : (PSINFO?.devcode == 2048) ? 'Charger' : (PSINFO?.devcode == 2304 || PSINFO?.devcode == 2452 || PSINFO?.devcode == 2449 || PSINFO?.devcode == 2400) ? 'Energy storage machine' : (PSINFO?.devcode == 2560) ? 'Anti-islanding' : (PSINFO?.devcode == -1) ? 'Datalogger' : PSINFO?.devcode}',
                          style: TextStyle(
                            fontSize: 0.025 * (height - width),
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          )),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.alias,
                          style: TextStyle(
                            fontSize: 0.022 * (height - width),
                            fontWeight: FontWeight.normal,
                            color: Colors.black87,
                          )),
                      Text('${PSINFO?.alias}',
                          style: TextStyle(
                              fontSize: 0.025 * (height - width),
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.address_upper,
                          style: TextStyle(
                            fontSize: 0.022 * (height - width),
                            fontWeight: FontWeight.normal,
                            color: Colors.black87,
                          )),
                      Text('${PSINFO?.devaddr}',
                          style: TextStyle(
                              fontSize: 0.025 * (height - width),
                              fontWeight: FontWeight.normal,
                              color: Colors.blue)),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.status_upper,
                          style: TextStyle(
                            fontSize: 0.022 * (height - width),
                            fontWeight: FontWeight.normal,
                            color: Colors.black87,
                          )),
                      Text(
                          (PSINFO?.status == 0)
                              ? AppLocalizations.of(context)!.online
                              : (PSINFO?.status == 1)
                                  ? AppLocalizations.of(context)!.offline
                                  : (PSINFO?.status == 2)
                                      ? AppLocalizations.of(context)!.fault
                                      : (PSINFO?.status == 3)
                                          ? AppLocalizations.of(context)!
                                              .standby
                                          : AppLocalizations.of(context)!.alarm,
                          style: TextStyle(
                            fontSize: 0.028 * (height - width),
                            fontWeight: FontWeight.bold,
                            color: PSINFO?.status == 0
                                ? Colors.green
                                : PSINFO?.status == 1
                                    ? Colors.red
                                    : Colors.orange,
                          )),
                    ],
                  ),
                  SizedBox(height: 2),
                  SizedBox(height: 1),
                  Row(children: [
                    Text(AppLocalizations.of(context)!.plant_upper,
                        style: TextStyle(
                          fontSize: 0.022 * (height - width),
                          fontWeight: FontWeight.normal,
                          color: Colors.black87,
                        )),
                    Text('${widget.Plantname}'.toUpperCase(),
                        style: TextStyle(
                            fontSize: 0.023 * (height - width),
                            fontWeight: FontWeight.bold,
                            color: Colors.blue)),
                  ]),
                ],
              ),
              trailing: Icon(Icons.arrow_right),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => deviceinfopage(
                          PID: PSINFO?.pid,
                          PN: PSINFO?.pn,
                          SN: PSINFO?.sn,
                          Plantname: widget.Plantname,
                          status: PSINFO?.status,
                          devcode: PSINFO?.devcode,
                          devaddr: PSINFO?.devaddr,
                          alias: PSINFO?.alias,
                        )));
              },
            ),
          );
        });
  }

  ///////////////////////////////////For Collectors List//////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////////////////
  Widget buildCollectorsList(
      CollectorsinfoofPlant psinfo, double width, double height) {
    return ListView.builder(
        physics: BouncingScrollPhysics(),
        itemCount: psinfo.dat!.collector?.length,
        itemBuilder: (context, index) {
          final PSINFO = psinfo.dat?.collector?[index];

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            decoration: new BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              boxShadow: [
                BoxShadow(
                  color: PSINFO?.status == 0
                      ? Colors.green.withOpacity(0.5)
                      : Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.asset('assets/logger.png',
                    height: 80, width: 70, fit: BoxFit.fill),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.alias,
                          style: TextStyle(
                            fontSize: 0.025 * (height - width),
                            fontWeight: FontWeight.normal,
                            color: Colors.black87,
                          )),
                      PSINFO?.alias == null
                          ? Text(AppLocalizations.of(context)!.datalogger,
                              style: TextStyle(
                                fontSize: 0.025 * (height - width),
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ))
                          : Text('${PSINFO?.alias}',
                              style: TextStyle(
                                fontSize: 0.028 * (height - width),
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              )),
                    ],
                  ),
                  SizedBox(height: 3),
                  Text('PN: ${PSINFO?.pn}',
                      style: TextStyle(
                        fontSize: 0.028 * (height - width),
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      )),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2),
                  Text(
                      AppLocalizations.of(context)!
                          .load(PSINFO?.load as Object),
                      style: TextStyle(
                        fontSize: 0.028 * (height - width),
                        fontWeight: FontWeight.normal,
                        color: Colors.black,
                      )),
                  SizedBox(height: 1),
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.status_upper,
                          style: TextStyle(
                            fontSize: 0.028 * (height - width),
                            fontWeight: FontWeight.normal,
                            color: Colors.black87,
                          )),
                      Text(
                          (PSINFO?.status == 0)
                              ? AppLocalizations.of(context)!.online
                              : (PSINFO?.status == 1)
                                  ? AppLocalizations.of(context)!.offline
                                  : (PSINFO?.status == 2)
                                      ? AppLocalizations.of(context)!.fault
                                      : (PSINFO?.status == 3)
                                          ? AppLocalizations.of(context)!
                                              .standby
                                          : (PSINFO?.status == 4)
                                              ? AppLocalizations.of(context)!
                                                  .warning
                                              : (PSINFO?.status == 5)
                                                  ? 'ERROR'
                                                  : 'Protocol error',
                          style: TextStyle(
                            fontSize: 0.03 * (height - width),
                            fontWeight: FontWeight.bold,
                            color: (PSINFO?.status == 0)
                                ? Colors.green
                                : Colors.red,
                          )),
                    ],
                  ),
                  SizedBox(height: 2),
                  PSINFO?.Signal == null || PSINFO?.Signal == 0
                      ? Container()
                      : Row(
                          children: [
                            Text(AppLocalizations.of(context)!.signal_upper,
                                style: TextStyle(
                                  fontSize: 0.028 * (height - width),
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                )),
                            RatingBarIndicator(
                              rating: PSINFO!.Signal! / 20,
                              itemBuilder: (context, index) => Icon(
                                Icons.circle,
                                color: PSINFO.Signal! <= 20
                                    ? Colors.red
                                    : PSINFO.Signal! <= 60
                                        ? Colors.orange
                                        : Colors.green,
                              ),
                              itemCount: 5,
                              itemSize: 10.0,
                              unratedColor: Colors.grey.withAlpha(50),
                              direction: Axis.horizontal,
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Text("${PSINFO.Signal!} %",
                                style: TextStyle(
                                  fontSize: 0.025 * (height - width),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                )),
                          ],
                        ),
                ],
              ),
              trailing: Icon(Icons.arrow_right),
              onTap: () async {
                await loadCollectorDevicesStatusQuery(PSINFO!.pn.toString());

                // if (collector_ps_info == null) {
                //   Fluttertoast.showToast(
                //     msg: AppLocalizations.of(context)!.device_not_found,
                //     toastLength: Toast.LENGTH_SHORT,
                //     gravity: ToastGravity.CENTER,
                //     timeInSecForIosWeb: 2,
                //     textColor: Colors.white,
                //     fontSize: 15.0);
                //   return;
                // }
                // Navigator.of(context).push(MaterialPageRoute(
                //     builder: (BuildContext context) => deviceinfopage(
                //           PN: collector_ps_info?.pn,
                //           SN: collector_ps_info?.sn,
                //           status: collector_ps_info?.status,
                //           devcode: collector_ps_info?.devcode,
                //           devaddr: collector_ps_info?.devaddr,
                //           alias: collector_ps_info?.devalias,
                //           PID: collector_ps_info?.pid,
                //           load: PSINFO.load,
                //           Plantname: widget.Plantname,
                //           firmware: PSINFO.firmware,
                //           outputpower: collector_ps_info?.outpower,
                //           energytoday: collector_ps_info?.energyToday,
                //           energytotal: collector_ps_info?.energyTotal,
                //           energyyear: collector_ps_info?.energyYear,
                //         )));

                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => collectorinfopage(
                          Pn: PSINFO.pn,
                          Alias: PSINFO.alias,
                          status: PSINFO.status,
                          datafetch: PSINFO.datFetch,
                          load: PSINFO.load,
                          Firmware: PSINFO.firmware,
                          PID: PSINFO.pid,
                          plantname: widget.Plantname,
                          signal: PSINFO.Signal,
                          descx: PSINFO.descx,
                        )));
              },
            ),
          );
        });
  }

  Future loadCollectorDevicesStatusQuery(String pn) async {
    EasyLoading.show();
    // setState(() { isLoading = true; });
    final data = await CollectorDevicesStatusQuery(PN: pn);

    final data2 = CollectorDevicesStatus.fromJson(data).dat?.device?[0];

    setState(() {
      collector_ps_info = data2;
      // isLoading = false;
    });

    EasyLoading.dismiss();
  }

  Future update_device_list() async {
    Future.delayed(Duration(seconds: 1), () {
      setState(() async {});
    });
  }

  ///end of Devicestate
}
