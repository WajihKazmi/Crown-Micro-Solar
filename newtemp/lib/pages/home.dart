// import 'package:crownmonitor/fontsizes.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crownmonitor/Models/ActiveOuputPowerOneDay.dart';
import 'package:crownmonitor/Models/AnnualPG.dart';
import 'package:crownmonitor/Models/AnnualPG2.dart';
import 'package:crownmonitor/Models/CollectorDevicesStatus.dart';
import 'package:crownmonitor/Models/CurrentOutputPowerofPS.dart';
import 'package:crownmonitor/Models/DailyPGinMonth.dart';
import 'package:crownmonitor/Models/DailyPGinMonth2.dart';
import 'package:crownmonitor/Models/DevicesofPlant.dart';
import 'package:crownmonitor/Models/MonthlyPGinyear.dart';
import 'package:crownmonitor/Models/MonthlyPGinyear2.dart';
import 'package:crownmonitor/Models/PowerGenerationRevenueCustomDate.dart';
import 'package:crownmonitor/Models/Powerstation_Query_Response.dart';
import 'package:crownmonitor/Models/QueryAlarmsOfAllPowerPlants.dart';
import 'package:crownmonitor/Models/QueryDeviceCount.dart';
import 'package:crownmonitor/Models/device_data_model.dart';
import 'package:crownmonitor/Models/device_data_model_details.dart';
import 'package:crownmonitor/datepickermodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart' as guage;

import 'AlramManagmentALLPlants.dart';
import 'login.dart';
import 'mainscreen.dart';

// import 'package:toggle_switch/toggle_switch.dart';

class Home extends StatefulWidget {
  String TotalPlants = '';
  String currency = '';

  //ALLplants Variables

  double _Current_outputPowerof_ALLPS = 00000;
  double _InstalledCapacityof_AllPS = 0.0;
  int plantcount = 0;
  int Devicecount = 0;
  int Alarmcount = 0;

  /// Total profits
  String totalco2_all = '0.0000';
  String totalso2_all = '0.0000';
  String totalcoal_all = '0.0000';
  String totalprofit_all = '0.0';
  String totalenergy_all = '0.0000';

  /// profits customdate
  String dateco2_all = '0.0000';
  String dateso2_all = '0.0000';
  String datecoal_all = '0.0000';
  String dateprofit_all = '0.0';
  String dateenergy_all = '0.0000';

  //last updated
  DateTime last_updated = DateTime.now();

  Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool downbtnpressed = false;
  ScrollController _homescrollcontroller = ScrollController();
  int plantID =
      0; //default 0//  plantid =1 to query plant no 2 from the list of power plants

  late List<Chartinfo> _chartData;
  String todayGeneration = "0.0000";
  String totalGeneration = "0.0000";
  late int indexpos = 0;
  late ZoomPanBehavior zoomPanBehavior;
  String chart_label = 'Time';

  /// togglle buuton position
  DateTime date1 = new DateTime(int.parse(DateTime.now().year.toString()),
      DateTime.now().month.toInt(), DateTime.now().day.toInt());
  late TextEditingController date = new TextEditingController();
  late List<bool> isSelected;

  String TotalPlants = '';
  String currency = '';
  String latestValue = "";

  int Page = 0; // 0 means first page
  int Pagesize = 1;
  double todayGenSum = 0.0;
  double totalGenSum = 0.0;
  //1 for querying only 1 plant per page
  late Timer _timer;
  DevlceDataModel? psInfo;
  var ps_Info2;
  DevlceDataModelDetails? psInfo2;
  String devcode = "";
  String devaddr = "";
  String pn = "";
  String sn = "";
  double combinedOutputPower = 0.0;
  String SN = '';
  String PN = '';

  // //ALLplants Variables

  // double _Current_outputPowerof_ALLPS = 00000;
  // double _InstalledCapacityof_AllPS = 0;
  // int plantcount = 0;
  // int Devicecount = 0;
  // int Alarmcount = 0;

  // /// Total profits
  // String totalco2_all = '0';
  // String totalso2_all = '0';
  // String totalcoal_all = '0';
  // String totalprofit_all = '0';
  // String totalenergy_all = '0';

  // /// profits customdate
  // String dateco2_all = '0';
  // String dateso2_all = '0';
  // String datecoal_all = '0';
  // String dateprofit_all = '0';
  // String dateenergy_all = '0';

  bool isAgent = false;

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

  //new chart variables
  var _trackballBehavior;
  final List<Color> color = <Color>[];
  final List<double> stops = <double>[];
  late LinearGradient gradientColors;

  /////
  ///
  @override
  void initState() {
    super.initState();
    date1 = new DateTime(int.parse(DateTime.now().year.toString()),
        DateTime.now().month.toInt(), DateTime.now().day.toInt());
    //_chartData = getChartData();
    WidgetsBinding.instance.addPostFrameCallback((t) async {
      Map<String, dynamic> ps_info = await DevicesofplantQuery(context,
          status: '0', devicetype: '0110', PID: 'all');

      psInfo = DevlceDataModel.fromJson(ps_info);
      for (int j = 0; j < psInfo!.dat.collector.length; j++) {
        ps_Info2 =
            await CollectorDevicesStatusQuery(PN: psInfo!.dat.collector[j].pn)
                .then((v) {
          psInfo2 = DevlceDataModelDetails.fromJson(v);

          if (psInfo2 != null && psInfo2!.dat.device.isNotEmpty) {
            for (int i = 0; i < psInfo2!.dat.device.length; i++) {
              fetch_allProfit_dateprofit_response(
                devaddr: psInfo2!.dat.device[i].devaddr.toString(),
                devcode: psInfo2!.dat.device[i].devcode.toString(),
                pn: psInfo2!.dat.device[i].pn,
                sn: psInfo2!.dat.device[i].sn,
              );
            }
          }
        });
      }

      indexpos = 0;
      setState(() {
        // devcode = psInfo2!.dat.device[0].devcode.toString();
        // devaddr = psInfo2!.dat.device[0].devaddr.toString();
        // pn = psInfo2!.dat.device[0].pn;
        // sn = psInfo2!.dat.device[0].sn.toString();
        // print(psInfo2?.dat.device[0].pn);
        // print(psInfo2?.dat.device[0].sn);
        // print(devcode);
        // print(devaddr);
        // print(pn);
        // print(sn);
        chart_label = 'Time';
        fetchGraphData();
      });
      date1 = new DateTime(DateTime.now().year.toInt(),
          DateTime.now().month.toInt(), DateTime.now().day.toInt());
      date.text = date1.year.toString() +
          '-' +
          date1.month.toString().padLeft(2, '0') +
          '-' +
          date1.day.toString().padLeft(2, '0');
    });

    _chartData = _getday();
    loadAgent();

    // _chartData1 = _dailyPower();
    _trackballBehavior = TrackballBehavior(
        // Enables the trackball
        enable: true,
        tooltipSettings: InteractiveTooltip(
            enable: true,
            color: Colors.white,
            textStyle: TextStyle(
              color: Colors.black,
            )));
    zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true,
    );

    date.text = DateTime.now().year.toString() +
        '-' +
        DateTime.now().month.toString().padLeft(2, '0') +
        '-' +
        DateTime.now().day.toString().padLeft(2, '0');

    isSelected = [true, false, false, false];
    focusToggle = [
      focusNodeButton1,
      focusNodeButton2,
      focusNodeButton3,
      focusNodeButton4,
    ];
    fetchGraphData();
    fetchCurrentouputPowerALLPS();
    fetchCurrentPlantStats();
    fetchPowerGenerationRevenue();
    fetchPlantcount_alarams_devicecount();
    // fetchDailyPGIMonth();
    _timer = new Timer.periodic(const Duration(seconds: 30),
        (Timer _timer) => fetchCurrentouputPowerALLPS());

    //fetchActiveOuputPowerOneDay();
  }

  Future loadAgent() async {
    var prefs = await SharedPreferences.getInstance();
    isAgent = prefs.getBool('isInstaller') ?? false;
  }

  FocusNode focusNodeButton1 = FocusNode();
  FocusNode focusNodeButton2 = FocusNode();
  FocusNode focusNodeButton3 = FocusNode();
  FocusNode focusNodeButton4 = FocusNode();

  late List<FocusNode> focusToggle;

  @override
  void dispose() {
    focusNodeButton1.dispose();
    focusNodeButton2.dispose();
    focusNodeButton3.dispose();
    focusNodeButton4.dispose();
    _timer.cancel();
    super.dispose();
  }

  Widget _toggle(double width, double height) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
            width: width / 12,
            child: TextButton(
              onPressed: () {
                if (indexpos == 0) {
                  date1 = new DateTime(date1.year, date1.month, date1.day - 1);
                  setState(() {});
                  date.text = date1.year.toString() +
                      '-' +
                      date1.month.toString().padLeft(2, '0') +
                      '-' +
                      date1.day.toString().padLeft(2, '0');
                  print(date.text);
                  setState(() {
                    fetchGraphData();
                  });
                } else if (indexpos == 1) {
                  date1 = new DateTime(date1.year, date1.month - 1, date1.day);
                  date.text = date1.year.toString() +
                      '-' +
                      date1.month.toString().padLeft(2, '0');
                  setState(() {
                    fetchDailyPGIMonth();
                  });
                } else if (indexpos == 2) {
                  date1 = new DateTime(date1.year - 1, date1.month, date1.day);

                  date.text = date1.year.toString();
                  setState(() {
                    fetchMonthlyPGinyear();
                  });
                } else if (indexpos == 3) {
                  date.clear();
                  setState(() {
                    fetchAnnualPg();
                  });
                }
              },
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 20,
              ),
            )),
        SizedBox(
          // width: width / 1.3,
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
              focusColor: Colors.red,
              focusNodes: focusToggle,
              children: <Widget>[
                // first toggle button
                Container(
                  width: width / 6,
                  child: Text(
                    'Day',
                    textAlign: TextAlign.center,
                    // style: Theme.of(context).textTheme.subtitle2,
                  ),
                ),
                // second toggle button
                Container(
                  width: width / 6,
                  child: Text(
                    'Month',
                    textAlign: TextAlign.center,
                    // style: Theme.of(context).textTheme.subtitle2,
                  ),
                ),
                Container(
                  width: width / 6,
                  child: Text(
                    'Year',
                    textAlign: TextAlign.center,
                    // style: Theme.of(context).textTheme.subtitle2,
                  ),
                ),
                Container(
                  width: width / 6,
                  child: Text(
                    'Total',
                    textAlign: TextAlign.center,
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
                    chart_label = 'Time';
                    fetchGraphData();
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
                    chart_label = 'Day';
                    // _chartData = <Chartinfo>[];
                    // _chartData = _getday();
                    fetchDailyPGIMonth();
                  });
                } else if (index == 2) {
                  date1 = new DateTime(
                      int.parse(DateTime.now().year.toString()),
                      DateTime.now().month.toInt(),
                      DateTime.now().day.toInt());
                  indexpos = 2;
                  date.text = date1.year.toString();

                  setState(() {
                    chart_label = 'Month';
                    fetchMonthlyPGinyear();
                  });
                } else if (index == 3) {
                  indexpos = 3;
                  date.clear();
                  setState(() {
                    chart_label = 'Year';
                    fetchAnnualPg();
                  });
                }
              },
              isSelected: isSelected,
            ),
          ),
        ),
        SizedBox(
          width: width / 12,
          child: TextButton(
            onPressed: () {
              DateTime currentDate = DateTime.now();

              if (indexpos == 0) {
                // Daily: Increment by one day
                DateTime nextDate =
                    DateTime(date1.year, date1.month, date1.day + 1);
                if (nextDate.isAfter(currentDate)) return;

                date1 = nextDate;
                date.text =
                    '${date1.year}-${date1.month.toString().padLeft(2, '0')}-${date1.day.toString().padLeft(2, '0')}';
                print(date.text);
                setState(() {
                  fetchGraphData();
                });
              } else if (indexpos == 1) {
                // Monthly: Increment by one month
                DateTime nextDate =
                    DateTime(date1.year, date1.month + 1, date1.day);
                if (nextDate.isAfter(currentDate)) return;

                date1 = nextDate;
                date.text =
                    '${date1.year}-${date1.month.toString().padLeft(2, '0')}';
                setState(() {
                  fetchDailyPGIMonth();
                });
              } else if (indexpos == 2) {
                // Yearly: Increment by one year
                DateTime nextDate =
                    DateTime(date1.year + 1, date1.month, date1.day);
                if (nextDate.isAfter(currentDate)) return;

                date1 = nextDate;
                date.text = '${date1.year}';
                setState(() {
                  fetchMonthlyPGinyear();
                });
              } else if (indexpos == 3) {
                // Annual: Clear date
                date.clear();
                setState(() {
                  fetchAnnualPg();
                });
              }
            },
            child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _getRadialGauge(double width, double height) {
    return guage.SfRadialGauge(axes: <guage.RadialAxis>[
      guage.RadialAxis(
          axisLineStyle: guage.AxisLineStyle(
            cornerStyle: guage.CornerStyle.bothCurve,
            thickness: 0.12,
            thicknessUnit: guage.GaugeSizeUnit.factor,
          ),
          interval: 0.1 * widget._InstalledCapacityof_AllPS == 0
              ? 0.1 * 5000
              : 0.1 * widget._InstalledCapacityof_AllPS,
          showTicks: false,

          // startAngle: 270,
          // endAngle: 270,
          minimum: 0,
          maximum: (widget._InstalledCapacityof_AllPS == 0)
              ? 5000
              : widget._InstalledCapacityof_AllPS,
          pointers: <guage.GaugePointer>[
            guage.RangePointer(
                dashArray: [width * 0.01, width * 0.04],
                width: width * 0.00015,
                pointerOffset: -width * 0.0002,
                sizeUnit: guage.GaugeSizeUnit.factor,
                value: widget._Current_outputPowerof_ALLPS,
                cornerStyle: guage.CornerStyle.bothCurve,
                color: Colors.redAccent.shade400),
            guage.MarkerPointer(
              value: widget._Current_outputPowerof_ALLPS,
              markerOffset: -15,
              markerWidth: width * 0.05,
              markerHeight: height * 0.015,
              color: Colors.redAccent.shade400,
            ),
          ],
          ranges: <guage.GaugeRange>[
            guage.GaugeRange(
                startWidth: width * 0.04,
                startValue: 0,
                endValue: (0.2 * widget._InstalledCapacityof_AllPS == 0)
                    ? 0.2 * 5000
                    : 0.2 * widget._InstalledCapacityof_AllPS,
                color: Colors.red),
            guage.GaugeRange(
                startValue: (0.2 * widget._InstalledCapacityof_AllPS == 0)
                    ? 0.2 * 5000
                    : 0.2 * widget._InstalledCapacityof_AllPS,
                endValue: (0.7 * widget._InstalledCapacityof_AllPS == 0)
                    ? 0.7 * 5000
                    : 0.7 * widget._InstalledCapacityof_AllPS,
                color: Colors.orange),
            guage.GaugeRange(
                endWidth: width * 0.04,
                startValue: (0.7 * widget._InstalledCapacityof_AllPS == 0)
                    ? 0.7 * 5000
                    : 0.7 * widget._InstalledCapacityof_AllPS,
                endValue: widget._InstalledCapacityof_AllPS == 0
                    ? 5000
                    : widget._InstalledCapacityof_AllPS,
                color: Colors.green)
          ],
          annotations: <guage.GaugeAnnotation>[
            guage.GaugeAnnotation(
              widget: Container(
                  child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.current_power_generation,
                    style: TextStyle(
                        fontSize: width / 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  SizedBox(height: height * 0.001),
                  Text(
                    AppLocalizations.of(context)!.all_powerstations,
                    style: TextStyle(
                        fontSize: width / 45,
                        fontWeight: FontWeight.w400,
                        color: Colors.black),
                  ),
                  SizedBox(height: height * 0.003),
                  Text(
                    latestValue + ' kW',
                    style: TextStyle(
                        fontSize: width / 45,
                        fontWeight: FontWeight.w900,
                        color: Colors.lightGreen.shade800),
                  ),
                  Container(
                    padding: EdgeInsets.all(2),
                    width: MediaQuery.of(context).size.width / 3.2,
                    child: Divider(
                        thickness: 1,
                        height: height * 0.002,
                        color: Colors.black),
                  ),
                  Container(
                    padding: EdgeInsets.all(4),
                    width: MediaQuery.of(context).size.width / 3.2,
                    child: Divider(
                        thickness: 1,
                        height: height * 0.002,
                        color: Colors.black),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.total_plants,
                        style: TextStyle(
                            fontSize: width / 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      Text(
                        widget.plantcount.toString(),
                        style: TextStyle(
                            fontSize: width / 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: height * 0.001,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.total_devices,
                        style: TextStyle(
                            fontSize: width / 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      Text(
                        widget.Devicecount.toString(),
                        style: TextStyle(
                            fontSize: width / 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: height * 0.001,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.total_alarms,
                        style: TextStyle(
                            fontSize: width / 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      Text(widget.Alarmcount.toString(),
                          style: TextStyle(
                              fontSize: width / 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent)),
                    ],
                  ),
                ],
              )),
              angle: 90,
              positionFactor: 0.7,
            )
          ])
    ]);
  }

  Widget _toggledown(double width, double height) {
    return Column(
      children: [
        SizedBox(
            width: width / 1.5,
            height: height / 22,
            child: indexpos == 3
                ? Container()
                : Card(
                    color: Colors.white38,
                    elevation: 5,
                    child: OutlinedButton.icon(
                        icon: Icon(
                          Icons.date_range,
                          size: 15,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade100,
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
                                date.text = datepick.year.toString() +
                                    '-' +
                                    datepick.month.toString().padLeft(2, '0') +
                                    '-' +
                                    datepick.day.toString().padLeft(2, '0');
                                // fetchCurrentPlantStats();
                                // fetchActiveOuputPowerOneDay();
                                fetchGraphData();
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
                                date.text = datepick.year.toString() +
                                    '-' +
                                    datepick.month.toString().padLeft(2, '0');

                                fetchDailyPGIMonth();
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
                                date.text = datepick.year.toString();
                                fetchMonthlyPGinyear();
                              },
                            );
                          }
                        }),
                  )),
      ],
    );
  }

  Widget _display(double x, double y, String name, String number, String name1,
      String number1, Icon icon1, Icon icon) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10),
        width: y,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Card(
              elevation: 1,
              color: Colors.white70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
                    child: Container(child: icon1),
                  ),
                  Container(
                      height: x / 18,
                      width: y / 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8.0),
                          bottomRight: Radius.circular(8.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                    fontSize: 0.024 * (x - y),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600),
                              ),
                              SizedBox(height: 5),
                              Text(
                                number,
                                style: TextStyle(
                                    fontSize: 0.024 * (x - y),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.lightBlue),
                              )
                            ],
                          ),
                        ],
                      ))
                ],
              ),
            ),
            Card(
              elevation: 1,
              color: Colors.white70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
                    child: Container(child: icon),
                  ),
                  Container(
                      height: x / 18,
                      width: y / 3,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(8.0),
                          bottomRight: Radius.circular(8.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name1,
                                style: TextStyle(
                                    fontSize: 0.024 * (x - y),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800),
                              ),
                              SizedBox(height: 5),
                              Text(
                                number1,
                                style: TextStyle(
                                    fontSize: 0.024 * (x - y),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.lightBlue),
                              ),
                            ],
                          ),
                        ],
                      ))
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chart(double width, double height) {
    return SafeArea(
      child: SfCartesianChart(
        enableAxisAnimation: true,
        zoomPanBehavior: zoomPanBehavior,
        tooltipBehavior: TooltipBehavior(enable: true),
        trackballBehavior: _trackballBehavior,
        series: <ChartSeries>[
          // Area and Spline Series (Only for Day option)
          if (indexpos == 0) ...[
            // Area Series
            AreaSeries<Chartinfo, dynamic>(
              name: 'Power',
              color: Colors.red.withOpacity(0.6),
              gradient: LinearGradient(
                colors: [
                  Colors.red.withOpacity(0.6),
                  Colors.orange.withOpacity(0.2),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              dataSource: _chartData,
              xValueMapper: (Chartinfo exp, _) => exp.chartinfocategory,
              yValueMapper: (Chartinfo exp, _) => double.parse(exp.name1),
              markerSettings: MarkerSettings(isVisible: false),
            ),

            // Spline Series for Overlay
            SplineSeries<Chartinfo, dynamic>(
              splineType: SplineType.natural, // Smooth Line
              name: 'Power Line',
              color: Colors.orange,
              width: 2,
              dataSource: _chartData,
              xValueMapper: (Chartinfo exp, _) => exp.chartinfocategory,
              yValueMapper: (Chartinfo exp, _) => double.parse(exp.name1),
              markerSettings: MarkerSettings(isVisible: false),
            ),
          ],

          // Bar Series (Only for Month, Year, Total options)
          if (indexpos != 0)
            ColumnSeries<Chartinfo, dynamic>(
              name: 'Power Column',
              color: Colors.orange,
              dataSource: _chartData,
              xValueMapper: (Chartinfo exp, _) => exp.chartinfocategory,
              yValueMapper: (Chartinfo exp, _) => double.parse(exp.name1),
              dataLabelSettings: DataLabelSettings(isVisible: true),
            ),
        ],
        primaryXAxis: CategoryAxis(
          // Use CategoryAxis for consistency
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: Colors.white30,
            dashArray: <double>[5, 5],
          ),
          labelStyle: TextStyle(color: Colors.white70),
          title: AxisTitle(
            text: chart_label,
            textStyle: TextStyle(
              color: Colors.deepOrange,
              fontFamily: 'Roboto',
              fontSize: width * 0.03,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        primaryYAxis: NumericAxis(
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: Colors.white30,
            dashArray: <double>[5, 5],
          ),
          labelStyle: TextStyle(color: Colors.white70),
          title: AxisTitle(
            text: 'Power (kWh)',
            textStyle: TextStyle(
              color: Colors.deepOrange,
              fontFamily: 'Roboto',
              fontSize: width * 0.03,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        backgroundColor: Colors.black,
      ),
    );
  }

  void _scrollDown() {
    _homescrollcontroller.animateTo(
        _homescrollcontroller.position.maxScrollExtent,
        duration: Duration(milliseconds: 500),
        curve: Curves.ease);
    setState(() {
      downbtnpressed = true;
    });
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

    //////gradient
    color.add(Colors.orange[400]!);
    color.add(Colors.red[700]!);
    color.add(Colors.red);
    stops.add(0.0);
    stops.add(0.5);
    stops.add(1.0);

    gradientColors = LinearGradient(colors: color, stops: stops);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: Scaffold(
        floatingActionButton: downbtnpressed
            ? Container()
            : FloatingActionButton.small(
                onPressed: _scrollDown,
                child: Icon(Icons.arrow_downward),
                backgroundColor: Colors.grey.withOpacity(0.2)),
        appBar: AppBar(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppLocalizations.of(context)!.plant_information,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 0.045 * (height - width))),
              // Text(" Overview",
              //     style: TextStyle(
              //         color: Colors.grey.shade800,
              //         fontWeight: FontWeight.w300,
              //         fontSize: 0.03 * (height - width))),
            ],
          ),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AlarmManagementALLPLants()));
                },
                icon: Icon(
                  Icons.notifications,
                  size: 25,
                  color: Colors.white,
                )),
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
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          controller: _homescrollcontroller,
          child: Container(
            color: Colors.black12,
            //height: height,
            //width: width,
            child: Stack(
              children: <Widget>[
                Container(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          SizedBox(height: height * 0.01),
                          // SizedBox(
                          //     // width: width / 1.3,
                          //     // height: height / 3.1,
                          //     width: width / 1,
                          //     height: height / 3,
                          //     child: _getRadialGauge(width, height)),
                          Container(
                            width: 0.95 * width,
                            height: 0.25 * height,
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade400,
                                    blurRadius: 120,
                                    spreadRadius: 2,
                                    offset: Offset(2, 2),
                                  )
                                ],
                                borderRadius: BorderRadius.circular(20)),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .current_power_generation,
                                    style: TextStyle(
                                        fontSize: 0.04 *
                                            (height - width), //0.045*width,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                  SizedBox(height: height * 0.001),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .all_powerstations,
                                    style: TextStyle(
                                        fontSize: 0.022 * (height - width),
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black),
                                  ),
                                  // SizedBox(height: height * 0.01),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        // widget._Current_outputPowerof_ALLPS
                                        //     .toString(),
                                        combinedOutputPower.toStringAsFixed(2),
                                        style: TextStyle(
                                            fontSize: 0.14 * (height - width),
                                            shadows: [
                                              BoxShadow(
                                                color: Colors.grey.shade400,
                                                blurRadius: 15,
                                                spreadRadius: 3,
                                                offset: Offset(2, 2),
                                              )
                                            ],
                                            fontWeight: FontWeight.w900,
                                            color:
                                                Theme.of(context).primaryColor),
                                      ),
                                      Text(
                                        widget._Current_outputPowerof_ALLPS >=
                                                1000
                                            ? 'MW'
                                            : ' kW',
                                        style: TextStyle(
                                            fontSize: 0.035 * (height - width),
                                            fontWeight: FontWeight.w900,
                                            color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),

                                  SizedBox(height: height * 0.001),
                                  Container(
                                    width: 0.95 * width,
                                    padding: EdgeInsets.only(left: 15),
                                    child: Text(
                                      'Last updated: ${DateFormat('h:mm a').format(widget.last_updated)}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 0.026 * (height - width),
                                          fontWeight: FontWeight.normal,
                                          color: Colors.blueGrey),
                                    ),
                                  ),
                                ]),
                          ),
                          SizedBox(height: height * 0.01),
                          Card(
                            color: Colors.white70,
                            elevation: 2,
                            child: Container(
                              height: 0.06 * height,
                              width: 0.95 * width,
                              padding: EdgeInsets.all(2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Card(
                                    elevation: 3,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      child: InkWell(
                                        onTap: (() {
                                          Navigator.pushAndRemoveUntil(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      MainScreen(
                                                        passed_index: 1,
                                                      )),
                                              (route) => false);
                                        }),
                                        child: Icon(
                                          Icons.storage_outlined,
                                          size: 0.03 * height,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Card(
                                    elevation: 3,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.devices,
                                        size: 0.03 * height,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                  Card(
                                    elevation: 3,
                                    child: Container(
                                      padding: EdgeInsets.all(4),
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      AlarmManagementALLPLants()));
                                        },
                                        child: Icon(
                                          Icons.warning_amber,
                                          size: 0.03 * height,
                                          color: Colors.redAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            color: Colors.white70,
                            elevation: 2,
                            child: Container(
                              width: 0.95 * width,
                              padding: EdgeInsets.all(8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(children: [
                                    Text(
                                        AppLocalizations.of(context)!
                                            .total_plants,
                                        style: TextStyle(
                                          fontSize: 0.024 * (height - width),
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black54,
                                        )),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Text('${widget.plantcount.toString()}',
                                        style: TextStyle(
                                            fontSize: 0.035 * (height - width),
                                            fontWeight: FontWeight.w800,
                                            color: Colors.blue)),
                                  ]),
                                  Column(children: [
                                    Text(
                                        AppLocalizations.of(context)!
                                            .total_devices,
                                        style: TextStyle(
                                          fontSize: 0.024 * (height - width),
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black54,
                                        )),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Text('${widget.Devicecount.toString()}',
                                        style: TextStyle(
                                            fontSize: 0.035 * (height - width),
                                            fontWeight: FontWeight.w800,
                                            color: Colors.blue)),
                                  ]),
                                  Column(children: [
                                    Text(
                                        AppLocalizations.of(context)!
                                            .total_alarms,
                                        style: TextStyle(
                                          fontSize: 0.024 * (height - width),
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black54,
                                        )),
                                    SizedBox(
                                      height: 2,
                                    ),
                                    Text('${widget.Alarmcount.toString()}',
                                        style: TextStyle(
                                            fontSize: 0.035 * (height - width),
                                            fontWeight: FontWeight.w800,
                                            color: Colors.red)),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                          Card(
                            color: Colors.blueGrey.shade300,
                            elevation: 2,
                            child: Container(
                              width: 0.95 * width,
                              height: 0.075 * height,
                              padding: EdgeInsets.all(5),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                            AppLocalizations.of(context)!
                                                .total_output_power,
                                            style: TextStyle(
                                              fontSize:
                                                  0.023 * (height - width),
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black54,
                                            )),
                                        Text(
                                          AppLocalizations.of(context)!
                                              .all_powerstations,
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                              fontSize:
                                                  0.018 * (height - width),
                                              color: Colors.black54),
                                        ),
                                        SizedBox(
                                          height: 0.008 * height,
                                        ),
                                        Text(
                                            // '${widget.totalenergy_all.substring(0, widget.totalenergy_all.indexOf('.') + 3)} kWh',
                                            '${totalGenSum} kWh',
                                            style: TextStyle(
                                                fontSize:
                                                    0.024 * (height - width),
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white)),
                                      ]),
                                  Card(
                                    child: Icon(
                                      Icons.flash_on,
                                      size: 0.04 * height,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                            AppLocalizations.of(context)!
                                                .installed_capacity,
                                            style: TextStyle(
                                              fontSize:
                                                  0.023 * (height - width),
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black54,
                                            )),
                                        Text(
                                            AppLocalizations.of(context)!
                                                .all_powerstations,
                                            style: TextStyle(
                                              fontSize:
                                                  0.018 * (height - width),
                                              fontWeight: FontWeight.normal,
                                              color: Colors.black54,
                                            )),
                                        SizedBox(
                                          height: 0.008 * height,
                                        ),
                                        Text(
                                            "${widget._InstalledCapacityof_AllPS.toStringAsFixed(1)} kW",
                                            style: TextStyle(
                                                fontSize:
                                                    0.024 * (height - width),
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white)),
                                      ]),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.005),
                          Container(
                            width: width,
                            height: 0.4 * height,
                            color: Colors.grey[900],
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Column(
                                children: [
                                  _toggle(width, height),
                                  _toggledown(width, height),
                                  Center(
                                    child: Container(
                                      width: width / 0.9,
                                      height: height / 4,
                                      child: _chartData.length != 0
                                          ? _chart(width, height)
                                          : Container(
                                              padding: EdgeInsets.only(top: 0),
                                              child: Center(
                                                  child: Text(
                                                      AppLocalizations.of(
                                                              context)!
                                                          .msg_no_data,
                                                      style: TextStyle(
                                                          color: Colors
                                                              .grey.shade500,
                                                          fontSize: 50,
                                                          fontWeight: FontWeight
                                                              .w100))),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(
                            height: height / 30,
                          ),
                          _display(
                              height,
                              width,
                              AppLocalizations.of(context)!.power_today,
                              todayGenSum.toString() + ' kWh',
                              // widget.dateenergy_all.substring(0,
                              //         widget.dateenergy_all.indexOf('.') + 3) +
                              //     ' kWh',
                              AppLocalizations.of(context)!.total_power,
                              totalGenSum.toString() + ' kWh',
                              // widget.totalenergy_all.substring(0,
                              //         widget.totalenergy_all.indexOf('.') + 3) +
                              //     ' kWh',
                              Icon(
                                Icons.flash_on,
                                color: Theme.of(context).primaryColor,
                              ),
                              Icon(Icons.flash_on,
                                  color: Theme.of(context).primaryColor)),
                          SizedBox(
                            height: height / 200,
                          ),
                          _display(
                              height,
                              width,
                              AppLocalizations.of(context)!.profit_today,
                              widget.dateprofit_all.substring(0,
                                      widget.dateprofit_all.indexOf('.') + 2) +
                                  ' ' +
                                  currency,

                              // double.parse(energyProceed.substring(
                              //     1, energyProceed.length)),
                              AppLocalizations.of(context)!.total_profit,
                              widget.totalprofit_all.substring(0,
                                      widget.totalprofit_all.indexOf('.') + 2) +
                                  ' ' +
                                  currency,
                              Icon(
                                Icons.monetization_on,
                                color: Theme.of(context).primaryColor,
                              ),
                              Icon(Icons.monetization_on,
                                  color: Theme.of(context).primaryColor)),
                          SizedBox(
                            height: height / 200,
                          ),
                          _display(
                              height,
                              width,
                              AppLocalizations.of(context)!.reduce_co2_today,
                              widget.dateco2_all.substring(
                                      0, widget.dateco2_all.indexOf('.') + 3) +
                                  ' kg',
                              AppLocalizations.of(context)!.total_reduce_co2,
                              widget.totalco2_all.substring(
                                      0, widget.totalco2_all.indexOf('.') + 3) +
                                  ' kg',
                              Icon(
                                Icons.graphic_eq,
                                color: Theme.of(context).primaryColor,
                              ),
                              Icon(Icons.graphic_eq,
                                  color: Theme.of(context).primaryColor)),
                          SizedBox(
                            height: height / 200,
                          ),
                          _display(
                              height,
                              width,
                              AppLocalizations.of(context)!.reduce_so2_today,
                              widget.dateso2_all.substring(
                                      0, widget.dateso2_all.indexOf('.') + 3) +
                                  ' kg',
                              AppLocalizations.of(context)!.total_reduce_so2,
                              widget.totalso2_all.substring(
                                      0, widget.totalso2_all.indexOf('.') + 3) +
                                  ' kg',
                              Icon(
                                Icons.graphic_eq,
                                color: Theme.of(context).primaryColor,
                              ),
                              Icon(Icons.graphic_eq,
                                  color: Theme.of(context).primaryColor)),
                          SizedBox(
                            height: height / 200,
                          ),
                          _display(
                              height,
                              width,
                              AppLocalizations.of(context)!.coal_saved_today,
                              widget.datecoal_all.substring(
                                      0, widget.datecoal_all.indexOf('.') + 3) +
                                  ' kg',
                              AppLocalizations.of(context)!.total_coal_saved,
                              widget.totalcoal_all.substring(0,
                                      widget.totalcoal_all.indexOf('.') + 3) +
                                  ' kg',
                              Icon(
                                Icons.graphic_eq,
                                color: Theme.of(context).primaryColor,
                              ),
                              Icon(Icons.graphic_eq,
                                  color: Theme.of(context).primaryColor)),
                          SizedBox(
                            height: height / 30,
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Chartinfo> _getday() {
    List<Chartinfo> chartData = [
      Chartinfo(
        DateTime(2022, 7, 8, 1, 10),
        '0',
      ),
      Chartinfo(
        DateTime(2022, 7, 8, 2, 10),
        '0',
      ),
      Chartinfo(
        DateTime(2022, 7, 8, 3, 10),
        '0',
      ),
      Chartinfo(
        DateTime(2022, 7, 8, 4, 10),
        '0',
      ),
      Chartinfo(
        DateTime(2022, 7, 8, 5, 10),
        '0',
      ),
    ];
    return chartData;
  }

  List<String> Months = [
    'jan',
    'feb',
    'mar',
    'apr',
    'may',
    'jun',
    'jul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec'
  ];

  var loadPowerGraphData;

  var gridPowerGraphData;

  var batteryPowerGraphData;

  var pvPowerGraphData;

  /////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////
  Future<void> _refreshData() async {
    await Future.delayed(Duration(milliseconds: 1000));
    fetchCurrentouputPowerALLPS();
    fetchCurrentPlantStats();
    fetchPowerGenerationRevenue();
    fetchPlantcount_alarams_devicecount();
    fetch_allProfit_dateprofit_response(
        devaddr: psInfo2!.dat.device[0].devaddr.toString(),
        devcode: psInfo2!.dat.device[0].devcode.toString(),
        pn: psInfo2!.dat.device[0].pn,
        sn: psInfo2!.dat.device[0].sn);
    fetchGraphData();
  }
  ///////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////

  Future fetchPowerGenerationRevenue() async {
    ///date format YYYY-MM-DD
    String formatted_date =
        ('${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}');

    var Jsonresponse_PowerGenerationRevenueCustomdate =
        await PowerGenerationRevenueCustomQuery(
            Date: date.text == '' || date.text.length <= 9
                ? formatted_date
                : date.text,
            Page: Page,
            Pagesize: 1);
    if (Jsonresponse_PowerGenerationRevenueCustomdate['err'] == 0) {
      PowerGenerationRevenueCustomDate _PGRCD =
          new PowerGenerationRevenueCustomDate.fromJson(
              Jsonresponse_PowerGenerationRevenueCustomdate);
    }
  }

  ///////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////

  Future fetch_allProfit_dateprofit_response(
      {required String devcode,
      required String devaddr,
      required String pn,
      required String sn}) async {
    ///date format YYYY-MM-DD
    String formatted_date =
        ('${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}');

    //for all profit response
    var Profitsresponse = await queryPlantsProfitStatistic(Date: 'all');
    //for customdate profit response
    // var dateProfitsresponse = await queryPlantsProfitStatistic2(
    //     // Date:
    //     //     date.text == '' || date.text.length <= 9 ? formatted_date : date.text,
    //     devcode: devcode,
    //     devaddr: devaddr,
    //     pn: pn,
    //     sn: sn);
    var dateProfitsresponse = await queryPlantsProfitStatistic3(
        // Date:
        //     date.text == '' || date.text.length <= 9 ? formatted_date : date.text,
        // devcode: devcode,
        // devaddr: devaddr,
        // pn: pn,
        sn: sn);
    if (Profitsresponse['err'] == 0 && mounted) {
      Showsnackbar(
          AppLocalizations.of(context)!.powersation_information_updated,
          800,
          Colors.green);
    } else {
      Showsnackbar(" ${Profitsresponse['desc']} ", 1500, Colors.red);
    }
    // List<dynamic> parameters = dateProfitsresponse['dat']["device"];
    setState(() {
      ////ALLplants Total profits
      if (Profitsresponse['err'] == 0) {
        widget.totalco2_all = Profitsresponse['dat']['co2'];
        widget.totalso2_all = Profitsresponse['dat']['so2'];
        widget.totalcoal_all = Profitsresponse['dat']['coal'];
        widget.totalprofit_all = Profitsresponse['dat']['profit'];
        widget.totalenergy_all = Profitsresponse['dat']['energy'];
        currency = Profitsresponse['dat']['currency'] ?? '';
      }

      ////ALLplants profits customdate
      if (dateProfitsresponse['err'] == 0) {
        // for (var param in parameters) {
        //   if (param["par"] == "energy_today") {
        //     todayGeneration = param["val"];
        //   } else if (param["par"] == "energy_total") {
        //     totalGeneration = param["val"];
        //   }
        for (var device in dateProfitsresponse['dat']["device"]) {
          todayGenSum += double.tryParse(device["energyToday"]) ?? 0.0;
          totalGenSum += double.tryParse(device["energyTotal"]) ?? 0.0;
          combinedOutputPower += double.tryParse(device["outpower"]) ?? 0.0;
        }

        print(todayGenSum);
        print(totalGenSum);
        print(combinedOutputPower);
      }
      // widget.dateco2_all = dateProfitsresponse['dat']['co2'];
      // widget.dateso2_all = dateProfitsresponse['dat']['so2'];
      // widget.datecoal_all = dateProfitsresponse['dat']['coal'];
      // widget.dateprofit_all = dateProfitsresponse['dat']['profit'];
      // widget.dateenergy_all = dateProfitsresponse['dat']['energy'];
    });
  }

  //////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////
  Future fetchPlantcount_alarams_devicecount() async {
    ////Alarm Count  -- Plants count -- Devices Count
    int? PlantCounts = await NumberofPowerStationQuery();
    var Jsonresponse_Devicecountinfo = await DeviceCountQuery();

    if (Jsonresponse_Devicecountinfo['desc'] == 'ERR_NO_AUTH') {
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('loggedin', false);

      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          (route) => false);

      return;
    }

    var Jsonresponse_AlarmsofALLpowerplants =
        await AlarmsofallPowerPlantsQuery();

    QueryDeviceCount _QueryDeviceCount =
        new QueryDeviceCount.fromJson(Jsonresponse_Devicecountinfo);
    QueryAlarmsOfAllPowerPlants _QueryAlarmsOfAllPowerPlants =
        new QueryAlarmsOfAllPowerPlants.fromJson(
            Jsonresponse_AlarmsofALLpowerplants);
    ////////////////////////////////////////////////////
    setState(() {
      widget.plantcount = PlantCounts;
      widget.Alarmcount = _QueryAlarmsOfAllPowerPlants.dat.count;
      widget.Devicecount = _QueryDeviceCount.dat.count;
    });
  }

  /////////////////////////////////////////////////////////////////////////////
  Future fetchCurrentouputPowerALLPS() async {
    String Current_outputPowerof_ALLPS;
    Current_outputPowerof_ALLPS = await CurrentOuputPowerof_ALLPSQuery();
    setState(() {
      widget._Current_outputPowerof_ALLPS =
          double.parse(Current_outputPowerof_ALLPS);
      widget.last_updated = DateTime.now();
    });
  }

  Future fetchCurrentPlantStats() async {
    String InstalledCapacityof_AllPS;
    InstalledCapacityof_AllPS = await InstalledCapacity_ALLPSQuery();

    setState(() {
      widget._InstalledCapacityof_AllPS =
          double.parse(InstalledCapacityof_AllPS);
    });
  }

  /////////////////Daily Power Generation in Month////////////
  // Future fetchDailyPGIMonth() async {
  //   // formatted current datetime // YYYY-MM
  //   String yearmonth = DateTime.now().year.toString() +
  //       DateTime.now().month.toString().padLeft(2, '0');
  Future<void> fetchDailyPGIMonth() async {
    String yearmonth = DateTime.now().year.toString() +
        DateTime.now().month.toString().padLeft(2, '0');

    String dateValue = date.text == '' || date.text.length <= 6
        ? yearmonth
        : date.text.substring(0, 7);

    List<String> parameters = [
      // "BATTERY_ENERGY_TODAY_CHARGE",
      // "BATTERY_ENERGY_TODAY_DISCHARGE",
      // "ENERGY_TODAY_TO_GRID",
      // "LOAD_ENERGY_TODAY",
      // "ENERGY_TODAY_FROM_GRID",
      "ENERGY_TODAY"
    ];

    // Check the length of collectors before the loop
    print("########### Total collectors: ${psInfo?.dat.collector.length}");

    for (var collector in psInfo?.dat.collector ?? []) {
      try {
        String PN = collector.pn ?? '';
        print("########### Processing collector with PN: $PN");
        String SN = '';
        String devaddr = '';
        String devcode = '';
        bool snFound = false; // Flag to check if SN was found

        // Find the corresponding SN and device details from the device list
        for (var device in psInfo2!.dat.device) {
          print("Checking device with PN: ${device.pn}");
          if (device.pn == PN) {
            SN = device.sn ?? '';
            devaddr = device.devaddr.toString();
            devcode = device.devcode.toString();
            print(
                "########### Found SN: $SN, devaddr: $devaddr, devcode: $devcode for PN: $PN");
            snFound = true;
            break; // Exit the inner loop after finding the correct SN
          }
        }

        // Skip the API call if SN is not found
        if (!snFound || SN.isEmpty) {
          print("########### No SN found for collector $PN. Skipping...");
          continue; // Move to the next collector without making the API call
        }

        // Fetch the data for each collector
        print(
            "########### Calling DailyPGinMonthQuery2 for PN: $PN and SN: $SN");
        List<Map<String, dynamic>> responses = await Future.wait(
          parameters.map((param) => DailyPGinMonthQuery2(
                PN: PN,
                SN: SN,
                devaddr: devaddr,
                devcode: devcode,
                parameter: param,
                yearmonth: dateValue,
                PID: pid.toString(),
              )),
        );

        // Parse responses
        List<DailyPGinMonth2> pgMonthDataList =
            responses.map((res) => DailyPGinMonth2.fromJson(res)).toList();

        setState(() {
          _chartData.clear();

          for (var _DPGIM in pgMonthDataList) {
            if (_DPGIM.err == 0) {
              for (int i = 0; i < _DPGIM.dat.option.length; i++) {
                if (_DPGIM.dat.option[i].val == "0.00") continue;

                _chartData.add(Chartinfo(
                  _DPGIM.dat.option[i].gts,
                  double.parse(_DPGIM.dat.option[i].val).toStringAsFixed(1),
                ));
              }

              // Get the latest value from the last chart data point
              if (_chartData.isNotEmpty) {
                latestValue = _chartData.last.name1;
                print("########### Latest value: $latestValue");
              }
              print("########### Daily Power Generation Data Updated!");
            } else if (_DPGIM.err == 12) {
              Showsnackbar(AppLocalizations.of(context)!.msg_no_record_found,
                  1000, Colors.black);
            } else {
              Showsnackbar("${_DPGIM.desc}", 1500, Colors.red);
            }
          }
        });

        // Show success message
        Showsnackbar(AppLocalizations.of(context)!.data_updated_successfully,
            500, Colors.green);
      } catch (e) {
        print(
            "########### Error fetching daily power generation data for collector $PN: $e");
        Showsnackbar("Failed to load data", 1500, Colors.red);
      }
    }
  }

  //   var Jsonresponse_DailyPGinMonth = await DailyPGinMonthQuery(
  //       // format yyyy-mm
  //       yearmonth: date.text == '' || date.text.length <= 6
  //           ? yearmonth
  //           : date.text.substring(0, 7),
  //       PID: 'all');
  //   DailyPGinMonth _DPGIM =
  //       new DailyPGinMonth.fromJson(Jsonresponse_DailyPGinMonth);

  //   if (_DPGIM.err == 0) {
  //     Showsnackbar(AppLocalizations.of(context)!.data_updated_successfully, 500,
  //         Colors.green);

  //     /// updating chartData list with Daily powergeneration in month query data
  //     setState(() {
  //       _chartData.clear();
  //       // _chartData = <Chartinfo>[];
  //       for (int i = 0; i < _DPGIM.dat!.perday!.length; i++) {
  //         if (_DPGIM.dat!.perday![i].val == "0.00") continue;

  //         _chartData.add(Chartinfo(_DPGIM.dat!.perday![i].ts!,
  //             double.parse(_DPGIM.dat!.perday![i].val!).toStringAsFixed(1)));

  //         //  print(_chartData[i].name1);
  //       }
  //     });
  //   } else if (_DPGIM.err == 12) {
  //     Showsnackbar(AppLocalizations.of(context)!.msg_no_record_found, 1000,
  //         Colors.black);
  //     setState(() {
  //       _chartData.clear();
  //     });
  //   } else {
  //     Showsnackbar(" ${_DPGIM.desc}", 1500, Colors.red);
  //     setState(() {
  //       _chartData.clear();
  //     });
  //   }
  // }

  /////////////////Daily Power Generation in Month//////end//////

  ////////////////////Monthly Power Generation in year//// start////////
  // Future fetchMonthlyPGinyear() async {
  //   // formatted current datetime // YYYY
  //   String year = DateTime.now().year.toString();

  //   var Jsonresponse_MonthlyPGinyear = await MonthlyPGinyearQuery(
  //       // format yyyy
  //       year: date.text == '' || date.text.length > 4
  //           ? year
  //           : date.text.substring(0, 4),
  //       PID: 'all');
  //   MonthlyPGinyear _MPGIY =
  //       new MonthlyPGinyear.fromJson(Jsonresponse_MonthlyPGinyear);

  //   if (_MPGIY.err == 0) {
  //     Showsnackbar(AppLocalizations.of(context)!.data_updated_successfully, 500,
  //         Colors.green);

  //     /// updating chartData list with Monthly Power Generation in year query data
  //     setState(() {
  //       _chartData.clear();
  //       for (int i = 0; i < _MPGIY.dat!.permonth!.length; i++) {
  //         _chartData.add(Chartinfo(_MPGIY.dat?.permonth?[i].ts,
  //             double.parse(_MPGIY.dat!.permonth![i].val!).toStringAsFixed(1)));
  //       }
  //     });
  //   } else if (_MPGIY.err == 12) {
  //     Showsnackbar(AppLocalizations.of(context)!.msg_no_record_found, 1000,
  //         Colors.black);
  //     setState(() {
  //       _chartData.clear();
  //     });
  //   } else {
  //     Showsnackbar(" ${_MPGIY.desc}", 1500, Colors.red);
  //     setState(() {
  //       _chartData.clear();
  //     });
  //   }
  // }

  Future<void> fetchMonthlyPGinyear() async {
    // Formatted current datetime (YYYY)
    String year = DateTime.now().year.toString();

    // Get the year from date input or use the current year
    String yearValue = date.text == '' || date.text.length > 4
        ? year
        : date.text.substring(0, 4);

    List<String> parameters = [
      "ENERGY_TOTAL", // You can add more parameters if needed
    ];

    // Check the length of collectors before the loop
    print("########### Total collectors: ${psInfo?.dat.collector.length}");

    for (var collector in psInfo?.dat.collector ?? []) {
      try {
        String PN = collector.pn ?? '';
        print("########### Processing collector with PN: $PN");
        String SN = '';
        String devaddr = '';
        String devcode = '';
        bool snFound = false; // Flag to check if SN was found

        // Find the corresponding SN and device details from the device list
        for (var device in psInfo2!.dat.device) {
          print("Checking device with PN: ${device.pn}");
          if (device.pn == PN) {
            SN = device.sn ?? '';
            devaddr = device.devaddr.toString();
            devcode = device.devcode.toString();
            print(
                "########### Found SN: $SN, devaddr: $devaddr, devcode: $devcode for PN: $PN");
            snFound = true;
            break; // Exit the inner loop after finding the correct SN
          }
        }

        // Skip the API call if SN is not found
        if (!snFound || SN.isEmpty) {
          print("########### No SN found for collector $PN. Skipping...");
          continue; // Move to the next collector without making the API call
        }

        // Fetch the data for each collector
        print(
            "########### Calling MonthlyPGinyearQuery2 for PN: $PN and SN: $SN");
        List<Map<String, dynamic>> responses = await Future.wait(
          parameters.map((param) => MonthlyPGinyearQuery2(
                date: yearValue,
                PN: PN,
                SN: SN,
                devaddr: devaddr,
                devcode: devcode,
                parameter: param,
              )),
        );

        // Parse responses
        List<MonthlyPGinyear2> powerDataList =
            responses.map((res) => MonthlyPGinyear2.fromJson(res)).toList();

        setState(() {
          _chartData.clear();

          // Iterate over all datasets and combine them
          for (var _MPGIY in powerDataList) {
            if (_MPGIY.err == 0) {
              for (int i = 0; i < _MPGIY.dat.option.length; i++) {
                _chartData.add(Chartinfo(
                  _MPGIY.dat.option[i].gts,
                  double.parse(_MPGIY.dat.option[i].val).toStringAsFixed(1),
                ));
              }
              print("Monthly Power Generation Data Updated!");
            } else if (_MPGIY.err == 12) {
              Showsnackbar(AppLocalizations.of(context)!.msg_no_record_found,
                  1000, Colors.black);
            } else {
              Showsnackbar(" ${_MPGIY.desc}", 1500, Colors.red);
            }
          }
        });

        // Show success message
        Showsnackbar(AppLocalizations.of(context)!.data_updated_successfully,
            500, Colors.green);
      } catch (e) {
        print("########### Error fetching monthly data for collector $PN: $e");
        Showsnackbar("Failed to load data", 1500, Colors.red);
      }
    }
  }

  /////////////////Monthly Power Generation in year//////end//////
  ///
  /// ////////////////////Annual Power Generation in year//// start////////
  // Future fetchAnnualPg() async {
  //   var Jsonresponse_AnnualPg = await AnnualPgQuery(PID: 'all');
  //   AnnualPg _APG = new AnnualPg.fromJson(Jsonresponse_AnnualPg);
  //   print(
  //       '[HOme Screen|AnnualPgquery] error code: ${_APG.err} <==> error description: ${_APG.desc} <==> Month: ${_APG.dat?.peryear?[0].ts?.day} <==> EnergyValue: ${_APG.dat?.peryear?[0].val}');
  //   if (_APG.err == 0) {
  //     Showsnackbar(AppLocalizations.of(context)!.data_updated_successfully, 500,
  //         Colors.green);

  //     /// updating chartData list with Annual Power Generation in year query data
  //     setState(() {
  //       _chartData.clear();
  //       for (int i = 0; i < _APG.dat!.peryear!.length; i++) {
  //         print('peryear length: ${_APG.dat!.peryear!.length}');
  //         _chartData.add(Chartinfo(_APG.dat!.peryear![i].ts!,
  //             double.parse(_APG.dat!.peryear![i].val!).toStringAsFixed(1)));
  //       }
  //     });
  //   } else if (_APG.err == 12) {
  //     Showsnackbar(AppLocalizations.of(context)!.msg_no_record_found, 1000,
  //         Colors.black);
  //     setState(() {
  //       _chartData.clear();
  //     });
  //   } else {
  //     Showsnackbar(" ${_APG.desc}", 1500, Colors.red);
  //     setState(() {
  //       _chartData.clear();
  //     });
  //   }
  // }
  Future<void> fetchAnnualPg() async {
    String year = DateTime.now().year.toString();
    String parameter = "ENERGY_TOTAL";

    // Check the length of collectors before the loop
    print("########### Total collectors: ${psInfo?.dat.collector.length}");

    for (var collector in psInfo?.dat.collector ?? []) {
      try {
        String PN = collector.pn ?? '';
        print("########### Processing collector with PN: $PN");
        String SN = '';
        String devaddr = '';
        String devcode = '';
        bool snFound = false; // Flag to check if SN was found

        // Find the corresponding SN and device details from the device list
        for (var device in psInfo2!.dat.device) {
          print("Checking device with PN: ${device.pn}");
          if (device.pn == PN) {
            SN = device.sn ?? '';
            devaddr = device.devaddr.toString();
            devcode = device.devcode.toString();
            print(
                "########### Found SN: $SN, devaddr: $devaddr, devcode: $devcode for PN: $PN");
            snFound = true;
            break; // Exit the inner loop after finding the correct SN
          }
        }

        // Skip the API call if SN is not found
        if (!snFound || SN.isEmpty) {
          print("########### No SN found for collector $PN. Skipping...");
          continue; // Move to the next collector without making the API call
        }

        // Fetch the annual power generation data for each collector
        print("########### Calling AnnualPgQuery2 for PN: $PN and SN: $SN");
        var Jsonresponse_AnnualPg = await AnnualPgQuery2(
          date: year,
          PN: PN,
          SN: SN,
          devaddr: devaddr,
          devcode: devcode,
          parameter: parameter,
        );

        AnnualPg2 _APG = AnnualPg2.fromJson(Jsonresponse_AnnualPg);
        print(
            '[Home Screen | AnnualPgQuery] error code: ${_APG.err} <==> error description: ${_APG.desc} <==> Year: ${_APG.dat.option[0].gts.year} <==> EnergyValue: ${_APG.dat.option[0].val}');

        if (_APG.err == 0) {
          Showsnackbar(AppLocalizations.of(context)!.data_updated_successfully,
              500, Colors.green);

          /// Updating chartData list with Annual Power Generation data
          setState(() {
            _chartData.clear();
            for (int i = 0; i < _APG.dat.option.length; i++) {
              print('peryear length: ${_APG.dat.option.length}');
              _chartData.add(Chartinfo(
                _APG.dat.option[i].gts,
                double.parse(_APG.dat.option[i].val).toStringAsFixed(1),
              ));
            }
          });
        } else if (_APG.err == 12) {
          Showsnackbar(AppLocalizations.of(context)!.msg_no_record_found, 1000,
              Colors.black);
          setState(() {
            _chartData.clear();
          });
        } else {
          Showsnackbar("${_APG.desc}", 1500, Colors.red);
          setState(() {
            _chartData.clear();
          });
        }
      } catch (e) {
        print(
            "########### Error fetching annual power generation data for collector $PN: $e");
        Showsnackbar("Failed to load data", 1500, Colors.red);
      }
    }
  }

  Future<void> fetchGraphData() async {
    String yearmonthdate = DateTime.now().year.toString() +
        DateTime.now().month.toString().padLeft(2, '0') +
        DateTime.now().day.toString().padLeft(2, '0');

    String dateValue = date.text == '' || date.text.length <= 8
        ? yearmonthdate
        : date.text.substring(0, 10);

    List<String> parameters = ["PV_OUTPUT_POWER"];
    List<dynamic> collectors = psInfo!.dat.collector;
    List<dynamic> allDevicesData = [];
    Map<String, dynamic> deviceMap = {
      for (var device in psInfo2!.dat.device) device.pn: device
    };

    try {
      // Fetching data for all collectors
      for (var collector in collectors) {
        try {
          var deviceData = await CollectorDevicesStatusQuery(PN: collector.pn);
          allDevicesData.add(deviceData);
        } catch (e) {
          print("Error fetching data for collector ${collector.pn}: $e");
        }
      }

      print("############# %%%%%%%%%%% All devices data: $allDevicesData");

      // double combinedOutputPower = 0.0;

      // for (var collector in collectors) {
      //   try {
      //     String PN = collector.pn ?? '';
      //     print("########### Processing collector with PN: $PN");

      //     // Get the matching device from the map
      //     var matchingDevice = deviceMap[PN];
      //     if (matchingDevice == null) {
      //       print(
      //           "########### No matching device found for PN: $PN. Skipping...");
      //       continue;
      //     }

      //     String SN = matchingDevice.sn ?? '';
      //     String devaddr = matchingDevice.devaddr.toString();
      //     String devcode = matchingDevice.devcode.toString();
      //     print(
      //         "########### Found SN: $SN, devaddr: $devaddr, devcode: $devcode for PN: $PN");

      //     // Fetch device parameters
      //     var response = await fetchdeviceparamES(
      //       devcode: devcode,
      //       PN: PN,
      //       devadr: devaddr,
      //       SN: SN,
      //     );

      //     if (response['err'] == 0 && response['dat'] != null) {
      //       List<dynamic> parameters = response['dat']['parameter'];

      //       var outputPowerParam = parameters.firstWhere(
      //         (param) => param['par'] == 'output_power',
      //         orElse: () => null,
      //       );

      //       if (outputPowerParam != null && outputPowerParam['val'] != null) {
      //         double outputPower =
      //             double.tryParse(outputPowerParam['val']) ?? 0.0;
      //         print(
      //             "########### Output Power for device ${collector.alias}: $outputPower kW");

      //         combinedOutputPower += outputPower;
      //       } else {
      //         print(
      //             "########### No output power data for device ${collector.alias}");
      //       }
      //     } else {
      //       print(
      //           "########### Error fetching data for device ${collector.alias}");
      //     }
      //   } catch (e) {
      //     print("########### Error calculating combined output power: $e");
      //   }
      // }

      print(
          "########### Combined Output Power of all devices: ${combinedOutputPower.toStringAsFixed(2)} kW");

      // Fetch power data for all collectors
      List<Map<String, dynamic>> allResponses = [];
      for (var collector in collectors) {
        try {
          String PN = collector.pn ?? '';
          var matchingDevice = deviceMap[PN];
          if (matchingDevice == null) continue;

          String SN = matchingDevice.sn ?? '';
          String devaddr = matchingDevice.devaddr.toString();
          String devcode = matchingDevice.devcode.toString();

          // List<Map<String, dynamic>> responses =
          //     await Future.wait(parameters.map(
          //   (param) => DeviceActiveOuputPowerOneDayQuery(
          //     Date: dateValue,
          //     PN: PN,
          //     SN: SN,
          //     devaddr: devaddr,
          //     devcode: devcode,
          //     parameter: param,
          //     // plantId: collector.pid.toString()),
          //   ),
          // ));
          List<Map<String, dynamic>> responses =
              await Future.wait(parameters.map(
            (param) => ActiveOuputPowerOneDayQuery(
                Date: dateValue, PID: collector.pid.toString()
                // plantId: collector.pid.toString()),
                ),
          ));

          // List<Map<String, dynamic>> responses =
          //     await Future.wait(parameters.map(
          //   (param) => ActiveOuputPowerOneDayQuery(
          //       Date: dateValue, PID: psInfo!.dat.collector[0].pid.toString()

          //       // plantId: collector.pid.toString()),
          //       ),
          // ));

          allResponses.addAll(responses);
          print(
              "########### Successfully fetched ${responses.length} responses for collector $PN");
        } catch (e) {
          print(
              "########### Error fetching data for collector ${collector.pn}: $e");
        }
      }

      print("########### Final response count: ${allResponses.length}");

      // Combine and process power data
      List<ActiveOuputPowerOneDay> powerDataList = allResponses
          .map((res) => ActiveOuputPowerOneDay.fromJson(res))
          .toList();

      setState(() {
        _chartData.clear();
        Map<DateTime, double> combinedData = {};

        for (var _AOPOD in powerDataList) {
          if (_AOPOD.err == 0) {
            for (var detail in _AOPOD.dat!.outputPower!) {
              if (detail.ts!.hour >= 5 && detail.ts!.hour <= 19) {
                double value = double.tryParse(detail.val!) ?? 0.0;

                if (combinedData.containsKey(detail.ts)) {
                  combinedData[detail.ts!] = combinedData[detail.ts]! + value;
                } else {
                  combinedData[detail.ts!] = value;
                }
              }
            }
          } else if (_AOPOD.err == 12) {
            Showsnackbar(
              AppLocalizations.of(context)!.msg_no_record_found,
              1000,
              Colors.black,
            );
          } else {
            Showsnackbar(
              "${_AOPOD.desc}",
              1500,
              Colors.red,
            );
          }
        }

        combinedData.forEach((timestamp, value) {
          _chartData.add(Chartinfo(
            timestamp,
            value.toStringAsFixed(1),
          ));
        });

        if (_chartData.isNotEmpty) {
          latestValue = _chartData.last.name1;
          print("########### Latest value: $latestValue");
        }
      });

      Showsnackbar(
        AppLocalizations.of(context)!.data_updated_successfully,
        500,
        Colors.green,
      );
    } catch (e) {
      print("Error fetching graph data: $e");
      Showsnackbar("Failed to load data", 1500, Colors.red);
    }
  }

  /////////////////Annual Power Generation in year//////end//////
  ///
  /////////////////ActiveOuputPowerOneDay////////////
  // Future fetchActiveOuputPowerOneDay() async {
  //   // formatted current datetime // YYYY-MM-DD
  //   String yearmonthdate = DateTime.now().year.toString() +
  //       DateTime.now().month.toString().padLeft(2, '0') +
  //       DateTime.now().day.toString().padLeft(2, '0');

  //   // var Jsonresponse_ActiveOuputPowerOneDay = await ActiveOuputPowerOneDayQuery(
  //   //     Date: date.text == '' || date.text.length <= 8
  //   //         ? yearmonthdate
  //   //         : date.text.substring(0, 10),
  //   //     PID: 'all');

  //   var Jsonresponse_ActiveOuputPowerOneDay =
  //       await DeviceActiveOuputPowerOneDayQuery(
  //     Date: date.text == '' || date.text.length <= 8
  //         ? yearmonthdate
  //         : date.text.substring(0, 10),
  //     PN: psInfo?.dat.collector[0].pn ?? "",
  //     SN: psInfo2!.dat.device[0].sn,
  //     devaddr: psInfo2!.dat.device[0].devaddr.toString(),
  //     devcode: psInfo2!.dat.device[0].devcode.toString(),
  //   );

  //   ActiveLoadOutputPower _AOPOD =
  //       new ActiveLoadOutputPower.fromJson(Jsonresponse_ActiveOuputPowerOneDay);
  //   print(
  //       '[HOme Screen|ActiveOuputPowerOneDay] error code: ${_AOPOD.err} <==> error description: ${_AOPOD.desc} <==> Date: ${_AOPOD.dat.detail[9].ts.day} <==> EnergyValue: ${_AOPOD.dat.detail[9].val}');

  //   if (_AOPOD.err == 0) {
  //     Showsnackbar(AppLocalizations.of(context)!.data_updated_successfully, 500,
  //         Colors.green);
  //     setState(() {
  //       _chartData.clear();
  //       for (int i = 0; i < _AOPOD.dat.detail.length; i++) {
  //         //newchange
  //         if (_AOPOD.dat.detail[i].ts.hour >= 5 &&
  //             _AOPOD.dat.detail[i].ts.hour <= 19) {
  //           _chartData.add(Chartinfo(_AOPOD.dat.detail[i].ts,
  //               double.parse(_AOPOD.dat.detail[i].val).toStringAsFixed(1)));
  //         }
  //       }
  //     });
  //   } else if (_AOPOD.err == 12) {
  //     Showsnackbar(AppLocalizations.of(context)!.msg_no_record_found, 1000,
  //         Colors.black);
  //     setState(() {
  //       _chartData.clear();
  //     });
  //   } else {
  //     Showsnackbar("${_AOPOD.desc}", 1500, Colors.red);
  //     setState(() {
  //       _chartData.clear();
  //     });
  //   }
  // }

  ///////////////// ActiveOuputPowerOneDay//////end//////
}

class Chartinfo {
  Chartinfo(this.chartinfocategory, this.name1);
  final DateTime? chartinfocategory;
  final String name1;
  // Color color;
}
