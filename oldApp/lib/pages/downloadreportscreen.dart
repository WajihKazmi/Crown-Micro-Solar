//import 'dart:html';
import 'dart:convert';
import 'dart:io';

import 'package:crownmonitor/Models/Powerstation_Query_Response.dart';
import 'package:crownmonitor/datepickermodel.dart';
import 'package:crownmonitor/fontsizes.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart' as picker;
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class downloadreport extends StatefulWidget {
  final String Pn;
  const downloadreport({Key? key, required this.Pn}) : super(key: key);

  @override
  State<downloadreport> createState() => _downloadreportState();
}

class _downloadreportState extends State<downloadreport> {
  DateTime date1 = new DateTime(int.parse(DateTime.now().year.toString()),
      DateTime.now().month.toInt(), DateTime.now().day.toInt());
  late TextEditingController date = new TextEditingController();
  late List<bool> isSelected;
  late int indexpos = 0;
  late String _localPath;
  DateTime? pickeddate;
  bool isloading = false;

  @override
  void initState() {
    // TODO: implement initState
    pickeddate = DateTime.now();
    date.text = DateTime.now().year.toString() +
        '-' +
        DateTime.now().month.toString().padLeft(2, '0') +
        '-' +
        DateTime.now().day.toString().padLeft(2, '0');
    isSelected = [true, false, false, false];

    Requestpermission();
    super.initState();
  }

  Requestpermission() async {
    var status = await Permission.storage.status;
    print(status);

    switch (status) {
      case PermissionStatus.denied:
        // TODO: Handle this case.

        status = await Permission.storage.request();

        if (status == PermissionStatus.denied) {
          await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: Text(
                      "Need Stroage Permission",
                      style: TextStyle(fontSize: 20, color: Colors.black),
                    ),
                    content: Text(
                      "Please provide storage permission in order to download the file to the device.",
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
                            await openAppSettings();
                          },
                          child: Text(
                            "Open Application Settings",
                            style: TextStyle(fontSize: 16, color: Colors.blue),
                          )),
                    ],
                  ));
        }

        Requestpermission();

        break;
      case PermissionStatus.granted:
        print("permission grandted");
        // TODO: Handle this case.
        break;

      case PermissionStatus.permanentlyDenied:
        print('PermissionStatus.denied forever');
        //  await Permission.storage.request();
        await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text(
                    "Need Stroage Permission",
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                  content: Text(
                    "Please provide storage permission in order to download the file to the device.",
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
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
                          await openAppSettings();
                        },
                        child: Text(
                          "Open Application Settings",
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
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: new AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          leading: IconButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              )),
          title: Text(
            'Download',
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 0.03 * (height - width)),
          )),
      body: isloading
          ? Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 5,
                ),
                CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: 0.8 * width,
                  child: Center(
                    child: Text(
                      "Downloading Report Please Wait ...",
                      maxLines: 2,
                      style: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                          fontSize: 0.03 * (height - width)),
                    ),
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
              ],
            ))
          : Center(
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 5,
                ),
                Icon(
                  Icons.description_sharp,
                  size: 100,
                  color: Colors.grey.shade400,
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey.shade500,
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      SizedBox(
                        width: 0.8 * width,
                        child: Text(
                          "Select the daily, monthly or yearly tab and pick the date to download device's report on that particular date.",
                          maxLines: 2,
                          style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Colors.black,
                              fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 5,
                ),
                _toggle(width, height),
                SizedBox(
                  height: 5,
                ),
                _toggledown(width, height),
                SizedBox(
                  height: 5,
                ),
                SizedBox(
                  width: 0.8 * width,
                  height: 0.06 * height,
                  child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          elevation: 10,
                          shape: StadiumBorder(),
                          backgroundColor: Colors.green),
                      child: Text(
                        'Download',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                      onPressed: () async {
                        await downloadfile(height, width, indexpos, widget.Pn);
                      }),
                )
              ],
            )),
    );
  }

  Future<File?> downloadfile(
      double height, width, int indexpos, String PN) async {
    setState(() {
      isloading = true;
    });

    //logic check
    String? Year, Month, Day;
    if (indexpos == 0) {
      Year = DateFormat('y').format(pickeddate!);
      Month = DateFormat('M').format(pickeddate!);
      Day = DateFormat('d').format(pickeddate!);
      print(Year);
      print(Month);
      print(Day);
    } else if (indexpos == 1) {
      Month = DateFormat('M').format(pickeddate!);
      Year = DateFormat('y').format(pickeddate!);
      print(Year);
      print(Day);
    } else if (indexpos == 2) {
      Year = DateFormat('y').format(pickeddate!);
      print(Year);
    }
    print(Year.toString());
    print(Month.toString());
    print(Day.toString());

    //filename
    String filename = "CrownDeviceReport ${date.text}.xlsx";
    filename = filename.trim();

    //define download path android

    _localPath = "/storage/emulated/0/Download/";

    /// test
    Directory directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists())
      directory = (await getExternalStorageDirectories(
              type: StorageDirectory.downloads))!
          .first;

    // Directory? tempDir =
    //     (await getExternalStorageDirectories(type: StorageDirectory.downloads))!
    //         .first;
    // String tempPath = tempDir!.path;
    print(directory);

    /// test

    ///Url generation

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final Secret = prefs.getString('Secret') ?? '';
    String salt = "12345678";
    String action =
        "&action=exportCollectorsData&i18n=en_US&pns=$PN&year=$Year&month=$Month&day=$Day";

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

    var data = salt + Secret + token + action + postaction;
    var output = utf8.encode(data);
    var sign = sha1.convert(output).toString();
    //print('Sign: $sign');
    String url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}' +
            action +
            postaction;

    //print(url);

    try {
      //Request download
      //final Response = await Dio().download(url, _localPath + filename);
      final Response =
          await Dio().download(url, directory.path + '/' + filename);
      setState(() {
        isloading = false;
      });

      if (Response.statusCode == 200) {
        showDialog<void>(
            context: context,
            builder: (_) => SizedBox(
                  height: 0.4 * height,
                  child: AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                          size: 80,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          width: 0.7 * width,
                          //   color: Colors.amber,
                          child: Center(
                            child: Text(
                              'Report Downloaded Successfully',
                              maxLines: 2,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                  fontSize: 0.03 * (height - width)),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Container(
                          width: 0.8 * width,
                          //  color: Colors.amber,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.grey.shade500,
                                size: 10,
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Text(
                                'Check Downloads folder of your phone.',
                                maxLines: 2,
                                style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                    fontSize: 0.025 * (height - width)),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                    actions: [
                      Center(
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).pop();
                            },
                            child: Text("Ok")),
                      )
                    ],
                  ),
                ));
        ;
      } else {
        showDialog<void>(
            context: context,
            builder: (_) => SizedBox(
                  height: 0.4 * height,
                  child: AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 80,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          'Error',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                              fontSize: 0.04 * (height - width)),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.grey.shade500,
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text(
                              'Unable to download this file.',
                              style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                  fontSize: 0.03 * (height - width)),
                            ),
                          ],
                        )
                      ],
                    ),
                    actions: [
                      Center(
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context, rootNavigator: true).pop();
                            },
                            child: Text("close")),
                      )
                    ],
                  ),
                ));
      }
    } catch (e) {
      print(e.toString());
      setState(() {
        isloading = false;
      });
      return null;
    }
  }

  Widget _toggledown(double width, double height) {
    return Column(
      children: [
        SizedBox(
          width: width / 1.2,
          height: height / 22,
          child: indexpos == 3
              ? Container()
              : Card(
                  color: Colors.white38,
                  elevation: 5,
                  child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.date_range,
                        size: 18,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade800,
                      ),
                      label: Text(
                          indexpos == 0
                              ? DateFormat.yMMMMd()
                                  .format(DateTime.parse(date.text))
                              : date.text,
                          style: TextStyle(
                            fontSize: 0.03 * (height - width),
                          )),
                      onPressed: () async {
                        if (indexpos == 0) {
                          picker.DatePicker.showPicker(
                            context,
                            pickerModel: YearMonthDayModel(
                              currentTime: DateTime.now(),
                              maxTime: DateTime.now(),
                              minTime: DateTime(2015),
                              locale: picker.LocaleType.en,
                            ),
                            theme: picker.DatePickerTheme(
                                headerColor: Theme.of(context).primaryColor,
                                backgroundColor: Color(0xffF4F4F4),
                                itemStyle: TextStyle(
                                    color: Colors.black, fontSize: 10),
                                doneStyle: TextStyle(
                                    color: Colors.white, fontSize: 16)),
                            locale: picker.LocaleType.en,
                            onChanged: (date) {
                              print('change $date');
                            },
                            onConfirm: (datepick) {
                              pickeddate = datepick;
                              date.text = datepick.year.toString() +
                                  '-' +
                                  datepick.month.toString().padLeft(2, '0') +
                                  '-' +
                                  datepick.day.toString().padLeft(2, '0');
                              setState(() {});
                              // fetchCurrentPlantStats();
                              //  fetchActiveOuputPowerOneDay();
                            },
                          );
                        } else if (indexpos == 1) {
                          picker.DatePicker.showPicker(
                            context,
                            pickerModel: YearMonthModel(
                              currentTime: DateTime.now(),
                              maxTime: DateTime.now(),
                              minTime: DateTime(2015),
                              locale: picker.LocaleType.en,
                            ),
                            theme: picker.DatePickerTheme(
                                headerColor: Theme.of(context).primaryColor,
                                backgroundColor: Color(0xffF4F4F4),
                                itemStyle: TextStyle(
                                    color: Colors.black, fontSize: 10),
                                doneStyle: TextStyle(
                                    color: Colors.white, fontSize: 16)),
                            locale: picker.LocaleType.en,
                            onChanged: (date) {
                              print('change $date');
                            },
                            onConfirm: (datepick) {
                              pickeddate = datepick;
                              date.text = datepick.year.toString() +
                                  '-' +
                                  datepick.month.toString().padLeft(2, '0');
                              setState(() {});

                              //  fetchDailyPGIMonth();
                            },
                          );
                        } else if (indexpos == 2) {
                          picker.DatePicker.showPicker(
                            context,
                            pickerModel: YearModel(
                              currentTime: DateTime.now(),
                              maxTime: DateTime.now(),
                              minTime: DateTime(2015),
                              locale: picker.LocaleType.en,
                            ),
                            theme: picker.DatePickerTheme(
                                headerColor: Theme.of(context).primaryColor,
                                backgroundColor: Color(0xffF4F4F4),
                                itemStyle: TextStyle(
                                    color: Colors.black, fontSize: 10),
                                doneStyle: TextStyle(
                                    color: Colors.white, fontSize: 16)),
                            locale: picker.LocaleType.en,
                            onChanged: (date) {
                              print('change $date');
                            },
                            onConfirm: (datepick) {
                              pickeddate = datepick;
                              date.text = datepick.year.toString();
                              setState(() {});
                              // fetchMonthlyPGinyear();
                            },
                          );
                        }
                      }),
                ),
        ),
        SizedBox(
          height: height / 100,
        ),
      ],
    );
  }

  Widget _toggle(double width, double height) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          // width: width / 1.2,
          height: height * 0.03,
          child: Material(
            color: Colors.grey[350],
            borderRadius: BorderRadius.circular(10.0),
            child: ToggleButtons(
              color: Colors.black,
              selectedColor: Colors.white,
              fillColor: Theme.of(context).primaryColor,
              // splashColor: Colors.lightBlue,
              // highlightColor: Colors.lightBlue,
              borderColor: Colors.transparent,
              borderWidth: 0.1,
              selectedBorderColor: Colors.transparent,
              renderBorder: true,
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
              disabledColor: Colors.blueGrey,
              disabledBorderColor: Colors.blueGrey,
              //focusColor: Colors.red,
              // focusNodes: focusToggle,
              children: <Widget>[
                // first toggle button
                Container(
                  width: width / 5,
                  child: Text('Daily',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 0.025 * (height - width))

                      // style: Theme.of(context).textTheme.subtitle2,
                      ),
                ),
                // second toggle button
                Container(
                  width: width / 5,
                  child: Text('Monthly',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 0.025 * (height - width))
                      // style: Theme.of(context).textTheme.subtitle2,
                      ),
                ),
                Container(
                  width: width / 5,
                  child: Text('Yearly',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 0.025 * (height - width))
                      // style: Theme.of(context).textTheme.subtitle2,
                      ),
                ),
                Container(
                  width: width / 5,
                  child: Text('Overall',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 0.025 * (height - width))
                      // style: Theme.of(context).textTheme.subtitle2,
                      ),
                ),
              ],
              // logic for button selection below
              onPressed: (int index) {
                setState(() {
                  for (int i = 0; i < isSelected.length; i++) {
                    isSelected[i] = i == index;
                    // print(index);
                  }
                });
                if (index == 0) {
                  indexpos = 0;
                  setState(() {
                    // chart_label = 'Time';
                    // fetchActiveOuputPowerOneDay();
                  });
                  date1 = new DateTime(DateTime.now().year.toInt(),
                      DateTime.now().month.toInt(), DateTime.now().day.toInt());
                  date.text = date1.year.toString() +
                      '-' +
                      date1.month.toString().padLeft(2, '0') +
                      '-' +
                      date1.day.toString().padLeft(2, '0');
                } else if (index == 1) {
                  indexpos = 1;
                  date1 = new DateTime(DateTime.now().year.toInt(),
                      DateTime.now().month.toInt(), DateTime.now().day.toInt());
                  date.text = date1.year.toString() +
                      '-' +
                      date1.month.toString().padLeft(2, '0');
                  setState(() {
                    // chart_label = 'Day';
                    // _chartData = <Chartinfo>[];
                    // _chartData = _getday();
                    // fetchDailyPGIMonth();
                  });
                } else if (index == 2) {
                  date1 = new DateTime(
                      int.parse(DateTime.now().year.toString()),
                      DateTime.now().month.toInt(),
                      DateTime.now().day.toInt());
                  indexpos = 2;
                  date.text = date1.year.toString();

                  setState(() {
                    // chart_label = 'Month';
                    // fetchMonthlyPGinyear();
                  });
                } else if (index == 3) {
                  indexpos = 3;
                  date.clear();
                  setState(() {
                    // chart_label = 'Year';
                    // fetchAnnualPg();
                  });
                }
              },
              isSelected: isSelected,
            ),
          ),
        ),
      ],
    );
  }
}
