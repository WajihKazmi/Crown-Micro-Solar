import 'dart:convert';

import 'package:crownmonitor/Models/CollectorDevicesStatus.dart';
import 'package:crownmonitor/pages/plant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'deviceinformation.dart';
import 'mainscreen.dart';

// TODO: this page not inf use - may be removed later
class collectorinfopage extends StatefulWidget {
  String? Alias;
  String? Pn;
  int? datafetch;
  int? load;
  int? status;
  String? Firmware;
  int? PID;
  String? plantname;

  //new
  double? signal;
  String? descx;

  collectorinfopage(
      {Key? key,
      this.signal,
      this.descx,
      this.plantname,
      this.PID,
      this.Firmware,
      this.Pn,
      this.Alias,
      this.datafetch,
      this.load,
      this.status})
      : super(key: key);

  @override
  _collectorinfopageState createState() => _collectorinfopageState();
}

class _collectorinfopageState extends State<collectorinfopage> {
  String? devicealias = '---';
  String? sn = '---';
  int? devadr = 0;
  int? devcode = 0;
  int? devstatus = 0;

  int? collectorstatus;
  final TextEditingController name = new TextEditingController();
  bool isAgent = false;
  bool isLoading = true;

  var ps_info = null;

  @override
  void initState() {
    super.initState();
    loadCollectorDevicesStatusQuery();
    loadAgent();
  }

  Future loadAgent() async {
    var prefs = await SharedPreferences.getInstance();

    setState(() {
      isAgent = prefs.getBool('isInstaller') ?? false;
    });
  }

  Future loadCollectorDevicesStatusQuery() async {
    final data = await CollectorDevicesStatusQuery(PN: widget.Pn!);

    setState(() {
      isLoading = false;
      ps_info = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    print('collector screen ${widget.plantname}');

    // set up delete  button
    Widget DelButton = ElevatedButton(
        child: Text(AppLocalizations.of(context)!.confirm_delete),
        onPressed: () async {
          var json = await DeleteCollector(PN: widget.Pn!);
          if (json['err'] == 0 || json['err'] == 257) {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.datalogger_deleted,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Plant(
                        passedindex: 3,
                        collector_callback: true,
                        PlantID: widget.PID.toString(),
                      )),
            );
          } else {
            Fluttertoast.showToast(
                msg: "Error: ${json['desc']}",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
          }
        });

    // set up namechange  button
    Widget NamechangeButton = ElevatedButton(
        child: Text(AppLocalizations.of(context)!.update_alias),
        onPressed: () async {
          var json = await NameChangeCollector(
              PN: widget.Pn!, name: name.text.replaceAll(RegExp(r' '), ""));
          if (json['err'] == 0) {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.alias_changed_sucessfully,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);

            Navigator.of(context, rootNavigator: true).pop();

            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Plant(
                        passedindex: 3,
                        collector_callback: true,
                        PlantID: widget.PID.toString(),
                      )),
            );
          } else {
            Fluttertoast.showToast(
                msg: "Error: ${json['desc']}",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
          }
        });

    ////REstart collector button
    ///// set up delete  button
    Widget RestartButton = ElevatedButton(
        child: Text(AppLocalizations.of(context)!.confirm_restart),
        onPressed: () async {
          var json = await RestartCollector(PN: widget.Pn!);
          if (json['err'] == 0) {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.rebooting_datalogger,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Plant(
                        passedindex: 3,
                        collector_callback: true,
                        PlantID: widget.PID.toString(),
                      )),
            );
          } else if (json['err'] == 1) {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.instruction_issued_msg,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
          } else if (json['err'] == 2) {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.instruction_failed_msg,
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
          } else {
            Fluttertoast.showToast(
                msg: "Error: ${json['desc']}",
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
        AppLocalizations.of(context)!.this_remove_datalogger_ps,
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

    // set up the Collector Restart AlertDialog
    AlertDialog Restart_alert = AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.restart_collector,
        style: TextStyle(fontSize: 30),
      ),
      content: Text(
        AppLocalizations.of(context)!.sure_restart_device,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: Colors.grey.shade800),
      ),
      actions: [
        RestartButton,
        CancelButton,
      ],
    );

    AlertDialog Changename_alert = AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.enter_new_alias,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      content: TextField(
        textAlign: TextAlign.center,
        onSubmitted: (String value) {
          setState(() {
            if (value == "") {
              name.text = widget.Alias!;
            } else {
              name.text = value;
            }
          });
        },
        controller: name,
        decoration: new InputDecoration(
          contentPadding: EdgeInsets.all(8),
          fillColor: Colors.white,
          filled: true,
          hintText: AppLocalizations.of(context)!
              .current_alias(widget.Alias.toString()),
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
      actions: [
        NamechangeButton,
        CancelButton,
      ],
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 25)),
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: false,
        actions: [
          isAgent
              ? IconButton(
                  onPressed: () async {
                    Map<String, String> headers = {
                      'Content-Type': 'application/json',
                      'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C'
                    };

                    var prefs = await SharedPreferences.getInstance();
                    String list = prefs.getString('Agentslist') ?? '';
                    Map<String, dynamic> jsonResponse = jsonDecode(list);
                    print(jsonResponse);

                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          actions: [
                            TextButton(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                          title: Text('Tap to login',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Roboto",
                                letterSpacing: 1,
                                color: Colors.red,
                              )),
                          content: SizedBox(
                            width: 200,
                            height: 300,
                            child: ListView.builder(
                              physics: BouncingScrollPhysics(),
                              itemCount: jsonResponse['Agentslist'].length,
                              itemBuilder: (BuildContext context, int index) {
                                return ListTile(
                                  trailing: Icon(Icons.arrow_right),
                                  title: Text(
                                      'SN: ${jsonResponse['Agentslist'][index]['SNNumber']}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Roboto",
                                        letterSpacing: 1,
                                        color: Colors.black,
                                      )),
                                  subtitle: Text(
                                      'Username: ${jsonResponse['Agentslist'][index]['Username']}'
                                          .toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: "Roboto",
                                        letterSpacing: 1,
                                        color: Colors.black,
                                      )),
                                  onTap: () async {
                                    EasyLoading.show(status: 'Loading');

                                    final agent_body = jsonEncode({
                                      "Username": jsonResponse['Agentslist']
                                          [index]['Username'],
                                      "Password": jsonResponse['Agentslist']
                                          [index]['Password'],
                                    });

                                    var jsonResponseAgent = null;
                                    await http
                                        .post(
                                            Uri.parse(
                                                'https://apis.crown-micro.net/api/MonitoringApp/Login'),
                                            headers: headers,
                                            body: agent_body)
                                        .then((responseAgent) async {
                                      if (responseAgent.statusCode == 200) {
                                        jsonResponseAgent =
                                            json.decode(responseAgent.body);
                                        if (jsonResponseAgent['Token'] !=
                                            null) {
                                          prefs.setString('token',
                                              jsonResponseAgent['Token']);
                                          prefs.setString('Secret',
                                              jsonResponseAgent['Secret']);
                                          prefs.setString(
                                              'UserID',
                                              jsonResponseAgent['UserID']
                                                  .toString());
                                          prefs.setBool('loggedin', true);

                                          EasyLoading.dismiss();
                                          Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      MainScreen()),
                                              (route) => false);
                                        }
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  icon: Icon(
                    Icons.rotate_left,
                    size: 25,
                    color: Colors.white,
                  ))
              : Container(),
        ],
        title: widget.Alias == null
            ? Text(
                AppLocalizations.of(context)!.datalogger_details,
                style: TextStyle(
                    fontSize: 0.04 * (height - width),
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              )
            : Row(
                children: [
                  Text(
                    '${widget.Alias} ',
                    style: TextStyle(
                        fontSize: 0.04 * (height - width),
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  Text(
                    AppLocalizations.of(context)!.details,
                    style: TextStyle(
                        fontSize: 0.04 * (height - width),
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
      ),
      body: Container(
        padding: EdgeInsets.symmetric(vertical: 8),
        //height: height,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              //  height: height / 4,
              width: width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    width: 0.95 * width,
                    height: 0.06 * height,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: new BoxDecoration(
                      color: Colors.grey.shade900,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(
                          width: 0.3 * width,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade600),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.edit, color: Colors.green, size: 15),
                                // SizedBox(
                                //   width: 5,
                                // ),
                                // Text(AppLocalizations.of(context)!.edit_alias,
                                //     style: TextStyle(
                                //       fontSize: 0.025 * (height - width),
                                //       fontWeight: FontWeight.bold,
                                //     )),
                              ],
                            ),
                            onPressed: () async {
                              // show the dialog
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Changename_alert;
                                },
                              );
                            },
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade600),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.restart_alt,
                                  color: Colors.grey, size: 15),
                              // SizedBox(
                              //   width: 5,
                              // ),
                              // Text(AppLocalizations.of(context)!.restart,
                              //     style: TextStyle(
                              //       fontSize: 0.025 * (height - width),
                              //       fontWeight: FontWeight.bold,
                              //     )),
                            ],
                          ),
                          onPressed: () async {
                            // show the dialog
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Restart_alert;
                              },
                            );
                          },
                        ),
                        SizedBox(
                          width: 0.3 * width,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.delete,
                                    color: Colors.white, size: 15),
                                // SizedBox(
                                //   width: 5,
                                // ),
                                // Text(AppLocalizations.of(context)!.delete,
                                //     style: TextStyle(
                                //       fontSize: 0.025 * (height - width),
                                //       fontWeight: FontWeight.bold,
                                //     )),
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
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    width: width - 20,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: new BoxDecoration(
                      color: Colors.black,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            AppLocalizations.of(context)!
                                .datalogger_details_upper,
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.normal,
                              color: Colors.white,
                            )),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Container(
                    width: width - 20,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(AppLocalizations.of(context)!.alias,
                                    style: TextStyle(
                                      fontSize: 0.03 * (height - width),
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black,
                                    )),
                                widget.Alias == null
                                    ? Text(
                                        AppLocalizations.of(context)!
                                            .not_available,
                                        style: TextStyle(
                                          fontSize: 0.03 * (height - width),
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black,
                                        ))
                                    : Text('${widget.Alias}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        )),
                              ],
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Row(
                              children: [
                                Text(AppLocalizations.of(context)!.pn,
                                    style: TextStyle(
                                      fontSize: 0.03 * (height - width),
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black,
                                    )),
                                Text('   ${widget.Pn}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    )),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(AppLocalizations.of(context)!.status_upper,
                                    style: TextStyle(
                                      fontSize: 0.03 * (height - width),
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87,
                                    )),
                                Text(
                                    (widget.status == 0)
                                        ? 'ONLINE'
                                        : (widget.status == 1)
                                            ? 'OFFLINE'
                                            : (widget.status == 2)
                                                ? 'FAULT'
                                                : (widget.status == 3)
                                                    ? 'STANDBY'
                                                    : (widget.status == 4)
                                                        ? 'WARNING'
                                                        : (widget.status == 5)
                                                            ? 'ERROR'
                                                            : 'Protocol error',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: widget.status == 0
                                          ? Colors.green
                                          : Colors.red,
                                    )),
                              ],
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Row(
                              children: [
                                Text(AppLocalizations.of(context)!.load_colon,
                                    style: TextStyle(
                                      fontSize: 0.03 * (height - width),
                                      fontWeight: FontWeight.normal,
                                      color: Colors.black87,
                                    )),
                                Text('${widget.load}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  widget.descx == null && widget.signal == null
                      ? Container()
                      : Container(
                          width: width - 20,
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: new BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.rectangle,
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 5,
                                blurRadius: 7,
                                offset:
                                    Offset(0, 3), // changes position of shadow
                              ),
                            ],
                          ),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                        AppLocalizations.of(context)!
                                            .description,
                                        style: TextStyle(
                                          fontSize: 8,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black87,
                                        )),
                                    Text('${widget.descx}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ))
                                  ],
                                ),
                                widget.signal == null
                                    ? Container()
                                    : Row(
                                        children: [
                                          Text(
                                              AppLocalizations.of(context)!
                                                  .signal,
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black,
                                              )),
                                          widget.signal == 0
                                              ? Container()
                                              : RatingBarIndicator(
                                                  rating: widget.signal! / 20,
                                                  itemBuilder:
                                                      (context, index) => Icon(
                                                    Icons.circle,
                                                    color: widget.signal! <= 20
                                                        ? Colors.red
                                                        : widget.signal! <= 60
                                                            ? Colors.orange
                                                            : Colors.green,
                                                  ),
                                                  itemCount: 5,
                                                  itemSize: 10.0,
                                                  unratedColor:
                                                      Colors.grey.withAlpha(50),
                                                  direction: Axis.horizontal,
                                                ),
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                              widget.signal == 0
                                                  ? "-----------"
                                                  : "${widget.signal!} %",
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.normal,
                                                color: Colors.black,
                                              )),
                                        ],
                                      ),
                              ])),
                  SizedBox(
                    height: 5,
                  ),
                  Container(
                    width: width - 20,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: new BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppLocalizations.of(context)!.firmware_version,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.normal,
                              color: Colors.black87,
                            )),
                        Text('${widget.Firmware}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            )),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    width: width - 20,
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: new BoxDecoration(
                      color: Colors.black,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                            AppLocalizations.of(context)!
                                .devices_under_equipment,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.white,
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Expanded(
              child: SizedBox(
                  height: height / 1.2,
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : Container(
                          child: ps_info?['err'] == 404
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .no_response_from_server,
                                      style: TextStyle(
                                        fontSize: 0.025 * width,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                              : ps_info?['err'] == 504
                                  ? Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Center(
                                        child: Text(
                                          'Request Timeout (Try Refreshing)',
                                          style: TextStyle(
                                            fontSize: 0.025 * width,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )
                                  : ps_info?['err'] == 258
                                      ? Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Center(
                                            child: Text(
                                              AppLocalizations.of(context)!
                                                  .device_not_found,
                                              style: TextStyle(
                                                fontSize: 0.025 * width,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        )
                                      : ps_info?['err'] == 257
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Center(
                                                child: Text(
                                                  AppLocalizations.of(context)!
                                                      .collector_not_found,
                                                  style: TextStyle(
                                                    fontSize: 0.025 * width,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : ps_info?['dat']['device'] != null
                                              ? CollectorDevicesList(
                                                  CollectorDevicesStatus
                                                      .fromJson(ps_info!),
                                                  width,
                                                  height)
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Center(
                                                    child: Text(
                                                      'Unhandled Exception'
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                          fontSize:
                                                              0.025 * width,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                ))),
            )
          ],
        ),
      ),
    );
  }

  Widget CollectorDevicesList(
      CollectorDevicesStatus psinfo, double width, double height) {
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
                  SizedBox(height: 1),
                  Text('SN: ${PSINFO?.sn}',
                      style: TextStyle(
                        fontSize: 0.025 * (height - width),
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      )),
                ],
              ),
              subtitle: Column(
                children: [
                  SizedBox(height: 2),
                  // Row(
                  //   children: [
                  //     Text('Address: '.toUpperCase(),
                  //         style: TextStyle(
                  //             fontSize: 0.02 * (height-width),
                  //           fontWeight: FontWeight.normal,
                  //           color: Colors.black,)),
                  //     Text('${PSINFO?.devaddr}',
                  //         style: TextStyle(
                  //             fontSize: 0.028 * (height-width),
                  //             fontWeight: FontWeight.bold,
                  //             color: Colors.blue)),
                  //   ],
                  // ),
                  SizedBox(height: 1),
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.status_upper,
                          style: TextStyle(
                            fontSize: 0.02 * (height - width),
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          )),
                      Text(
                          (PSINFO?.status == 0)
                              ? 'ONLINE'
                              : (PSINFO?.status == 1)
                                  ? 'OFFLINE'
                                  : (PSINFO?.status == 2)
                                      ? 'FAULT'
                                      : (PSINFO?.status == 3)
                                          ? 'STANDBY'
                                          : (PSINFO?.status == 4)
                                              ? 'ALARM'
                                              : 'ERROR',
                          style: TextStyle(
                              fontSize: 0.025 * (height - width),
                              fontWeight: FontWeight.bold,
                              color: PSINFO?.status == 0
                                  ? Colors.green
                                  : PSINFO?.status == 1
                                      ? Colors.red
                                      : Colors.orange)),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.plant_upper,
                          style: TextStyle(
                            fontSize: 0.02 * (height - width),
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          )),
                      Text('${widget.plantname}',
                          style: TextStyle(
                              fontSize: 0.025 * (height - width),
                              fontWeight: FontWeight.bold,
                              color: Colors.blue)),
                    ],
                  ),
                  SizedBox(
                    height: 2,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(AppLocalizations.of(context)!.device_type_colon,
                          style: TextStyle(
                            fontSize: 0.02 * (height - width),
                            fontWeight: FontWeight.normal,
                            color: Colors.black,
                          )),
                      Text(
                          '${(PSINFO?.devcode == 530) ? 'Inverter' : (PSINFO?.devcode == 768) ? 'Env-monitor' : (PSINFO?.devcode == 1024) ? 'Smart meter' : (PSINFO?.devcode == 1280) ? 'Combining manifolds' : (PSINFO?.devcode == 1536) ? 'Camera' : (PSINFO?.devcode == 1792) ? 'Battery' : (PSINFO?.devcode == 2048) ? 'Charger' : (PSINFO?.devcode == 2304 || PSINFO?.devcode == 2452 || PSINFO?.devcode == 2449 || PSINFO?.devcode == 2400) ? 'Energy storage machine' : (PSINFO?.devcode == 2560) ? 'Anti-islanding' : (PSINFO?.devcode == -1) ? 'Datalogger' : PSINFO?.devcode}',
                          style: TextStyle(
                              fontSize: 0.022 * (height - width),
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  )
                ],
              ),
              trailing: Icon(Icons.arrow_right),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (BuildContext context) => deviceinfopage(
                          PN: widget.Pn,
                          SN: PSINFO?.sn,
                          status: PSINFO?.status,
                          devcode: PSINFO?.devcode,
                          devaddr: PSINFO?.devaddr,
                          alias: PSINFO?.devalias,
                          PID: widget.PID!,
                          load: widget.load,
                          Plantname: widget.plantname,
                          firmware: widget.Firmware,
                          outputpower: PSINFO?.outpower,
                          energytoday: PSINFO?.energyToday,
                          energytotal: PSINFO?.energyTotal,
                          energyyear: PSINFO?.energyYear,
                        )));
              },
            ),
          );
        });
  }

  //end of collector homestate
}
