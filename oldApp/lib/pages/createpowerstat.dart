import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as picker;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mainscreen.dart';

class CreatePowerStation extends StatefulWidget {
  const CreatePowerStation({Key? key}) : super(key: key);

  @override
  _CreatePowerStationState createState() => _CreatePowerStationState();
}

class _CreatePowerStationState extends State<CreatePowerStation> {
  //////////////Text editing controllers/////////////////////////////////
  final TextEditingController Plantnamecontroller = TextEditingController();

  final TextEditingController countrycontroller = TextEditingController();
  final TextEditingController provincecontroller = TextEditingController();
  final TextEditingController citycontroller = TextEditingController();
  final TextEditingController countycontroller = TextEditingController();
  final TextEditingController longitudecontroller = TextEditingController();
  final TextEditingController latitudecontroller = TextEditingController();
  final TextEditingController towncontroller = TextEditingController();
  final TextEditingController addresscontroller = TextEditingController();
  final TextEditingController villagecontroller = TextEditingController();

  final TextEditingController Unitprofitcontroller = TextEditingController();
  final TextEditingController co2controller = TextEditingController();
  final TextEditingController so2controller = TextEditingController();
  final TextEditingController coalcontroller = TextEditingController();

  final TextEditingController nominalPowercontroller = TextEditingController();
  final TextEditingController energyyearestimatecontroller =
      TextEditingController();
  final TextEditingController Designcompanycontroller = TextEditingController();

  final TextEditingController date = TextEditingController();

  List<String> _powerdesc = ['kW', 'W', 'MW', 'GW']; // Option 2
  late String _selectedpowerdesc = 'kW';

  List<String> _timezone = [
    '(GMT +05:00) Asia, Karachi',
    '(UTC+04:00) Abu Dhabi, Muscat',
    '(UTC+03:00) Kuwait, Riyadh',
    '(UTC+08:00) Beijing, Chongqing, Hong Kong, Urumqi',
    '(UTC-07:00) Pacific Daylight Time (US & Canada)'
  ];
  String _selectedtimezone = '(GMT +05:00) Asia, Karachi';
  String _selectedtimezone_converted = '18000';

  List<String> _capitalgain = [
    'RMB(¥)',
    'USD(\$)',
    'EURO(€)',
    "AUD(A\$)",
    "GBP(£)",
    "HKB(HK)",
    "SEK(kr)",
    "RS(₹)",
    "REAL(R)",
    "MXN(Mex)",
    "THB(B)",
    "PKR(Rs)",
    "ZAR(R)",
    "SAR(SR)",
    "AED(AED)",
    "VND",
    "MYR",
    "HUF",
    "TWD",
  ];

  InquiryofPSI() async {
    String salt = "12345678";
    String secret = "e216fe6d765ebbd05393ba598c8d0ac20b4d2122";
    String token =
        "4f07ebae2a2cb357608bb1c920924f7dd50536b00c09fb9d973441777ac66b4b";

    String action = "&action=queryPlantInfo&plantid=1";

    var data = salt + secret + token + action;
    print(data);

    var sign = utf8.encode(data);

    var output = sha1.convert(sign).toString();

    //   print(output);
    try {
      await callInquiryapi(output, salt, token, "123");
    } catch (e) {
      print(e);
    }
  }

  Future callInquiryapi(
      String sign, String salt, String token, String pn) async {
    String url =
        "http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}&action=queryPlantInfo&plantid=1";

    print(url);
    var response = await http.get(Uri.parse(url));

    print(response.body);

    if (response.statusCode >= 400) {
      throw ('Error');
    } else {
      print(response.body);
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////** Createpowerstation  interface. *//////START///////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

  Future CreatePowerstationApi(
      {required String Plantname,
      required String country,
      required String province,
      required String city,
      required String county,
      required String lat,
      required String lon,
      required String timezone,
      required String? town,
      required String? village,
      required String? address,
      required String UnitProfit,
      required String currency,
      required String coal,
      required String co2,
      required String so2,
      required String? countrycurrency,
      required String nominalPower,
      required String? EnergyYearEstimate,
      required String? DesignCompany,
      String? PicBig,
      String? PicSmall,
      required String installdate}) async {
    print(
        'name:${Plantname.toString().toUpperCase()}, timezone:$timezone, install Date:$installdate, DesignCompany:$DesignCompany, address:$address, town:$town, lat:$lat, lon:$lon, Power:$nominalPower, Profit:$UnitProfit, Currency:$currency, Coal:$coal, Co2:$co2, So2:$so2');
    var jsonResponse = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final Secret = prefs.getString('Secret') ?? '';
    print('token: $token');
    print('Secret: $Secret');
    String salt = "12345678";

    //String action = "&action=queryPlants&orderBy=ascPlantName";

    ///--------------test--------------------------7-4-22/////
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    String appName = packageInfo.appName;
    String packageName = packageInfo.packageName;
    String version = packageInfo.version;
    String buildNumber = packageInfo.buildNumber;
    String platform = Platform.isAndroid ? "android" : "ios";
    String Source = "1";

    String postaction =
        "&source=$Source&app_id=$packageName&app_version=$version&app_client=$platform";
    //////------------------------//////////////////////////////////

    /////////////////////////////////////////////////////////////
    ////////////////// TO CREATE ACTION for sign ////////////////
    /////////////////////////////////////////////////////////////

    Map<String, dynamic> queryparameters = {
      'action': 'addPlant', //required
      'name': '$Plantname', //required
      'address.country': '$country', //required
      'address.province': '$province', //required
      'address.city': '$city', //required
      'address.county': '$county', //required
      'address.lon': '$lon', //required
      'address.lat': '$lat', //required
      'address.timezone': '$timezone', //required
      'address.town': '$town',
      'address.village': '$village',
      'address.address': '$address',
      'profit.unitProfit': '$UnitProfit', //required
      'profit.currency': '$currency', //required
      'profit.coal': '$coal', //required
      'profit.co2': '$co2', //required
      'profit.so2': '$so2', //required
      'address.currencyCountry': '$countrycurrency',
      'nominalPower': '$nominalPower', //required
      'energyYearEstimate': '$EnergyYearEstimate',
      'designCompany': '$DesignCompany',
      'install': '$installdate',
      //'picBig' :  PicBig == null ? "" : await MultipartFile.fromFile(PicBig, filename: Plantname) ,
      "source": "$Source",
      "app_id": "$packageName",
      "app_version": "$version",
      "app_client": "$platform" //required
    };

    // Map<String, String> queryparameters = {
    //   'action': 'addPlant',
    //   'name': 'TESTPLANT',
    //   'address.country': 'Pakistan',
    //   'address.province': 'sindh',
    //   'address.city': 'karachi',
    //   'address.county': 'abc',
    //   'address.lon': '25.545422',
    //   'address.lat': '68.433222',
    //   'address.timezone': '18000',
    //   'profit.unitProfit': '1.12',
    //   'profit.currency': '￥',
    //   'profit.coal': '0.221',
    //   'profit.co2': '0.031',
    //   'profit.so2': '0.023',
    //   'nominalPower': '20000',
    //   'install': '2022-02-04 02:09:18',
    // };

    //query plantsinfo ///
    // Map<String, String> queryparameters = {
    //   'action': 'queryPlants',
    //   'orderBy': 'ascStatus',
    //   'page ': '1',
    //   'pagesize': '4',
    // };

    String action = '&' + Uri(queryParameters: queryparameters).query;

    ////////////////////////////////////////////////////////
    ////////////// TO CREATE ACTION for sign ////////////////
    ////////////////////////////////////////////////////////

    ////////////////////////////////////////////////////////////
    /////////////////// To create sign /////////////////////////

    print('action: $action');
    var data = salt + Secret + token + action;
    var output = utf8.encode(data);
    var sign = sha1.convert(output).toString();
    print('Sign: $sign');
    /////////////////// To create sign /////////////////////////
    ////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////
    /////////// TO CREATE QueryParameter with sign+salt+token+action ////////
    Map<String, dynamic> parameterswithsignsalttokenaction = {
      'sign': '$sign',
      'salt': '$salt',
      'token': '$token',
    };
    parameterswithsignsalttokenaction.addAll(queryparameters);
    ////////////// TO CREATE QueryParameter with sign+salt+token+action ////////////////
    ////////////////////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////////////////////////////
    ////////////// TO CREATE Api request url  with apilink+sign+salt+token+action ////////////////
    var uri = Uri.parse('http://api.dessmonitor.com/public/');
    uri = uri.replace(queryParameters: parameterswithsignsalttokenaction);
    print('URI:$uri');
    ////////////// TO CREATE Api request url  with apilink+sign+salt+token+action ////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////

    ////////////// Posting createpowerstation request with query parameters and handling response ////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    try {
      await http.post(uri).then((response) {
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

            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => MainScreen(
                          passed_index: 1,
                        )),
                (route) => false);
          } else {
            // showMessage('Error', '${jsonResponse['desc'].toString()}', true);
            Fluttertoast.showToast(
                msg: "${jsonResponse['desc'].toString()}",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
          }
        }
        print('APIrequest response : ${jsonResponse}');
        print('APIrequest statucode : ${response.statusCode}');
      });
    } catch (e) {
      showMessage('Error', e.toString(), true);
    }
    ////////////// Posting createpowerstation request with query parameters and handling response ////////////////
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //////////////////////////////////////** Createpowerstation  interface. *//////END///////////////////////////
  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////

  void showMessage(String title, String errorMessage, bool isSuccess) {
    showDialog(
        context: context,
        builder: (BuildContext builderContext) {
          return AlertDialog(
            title: Text(title),
            content: Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            actions: [
              TextButton(
                child: Text("Ok"),
                onPressed: () async {
                  Navigator.of(builderContext).pop();
                },
              )
            ],
          );
        }).then((value) {
      // setState(() {
      //   isLoading = false;
      // });
    });
  }

  String _selectedcapitalgain = 'RMB(¥)';
  String _currency = '¥';

  dynamic _pickImageError;
  XFile? imageFile = null;
  Future<void> _showChoiceDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              "Choose option",
              style: TextStyle(color: Colors.blue),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Divider(
                    height: 1,
                    color: Colors.blue,
                  ),
                  ListTile(
                    onTap: () {
                      _openGallery(context);
                    },
                    title: Text("Gallery",
                        style: TextStyle(color: Colors.black, fontSize: 17)),
                    leading: Icon(
                      Icons.account_box,
                      color: Colors.blue,
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: Colors.blue,
                  ),
                  ListTile(
                    onTap: () {
                      _openCamera(context);
                    },
                    title: Text(
                      "Camera",
                      style: TextStyle(color: Colors.black, fontSize: 17),
                    ),
                    leading: Icon(
                      Icons.camera,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _textfield(
      double width,
      double height,
      String name,
      String hint,
      bool enable,
      TextEditingController controller,
      TextInputType textInputType) {
    return Column(
      children: [
        Container(
          height: height / 20,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: TextStyle(
                      fontSize: 0.025 * (height - width), color: Colors.black),
                ),
                new Flexible(
                  child: TextField(
                      keyboardType: textInputType,
                      controller: controller,
                      style: TextStyle(
                          fontSize: 0.035 * (height - width),
                          color: Colors.black),
                      enabled: enable,
                      textAlign: TextAlign.end,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: hint,
                          hintStyle: TextStyle(
                              fontSize: 0.025 * (height - width),
                              color: Colors.black38),
                          fillColor: Colors.white,
                          filled: true)),
                )
              ],
            ),
          ),
        ),
        SizedBox(
          height: height / 250,
        ),
      ],
    );
  }

  Widget _textfieldicon(double width, double height, String name, String hint,
      bool enable, Icon icon) {
    return Column(
      children: [
        Container(
          height: height / 20,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(name, style: Theme.of(context).textTheme.bodyLarge),
                new Flexible(
                  child: TextField(
                      enabled: enable,
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.end,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: hint,
                          hintStyle: Theme.of(context).textTheme.bodyMedium,
                          suffixIcon: icon,
                          fillColor: Colors.white,
                          filled: true)),
                )
              ],
            ),
          ),
        ),
        SizedBox(
          height: height / 250,
        ),
      ],
    );
  }

  Widget _datetimepicker(double width, double height, String name, String hint,
      bool enable, Icon icon) {
    return Column(
      children: [
        Container(
          height: height / 20,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: TextStyle(
                      fontSize: 0.025 * (height - width), color: Colors.black),
                ),
                new Flexible(
                  child: InkWell(
                      onTap: () {
                        print(date);
                        // Navigator.push(
                        //     context, MaterialPageRoute(builder: (context) => Datepicker()));

                        // showMonthPicker(
                        //   context: context,
                        //   firstDate: DateTime(DateTime.now().year - 1, 5),
                        //   lastDate: DateTime(DateTime.now().year + 1, 9),
                        //   initialDate: DateTime.now(),
                        //   locale: Locale("en"),
                        // ).then((date) {
                        //   if (date != null) {
                        //     // Navigator.push(context,
                        //     //     MaterialPageRoute(builder: (context) => Monthlystats()));
                        //     setState(() {
                        //       // selectedDate = date;
                        //       // month = date.month;
                        //       // year = date.year;
                        //       // set();
                        //       // print(month);
                        //       // print(year);
                        //     });
                        //   }
                        // });

                        picker.DatePicker.showDatePicker(context,
                            showTitleActions: true,
                            minTime: DateTime(2015, 3, 5),
                            maxTime: DateTime(
                                DateTime.now().year.toInt(),
                                DateTime.now().month.toInt(),
                                DateTime.now().day.toInt()),
                            theme: picker.DatePickerTheme(
                                headerColor: Theme.of(context).primaryColor,
                                backgroundColor: Color(0xffF4F4F4),
                                itemStyle: TextStyle(
                                    color: Colors.black, fontSize: 10),
                                doneStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16)), onChanged: (datepick) {
                          print('change $datepick in time zone ' +
                              datepick.timeZoneName +
                              '+' +
                              datepick.timeZoneOffset.inSeconds.toString());
                        }, onConfirm: (datepick) {
                          print('confirm: $datepick');

                          date.text = datepick.year.toString() +
                              '-' +
                              datepick.month.toString() +
                              '-' +
                              datepick.day.toString() +
                              ' ' +
                              DateTime.now().hour.toString() +
                              ':' +
                              DateTime.now().minute.toString() +
                              ':' +
                              DateTime.now().second.toString();

                          print('establishment time: ${date.text}');
                        }, currentTime: DateTime.now(), locale: picker.LocaleType.en);
                      },
                      child: TextField(
                          controller: date,
                          style: TextStyle(
                            fontSize: 0.035 * (height - width),
                            color: Colors.blue,
                          ),
                          enabled: false,
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(
                              hintText: 'Tap here to select data',
                              // suffixIcon: icon,
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                fontSize: 0.026 * (height - width),
                                color: Colors.blue,
                              ),
                              fillColor: Colors.white,
                              filled: true))),
                )
              ],
            ),
          ),
        ),
        SizedBox(
          height: height / 250,
        ),
      ],
    );
  }

  Widget _field(double width, double height, String name, Widget secondwidget) {
    return Column(
      children: [
        Container(
          // height: height / 20,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: TextStyle(
                      fontSize: 0.025 * (height - width), color: Colors.black),
                ),
                secondwidget,
              ],
            ),
          ),
        ),
        SizedBox(
          height: height / 250,
        ),
      ],
    );
  }

  // Widget _dropfield(double width, double height, String name, List list,
  //     String selectedvalue) {
  //   return Column(
  //     children: [
  //       Container(
  //         // height: height / 20,
  //         color: Colors.white,
  //         child: Padding(
  //           padding: const EdgeInsets.all(8.0),
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //             crossAxisAlignment: CrossAxisAlignment.center,
  //             children: [
  //               Text(name,
  //                   style: TextStyle(
  //                       fontSize: width / h4,
  //                       color: Colors.black,
  //                       fontWeight: FontWeight.normal)),
  //               SizedBox(
  //                 height: height / 40,
  //                 child: DropdownButtonHideUnderline(
  //                   child: DropdownButton(
  //                     style: TextStyle(
  //                         fontSize: width / h4,
  //                         color: Colors.grey[700],
  //                         fontWeight: FontWeight.normal),
  //                     icon: Icon(
  //                       Icons.keyboard_arrow_down_sharp,
  //                       size: width / 20,
  //                     ),
  //                     value: selectedvalue,
  //                     onChanged: (newValue) {
  //                       setState(() {
  //                         selectedvalue = newValue.toString();
  //                       });
  //                     },
  //                     items: list.map((cap) {
  //                       return DropdownMenuItem(
  //                         child: new Text(cap),
  //                         value: cap,
  //                       );
  //                     }).toList(),
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //       SizedBox(
  //         height: height / 250,
  //       ),
  //     ],
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            )),
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          'Add Plant',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        centerTitle: true,
        actions: [
          // TextButton(
          //     style: TextButton.styleFrom(
          //         primary: Colors.white, backgroundColor: Colors.white),
          //     onPressed: () {
          //       // InquiryofPSI();
          //       CreatePowerstationApi(
          //         Plantname: Plantnamecontroller.text,
          //         country: countrycontroller.text,
          //         province: provincecontroller.text,
          //         city: citycontroller.text,
          //         county: countycontroller.text,
          //         lat: latitudecontroller.text,
          //         lon: longitudecontroller.text,
          //         timezone: _selectedtimezone_converted,
          //         UnitProfit: Unitprofitcontroller.text,
          //         currency: _currency,
          //         coal: coalcontroller.text,
          //         co2: co2controller.text,
          //         so2: so2controller.text,
          //         nominalPower: nominalPowercontroller.text,
          //         installdate: date.text,
          //         town: towncontroller.text,
          //         village: villagecontroller.text,
          //         address: addresscontroller.text,
          //         countrycurrency: _selectedcapitalgain,
          //         EnergyYearEstimate: energyyearestimatecontroller.text,
          //         DesignCompany: Designcompanycontroller.text,
          //       );
          //     },
          //     child: Text('Create Station',
          //         style: Theme.of(context).textTheme.subtitle1))
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          width: width,
          color: Colors.grey[300],
          child: Column(
            children: <Widget>[
              SizedBox(
                height: height / 70,
              ),
              Row(
                children: [
                  Text(
                    '  Basic Information',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
              SizedBox(
                height: height / 70,
              ),
              _textfield(
                  width,
                  height,
                  "Plant name   (required)",
                  'Please enter plant name',
                  true,
                  Plantnamecontroller,
                  TextInputType.text),
              _textfield(
                  width,
                  height,
                  "Design Company  (optional)",
                  'Please enter design company',
                  true,
                  Designcompanycontroller,
                  TextInputType.text),
              // _field(
              //   width,
              //   height,
              //   'Plant pictures',
              //   // ClipRRect(
              //   //   borderRadius: BorderRadius.circular(1.0),
              //   //   child: Image.network('https://picsum.photos/250?image=9',
              //   //       height: height / 15,
              //   //       width: width / 7.5,
              //   //       fit: BoxFit.fill),
              //   // )
              //   InkWell(
              //     child: (imageFile == null)
              //         ? Text(
              //             "Tap to select picture",
              //             style: TextStyle(
              //                 fontSize: 0.035 * (height - width),
              //                 color: Colors.blue),
              //           )
              //         : Image.file(
              //             File(imageFile!.path),
              //           ),
              //     onTap: () {
              //       _showChoiceDialog(context);
              //     },
              //   ),
              // ),
              SizedBox(
                height: height / 90,
              ),
              Row(
                children: [
                  Text(
                    '  Installed Capacity',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
              SizedBox(
                height: height / 90,
              ),
              _field(
                width,
                height,
                "Installed capacity unit",
                SizedBox(
                  height: height / 40,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      style: TextStyle(
                          fontSize: 0.035 * (height - width),
                          color: Colors.black),
                      icon: Icon(
                        Icons.keyboard_arrow_down_sharp,
                        size: width / 20,
                      ),
                      value: _selectedpowerdesc,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedpowerdesc = newValue.toString();
                        });
                      },
                      items: _powerdesc.map((location) {
                        return DropdownMenuItem(
                          child: new Text(location),
                          value: location,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              _textfield(
                  width,
                  height,
                  "Nominal Capacity   (required)",
                  'Intalled Capacity in $_selectedpowerdesc',
                  true,
                  nominalPowercontroller,
                  TextInputType.number),
              _textfield(
                  width,
                  height,
                  "Energy Year Estimate   (optional)",
                  'Energy Year Estimate in $_selectedpowerdesc',
                  true,
                  energyyearestimatecontroller,
                  TextInputType.number),
              SizedBox(
                height: height / 90,
              ),
              Row(
                children: [
                  Text(
                    '  Install Information',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
              SizedBox(
                height: height / 90,
              ),
              _field(
                width,
                height,
                "Time Zone   (required)",
                SizedBox(
                  height: height / 40,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      style: TextStyle(
                          fontSize: 0.025 * (height - width),
                          color: Colors.black),
                      icon: Icon(
                        Icons.keyboard_arrow_down_sharp,
                        size: 20,
                      ),
                      value: _selectedtimezone,
                      onChanged: (newValue) {
                        switch (newValue) {
                          case '(GMT +05:00) Asia, Karachi':
                            setState(() {
                              _selectedtimezone_converted = '18000';
                              _selectedtimezone = newValue.toString();
                            });
                            break;
                          case '(UTC+04:00) Abu Dhabi, Muscat':
                            setState(() {
                              _selectedtimezone_converted = '14400';
                              _selectedtimezone = newValue.toString();
                            });
                            break;
                          case '(UTC+03:00) Kuwait, Riyadh':
                            setState(() {
                              _selectedtimezone_converted = '10800';
                              _selectedtimezone = newValue.toString();
                            });
                            break;
                          case '(UTC+08:00) Beijing, Chongqing, Hong Kong, Urumqi':
                            setState(() {
                              _selectedtimezone_converted = '28800';
                              _selectedtimezone = newValue.toString();
                            });
                            break;
                          case '(UTC-07:00) Pacific Daylight Time (US & Canada)':
                            setState(() {
                              _selectedtimezone_converted = '-25200';
                              _selectedtimezone = newValue.toString();
                            });
                            break;
                        }
                        print(_selectedtimezone_converted);
                        print(_selectedtimezone);
                        // if (newValue == '(GMT +05:00) Asia, Karachi') {
                        //   setState(() {
                        //     // _selectedtimezone_converted = DateTime.now()
                        //     //     .timeZoneOffset
                        //     //     .inSeconds
                        //     //     .toString();
                        //     // GMT offset converted to hours e.g 5 hours= 18000 seconds
                        //     _selectedtimezone_converted = '18000';
                        //     _selectedtimezone = newValue.toString();
                        //     print(_selectedtimezone_converted);
                        //     print(_selectedtimezone);
                        //   });
                        // } else {
                        //   setState(() {
                        //     _selectedtimezone = newValue.toString();
                        //   });
                        // }
                      },
                      items: _timezone.map((timezone) {
                        return DropdownMenuItem(
                          child: new Text(timezone),
                          value: timezone,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              _datetimepicker(
                  width,
                  height,
                  'Installation Date   (required)',
                  'Enter Date',
                  false,
                  Icon(
                    Icons.keyboard_arrow_down_sharp,
                    size: width / 20,
                  )),
              _textfield(width, height, "Country  (required)", 'Enter Country',
                  true, countrycontroller, TextInputType.text),
              _textfield(
                  width,
                  height,
                  "Province  (required)",
                  'Enter Province',
                  true,
                  provincecontroller,
                  TextInputType.text),
              _textfield(width, height, "City  (required)", 'Enter City', true,
                  citycontroller, TextInputType.text),
              _textfield(width, height, "County  (required)", 'Enter County',
                  true, countycontroller, TextInputType.text),
              _textfield(width, height, "Town  (optional)", 'Enter Town', true,
                  towncontroller, TextInputType.text),
              _textfield(width, height, "village  (optional)", 'Enter Village',
                  true, villagecontroller, TextInputType.text),
              _textfield(width, height, "Address  (optional)", 'Enter Address',
                  true, addresscontroller, TextInputType.text),
              _textfield(
                  width,
                  height,
                  "Longitude   (required)",
                  'Enter Longitude',
                  true,
                  longitudecontroller,
                  TextInputType.number),
              _textfield(
                  width,
                  height,
                  "Latitude   (required)",
                  'Enter Latitude',
                  true,
                  latitudecontroller,
                  TextInputType.number),
              SizedBox(
                height: height / 90,
              ),
              Row(
                children: [
                  Text(
                    '  Income formula',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
              SizedBox(
                height: height / 90,
              ),
              _field(
                width,
                height,
                "Capital gain unit   (required)",
                SizedBox(
                  height: height / 40,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      style: TextStyle(
                          fontSize: 0.035 * (height - width),
                          color: Colors.black),
                      icon: Icon(
                        Icons.keyboard_arrow_down_sharp,
                        size: width / 20,
                      ),
                      value: _selectedcapitalgain,
                      onChanged: (newValue) {
                        switch (newValue) {
                          case "RMB(¥)":
                            {
                              setState(() {
                                _selectedcapitalgain = newValue.toString();
                                _currency = '¥';
                              });
                            }
                            break;
                          case "USD(\$)":
                            {
                              setState(() {
                                _selectedcapitalgain = newValue.toString();
                                _currency = '\$';
                              });
                            }
                            break;
                          case "EURO(€)":
                            {
                              setState(() {
                                _selectedcapitalgain = newValue.toString();
                                _currency = '€';
                              });
                            }
                            break;
                          case "AUD(A\$)":
                            {
                              setState(() {
                                _selectedcapitalgain = newValue.toString();
                                _currency = 'A\$';
                              });
                            }
                            break;
                          case "GBP(£)":
                            {
                              setState(() {
                                _selectedcapitalgain = newValue.toString();
                                _currency = '£';
                              });
                            }
                            break;
                          case "HKB(HK)":
                            {
                              setState(() {
                                _selectedcapitalgain = newValue.toString();
                                _currency = 'Hk';
                              });
                            }
                            break;
                          case "SEK(kr)":
                            {
                              setState(() {
                                _selectedcapitalgain = newValue.toString();
                                _currency = 'Kr';
                              });
                            }
                            break;
                          case "REAL(R)":
                            {
                              setState(() {
                                _selectedcapitalgain = newValue.toString();
                                _currency = 'R';
                              });
                            }
                            break;
                          case "MXN(Mex)":
                            {
                              setState(() {
                                _selectedcapitalgain = newValue.toString();
                                _currency = 'Mex';
                              });
                            }
                            break;
                          case "THB(B)":
                            {
                              setState(() {
                                _selectedcapitalgain = newValue.toString();
                                _currency = 'B';
                              });
                            }
                            break;
                          case "PKR(Rs)":
                            {
                              setState(() {
                                _selectedcapitalgain = newValue.toString();
                                _currency = 'Rs';
                              });
                            }
                            break;
                          case "ZAR(R)":
                            {
                              setState(() {
                                _selectedcapitalgain = newValue.toString();
                                _currency = 'R';
                              });
                            }
                            break;
                          case "SAR(SR)":
                            {
                              setState(() {
                                _selectedcapitalgain = newValue.toString();
                                _currency = 'SR';
                              });
                            }
                            break;
                          case "AED(AED)":
                            {
                              setState(() {
                                _selectedcapitalgain = newValue.toString();
                                _currency = 'AED';
                              });
                            }
                            break;
                          default:
                            {
                              print("Invalid choice");
                            }
                            break;
                        }
                      },
                      items: _capitalgain.map((capitalgain) {
                        return DropdownMenuItem(
                          child: new Text(capitalgain),
                          value: capitalgain,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              _textfield(
                  width,
                  height,
                  "Unit Capital gain   (required)",
                  'Enter Unit Capital gains',
                  true,
                  Unitprofitcontroller,
                  TextInputType.number),
              _textfield(
                  width,
                  height,
                  "Standard coal saved   (required)",
                  'Enter standard coal saved',
                  true,
                  coalcontroller,
                  TextInputType.number),
              _textfield(
                  width,
                  height,
                  "CO2 emission reduction   (required)",
                  'Enter CO2 emission reduction',
                  true,
                  co2controller,
                  TextInputType.number),
              _textfield(
                  width,
                  height,
                  "SO2 emission reduction   (required)",
                  'Enter SO2 emission reduction',
                  true,
                  so2controller,
                  TextInputType.number),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  width: 0.9 * width,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text('ADD PLANT'.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 0.045 * width,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    onPressed: () {
                      CreatePowerstationApi(
                        Plantname: Plantnamecontroller.text,
                        country: countrycontroller.text,
                        province: provincecontroller.text,
                        city: citycontroller.text,
                        county: countycontroller.text,
                        lat: latitudecontroller.text,
                        lon: longitudecontroller.text,
                        timezone: _selectedtimezone_converted,
                        UnitProfit: Unitprofitcontroller.text,
                        currency: _currency,
                        coal: coalcontroller.text,
                        co2: co2controller.text,
                        so2: so2controller.text,
                        nominalPower: nominalPowercontroller.text,
                        installdate: date.text,
                        town: towncontroller.text,
                        village: villagecontroller.text,
                        address: addresscontroller.text,
                        countrycurrency: _selectedcapitalgain,
                        EnergyYearEstimate: energyyearestimatecontroller.text,
                        DesignCompany: Designcompanycontroller.text,
                        // PicBig: imageFile
                      );
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _openGallery(BuildContext context) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: MediaQuery.of(context).size.width / 6,
          maxHeight: MediaQuery.of(context).size.height / 14);
      setState(() {
        imageFile = pickedFile!;
      });

      Navigator.pop(context);
    } catch (e) {
      print(e);
    }
  }

  void _openCamera(BuildContext context) async {
    try {
      final pickedFile = await ImagePicker()
          .pickImage(source: ImageSource.camera, maxWidth: 200, maxHeight: 200);
      setState(() {
        imageFile = pickedFile!;
      });
      Navigator.pop(context);
    } catch (e) {
      print(e);
    }
  }
}
