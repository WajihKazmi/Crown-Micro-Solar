import 'dart:convert';
import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:crownmonitor/Models/Accountinfo.dart';
import 'package:crownmonitor/Models/Powerstation_Query_Response.dart';
import 'package:crownmonitor/Models/QueryAlarmsOfAllPowerPlants.dart';
import 'package:crownmonitor/Models/QueryDeviceCount.dart';
import 'package:crownmonitor/main.dart';
import 'package:crownmonitor/pages/Aboutus.dart';
import 'package:crownmonitor/pages/accountsecurity/accountsecurity.dart';
import 'package:crownmonitor/pages/interfacetheme/interfacetheme.dart';
import 'package:crownmonitor/pages/language_selection_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'Accountinfo_Screen.dart';
import 'contactinfoscreen.dart';
import 'login.dart';

class Users extends StatefulWidget {
  /// plant info
  int plantcount = 0;
  // Device info
  int Devicecount = 0;
  // AlarmsCount
  int Alarmcount = 0;
  // accountinfo
  String username = 'fetching';
  String Role = 'fetching';
  String nickname = 'fetching';
  //testing
  String uid = 'fetching';
  String mobile = 'fetching';
  String email = 'fetching';
  String Account_status = 'fetching';
  String Account_registration_time = 'fetching';
  String timezone = 'fetching';
  String? Photo;
  //conditions check
  bool Account_info_loaded = false;

  Users({
    Key? key,
  }) : super(key: key);

  @override
  _UsersState createState() => _UsersState();
}

class _UsersState extends State<Users> {
  //initial values
  String version = "1.0.0";
  String buildNumber = "0";

  /////////////////TExt editing controllers///////////////////////
  late TextEditingController plants = new TextEditingController();
  late TextEditingController d = new TextEditingController();
  late TextEditingController alarm = new TextEditingController();
  late TextEditingController agentCodeController = new TextEditingController();

  void Showsnackbar(String message, int milliseconds, Color? color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: color,
          content: Text(
            '${message}',
            style: TextStyle(color: Colors.white),
          ),
          duration: Duration(milliseconds: milliseconds),
        ),
      );
    }
  }

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

  Widget _display(
    String name,
    Icon icon,
    double width,
    double height,
    String value,
    Color textcolor,
  ) {
    return Row(
      //crossAxisAlignment: CrossAxisAlignment.center,
      //mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Container(
          child: Icon(
            icon.icon,
            size: 30,
          ),
        ),
        SizedBox(
          width: width / 35,
        ),
        Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: TextStyle(
                    fontSize: 0.025 * (height - width),
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: width / 100,
              ),
              Text(
                value,
                style: TextStyle(
                    fontSize: 0.035 * (height - width),
                    fontWeight: FontWeight.bold,
                    color: textcolor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  //////////////////calling Queryplants interface/////////////////////////////////////
  Future LoadData() async {

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
    buildNumber = packageInfo.buildNumber;
    log(version.toString());
    log(buildNumber.toString());

    ////Alarm Count  -- Plants count -- Devices Count
    int? PlantCounts = await NumberofPowerStationQuery();
    var Jsonresponse_Accountinfo = await AccountInfoQuery();
    var Jsonresponse_Devicecountinfo = await DeviceCountQuery();
    var Jsonresponse_AlarmsofALLpowerplants = await AlarmsofallPowerPlantsQuery();
    Accountinfo _Accountinfo = new Accountinfo.fromJson(Jsonresponse_Accountinfo);
    QueryDeviceCount _QueryDeviceCount = new QueryDeviceCount.fromJson(Jsonresponse_Devicecountinfo);
    QueryAlarmsOfAllPowerPlants _QueryAlarmsOfAllPowerPlants = new QueryAlarmsOfAllPowerPlants.fromJson(Jsonresponse_AlarmsofALLpowerplants);
    ////////////////////////////////////////////////////
    print(
        '[User Screen|Accountinfoquery] error code: ${_Accountinfo.err} <==> error description: ${_Accountinfo.desc} <==> Username: ${_Accountinfo.dat.usr}');
    print(
        '[User Screen|DeviceCountquery] error code: ${_QueryDeviceCount.err} <==> error description: ${_QueryDeviceCount.desc} <==> Devicecount: ${_QueryDeviceCount.dat.count}');
    print(
        '[User Screen|ALLALarmsCountquery] error code: ${_QueryAlarmsOfAllPowerPlants.err} <==> error description: ${_QueryAlarmsOfAllPowerPlants.desc} <==> Alarmscount: ${_QueryAlarmsOfAllPowerPlants.dat.count}');

    // if (_Accountinfo.err == 0) {
    //   Showsnackbar("Data Updated Successfully...", 500, Colors.green);
    // } else {
    //   Showsnackbar("${_Accountinfo.desc}", 1500, Colors.black);
    // }

    setState(() {
      widget.plantcount = PlantCounts;
      widget.Alarmcount = _QueryAlarmsOfAllPowerPlants.dat.count;
      widget.Devicecount = _QueryDeviceCount.dat.count;
      widget.uid = _Accountinfo.dat.uid.toString();
      widget.mobile = _Accountinfo.dat.mobile;
      widget.email = _Accountinfo.dat.email;
      widget.Account_status = _Accountinfo.dat.enable.toString();
      widget.Photo = _Accountinfo.dat.photo ?? null;
      // widget.Account_registration_time =
      //     '${_Accountinfo.dat.gts.day}-${_Accountinfo.dat.gts.month}-${_Accountinfo.dat.gts.year}';
      widget.Account_registration_time =
          DateFormat.yMd().add_jm().format(_Accountinfo.dat.gts);
      widget.timezone = _Accountinfo.dat.gts.timeZoneName..toString();
      ////// Extracting name (bilal) from username e.g Crown213_bilal ///////////////
      int index_of_underscore = _Accountinfo.dat.usr.indexOf('_');
      widget.username = _Accountinfo.dat.usr.substring(index_of_underscore + 1);
      ///////////////////////////////////////////////////////////////////////
      widget.nickname = _Accountinfo.dat.qname == AppLocalizations.of(context)!.msg_not_available
          ? _Accountinfo.dat.usr
          : _Accountinfo.dat.qname;
      switch (_Accountinfo.dat.role) {
        case 0:
          {
            widget.Role = AppLocalizations.of(context)!.power_station_owner;
          }
          break;
        case 1:
          {
            widget.Role = AppLocalizations.of(context)!.manufacturer_account;
          }
          break;
        case 2:
          {
            widget.Role = AppLocalizations.of(context)!.dealer;
          }
          break;
        case 3:
          {
            widget.Role = AppLocalizations.of(context)!.group_account_number;
          }
          break;
        case 5:
          {
            widget.Role = AppLocalizations.of(context)!.power_station_browsing_account;
          }
          break;

        default:
          {
            print("Invalid choice");
          }
          break;
      }
      widget.Account_info_loaded = true;
    });
  }

  //////////////////calling Queryplants interface/////////////////////////////////////
  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    LoadData();
  }

  bool isSwitched = false;
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(height / 6.5),
        child: AppBar(
          toolbarHeight: height / 6.5,
          title: Column(
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Accountinfo_Screen(
                              Photo: widget.Photo,
                              uid: widget.uid,
                              username: widget.username,
                              Role: widget.Role,
                              mobile: widget.mobile,
                              email: widget.email,
                              nickname: widget.nickname,
                              Account_status: widget.Account_status,
                              Account_registration_time:
                                  widget.Account_registration_time,
                              timezone: widget.timezone)));
                },
                child: Row(
                  children: [
                    widget.Photo != null
                        ? CachedNetworkImage(
                            imageUrl: widget.Photo!,
                            placeholder: (_, url) =>
                                new CircularProgressIndicator(
                              color: Colors.white,
                            ),
                            imageBuilder: (context, imageProvider) =>
                                CircleAvatar(
                              radius: 0.05 * height,
                              backgroundImage: imageProvider,
                            ),
                          )
                        : CircleAvatar(
                            backgroundColor: Colors.white38,
                            radius: 0.05 * height,
                            child: Icon(
                              Icons.account_circle_sharp,
                              size: 0.08 * height,
                              color: Colors.white,
                            )),
                    SizedBox(width: width / 20),
                    widget.Account_info_loaded
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.username.toUpperCase(),
                                style: TextStyle(
                                    fontSize: 0.045 * (height - width),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '${AppLocalizations.of(context)!.role} ${widget.Role}',
                                style: TextStyle(
                                    fontSize: 0.035 * (height - width),
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white),
                              )
                            ],
                          )
                        : Center(
                            child: Row(
                              children: [
                                CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 1.5,
                                  backgroundColor: Colors.white24,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    AppLocalizations.of(context)!.msg_loading,
                                    style: TextStyle(fontSize: 0.04 * width),
                                  ),
                                )
                              ],
                            ),
                          ),
                    Flexible(
                        flex: 1,
                        fit: FlexFit.tight,
                        child: SizedBox(
                          width: double.infinity,
                        )),
                    Icon(
                      Icons.menu_open,
                      color: Colors.white,
                      size: width / 15,
                    )
                  ],
                ),
              ),
            ],
          ),
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0.0,
        ),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
           
            Column(
              children: [
                Container(
                  height: height / 14,
                  width: width,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: (Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        // ...
                        _display(
                            AppLocalizations.of(context)!.total_plants,
                            Icon(
                              Icons.storage_outlined,
                              color: Colors.grey[700],
                            ),
                            width,
                            height,
                            widget.plantcount.toString(),
                            Colors.green),
                        Container(
                            height: 40,
                            child: VerticalDivider(
                              color: Colors.grey,
                              thickness: 1.5,
                            )),
                        _display(
                            AppLocalizations.of(context)!.devices,
                            Icon(Icons.devices, color: Colors.grey[700]),
                            width,
                            height,
                            widget.Devicecount.toString(),
                            Colors.green),
                        Container(
                            height: 40,
                            child: VerticalDivider(
                              color: Colors.grey,
                              thickness: 1.5,
                            )),
                        _display(
                            AppLocalizations.of(context)!.alarms,
                            Icon(Icons.warning_amber, color: Colors.grey[700]),
                            width,
                            height,
                            widget.Alarmcount.toString(),
                            Colors.redAccent.shade400)
                      ],
                    )),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ListTile(
                        dense: true,
                        title: Text(AppLocalizations.of(context)!.account_security,
                            style: TextStyle(
                                fontSize: 0.035 * (height - width),
                                fontWeight: FontWeight.normal,
                                color: Colors.grey.shade600)),
                        leading: Icon(Icons.security,
                            color: Theme.of(context).primaryColor, size: 30),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                        ),
                        onTap: () {
                          widget.mobile == 'fetching'
                              ? null
                              : Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AccountSecurity(
                                          phonenumber: "+" + widget.mobile,
                                          username: widget.username)));
                        },
                      ),
                      Divider(),
                      
                      ListTile(
                        dense: true,
                        title: Text(AppLocalizations.of(context)!.interface_theme,
                            style: TextStyle(
                                fontSize: 0.035 * (height - width),
                                fontWeight: FontWeight.normal,
                                color: Colors.grey.shade600)),
                        leading: Icon(Icons.theaters,
                            color: Theme.of(context).primaryColor, size: 30),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Interfacetheme()));
                        },
                      ),
                      Divider(),
                      ListTile(
                        dense: true,
                        title: Text(AppLocalizations.of(context)!.contact_information,
                            style: TextStyle(
                                fontSize: 0.035 * (height - width),
                                fontWeight: FontWeight.normal,
                                color: Colors.grey.shade600)),
                        leading: Icon(Icons.contact_phone_rounded,
                            color: Theme.of(context).primaryColor, size: 30),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => contactinfoscreen()));
                        },
                      ),
                      Divider(),
                      
                      ListTile(
                        dense: true,
                        title: Text(AppLocalizations.of(context)!.about_us,
                            style: TextStyle(
                                fontSize: 0.035 * (height - width),
                                fontWeight: FontWeight.normal,
                                color: Colors.grey.shade600)),
                        leading: Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                          size: 30,
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => aboutus()));
                        },
                      ),

                      Divider(),

                      ListTile(
                        dense: true,
                        title: Text(AppLocalizations.of(context)!.change_language,
                            style: TextStyle(
                                fontSize: 0.035 * (height - width),
                                fontWeight: FontWeight.normal,
                                color: Colors.grey.shade600)),
                        leading: Icon(
                          Icons.translate_outlined,
                          color: Theme.of(context).primaryColor,
                          size: 30,
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 20,
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LanguageSelectionMenuPage()));
                        },
                      ),

                      SizedBox(
                        width: width,
                        height: height / 50,
                      ),

                      Container(
                        padding: EdgeInsets.all(10),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40.0)),
                          tileColor: Colors.green,
                          title: Center(
                              child: Text(
                            AppLocalizations.of(context)!.btn_add_installer,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 0.04 * (height - width),
                                fontWeight: FontWeight
                                    .bold), //Theme.of(context).textTheme.bodyText1,
                          )),
                          onTap: () async {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('Add Installer Code'),
                                  content: TextField(
                                    controller: agentCodeController,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('Cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: Text('Submit'),
                                      onPressed: () async {
                                        final prefs = await SharedPreferences
                                            .getInstance();

                                        EasyLoading.show(status: 'Loading');
                                        Map<String, String> headers = {
                                          'Content-Type': 'application/json',
                                          'x-api-key':
                                              'C5BFF7F0-B4DF-475E-A331-F737424F013C'
                                        };
                                        final body = jsonEncode({
                                          "UserID": int.parse(
                                              prefs.get('UserID').toString()),
                                          "AgentCode": agentCodeController.text
                                        });

                                        try {
                                          await http
                                              .post(
                                                  Uri.parse(
                                                      'https://apis.crown-micro.net/api/MonitoringApp/UpdateAgentCode'),
                                                  headers: headers,
                                                  body: body)
                                              .then((response) async {
                                            EasyLoading.dismiss();

                                            if (response.statusCode == 200) {
                                              Fluttertoast.showToast(
                                                  msg: 'Agent code added',
                                                  backgroundColor:
                                                      Colors.green);
                                            } else {
                                              Fluttertoast.showToast(
                                                  msg: 'Wrong code',
                                                  backgroundColor: Colors.red);
                                            }
                                            Navigator.of(context).pop();
                                          });
                                        } catch (e) {
                                          EasyLoading.dismiss();
                                        }
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),

                      Container(
                        padding: EdgeInsets.all(10),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40.0)),
                          tileColor: Colors.black,
                          title: Center(
                              child: Text(
                            AppLocalizations.of(context)!.btn_signout,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 0.04 * (height - width),
                                fontWeight: FontWeight
                                    .bold), //Theme.of(context).textTheme.bodyText1,
                          )),
                          onTap: () async {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(AppLocalizations.of(context)!.dialogue_confirmation),
                                  content: Text(
                                    AppLocalizations.of(context)!.dialogue_msg_signout,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text(AppLocalizations.of(context)!.dialogue_btn_cancle),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: Text(AppLocalizations.of(context)!.dialogue_btn_yes),
                                      onPressed: () async {
                                        final prefs = await SharedPreferences.getInstance();
                                        prefs.setBool('loggedin', false);
                                        prefs.setBool('isInstaller', false);
                                        prefs.setString('Agentslist', '');
                                        // prefs.clear();
                                        Navigator.push(context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  const MyApp()),
                                        );
                                        // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginPage()), (route) => false);
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),

                      Container(
                        padding: EdgeInsets.all(10),
                        child: ListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40.0)),
                          tileColor: Colors.red,
                          title: Center(
                              child: Text(
                            AppLocalizations.of(context)!.btn_delete_acccount,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 0.04 * (height - width),
                                fontWeight: FontWeight
                                    .bold), //Theme.of(context).textTheme.bodyText1,
                          )),
                          onTap: () async {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(AppLocalizations.of(context)!.dialogue_delete_account),
                                  content: Text(
                                    AppLocalizations.of(context)!.dialogue_msg_delete_account,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text(AppLocalizations.of(context)!.dialogue_btn_cancle),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: Text(AppLocalizations.of(context)!.dialogue_btn_delete),
                                      onPressed: () async {
                                        final prefs = await SharedPreferences
                                            .getInstance();
                                        prefs.setBool('loggedin', false);

                                        EasyLoading.show(status: 'Loading');
                                        Map<String, String> headers = {
                                          'Content-Type': 'application/json',
                                          'x-api-key':
                                              'C5BFF7F0-B4DF-475E-A331-F737424F013C'
                                        };
                                        final body = jsonEncode({
                                          "UserID": prefs.get('UserID'),
                                        });
                                        try {
                                          await http
                                              .post(
                                                  Uri.parse(
                                                      'https://apis.crown-micro.net/api/MonitoringApp/DeactivateAccount'),
                                                  headers: headers,
                                                  body: body)
                                              .then((response) async {
                                            EasyLoading.dismiss();
                                            Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        LoginPage()),
                                                (route) => false);
                                          });
                                        } catch (e) {
                                          EasyLoading.dismiss();
                                        }
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        height: 0.1 * height,
                      ),
                      Column(
                        children: [
                          Container(
                            width: 0.9 * width,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                  AppLocalizations.of(context)!.version_text +
                                      version +
                                      '.' +
                                      buildNumber,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 0.035 * (height - width),
                                      fontWeight: FontWeight.normal,
                                      color: Colors.grey.shade400)),
                            ),
                          ),
                          Container(
                            color: Colors.transparent,
                            width: 0.12 * height,
                            child: Container(
                                color: Colors.transparent,
                                child: Image(
                                    image: AssetImage(
                                        'assets/crown-black-logo.png'))),
                          ),
                          SizedBox(
                            width: width,
                            height: height / 50,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
