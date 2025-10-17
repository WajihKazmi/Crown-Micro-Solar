import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crownmonitor/Models/Powerstation_Query_Response.dart';
import 'package:crownmonitor/fontsizes.dart';
import 'package:crownmonitor/pages/createpowerstat.dart';
import 'package:crownmonitor/pages/mainscreen.dart';
import 'package:crownmonitor/pages/plant.dart' as plantspage;
import 'package:crypto/crypto.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:awesome_dropdown/awesome_dropdown.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Lists extends StatefulWidget {
  const Lists({Key? key}) : super(key: key);

  @override
  _ListsState createState() => _ListsState();
}

class _ListsState extends State<Lists> {
  late TextEditingController name = new TextEditingController();
  late TextEditingController search = new TextEditingController();
  late TextEditingController PlantName = new TextEditingController();
  late TextEditingController remarks = new TextEditingController();

  int _value = 1;
  // final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  bool _isBackPressedOrTouchedOutSide = false,
      _isDropDownOpened = false,
      _isPanDown = false;
  bool _isBackPressedOrTouchedOutSide1 = false,
      _isDropDownOpened1 = false,
      _isPanDown1 = false;
  late List<String> _list;
  String _selectedItem = '';
  late List<String> _list1;
  String _selectedItem1 = '';

  ///for all plants we used 5
  int _selectedItem_converted = 5;
  String _selectedItem1_converted = 'ascPlantName';

  @override
  void initState() {
    _list = [
      "All Plant",
      "Normal plant",
      "Alarm plant",
      "Attention plant",
      "Offline plant"
    ];
    _selectedItem = 'All Plant';
    _list1 = [
      "Plant Name A-Z",
      "Plant Name Z-A",
      "Sort by Earliest time",
      "Sort by Latest time",
      "Power station status Ascending",
      "Power station status Descending"
    ];
    _selectedItem1 = 'Plant Name A-Z';

    super.initState();
  }

  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    if (mounted) {
      super.setState(fn);
    }
  }

  AddPlantNew({
    required String PlantnNAME,
    required String? REMARKS,
  }) async {
    print(PlantnNAME);
    print(REMARKS);
    var jsonResponse = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final Secret = prefs.getString('Secret') ?? '';
    String salt = "12345678";

    //new
    String action =
        "&action=addPlantEs&source=1&name=$PlantnNAME&remark=$REMARKS";
    print(action);

    var data = salt + Secret + token + action;
    var output = utf8.encode(data);
    var sign = sha1.convert(output).toString();
    //print('Sign: $sign');
    String url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
            action;

    print("url");

    try {
      await http.get(Uri.parse(url)).then((response) {
        if (response.statusCode == 200) {
          jsonResponse = json.decode(response.body);
          if (jsonResponse['err'] == 0) {
            // showMessage('Success', 'Power Station Created Successfully.', true);
            Fluttertoast.showToast(
                msg: "Plant Added Successfully.",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
            setState(() {});
          } else {
            // showMessage('Error', '${jsonResponse['desc'].toString()}', true);
            Fluttertoast.showToast(
                msg: "${jsonResponse['desc'].toString()}",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
            setState(() {});
          }
        }
        print('APIrequest response : ${jsonResponse}');
        print('APIrequest statucode : ${response.statusCode}');
      });
    } catch (e) {
      print(e);
    }
    ////////////// Posting createpowerstation request with query parameters and handling response ////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    Widget Addplant = ElevatedButton(
        child: Text("Add"),
        onPressed: () async {
          // print(PlantName.text);
          // print(remarks.text);
          await AddPlantNew(PlantnNAME: PlantName.text, REMARKS: remarks.text);
        });
    Widget CancelButton = ElevatedButton(
      child: Text("Cancel"),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop();
      },
    );
    return GestureDetector(
      onTap: _removeFocus,
      onPanDown: (focus) {
        _isPanDown = true;
        _isPanDown1 = true;
        _removeFocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          centerTitle: false,
          automaticallyImplyLeading: false,
          // actions: [
          //   TextButton(
          //       onPressed: () async {
          //         showDialog(
          //             context: context,
          //             builder: (_) => AlertDialog(
          //                   title: Text(
          //                     "Add Plant",
          //                     style: TextStyle(
          //                         fontSize: 20, fontWeight: FontWeight.w500),
          //                   ),
          //                   content: Column(
          //                       mainAxisSize: MainAxisSize.min,
          //                       children: [
          //                         TextField(
          //                           onSubmitted: (String value) {
          //                             setState(() {
          //                               PlantName.text = value;
          //                             });
          //                           },
          //                           controller: PlantName,
          //                           decoration: new InputDecoration(
          //                             contentPadding: EdgeInsets.all(10),
          //                             fillColor: Colors.white,
          //                             filled: true,
          //                             hintText: 'Enter Plant Name',
          //                             enabledBorder: const OutlineInputBorder(
          //                               borderRadius: BorderRadius.all(
          //                                   Radius.circular(10.0)),
          //                               borderSide: const BorderSide(
          //                                 color: Colors.grey,
          //                               ),
          //                             ),
          //                             focusedBorder: OutlineInputBorder(
          //                               borderRadius: BorderRadius.all(
          //                                   Radius.circular(10.0)),
          //                               // borderSide: BorderSide(color: Colo),
          //                             ),
          //                           ),
          //                           style:
          //                               Theme.of(context).textTheme.headline3,
          //                           textAlignVertical: TextAlignVertical.center,
          //                         ),
          //                         SizedBox(
          //                           height: 5,
          //                         ),
          //                         TextField(
          //                           onSubmitted: (String value) {
          //                             setState(() {
          //                               remarks.text = value;
          //                             });
          //                           },
          //                           controller: remarks,
          //                           decoration: new InputDecoration(
          //                             contentPadding: EdgeInsets.all(10),
          //                             fillColor: Colors.white,
          //                             filled: true,
          //                             hintText: 'Enter Remarks (optional)',
          //                             enabledBorder: const OutlineInputBorder(
          //                               borderRadius: BorderRadius.all(
          //                                   Radius.circular(10.0)),
          //                               borderSide: const BorderSide(
          //                                 color: Colors.grey,
          //                               ),
          //                             ),
          //                             focusedBorder: OutlineInputBorder(
          //                               borderRadius: BorderRadius.all(
          //                                   Radius.circular(10.0)),
          //                               // borderSide: BorderSide(color: Colo),
          //                             ),
          //                           ),
          //                           style:
          //                               Theme.of(context).textTheme.headline3,
          //                           textAlignVertical: TextAlignVertical.center,
          //                         ),
          //                       ]),
          //                   actions: [
          //                     Addplant,
          //                     CancelButton,
          //                   ],
          //                 ));

          //         Navigator.push(
          //             context,
          //             MaterialPageRoute(
          //                 builder: (context) => CreatePowerStation()));
          //       },
          //       child: Column(
          //         mainAxisAlignment: MainAxisAlignment.center,
          //         children: [
          //           Icon(
          //             Icons.add_circle_outline,
          //             color: Colors.white,
          //             size: 18,
          //           ),
          //           SizedBox(height: 3),
          //           Text('Add Plant',
          //               style: TextStyle(
          //                   color: Colors.white,
          //                   fontSize: 0.025 * (height - width),
          //                   fontWeight: FontWeight.bold)),
          //         ],
          //       ))
          // ],
          title: Container(
            height: 30,
            width: width,
            child: TextField(
              onSubmitted: (String value) {
                setState(() {
                  search.text = value;
                });
              },
              controller: search,
              decoration: new InputDecoration(
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.white,
                filled: true,
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.black,
                ),
                hintText: 'Please Enter Plant Name',
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  borderSide: const BorderSide(
                    color: Colors.white,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  // borderSide: BorderSide(color: Colo),
                ),
              ),
              style: Theme.of(context).textTheme.bodySmall,
              textAlignVertical: TextAlignVertical.center,
            ),
          ),
        ),
        body: Container(
          height: height,
          child: Stack(
            children: <Widget>[
              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              // color: Colors.grey,
                              width: width,
                              child: Row(
                                children: [],
                              ),
                            ),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: width / 2.2,
                    // color: Colors.white,
                    child: AwesomeDropDown(
                      isPanDown: _isPanDown,
                      isBackPressedOrTouchedOutSide:
                          _isBackPressedOrTouchedOutSide,
                      padding: 0,
                      dropDownIcon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.black,
                        size: 30,
                      ),
                      elevation: 0,
                      dropDownBorderRadius: 1,
                      dropDownTopBorderRadius: 1,
                      dropDownBottomBorderRadius: 1,
                      dropDownIconBGColor: Colors.transparent,
                      dropDownOverlayBGColor: Colors.transparent,
                      dropDownBGColor: Colors.transparent,
                      dropDownList: _list,
                      selectedItem: _selectedItem,
                      numOfListItemToShow: 5,
                      selectedItemTextStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 0.025 * (height - width),
                        fontWeight: FontWeight.bold,
                      ),
                      dropDownListTextStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 0.025 * (height - width),
                          fontWeight: FontWeight.w300,
                          backgroundColor: Colors.transparent),
                      onDropDownItemClick: (selectedItem) {
                        setState(() {
                          _selectedItem = selectedItem;
                          switch (_selectedItem) {
                            case "All Plant":
                              {
                                _selectedItem_converted = 5;
                              }
                              break;
                            case "Normal plant":
                              {
                                _selectedItem_converted = 0;
                              }
                              break;
                            case "Alarm plant":
                              {
                                _selectedItem_converted = 4;
                              }
                              break;
                            case "Attention plant":
                              {
                                _selectedItem_converted = 7;
                              }
                              break;
                            case "Offline plant":
                              {
                                _selectedItem_converted = 1;
                              }
                              break;
                          }
                        });
                      },
                      dropStateChanged: (isOpened) {
                        _isDropDownOpened = isOpened;

                        if (!isOpened) {
                          _isBackPressedOrTouchedOutSide = false;
                        }
                      },
                    ),
                  ),
                  Container(
                    width: width / 2.2,
                    // color: Colors.white,
                    child: AwesomeDropDown(
                      isPanDown: _isPanDown1,
                      isBackPressedOrTouchedOutSide:
                          _isBackPressedOrTouchedOutSide1,
                      padding: 0,
                      dropDownIcon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.black,
                        size: 26,
                      ),
                      elevation: 0,
                      dropDownBorderRadius: 1,
                      dropDownTopBorderRadius: 1,
                      dropDownBottomBorderRadius: 1,
                      dropDownIconBGColor: Colors.transparent,
                      dropDownOverlayBGColor: Colors.transparent,
                      dropDownBGColor: Colors.transparent,
                      dropDownList: _list1,
                      selectedItem: _selectedItem1,
                      numOfListItemToShow: 8,
                      selectedItemTextStyle: TextStyle(
                        color: Colors.black,
                        fontSize: 0.025 * (height - width),
                        fontWeight: FontWeight.bold,
                      ),
                      dropDownListTextStyle: TextStyle(
                          color: Colors.black,
                          fontSize: 0.025 * (height - width),
                          fontWeight: FontWeight.w300,
                          backgroundColor: Colors.transparent),
                      onDropDownItemClick: (selectedItem1) {
                        setState(() {
                          _selectedItem1 = selectedItem1;
                          switch (_selectedItem1) {
                            case "Plant Name A-Z":
                              {
                                _selectedItem1_converted = 'ascPlantName';
                              }
                              break;
                            case "Plant Name Z-A":
                              {
                                _selectedItem1_converted = 'descPlantName';
                              }
                              break;
                            case "Sort by Earliest time":
                              {
                                _selectedItem1_converted = 'ascInstall';
                              }
                              break;
                            case "Sort by Latest time":
                              {
                                _selectedItem1_converted = 'descInstall';
                              }
                              break;
                            case "Power station status Ascending":
                              {
                                _selectedItem1_converted = 'ascStatus';
                              }
                              break;
                            case "Power station status Descending":
                              {
                                _selectedItem1_converted = 'descStatus';
                              }
                              break;
                          }
                        });
                      },
                      dropStateChanged: (isOpened1) {
                        _isDropDownOpened1 = isOpened1;
                        _isBackPressedOrTouchedOutSide = false;

                        if (!isOpened1) {
                          _isBackPressedOrTouchedOutSide1 = false;
                        }
                      },
                    ),
                  ),
                ],
              ),
              Padding(
                  padding: const EdgeInsets.only(top: 50.0),
                  child: FutureBuilder<Map<String, dynamic>>(
                      future: ListofPowerStationQuery(context,
                          status: _selectedItem_converted,
                          orderby: _selectedItem1_converted,
                          Plantname: search.text),
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
                                        'Rejectied'
                                        '(Try from the plant owner or distributor or equipment'
                                        'manufacturer account, other roles rejected)}',
                                        style: TextStyle(
                                            fontSize: 0.025 * width,
                                            fontWeight: FontWeight.bold))),
                              );
                            } else if (PSinfo?['err'] == 260) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                    child: Text('Power Station Not Found',
                                        style: TextStyle(
                                            fontSize: 0.025 * width,
                                            fontWeight: FontWeight.bold))),
                              );
                            } else if (PSinfo?['err'] == 404) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                    child: Text('No Response From Server',
                                        style: TextStyle(
                                            fontSize: 0.025 * width,
                                            fontWeight: FontWeight.bold))),
                              );
                            } else if (PSinfo?['err'] == 12) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                    child: Text('No Record Found',
                                        style: TextStyle(
                                            fontSize: 0.025 * width,
                                            fontWeight: FontWeight.bold))),
                              );
                            } else if (PSinfo?['err'] == 504) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                    child: Text(
                                        'Request Timeout (Refresh the list)',
                                        style: TextStyle(
                                            fontSize: 0.025 * width,
                                            fontWeight: FontWeight.bold))),
                              );
                            } else {
                              Response PSinfo =
                                  Response.fromJson(snapshot.data!);

                              return buildPlantList(PSinfo, width, height);
                            }
                        }
                      }))
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPlantList(Response psinfo, double width, double height) {
    return ListView.builder(
        physics: BouncingScrollPhysics(),
        itemCount: psinfo.dat!.plant?.length,
        itemBuilder: (context, index) {
          final PSINFO = psinfo.dat?.plant?[index];
          print('object ${PSINFO?.picSmall}');

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
            child: Column(
              children: [
                ListTile(
                  minLeadingWidth: 2,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: (PSINFO!.picSmall!.contains('https://'))
                        ? CachedNetworkImage(
                            imageUrl: PSINFO.picSmall!,
                            fit: BoxFit.fill,
                            height: height / 8,
                            width: width / 6,
                            placeholder: (_, s) => CircularProgressIndicator(),
                          )
                        : Image.asset('assets/PS.jpg',
                            height: 90, width: 70, fit: BoxFit.fill),
                  ),
                  title: Text('${PSINFO!.name}'.toUpperCase(),
                      style: TextStyle(
                        fontSize: 0.03 * (height - width),
                        fontWeight: FontWeight.bold,
                        fontFamily: "Roboto",
                        letterSpacing: 1,
                        color: Colors.black,
                      )),
                  subtitle: Column(
                    children: [
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Text('Current Power: '.toUpperCase(),
                              style: TextStyle(
                                fontSize: 0.02 * (height - width),
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              )),
                          Text(
                              '${double.parse(PSINFO.Currentoutputpower!).toStringAsFixed(2)}'
                              ' kW',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 0.025 * (height - width),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue)),
                        ],
                      ),
                      SizedBox(height: 1),
                      Row(
                        children: [
                          Text('Plant Capacity: '.toUpperCase(),
                              style: TextStyle(
                                fontSize: 0.02 * (height - width),
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              )),
                          Text(
                              '${double.parse(PSINFO.nominalPower!).toStringAsFixed(2)}'
                              ' kW',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 0.025 * (height - width),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue)),
                        ],
                      ),
                      SizedBox(height: 1),
                      Row(
                        children: [
                          Text('Total Power:     '.toUpperCase(),
                              style: TextStyle(
                                fontSize: 0.02 * (height - width),
                                fontWeight: FontWeight.normal,
                                color: Colors.black,
                              )),
                          Text(
                              '${double.parse(PSINFO.Totalpower!).toStringAsFixed(2)}'
                              ' kWh',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 0.025 * (height - width),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue)),
                        ],
                      ),
                      SizedBox(height: 1),
                      Row(
                        children: [
                          Text('Installation Date: '.toUpperCase(),
                              style: TextStyle(
                                fontSize: 0.02 * (height - width),
                                fontWeight: FontWeight.normal,
                                color: Colors.black87,
                              )),
                          Text(
                              '${DateFormat.yMd().add_jm().format(PSINFO.install!)}',
                              style: TextStyle(
                                  fontSize: 0.025 * (height - width),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue)),
                        ],
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_right),
                  onTap: () {
                    //  Navigator.pushAndRemoveUntil(
                    // context,
                    // MaterialPageRoute(builder: (context) => Lists()),
                    // (route) => false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (BuildContext context) => plantspage.Plant(
                                Plantname: PSINFO.name,
                                Plant_status: PSINFO.status.toString(),
                                Country: 'sdsadasd',
                                province: PSINFO.address?.province,
                                City: PSINFO.address?.city,
                                County: PSINFO.address?.county,
                                town: PSINFO.address?.town,
                                village: PSINFO.address?.village,
                                address: PSINFO.address?.address,
                                lon: PSINFO.address?.lon,
                                lat: PSINFO.address?.lat,
                                timezone: PSINFO.address?.timezone.toString(),
                                Unitprofit: PSINFO.profit?.unitProfit,
                                currency: PSINFO.profit?.currency,
                                coalsaved: PSINFO.profit?.coal,
                                so2emission: PSINFO.profit?.so2,
                                co2emission: PSINFO.profit?.co2,
                                DesignCompany: PSINFO.designCompany,
                                DesignPower: double.parse(PSINFO.nominalPower!),
                                Annual_Planned_Power:
                                    double.parse(PSINFO.energyYearEstimate!),
                                picbig: PSINFO.picBig,
                                picsmall: PSINFO.picSmall,
                                installed_date: PSINFO.install,
                                Average_troublefree_operationtime: 0,
                                Continuous_troublefree_operationtime: 0,
                                PlantID: PSINFO.pid.toString(),
                              )),
                    );
                  },
                ),
                // Divider(),
                // Container(
                //   color: Colors.white54,
                //   child: Card(
                //     elevation: 5,
                //     color: Colors.grey.shade100,
                //     child: Padding(
                //       padding: const EdgeInsets.all(5.0),
                //       child: Row(
                //         mainAxisAlignment: MainAxisAlignment.center,
                //         children: [
                //           Text('Status: '.toUpperCase(),
                //               style: TextStyle(
                //                   fontSize: 0.024 * (height - width),
                //                   fontWeight: FontWeight.bold,
                //                   color: Colors.grey)),
                //           Text(
                //               (PSINFO?.status == 0)
                //                   ? 'Online'.toUpperCase()
                //                   : (PSINFO?.status == 1)
                //                       ? 'Offline'.toUpperCase()
                //                       : (PSINFO?.status == 2)
                //                           ? 'Fault'.toUpperCase()
                //                           : (PSINFO?.status == 3)
                //                               ? 'Standby'.toUpperCase()
                //                               : 'Alarm'.toUpperCase(),
                //               style: TextStyle(
                //                 fontSize: 0.028 * (height - width),
                //                 fontWeight: FontWeight.bold,
                //                 color: (PSINFO?.status == 0)
                //                     ? Colors.green
                //                     : Colors.red,
                //               )),
                //         ],
                //       ),
                //     ),
                //   ),
                // )
              ],
            ),
          );
        });
  }

  void _removeFocus() {
    if (_isDropDownOpened) {
      setState(() {
        _isBackPressedOrTouchedOutSide = true;
      });
    }
    if (_isDropDownOpened1) {
      setState(() {
        _isBackPressedOrTouchedOutSide1 = true;
      });
    }
  }
}
