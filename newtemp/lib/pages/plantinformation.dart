import 'dart:convert';
import 'dart:io';

import 'package:crownmonitor/fontsizes.dart';
import 'package:crownmonitor/pages/list.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as picker;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as PATH;
import 'package:http_parser/http_parser.dart';

import '../Models/Powerstation_Query_Response.dart';
import 'mainscreen.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlantInformation extends StatefulWidget {
  //plantinfoqueryvariables
  String? PID;
  String? Plantname;
  String? Plant_status;
  String? Country;
  String? province;
  String? City;
  String? County;
  String? town;
  String? village;
  String? address;
  String? lon;
  String? lat;
  String? timezone;
  String? Unitprofit;
  String? currency;
  String? coalsaved;
  String? so2emission;
  String? co2emission;

  double? DesignPower;
  double? Annual_Planned_Power;
  String? DesignCompany;
  String? picbig;
  String? picsmall;
  DateTime? installed_date;

  int? Average_troublefree_operationtime;
  int? Continuous_troublefree_operationtime;

  PlantInformation(
      {Key? key,
      this.PID,
      this.Plantname,
      this.Plant_status,
      this.Country,
      this.province,
      this.City,
      this.County,
      this.town,
      this.village,
      this.address,
      this.lon,
      this.lat,
      this.timezone,
      this.Unitprofit,
      this.currency,
      this.coalsaved,
      this.so2emission,
      this.co2emission,
      this.DesignPower,
      this.DesignCompany,
      this.Annual_Planned_Power,
      this.Average_troublefree_operationtime,
      this.Continuous_troublefree_operationtime,
      this.installed_date,
      this.picbig,
      this.picsmall})
      : super(key: key);

  @override
  _PlantInformationState createState() => _PlantInformationState();
}

class _PlantInformationState extends State<PlantInformation> {
  final TextEditingController plantName = TextEditingController();
  final TextEditingController plantstatus = TextEditingController();
  final TextEditingController installedcapacity = TextEditingController();
  final TextEditingController annualplannedpower = TextEditingController();
  final TextEditingController installers = TextEditingController();
  final TextEditingController plantestablisment = TextEditingController();

  final TextEditingController country = TextEditingController();
  final TextEditingController province = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController county = TextEditingController();
  final TextEditingController town = TextEditingController();
  final TextEditingController village = TextEditingController();
  final TextEditingController timezone = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController lat = TextEditingController();
  final TextEditingController lon = TextEditingController();

  final TextEditingController _Currency = TextEditingController();
  final TextEditingController capitalgains = TextEditingController();
  final TextEditingController standardcoal = TextEditingController();
  final TextEditingController CO2emission = TextEditingController();
  final TextEditingController SO2emission = TextEditingController();
  String currency = '';
  String _selectedcapitalgain = 'RMB(¥)';
  String _currency = '¥';
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

  bool Editinfo_pressed = false;

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
                Text(name,
                    style: TextStyle(
                        fontSize: 0.032 * (height - width),
                        fontWeight: FontWeight.normal)),
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

  Widget _textfield(double width, double height, String name, bool enable,
      TextEditingController controller, TextInputType textInputType) {
    return Column(
      children: [
        Container(
          height: height / 22,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(name + ' :',
                    style: TextStyle(
                        fontSize: 0.032 * (height - width),
                        fontWeight: FontWeight.normal)),
                new Flexible(
                  child: TextField(
                      keyboardType: textInputType,
                      controller: controller,
                      onSubmitted: (text) {
                        controller.text = text.toUpperCase();
                      },
                      onTap: () {
                        //////////////////
                        if (name == 'Plant establishment Date') {
                          picker.DatePicker.showDatePicker(
                            context,
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
                                    color: Colors.white, fontSize: 16)),
                            onChanged: (datepick) {
                              print('change $datepick in time zone ' +
                                  datepick.timeZoneName +
                                  '+' +
                                  datepick.timeZoneOffset.inSeconds.toString());
                            },
                            onConfirm: (datepick) {
                              print('confirm: $datepick');

                              controller.text = datepick.year.toString() +
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
                            },
                            currentTime: DateTime.now(),
                          );
                        } else {
                          return;
                        }

                        //////////////////
                      },
                      style: TextStyle(
                          fontSize: name == 'Timezone'
                              ? 0.025 * (height - width)
                              : 0.034 * (height - width),
                          fontWeight: FontWeight.bold,
                          color: enable ? Colors.blue : Colors.blueGrey),
                      enabled: enable ? true : false,
                      textAlign: TextAlign.end,
                      decoration: enable
                          ? InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                gapPadding: 2,
                                borderSide: BorderSide(
                                    color: Colors.lightBlue, width: 1.2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.blueGrey, width: 0.8),
                              ),
                              hintStyle: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 0.05 * width,
                              ),
                              fillColor: Colors.white,
                              filled: true)
                          : InputDecoration(
                              hintStyle: TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 0.034 * (height - width),
                              ),
                              fillColor: Colors.white,
                              filled: true)),
                )
              ],
            ),
          ),
        ),
        SizedBox(
          height: height / 200,
        ),
      ],
    );
  }

  Widget _heading(double width, double height, String name) {
    return Column(
      children: [
        SizedBox(
          height: height / 400,
        ),
        Container(
          height: height / 20,
          color: Colors.grey.shade200,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 0.05 * (height - width),
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey)),
              ],
            ),
          ),
        ),
        SizedBox(
          height: height / 500,
        ),
      ],
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    //initailizing text controllers with plant varaibles which we got from other class (plant)...
    plantName.text = widget.Plantname ?? 'not available';
    country.text = widget.Country ?? 'not available';
    province.text = widget.province ?? 'not available';
    city.text = widget.City ?? 'not available';
    county.text = widget.County ?? 'not available';
    town.text = widget.town ?? 'not available';
    village.text = widget.village ?? 'not available';
    address.text = widget.address ?? 'not available';
    lon.text = widget.lon ?? 'not available';
    lat.text = widget.lat ?? 'not available';
    //var date = new DateTime.fromMillisecondsSinceEpoch(14400000);
    //timezone.text = 'GMT' + date.timeZoneName;

    // String operator = offset < 0 ? '-' : '+';
    // timezone.text = 'GMT' + operator + offset.toStringAsFixed(0);
    // double offset = (int.parse(widget.timezone!) / 3600);
    //print(offset.toStringAsFixed(0));
    String timezone_converted = '';

    switch (widget.timezone) {
      case '18000':
        setState(() {
          timezone_converted = "(GMT +05:00) Asia, Karachi";
        });
        break;
      case '14400':
        setState(() {
          timezone_converted = "(UTC+04:00) Abu Dhabi, Muscat";
        });
        break;
      case '10800':
        setState(() {
          timezone_converted = "(UTC+03:00) Kuwait, Riyadh";
        });
        break;
      case '28800':
        setState(() {
          timezone_converted =
              "(UTC+08:00) Beijing, Chongqing, Hong Kong, Urumqi";
        });
        break;
      case '-25200':
        setState(() {
          timezone_converted =
              "(UTC-07:00) Pacific Daylight Time (US & Canada)";
        });
        break;
    }

    timezone.text = timezone_converted;

    //////////////////////////////////////////////////////////
    capitalgains.text = widget.Unitprofit ?? 'not available';
    currency = widget.currency ?? 'not available';
    _Currency.text = widget.currency ?? 'not available';
    standardcoal.text = widget.coalsaved ?? 'not available';
    SO2emission.text = widget.so2emission ?? 'not available';
    CO2emission.text = widget.co2emission ?? 'not available';
    installedcapacity.text = widget.DesignPower.toString();
    annualplannedpower.text = widget.Annual_Planned_Power.toString();
    installers.text = widget.DesignCompany ?? 'not available';
    plantestablisment.text = widget.installed_date.toString();

    switch (int.parse(widget.Plant_status!)) {
      case 0:
        {
          plantstatus.text = 'ONLINE';
        }
        break;
      case 1:
        {
          plantstatus.text = 'OFFLINE';
        }
        break;
      case 4:
        {
          plantstatus.text = 'WARNING';
        }
        break;
      case 7:
        {
          plantstatus.text = 'ATTENTION';
        }
        break;
    }
    ;
  }

////////////////////// TODO *************************
  ///
  /// implement upload image feature.... find documentation....
  uploadimage(var _image) async {
    print(_image);
    print(PATH.basename(_image));
    Dio dio = new Dio();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final Secret = prefs.getString('Secret') ?? '';
    String salt = "12345678";

    FormData formData = FormData.fromMap({
      //required
      'file': _image == null
          ? ""
          : await MultipartFile.fromFile(_image,
              filename: PATH.basename(_image),
              contentType: MediaType("image", 'png'))
    });

    String action = "&action=uploadImg&source=1&thumbnail=true";

    var data = salt + Secret + token + action;
    var output = utf8.encode(data);
    var sign = sha1.convert(output).toString();
    String url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
            action;

    try {
      var response = await dio.post(url, data: formData);
      if (response.statusCode != 200) {
        return null;
      }
      print("Success");
      print(response);
      return response;
    } catch (e) {
      print(e);
      return null;
    }
  }

  XFile? imageFile = null;

  void _openGallery(BuildContext context) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          maxWidth: MediaQuery.of(context).size.width / 6,
          maxHeight: MediaQuery.of(context).size.height / 14);

      imageFile = pickedFile!;
      setState(() {});

      //

      //await uploadimage(imageFile!.path);

      Navigator.pop(context);
    } catch (e) {
      print(e);
    }
  }

  void _openCamera(BuildContext context) async {
    try {
      final pickedFile = await ImagePicker()
          .pickImage(source: ImageSource.camera, maxWidth: 200, maxHeight: 200);

      imageFile = pickedFile!;
      setState(() {});

      //

      //await uploadimage(imageFile!.path);

      Navigator.pop(context);
    } catch (e) {
      print(e);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    print('PicBIG plant information page:   ${widget.picsmall}');

    print('Plant name  plant information page:   ${widget.Plantname}');

    // set up delete  button
    Widget DelButton = ElevatedButton(
        child: Text(AppLocalizations.of(context)!.confirm_delete),
        onPressed: () async {
          var json =
              await DeletePS(PID: widget.PID!, plantname: widget.Plantname!);
          if (json['err'] == 0 || json['err'] == 260) {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.msg_plant_deleted,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
            //new//
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => MainScreen(
                          passed_index: 1,
                        )),
                (route) => false);
            //old//
            // Navigator.pushAndRemoveUntil(
            //     context,
            //     MaterialPageRoute(builder: (context) => Lists()),
            //     (route) => false);
          } else {
            Fluttertoast.showToast(
                msg: "${json['desc']}",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
          }
        });

    Widget CancelButton = ElevatedButton(
      child: Text(AppLocalizations.of(context)!.btn_cancel),
      onPressed: () {
        Navigator.of(context, rootNavigator: true).pop();
      },
    );

    // set up the Delete AlertDialog
    AlertDialog Delete_alert = AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.are_you_sure,
        style: TextStyle(fontSize: 30),
      ),
      content: Text(
        AppLocalizations.of(context)!.this_will_delete_plant,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade800),
      ),
      actions: [
        DelButton,
        CancelButton,
      ],
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        // leading: IconButton(
        //     onPressed: () {
        //       Navigator.pushAndRemoveUntil(
        //           context,
        //           MaterialPageRoute(
        //               builder: (context) => MainScreen(passed_index: 1)),
        //           (route) => false);
        //     },
        //     icon: Icon(Icons.arrow_back, color: Colors.white, size: 25)),
        backgroundColor: Theme.of(context).primaryColor,
        title: Text(
          AppLocalizations.of(context)!.plant_information,
          style: TextStyle(
                fontSize: 0.045 * (height - width),
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
        ),
        // centerTitle: true,
        actions: [
          // IconButton(
          //     onPressed: () {},
          //     icon: Icon(Icons.camera, color: Colors.white, size: 25))
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          width: width,
          color: Colors.grey.shade300,
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 2,
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.9),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  // borderRadius: BorderRadius.circular(8.0),
                  child: (widget.picsmall!.contains('https://'))
                      ? Image.network('${widget.picsmall!}',
                          height: height / 4,
                          width: width / 1.01,
                          fit: BoxFit.fill)
                      : Image.asset('assets/PS.jpg',
                          height: height / 4,
                          width: width / 1.01,
                          fit: BoxFit.fill),
                ),
              ),
              !Editinfo_pressed
                  ? Container(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: 0.4 * width,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.edit,
                                        color: Colors.green, size: 20),
                                    SizedBox(
                                      width: 5,
                                    ),
                                    Text(AppLocalizations.of(context)!.edit_plant,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.green)),
                                  ],
                                ),
                                onPressed: () async {
                                  setState(() {
                                    Editinfo_pressed = true;
                                  });
                                  // show the dialog
                                },
                              ),
                            ),
                            SizedBox(
                              width: 0.5 * width,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                    SizedBox(
                                      width: 2,
                                    ),
                                    Text(AppLocalizations.of(context)!.delete_plant,
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red)),
                                  ],
                                ),
                                onPressed: () async {
                                  // show the dialog
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Delete_alert;
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container(),
              _heading(width, height, AppLocalizations.of(context)!.plant_information),
              // _textfield(width, height, 'Plant Status', false, plantstatus,
              //     TextInputType.text),
              _textfield(width, height, AppLocalizations.of(context)!.plant_name, Editinfo_pressed,
                  plantName, TextInputType.text),
              _textfield(width, height, AppLocalizations.of(context)!.design_company, Editinfo_pressed,
                  installers, TextInputType.text),
              _textfield(width, height, AppLocalizations.of(context)!.installed_capacity_kw,
                  Editinfo_pressed, installedcapacity, TextInputType.number),
              _textfield(width, height, AppLocalizations.of(context)!.annual_planned_power,
                  Editinfo_pressed, annualplannedpower, TextInputType.number),
              _textfield(width, height, AppLocalizations.of(context)!.plant_establishment_date,
                  Editinfo_pressed, plantestablisment, TextInputType.datetime),
              // !Editinfo_pressed
              //     ? Container()
              //     : _field(
              //         width,
              //         height,
              //         'Plant pictures',
              //         // ClipRRect(
              //         //   borderRadius: BorderRadius.circular(1.0),
              //         //   child: Image.network('https://picsum.photos/250?image=9',
              //         //       height: height / 15,
              //         //       width: width / 7.5,
              //         //       fit: BoxFit.fill),
              //         // )
              //         InkWell(
              //           child: (imageFile == null)
              //               ? Text(
              //                   "Tap to select picture",
              //                   style: TextStyle(
              //                       fontSize: 0.035 * (height - width),
              //                       color: Colors.blue),
              //                 )
              //               : Image.file(
              //                   File(imageFile!.path),
              //                 ),
              //           onTap: () {
              //             _showChoiceDialog(context);
              //           },
              //         ),
              //       ),
              _heading(width, height, AppLocalizations.of(context)!.location),
              _textfield(width, height, AppLocalizations.of(context)!.country, Editinfo_pressed, country,
                  TextInputType.text),
              _textfield(width, height, AppLocalizations.of(context)!.province, Editinfo_pressed, province,
                  TextInputType.text),
              _textfield(width, height, AppLocalizations.of(context)!.city, Editinfo_pressed, city,
                  TextInputType.text),
              _textfield(width, height, AppLocalizations.of(context)!.district_county, Editinfo_pressed,
                  county, TextInputType.text),
              _textfield(width, height, AppLocalizations.of(context)!.town, Editinfo_pressed, town,
                  TextInputType.text),
              _textfield(width, height, AppLocalizations.of(context)!.village, Editinfo_pressed, village,
                  TextInputType.text),
              Editinfo_pressed
                  ? _field(
                      width,
                      height,
                      AppLocalizations.of(context)!.timezone_space,
                      SizedBox(
                        height: height / 40,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton(
                            style: TextStyle(
                                fontSize: 0.025 * (height - width),
                                fontWeight: FontWeight.normal,
                                color: Colors.grey.shade800),
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
                    )
                  : _textfield(width, height, AppLocalizations.of(context)!.timezone, Editinfo_pressed,
                      timezone, TextInputType.text),
              _textfield(width, height, AppLocalizations.of(context)!.address, Editinfo_pressed, address,
                  TextInputType.text),
              _textfield(width, height, AppLocalizations.of(context)!.lattitude, Editinfo_pressed, lat,
                  TextInputType.number),
              _textfield(width, height, AppLocalizations.of(context)!.longitude, Editinfo_pressed, lon,
                  TextInputType.number),
              _heading(width, height, AppLocalizations.of(context)!.income_formula),

              Editinfo_pressed
                  ? _field(
                      width,
                      height,
                      AppLocalizations.of(context)!.capital_gain_unit,
                      SizedBox(
                        height: height / 40,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton(
                            style: TextStyle(
                                fontSize: 0.038 * (height - width),
                                fontWeight: FontWeight.normal,
                                color: Colors.grey.shade800),
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
                                      _selectedcapitalgain =
                                          newValue.toString();
                                      _currency = '¥';
                                    });
                                  }
                                  break;
                                case "USD(\$)":
                                  {
                                    setState(() {
                                      _selectedcapitalgain =
                                          newValue.toString();
                                      _currency = '\$';
                                    });
                                  }
                                  break;
                                case "EURO(€)":
                                  {
                                    setState(() {
                                      _selectedcapitalgain =
                                          newValue.toString();
                                      _currency = '€';
                                    });
                                  }
                                  break;
                                case "AUD(A\$)":
                                  {
                                    setState(() {
                                      _selectedcapitalgain =
                                          newValue.toString();
                                      _currency = 'A\$';
                                    });
                                  }
                                  break;
                                case "GBP(£)":
                                  {
                                    setState(() {
                                      _selectedcapitalgain =
                                          newValue.toString();
                                      _currency = '£';
                                    });
                                  }
                                  break;
                                case "HKB(HK)":
                                  {
                                    setState(() {
                                      _selectedcapitalgain =
                                          newValue.toString();
                                      _currency = 'Hk';
                                    });
                                  }
                                  break;
                                case "SEK(kr)":
                                  {
                                    setState(() {
                                      _selectedcapitalgain =
                                          newValue.toString();
                                      _currency = 'Kr';
                                    });
                                  }
                                  break;
                                case "REAL(R)":
                                  {
                                    setState(() {
                                      _selectedcapitalgain =
                                          newValue.toString();
                                      _currency = 'R';
                                    });
                                  }
                                  break;
                                case "MXN(Mex)":
                                  {
                                    setState(() {
                                      _selectedcapitalgain =
                                          newValue.toString();
                                      _currency = 'Mex';
                                    });
                                  }
                                  break;
                                case "THB(B)":
                                  {
                                    setState(() {
                                      _selectedcapitalgain =
                                          newValue.toString();
                                      _currency = 'B';
                                    });
                                  }
                                  break;
                                case "PKR(Rs)":
                                  {
                                    setState(() {
                                      _selectedcapitalgain =
                                          newValue.toString();
                                      _currency = 'Rs';
                                    });
                                  }
                                  break;
                                case "ZAR(R)":
                                  {
                                    setState(() {
                                      _selectedcapitalgain =
                                          newValue.toString();
                                      _currency = 'R';
                                    });
                                  }
                                  break;
                                case "SAR(SR)":
                                  {
                                    setState(() {
                                      _selectedcapitalgain =
                                          newValue.toString();
                                      _currency = 'SR';
                                    });
                                  }
                                  break;
                                case "AED(AED)":
                                  {
                                    setState(() {
                                      _selectedcapitalgain =
                                          newValue.toString();
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
                    )
                  : _textfield(width, height, AppLocalizations.of(context)!.currency, Editinfo_pressed,
                      _Currency, TextInputType.text),
              _textfield(width, height, AppLocalizations.of(context)!.capital_gain_currency(currency),
                  Editinfo_pressed, capitalgains, TextInputType.number),
              _textfield(width, height, AppLocalizations.of(context)!.standard_coal_saved, Editinfo_pressed,
                  standardcoal, TextInputType.number),
              _textfield(width, height, AppLocalizations.of(context)!.co2_emission_reduction_kg,
                  Editinfo_pressed, CO2emission, TextInputType.number),
              _textfield(width, height, AppLocalizations.of(context)!.so2_emission_reduction_kg,
                  Editinfo_pressed, SO2emission, TextInputType.number),

              Editinfo_pressed
                  ? Container(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 0.8 * width,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green),
                                child: Text(
                                    AppLocalizations.of(context)!.update_plant_information,
                                    style: TextStyle(
                                      fontSize: 0.035 * width,
                                      fontWeight: FontWeight.bold,
                                    )),
                                onPressed: () async {
                                  await EDITPS(
                                      PID: widget.PID!,
                                      Plantname: plantName.text,
                                      country: country.text,
                                      province: province.text,
                                      city: city.text,
                                      county: county.text,
                                      lat: lat.text,
                                      lon: lon.text,
                                      timezone: _selectedtimezone_converted,
                                      UnitProfit: capitalgains.text,
                                      currency: _currency,
                                      countrycurrency: _selectedcapitalgain,
                                      coal: standardcoal.text,
                                      co2: CO2emission.text,
                                      so2: SO2emission.text,
                                      nominalPower: installedcapacity.text,
                                      installdate: plantestablisment.text,
                                      town: town.text,
                                      village: village.text,
                                      address: address.text,
                                      EnergyYearEstimate:
                                          annualplannedpower.text,
                                      DesignCompany: installers.text,
                                      PicBig: imageFile == null
                                          ? null
                                          : imageFile!.path);
                                  Fluttertoast.showToast(
                                      msg: AppLocalizations.of(context)!.msg_plant_info_updated,
                                      toastLength: Toast.LENGTH_LONG,
                                      gravity: ToastGravity.CENTER,
                                      timeInSecForIosWeb: 2,
                                      textColor: Colors.white,
                                      fontSize: 15.0);

                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => Lists()),
                                      (route) => false);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Container()
            ],
          ),
        ),
      ),
    );
  }
}
