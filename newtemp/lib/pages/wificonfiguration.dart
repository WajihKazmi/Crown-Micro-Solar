import 'dart:async';
import 'dart:developer';

import 'package:app_settings/app_settings.dart';
import 'package:crownmonitor/fontsizes.dart';
// import 'package:esptouch_flutter/esptouch_flutter.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:location/location.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart' as PH;

import 'Webview.dart';
import 'login.dart';

final TextEditingController wifiname = TextEditingController();
final TextEditingController wifibssid = TextEditingController();

class Wificonfiguration extends StatefulWidget {
  @override
  WificonfigurationState createState() {
    return WificonfigurationState();
  }
}

class WificonfigurationState extends State<Wificonfiguration> {
  //////////////////////////////////////
  //>>>>>>>>//// WifiInfo _wifiInfo = WifiInfo();
  // final TextEditingController wifiname = TextEditingController();
  final TextEditingController wifipassword =
      TextEditingController(text: 'ahmed.saad316');
  var _isSucceed = false;
  bool hidepassword = true;

  final NetworkInfo _networkinfo = NetworkInfo();
  String? wifiName;
  late Timer wifissidtimer;
  Location location = new Location();

  checklocationservice() async {
    var serviceenabled = await location.serviceEnabled();
    if (!serviceenabled) {
      serviceenabled = await location.requestService();
      if (!serviceenabled) {
        return;
      }
    }
 }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    wifissidtimer.cancel();
  }

  @override
  void initState() {
    super.initState();
    // initPlatformState();
    checklocationservice();
    Requestpermission();
    wifissidtimer = Timer.periodic(Duration(seconds: 2), (t) {
      checkWifiConnectivity();
    });
  }

  Requestpermission() async {
    var status = await location.hasPermission();
  // log("connection status: ${status.toString()}");
    log("connection status: ${status.toString()}");

    switch (status) {
      case PermissionStatus.denied:
        // TODO: Handle this case.

        await location.requestPermission();

        Requestpermission();

        break;
      case PermissionStatus.granted:
        print("permission grandted");
        // TODO: Handle this case.
        break;
      
      case PermissionStatus.deniedForever:
        print('PermissionStatus.denied forever');
        await location.requestPermission();
        await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text(
                    "Need Location Permission",
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                  content: Text(
                    "Please provide location permission in order to setup the device properly.",
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          "Close",
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        )),
                    TextButton(
                        onPressed: () async {
                          await PH.openAppSettings();
                        },
                        child: Text(
                          "Open Location Settings",
                          style: TextStyle(fontSize: 16, color: Colors.blue),
                        )),
                  ],
                ));

         Requestpermission();
        // TODO: Handle this case.
        break;
        default:
        break;
    }
    ;

    // if (!status) {
    //   await PH.Permission.locationAlways.request();
    // }
    // checkWifiConnectivity();
  }

  checkWifiConnectivity() async {
    wifiName = await _networkinfo.getWifiName();
    setState(() {
      wifiName = this.wifiName;
    });
    log("SSID: ${wifiName.toString()}");
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  // Future<void> initPlatformState() async {
  //   WifiInfo wifiInfo;
  //   // Platform messages may fail, so we use a try/catch PlatformException.
  //   try {
  //     wifiInfo = await WifiConnection.wifiInfo;
  //   } on PlatformException {
  //     return;
  //   }

  //   // If the widget was removed from the tree while the asynchronous platform
  //   // message was in flight, we want to discard the reply rather than calling
  //   // setState to update our non-existent appearance.
  //   if (!mounted) return;

  //   setState(() {
  //     _wifiInfo = wifiInfo;
  //   });
  // }

  //////////////////

  int _activeStepIndex = 0;

  List<Step> stepList(width, height) => [
        Step(
          isActive: _activeStepIndex >= 0,
          state: _activeStepIndex <= 0 ? StepState.indexed : StepState.complete,
          title: Container(
            width: MediaQuery.of(context).size.width / 10,
            child: Column(
              children: [
                Text('Connect WiFi Module',
                    style: TextStyle(
                        fontSize:
                            MediaQuery.of(context).size.height / stepperfont)),
              ],
            ),
          ),
          content: Container(
              width: MediaQuery.of(context).size.width,
              color: Colors.transparent,
              child: Column(
                children: [
                  Text(
                      'Please Connect to the same Wi-Fi as the PN number of the Wi-Fi Module for configuration.',
                      style: Theme.of(context).textTheme.bodyLarge),
                  SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                      width: 200,
                      child: Card(
                          elevation: 5,
                          child:
                              Image(image: AssetImage('assets/PNssid.jpeg')))),
                  SizedBox(
                    height: 20,
                  ),
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: Color.fromARGB(255, 1, 160, 252),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: [
                        Container(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.info, color: Colors.black),
                                  Text(
                                    'How to connect?',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                h3),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    child: Column(
                                      children: [
                                        Text(
                                          '1.Enter the phone system Settings-WLAN',
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  h3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        '2.Select the same Wi-Fi as the Wi-Fi Module PN to connect',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                h3),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        '3.After the connection is successful, return to the APP for network configuration',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                h3),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(40.0),
                      color: Theme.of(context).primaryColor,
                      child: MaterialButton(
                        minWidth: (MediaQuery.of(context).size.width - 60),
                        // padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                        onPressed: () async {
                          // print(_wifiInfo.ssid);
                          //await AppSettings.openWIFISettings();
                          await AppSettings.openAppSettings();

                          // showLoaderDialog1(context);
                        },
                        child: Text(
                          'Open Wifi Settings',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      )),
                  const SizedBox(
                    height: 20,
                  ),
                  Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(40.0),
                      color: Colors.green,
                      child: MaterialButton(
                        minWidth: (MediaQuery.of(context).size.width - 60),
                        // padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                        onPressed: () {
                          {
                            // print(_wifiInfo.ssid);
                            // showLoaderDialog1(context);
                            if (_activeStepIndex <
                                    (stepList(width, height).length - 1) &&
                                wifiName != null) {
                              setState(() {
                                _activeStepIndex += 1;
                              });
                            } else {
                              print('Submited');
                              Fluttertoast.showToast(
                                  msg: "Connect to Wifi first",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                  timeInSecForIosWeb: 2,
                                  textColor: Colors.white,
                                  fontSize: 15.0);
                            }
                          }
                        },
                        child: Text(
                          'Confirm connected to Wi-Fi-Module',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      )),
                ],
              )),
        ),
        // Step(
        //     state:
        //         _activeStepIndex <= 1 ? StepState.indexed : StepState.complete,
        //     isActive: _activeStepIndex >= 1,
        //     title: Container(
        //       width: MediaQuery.of(context).size.width / 10,
        //       child: Column(
        //         children: [
        //           Text('Network Settings',
        //               style: TextStyle(
        //                   fontSize: MediaQuery.of(context).size.height /
        //                       stepperfont)),
        //         ],
        //       ),
        //     ),
        //     content: Container(
        //       child: Column(
        //         children: [
        //           Row(
        //             children: [
        //               Icon(
        //                 Icons.wifi,
        //                 color: Colors.black,
        //                 size: 35,
        //               ),
        //               SizedBox(
        //                 width: 5,
        //               ),
        //               Container(
        //                 width: MediaQuery.of(context).size.width / 1.4,
        //                 child: Column(
        //                   mainAxisAlignment: MainAxisAlignment.center,
        //                   children: [
        //                     Text(
        //                       'Please connect with the wireless router to ensure remote data transmission',
        //                       style: Theme.of(context).textTheme.bodyText1,
        //                       textAlign: TextAlign.left,
        //                     ),
        //                   ],
        //                 ),
        //               )
        //             ],
        //           ),
        //           const SizedBox(
        //             height: 20,
        //           ),
        //           // Text(
        //           //   'Is wifi connected?: $_isSucceed',
        //           //   textAlign: TextAlign.center,
        //           // ),
        //           TextFormField(
        //             style: Theme.of(context).textTheme.bodyText1,
        //             controller: wifiname,
        //             textAlign: TextAlign.center,
        //             decoration: new InputDecoration(
        //               contentPadding: EdgeInsets.all(8),
        //               fillColor: Colors.white,
        //               filled: true,
        //               prefixText: 'Router      ',
        //               prefixStyle: Theme.of(context).textTheme.bodyText1,
        //               hintText: 'Please enter Wi-Fi name',
        //               suffixIcon: InkWell(
        //                   onTap: () {
        //                     showLoaderDialog1(context);
        //                   },
        //                   child: Icon(Icons.wifi, color: Colors.black)),
        //               enabledBorder: const OutlineInputBorder(
        //                 borderRadius: BorderRadius.all(Radius.circular(10.0)),
        //                 borderSide: const BorderSide(
        //                   color: Colors.grey,
        //                 ),
        //               ),
        //               focusedBorder: OutlineInputBorder(
        //                 borderRadius: BorderRadius.all(Radius.circular(10.0)),
        //                 // borderSide: BorderSide(color: Colo),
        //               ),
        //             ),
        //             // decoration: InputDecoration(
        //             //     prefixText: 'Router      ',
        //             //     prefixStyle: Theme.of(context).textTheme.bodyText1,
        //             //     border: InputBorder.none,
        //             //     hintText: 'Please enter Wi-Fi name',
        //             //     hintStyle: Theme.of(context).textTheme.bodyText2,
        //             //     fillColor: Color(0xfff3f3f4),
        //             //     suffixIcon: InkWell(
        //             //         onTap: () {
        //             //           showLoaderDialog1(context);
        //             //         },
        //             //         child: Icon(Icons.wifi, color: Colors.black)),
        //             //     filled: true)),
        //           ),
        //           const SizedBox(
        //             height: 20,
        //           ),
        //           TextFormField(
        //             style: Theme.of(context).textTheme.bodyText1,
        //             controller: wifipassword,
        //             obscureText: hidepassword,
        //             textAlign: TextAlign.center,
        //             decoration: new InputDecoration(
        //               contentPadding: EdgeInsets.all(8),
        //               fillColor: Colors.white,
        //               filled: true,
        //               prefixText: 'Password ',
        //               prefixStyle: Theme.of(context).textTheme.bodyText1,
        //               hintText: 'Please enter password',
        //               suffixIcon: InkWell(
        //                   onTap: () {
        //                     setState(() {
        //                       hidepassword = !hidepassword;
        //                     });
        //                   },
        //                   child: Icon(Icons.password_rounded,
        //                       color: Colors.black)),
        //               enabledBorder: const OutlineInputBorder(
        //                 borderRadius: BorderRadius.all(Radius.circular(10.0)),
        //                 borderSide: const BorderSide(
        //                   color: Colors.grey,
        //                 ),
        //               ),
        //               focusedBorder: OutlineInputBorder(
        //                 borderRadius: BorderRadius.all(Radius.circular(10.0)),
        //                 // borderSide: BorderSide(color: Colo),
        //               ),
        //             ),

        //             // decoration: InputDecoration(
        //             //     prefixText: 'Password ',
        //             //     prefixStyle: Theme.of(context).textTheme.bodyText1,
        //             //     hintText: 'Please enter password',
        //             //     hintStyle: Theme.of(context).textTheme.bodyText2,
        //             //     border: InputBorder.none,
        //             //     fillColor: Color(0xfff3f3f4),
        //             //     suffixIcon:
        //             //         Icon(Icons.password_rounded, color: Colors.black),
        //             //     filled: true)
        //           ),
        //           SizedBox(
        //             height: MediaQuery.of(context).size.width / 10,
        //           ),
        //           Material(
        //               elevation: 5.0,
        //               borderRadius: BorderRadius.circular(40.0),
        //               color: Theme.of(context).primaryColor,
        //               child: MaterialButton(
        //                 minWidth: (MediaQuery.of(context).size.width - 140),
        //                 // padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
        //                 onPressed: () async {
        //                   await _onConnectPressed();
        //                   initPlatformState();
        //                   {
        //                     if (_activeStepIndex < (stepList().length - 1)) {
        //                       setState(() {
        //                         _activeStepIndex += 1;
        //                       });
        //                     } else {
        //                       print('Submited');
        //                     }
        //                   }
        //                 },
        //                 child: Text('Settings',
        //                     style: Theme.of(context).textTheme.subtitle2),
        //               )),
        //         ],
        //       ),
        //     )),
        Step(
            state:
                _activeStepIndex <= 1 ? StepState.indexed : StepState.complete,
            isActive: _activeStepIndex >= 1,
            title: Container(
              width: MediaQuery.of(context).size.width / 10,
              child: Column(
                children: [
                  Text('Configure Wi-Fi Module',
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height /
                              stepperfont)),
                ],
              ),
            ),
            content: Container(
              width: MediaQuery.of(context).size.width,
              color: Colors.transparent,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: Color.fromARGB(255, 1, 160, 252),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: [
                        Container(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.info, color: Colors.black),
                                  SizedBox(
                                    width: width / 120,
                                  ),
                                  Text(
                                    'How to configure WiFi-Module network settings?',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: width / 35),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: width / 80,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          "1.Tapping the 'Network Settings' button below will take you to the",
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize: width / 37),
                                        ),
                                        Text(
                                          "Wi-Fi-Module's configuration page where you can see ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize: width / 37),
                                        ),
                                        Text(
                                          "device's info.",
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize: width / 37),
                                        ),
                                        Center(
                                            child: Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.blue,
                                          size: width / 13,
                                        )),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: width / 85,
                  ),
                  SizedBox(
                      width: width / 2,
                      child: Card(
                          elevation: 5,
                          child: Image(
                              image: AssetImage('assets/deviceinfo.jpeg')))),
                  SizedBox(
                    height: width / 85,
                  ),
                  ////////////////////////////////////////////////////
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: Color.fromARGB(255, 1, 160, 252),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    width: width,
                    child: Column(
                      children: [
                        Container(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        "2.Once there goto 'STA Set' and serach the SSID of the Router you want ",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: width / 40),
                                      ),
                                      Text(
                                        "to connect this device to and enter the router's password and hit apply.",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: width / 45),
                                      ),
                                      Center(
                                          child: Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.blue,
                                        size: width / 13,
                                      )),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: width / 85,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: width / 85,
                  ),
                  SizedBox(
                      width: width / 2,
                      child: Card(
                        elevation: 5,
                        child: Image(
                            image: AssetImage('assets/networksetting.jpeg')),
                      )),
                  SizedBox(
                    height: width / 85,
                  ),
                  ////////////////////////////////////////////////////
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: Color.fromARGB(255, 1, 160, 252),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: [
                        Container(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '3.After pressing apply press the restart button',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: width / 37),
                                      ),
                                      Text(
                                        'to restart the device with new settings updated.',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: width / 37),
                                      ),
                                      Center(
                                          child: Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.blue,
                                        size: width / 13,
                                      )),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: width / 85,
                  ),
                  SizedBox(
                      width: width / 2,
                      child: Card(
                          elevation: 5,
                          child:
                              Image(image: AssetImage('assets/R-promt.jpeg')))),
                  SizedBox(
                    height: width / 85,
                  ),
                  ///////////////////////////////////////////////
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        border: Border.all(
                          color: Color.fromARGB(255, 1, 160, 252),
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    width: width,
                    child: Column(
                      children: [
                        Container(
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '4.Check the status leds (NET:Router) & (SRV: Internet)',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: width / 37),
                                      ),
                                      Text(
                                        'on the device to see wether it is connected successfully  ',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: width / 37),
                                      ),
                                      Text(
                                        'to Router and the Internet.',
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: width / 37),
                                      ),
                                      Center(
                                          child: Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.blue,
                                        size: width / 13,
                                      )),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: width / 80,
                  ),
                  SizedBox(
                      width: width / 2,
                      child: Card(
                        elevation: 5,
                        child: Image(
                            image: AssetImage('assets/wifimodule-leds.jpeg')),
                      )),
                  SizedBox(
                    height: width / 200,
                  ),
                  //////////////////////////////////////////
                  const SizedBox(
                    height: 20,
                  ),
                  Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(40.0),
                      color: Colors.green.shade500,
                      child: MaterialButton(
                        minWidth: (MediaQuery.of(context).size.width - 60),
                        // padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                        onPressed: () {
                          // if (_wifiInfo.ssid != 'missing' &&
                          //     _wifiInfo.ssid?.length == 14)

                          if (wifiName != null) {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    webviewscreen()));

                            if (_activeStepIndex <
                                (stepList(width, height).length - 1)) {
                              setState(() {
                                _activeStepIndex += 1;
                              });
                            } else {
                              print('Submited');
                            }
                          } else {
                            Fluttertoast.showToast(
                                msg:
                                    "Connect to Wifi-Module Access Point first.",
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.CENTER,
                                timeInSecForIosWeb: 2,
                                textColor: Colors.white,
                                fontSize: 15.0);
                            setState(() {
                              _activeStepIndex -= 1;
                            });
                          }
                        },
                        child: Text(
                          'Open network settings of this device',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      )),
                ],
              ),
            )),
        Step(
            state: StepState.complete,
            isActive: _activeStepIndex >= 2,
            title: Container(
              width: MediaQuery.of(context).size.width / 10,
              child: Column(
                children: [
                  Text('Sucessful Configuration',
                      style: TextStyle(
                          fontSize: MediaQuery.of(context).size.height /
                              stepperfont)),
                ],
              ),
            ),
            content: Container(
                width: MediaQuery.of(context).size.width,
                color: Colors.transparent,
                child: Column(children: [
                  SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                      width: 200,
                      child: Card(
                          elevation: 5,
                          child: Image(
                              image: AssetImage('assets/SR-promt.jpeg')))),
                  SizedBox(
                    height: 30,
                  ),
                  Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          border: Border.all(
                            color: Color.fromARGB(255, 1, 160, 252),
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(20))),
                      width: MediaQuery.of(context).size.width,
                      child: Column(children: [
                        Container(
                            child: Column(
                          children: [
                            Icon(Icons.check_box_outlined, color: Colors.green),
                            Text(
                              "If you got the 'Successful Restart' meassage",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      MediaQuery.of(context).size.width / 30),
                            ),
                            Text(
                              "then the device's network settings are updated successfully!",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize:
                                      MediaQuery.of(context).size.width / 35),
                            ),
                          ],
                        )),
                      ])),
                  const SizedBox(
                    height: 20,
                  ),
                  Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(40.0),
                      color: Colors.green.shade500,
                      child: MaterialButton(
                        minWidth: (MediaQuery.of(context).size.width - 60),
                        // padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                        onPressed: () {
                          {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    LoginPage()));
                            if (_activeStepIndex <
                                (stepList(width, height).length - 1)) {
                              setState(() {
                                _activeStepIndex += 1;
                              });
                            } else {
                              print('Submited');
                            }
                          }
                        },
                        child: Text(
                          'Go Back to Login Page',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      )),
                ])))
      ];

  Widget _closebutton(double x, double y) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: x * 0.005),
        child: Row(children: <Widget>[
          Container(
            padding: EdgeInsets.only(left: 0, top: y * 0.01, bottom: y * 0.01),
            child: Icon(
              Icons.close,
              color: Colors.white,
              size: 25,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _backButton(double x, double y) {
    return InkWell(
      onTap: () {
        if (_activeStepIndex == 0) {
          print('null');
        } else {
          if (_activeStepIndex < (stepList(x, y).length - 1)) {
            setState(() {
              _activeStepIndex -= 1;
            });
          } else {
            print('Submited');
          }
        }
      },
      child: Container(
        child: Row(
          children: <Widget>[
            Container(
              padding:
                  EdgeInsets.only(left: 0, top: y * 0.01, bottom: y * 0.01),
              child: Icon(
                Icons.keyboard_arrow_left,
                color: Colors.white,
                size: 25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final height = MediaQuery.of(context).size.height;
    return MaterialApp(
        home: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: AppBar(
          title: Text(
            'Wi-Fi Configuration',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: [
                _closebutton(width, height), /* _backButton(width, height)*/
              ],
            ),
          ),
          actions: <Widget>[
            // TextButton(
            //     onPressed: () {
            //       Navigator.push(context,
            //           MaterialPageRoute(builder: (context) => Diagnosis()));
            //     },
            //     child: Text(
            //       'Diagnosis',
            //       style: Theme.of(context).textTheme.subtitle1,
            //     ))
          ],
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),
      ),
      body: Container(
        color: Colors.white10,
        child: Stack(
          children: <Widget>[
            SizedBox(
              width: width,
              height: height / 3.9,
              child: Container(
                color: Theme.of(context).primaryColor,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(children: [
                            Text(
                              'You are currently connected to',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ]),
                          SizedBox(
                            height: 8,
                          ),

                          Row(
                            children: [
                              wifiName != null
                                  ? Center(
                                      child: Icon(
                                      Icons.wifi,
                                      color: Colors.white,
                                      size: 20,
                                    ))
                                  : Container(),
                              SizedBox(
                                width: 10,
                              ),
                              Text(wifiName != null ? wifiName! : "",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 0.04 * (height - width)),
                                  textAlign: TextAlign.left),
                            ],
                          ),
                          // Row(
                          //   children: [
                          //     Text(
                          //       'Unconnected Wi-Fi Module',
                          //       style: Theme.of(context).textTheme.subtitle1,
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              child: Padding(
                padding: const EdgeInsets.only(top: 150),
                child: Stepper(
                  physics: ScrollPhysics(),
                  type: StepperType.horizontal,
                  currentStep: _activeStepIndex,

                  steps: stepList(width, height),
                  controlsBuilder: (context, _) {
                    return Row(
                      children: <Widget>[
                        TextButton(
                          onPressed: () {},
                          child: const Text(''),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(''),
                        ),
                      ],
                    );
                  },
                  // onStepContinue: () {
                  //   if (_activeStepIndex < (stepList().length - 1)) {
                  //     setState(() {
                  //       _activeStepIndex += 1;
                  //     });
                  //   } else {
                  //     print('Submited');
                  //   }
                  // },
                  // onStepCancel: () {
                  //   if (_activeStepIndex == 0) {
                  //     return;
                  //   }

                  //   setState(() {
                  //     _activeStepIndex -= 1;
                  //   });
                  // },
                  ////////////////////////////////////////////////////
                  onStepContinue: () {},
                  onStepCancel: () {},
                  onStepTapped: (int index) {
                    print(index);

                    setState(() {
                      _activeStepIndex = index;
                    });
                    // if (index == 2) {
                    //   Navigator.of(context).push(MaterialPageRoute(
                    //       builder: (BuildContext context) => webviewscreen()));
                    // }
                  },

                  // controlsBuilder: (BuildContext context, ControlsDetails details) {
                  //   final isLastStep = _activeStepIndex == stepList().length - 1;
                  //   return Container(
                  //     child: Row(
                  //       children: [
                  //         // Expanded(
                  //         //   child: ElevatedButton(
                  //         //     onPressed: onStepContinue,
                  //         //     child: (isLastStep)
                  //         //         ? const Text('Submit')
                  //         //         : const Text('Next'),
                  //         //   ),
                  //         // ),
                  //         // const SizedBox(
                  //         //   width: 10,
                  //         // ),
                  //         // if (_activeStepIndex > 0)
                  //         //   Expanded(
                  //         //     child: ElevatedButton(
                  //         //       onPressed: onStepCancel,
                  //         //       child: const Text('Back'),
                  //         //     ),
                  //         //   )
                  //       ],
                  //     ),
                  //   );
                  // },
                ),
              ),
            ),
          ],
        ),
      ),
    ));
  }

//////////////////////////////////////////////////
  // Future<void> _onConnectPressed() async {
  //   final ssid = wifiname.text;
  //   final password = wifipassword.text;
  //   final bssid = wifibssid.text;
  //   // setState(() => _isSucceed = false);
  //   final isSucceed =
  //       await WifiConnector.connectToWifi(ssid: ssid, password: password);

  //   final task = ESPTouchTask(ssid: ssid, bssid: bssid, password: password);
  //   final Stream<ESPTouchResult> stream = task.execute();
  //   final sub = stream.listen((r) => print('IP: ${r.ip} MAC: ${r.bssid}'));
  //   Future.delayed(Duration(seconds: 12), () => sub.cancel());

  //   //setState(() => _isSucceed = true);
  // }
}

//String _wifiname = '';
///////////////////////////////////////////////////
///
///
///
// showLoaderDialog1(BuildContext context) {
//   AlertDialog alert = AlertDialog(
//     // insetPadding: EdgeInsets.symmetric(
//     //     horizontal: MediaQuery.of(context).size.width / 1,
//     // vertical: MediaQuery.of(context).size.height / 3),
//     content: SizedBox(
//       height: 300,
//       child: Center(
//           child: FutureBuilder(
//               future: WiFiForIoTPlugin.loadWifiList(),
//               builder: (context, AsyncSnapshot snapshot) {
//                 if (!snapshot.hasData) {
//                   return Center(child: CircularProgressIndicator());
//                 } else {
//                   return SingleChildScrollView(
//                     child: Container(
//                         width: double.maxFinite,
//                         height: MediaQuery.of(context).size.height / 3,
//                         child: ListView.builder(
//                             itemCount: snapshot.data.length,
//                             scrollDirection: Axis.vertical,
//                             itemBuilder: (BuildContext context, int index) {
//                               // return Text('${snapshot.data[index].ssid}');
//                               print(snapshot.data[index].ssid);
//                               return Center(
//                                   child: Stack(children: <Widget>[
//                                 Column(
//                                   children: [
//                                     Container(
//                                       child: ListTile(
//                                         dense: true,
//                                         onTap: () {
//                                           print(snapshot.data[index].ssid);
//                                           Navigator.pop(context);
//                                           wifiname.text =
//                                               snapshot.data[index].ssid;
//                                           wifibssid.text =
//                                               snapshot.data[index].bssid;
//                                         },
//                                         title: Text(
//                                           snapshot.data[index].ssid,
//                                           style: Theme.of(context)
//                                               .textTheme
//                                               .bodyText1,
//                                         ),
//                                         trailing: Icon(
//                                           Icons.wifi,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ]));
//                             })),
//                   );
//                 }
//               })
//           // ]),
//           ),
//     ),
//     actions: [
//       // TextButton(
//       //     onPressed: () {
//       //       Navigator.of(context, rootNavigator: true).pop();
//       //     },
//       //     child: Text('Cancel'))
//       Material(
//           elevation: 1,
//           borderRadius: BorderRadius.circular(5.0),
//           color: Theme.of(context).primaryColor,
//           child: MaterialButton(
//             minWidth: (MediaQuery.of(context).size.width - 280),
//             // padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
//             onPressed: () {
//               Navigator.of(context, rootNavigator: true).pop();
//             },
//             child: Text(
//               'Cancel',
//               style: Theme.of(context).textTheme.subtitle1,
//             ),
//           ))
//     ],
//   );
//   showDialog(
//     barrierDismissible: false,
//     context: context,
//     builder: (BuildContext context) {
//       return alert;
//     },
//   );
// }
