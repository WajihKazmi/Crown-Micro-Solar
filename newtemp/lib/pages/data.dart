// import 'package:crownmonitor/fontsizes.dart';
import 'dart:async';

import 'package:crownmonitor/Models/ActiveOuputPowerOneDay.dart';
import 'package:crownmonitor/Models/AnnualPG.dart';
import 'package:crownmonitor/Models/Averagetroublefreeoperationtime.dart';
import 'package:crownmonitor/Models/CurrentOutputPowerofPS.dart';
import 'package:crownmonitor/Models/DailyPGinMonth.dart';
import 'package:crownmonitor/Models/MonthlyPGinyear.dart';
import 'package:crownmonitor/Models/continuoustroublefreeoperationtime.dart';
import 'package:crownmonitor/Models/queryPlantCurrentDataNEW.dart';
import 'package:crownmonitor/datepickermodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'mainscreen.dart';

class Data extends StatefulWidget {
  String? PlantID;
  //plantinfoqueryvariables

  String? province;
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

  String? picbig;
  String? picsmall;

  //This plant varaibles
  //////////////little confusion/////////
  String energyProceed = "0.0000";
  String coalSaved = "0.0000";
  String co2Reduced = "0.0000";
  String so2Reduced = "0.0000";
  String TotalPlants = '';
  ///////////////////////////////////////

  // current power data of powerstation////
  double CurrentPowerofPS = 0;
  String energyToday = "0.0000";

  //plantinfoqueryvariables
  String? Plantname = '----';
  String? Country = '----';
  String? City = '----';
  String? DesignCompany = '----';
  DateTime? installed_date = DateTime.now();
  double? DesignPower = 0;
  double? Annual_Planned_Power = 0;
  String? Plant_status = 'loading';
  int? Average_troublefree_operationtime = 0;
  int? Continuous_troublefree_operationtime = 0;
  String PowerCertainYear = '00.00';
  /////////// PLANT CURRENT DATA STATS NEW ////////////////
  String ENERGY_TODAY = '0.0000';
  String ENERGY_MONTH = '0.0000';
  String ENERGY_YEAR = '0.0000';
  String ENERGY_TOTAL = '0.0000';
  String ENERGY_PROCEEDS = '0.0000';
  String ENERGY_COAL = '0.0000';
  String ENERGY_CO2 = '0.0000';
  String ENERGY_SO2 = '0.0000';
  String CURRENT_TEMP = '0.0000';

  ///Ambient temperature
  String CURRENT_RADIANT = '--'; ////solar irradiance
  String BATTERY_SOC = '--';
  //////////// PLANT CURRENT DATA STATS NEW ////////////////

  //last updated
  DateTime last_updated = DateTime.now();

  Data(
      {Key? key,
      this.PlantID,
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
  _DataState createState() => _DataState();
}

class _DataState extends State<Data> {
  bool downbtnpressed = false;
  ScrollController _Datascrollcontroller = ScrollController();
  late List<Chartinfo> _chartData;

  late int indexpos = 0;
  late ZoomPanBehavior zoomPanBehavior;
  String chart_label = 'Time';

  /// togglle buuton position
  DateTime date1 = new DateTime(int.parse(DateTime.now().year.toString()),
      DateTime.now().month.toInt(), DateTime.now().day.toInt());
  late TextEditingController date = new TextEditingController();
  late List<bool> isSelected;

  int Page = 0; // 0 means first page
  int Pagesize = 1; //1 for querying only 1 plant per page
  String Plant_status = '0';
  late Timer _timer1;

  ///new chart varaiables
  var _trackballBehavior;
  final List<Color> color = <Color>[];
  final List<double> stops = <double>[];
  late LinearGradient gradientColors;
  ////

  @override
  void initState() {
    super.initState();

    _chartData = _getday();

    _trackballBehavior = TrackballBehavior(
        // Enables the trackball
        enable: true,
        tooltipSettings: InteractiveTooltip(
            enable: true,
            color: Colors.white,
            textStyle: TextStyle(color: Colors.black)));
    zoomPanBehavior = ZoomPanBehavior(enablePanning: true);
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

    fetchCurrentPlantStats();
    FetchCurrentPlantDATANEW();
    fetch_Cont_avgtime();
    fetchActiveOuputPowerOneDay();
    // fetchDailyPGIMonth();
    _timer1 = new Timer.periodic(const Duration(seconds: 30), (_timer1) {
      fetchCurrentPlantStats();
      fetchActiveOuputPowerOneDay();
    });
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
    _timer1.cancel();

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
                  date.text = date1.year.toString() +
                      '-' +
                      date1.month.toString().padLeft(2, '0') +
                      '-' +
                      date1.day.toString().padLeft(2, '0');
                  setState(() {
                    fetchActiveOuputPowerOneDay();
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
                    fetchActiveOuputPowerOneDay();
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
            // DAte text under toggle
            width: width / 12,
            child: TextButton(
              onPressed: () {
                if (indexpos == 0) {
                  date1 = new DateTime(date1.year, date1.month, date1.day + 1);
                  date.text = date1.year.toString() +
                      '-' +
                      date1.month.toString().padLeft(2, '0') +
                      '-' +
                      date1.day.toString().padLeft(2, '0');
                } else if (indexpos == 1) {
                  date1 = new DateTime(date1.year, date1.month + 1, date1.day);
                  date.text = date1.year.toString() +
                      '-' +
                      date1.month.toString().padLeft(2, '0');
                } else if (indexpos == 2) {
                  date1 = new DateTime(date1.year + 1, date1.month, date1.day);

                  date.text = date1.year.toString();
                } else {
                  date.text = '';
                }
              },
              child:
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            )),
      ],
    );
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
                        size: 18,
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
                              fetchActiveOuputPowerOneDay();
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
                ),
          //  TextButton(
          //   onPressed: () {
          //     if (indexpos == 0) {
          //       DatePicker.showPicker(
          //         context,
          //         pickerModel: YearMonthDayModel(
          //           currentTime: DateTime.now(),
          //           maxTime: DateTime.now(),
          //           minTime: DateTime(2015),
          //           locale: LocaleType.en,
          //         ),
          //         theme: DatePickerTheme(
          //             headerColor: Theme.of(context).primaryColor,
          //             backgroundColor: Color(0xffF4F4F4),
          //             itemStyle: TextStyle(color: Colors.black, fontSize: 10),
          //             doneStyle: TextStyle(color: Colors.white, fontSize: 16)),
          //         locale: LocaleType.en,
          //         onChanged: (date) {
          //           print('change $date');
          //         },
          //         onConfirm: (datepick) {
          //           date.text = datepick.year.toString() +
          //               '-' +
          //               datepick.month.toString().padLeft(2, '0') +
          //               '-' +
          //               datepick.day.toString().padLeft(2, '0');
          //           // fetchCurrentPlantStats();
          //           fetchActiveOuputPowerOneDay();
          //         },
          //       );
          //     } else if (indexpos == 1) {
          //       DatePicker.showPicker(
          //         context,
          //         pickerModel: YearMonthModel(
          //           currentTime: DateTime.now(),
          //           maxTime: DateTime.now(),
          //           minTime: DateTime(2015),
          //           locale: LocaleType.en,
          //         ),
          //         theme: DatePickerTheme(
          //             headerColor: Theme.of(context).primaryColor,
          //             backgroundColor: Color(0xffF4F4F4),
          //             itemStyle: TextStyle(color: Colors.black, fontSize: 10),
          //             doneStyle: TextStyle(color: Colors.white, fontSize: 16)),
          //         locale: LocaleType.en,
          //         onChanged: (date) {
          //           print('change $date');
          //         },
          //         onConfirm: (datepick) {
          //           date.text = datepick.year.toString() +
          //               '-' +
          //               datepick.month.toString().padLeft(2, '0');

          //           fetchDailyPGIMonth();
          //         },
          //       );
          //     } else if (indexpos == 2) {
          //       DatePicker.showPicker(
          //         context,
          //         pickerModel: YearModel(
          //           currentTime: DateTime.now(),
          //           maxTime: DateTime.now(),
          //           minTime: DateTime(2015),
          //           locale: LocaleType.en,
          //         ),
          //         theme: DatePickerTheme(
          //             headerColor: Theme.of(context).primaryColor,
          //             backgroundColor: Color(0xffF4F4F4),
          //             itemStyle: TextStyle(color: Colors.black, fontSize: 10),
          //             doneStyle: TextStyle(color: Colors.white, fontSize: 16)),
          //         locale: LocaleType.en,
          //         onChanged: (date) {
          //           print('change $date');
          //         },
          //         onConfirm: (datepick) {
          //           date.text = datepick.year.toString();
          //           fetchMonthlyPGinyear();
          //         },
          //       );
          //     }
          //   },
          //   child: TextField(
          //       enabled: false,
          //       decoration: InputDecoration(
          //           border: InputBorder.none,
          //           contentPadding: EdgeInsets.only()),
          //       textAlign: TextAlign.center,
          //       controller: date,
          //       style: Theme.of(context).textTheme.subtitle1),
          // ),
        ),
        SizedBox(
          height: height / 100,
        ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
                    child: Container(child: icon1),
                  ),
                  Container(
                      height: x / 22,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
                    child: Container(child: icon),
                  ),
                  Container(
                      height: x / 22,
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
          indexpos != 0
              ? ColumnSeries<Chartinfo, dynamic>(
                  // selectionBehavior: _selectionBehavior,

                  width: 0.4,
                  spacing: 0.01,
                  name: 'Power',
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5)),
                  enableTooltip: true,
                  color: Theme.of(context).primaryColor,
                  dataSource: _chartData,
                  xValueMapper: (Chartinfo exp, _) => exp.chartinfocategory,
                  yValueMapper: (Chartinfo exp, _) => double.parse(exp.name1),
                  dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                      showZeroValue: false,
                      textStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                          fontSize: 0.02 * (height - width))),
                  markerSettings: MarkerSettings(
                    isVisible: false,
                  ))
              : AreaSeries<Chartinfo, dynamic>(
                  name: 'Power',
                  // width: 0.4,
                  // spacing: 0.01,
                  // name: 'Energy',
                  // borderRadius: BorderRadius.only(
                  //     topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                  //enableTooltip: true,
                  color: Theme.of(context).primaryColor,
                  gradient: gradientColors,
                  dataSource: _chartData,
                  xValueMapper: (Chartinfo exp, _) => exp.chartinfocategory,
                  yValueMapper: (Chartinfo exp, _) => double.parse(exp.name1),
                  // dataLabelSettings: DataLabelSettings(
                  //     isVisible: true,
                  //     showZeroValue: false,

                  //     textStyle: TextStyle(
                  //         color: Colors.white,
                  //         fontWeight: FontWeight.normal,
                  //         fontSize: 12)),
                  markerSettings: MarkerSettings(
                    isVisible: false,
                  ))
        ],
        primaryXAxis: DateTimeCategoryAxis(
            //labelPlacement: LabelPlacement.onTicks,
            majorGridLines: MajorGridLines(
                width: 2, color: Colors.white10, dashArray: <double>[5, 5]),
            title: AxisTitle(
                text: chart_label,
                textStyle: TextStyle(
                    color: Colors.deepOrange,
                    fontFamily: 'Roboto',
                    fontSize: width * 0.03,
                    fontWeight: FontWeight.w300)),
            /////
            dateFormat: indexpos == 1
                ? DateFormat('d')
                : indexpos == 2
                    ? DateFormat('MMM')
                    : indexpos == 3
                        ? DateFormat('y')
                        : DateFormat('j'),
            intervalType: indexpos == 1
                ? DateTimeIntervalType.days
                : indexpos == 2
                    ? DateTimeIntervalType.months
                    : indexpos == 3
                        ? DateTimeIntervalType.years
                        : DateTimeIntervalType.hours,
            interval: indexpos == 0 ? 3 : 1
            //labelRotation: 0
            // intervalType: DateTimeIntervalType.hours,
            //                   interval: 1
            ),

        //  CategoryAxis(
        //     // plotOffset: 2,
        //     // visibleMinimum: 0,
        //     plotOffset: 5,
        //     labelPlacement: LabelPlacement.onTicks,
        //     visibleMaximum: 11,
        //     interval: indexpos == 0 ? 0.45 : 1,
        //     majorGridLines: MajorGridLines(
        //         width: 2, color: Colors.white10, dashArray: <double>[5, 5]),
        //     title: AxisTitle(
        //         text: chart_label,
        //         textStyle: TextStyle(
        //             color: Colors.deepOrange,
        //             fontFamily: 'Roboto',
        //             fontSize: width * 0.03,
        //             fontWeight: FontWeight.w300))),
        primaryYAxis: NumericAxis(
            // visibleMinimum: 1.0000,
            // plotOffset: 1,
            majorGridLines: MajorGridLines(
                width: 0, color: Colors.transparent, dashArray: <double>[2, 2]),
            title: AxisTitle(
                text: 'Power (kWh)',
                textStyle: TextStyle(
                    color: Colors.deepOrange,
                    fontFamily: 'Roboto',
                    fontSize: width * 0.03,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300))),
      ),
    );
  }

  // Widget _piechart(double width, double height) {
  //   return Center(
  //       child: Container(
  //           child: SfCircularChart(
  //               title: ChartTitle(
  //                   text: 'Pie Chart',
  //                   textStyle: TextStyle(
  //                       fontSize: 12,
  //                       fontFamily: 'Gilroy',
  //                       fontWeight: FontWeight.normal,
  //                       color: Colors.black,
  //                       letterSpacing: 1)),
  //               legend: Legend(
  //                   isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
  //               tooltipBehavior: TooltipBehavior(enable: true),
  //               series: <CircularSeries>[
  //         PieSeries<Chartinfo, String>(
  //             dataSource: _chartData,

  //             // pointColorMapper: (ChartData data, _) => data.color,
  //             dataLabelSettings: DataLabelSettings(isVisible: true),
  //             // pointColorMapper: (Chartinfo data, _) => data.color,
  //             xValueMapper: (Chartinfo data, _) => data.chartinfocategory,
  //             yValueMapper: (Chartinfo data, _) => double.parse(data.name1))
  //       ])));
  // }

  void _scrollDown() {
    _Datascrollcontroller.animateTo(
        _Datascrollcontroller.position.maxScrollExtent,
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
    date1 = new DateTime(int.parse(DateTime.now().year.toString()),
        DateTime.now().month.toInt(), DateTime.now().day.toInt());
    print('Chart length : ${_chartData.length}');

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
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(widget.Plantname!.toUpperCase(),
                  style: TextStyle(
                      color: Colors.grey.shade900,
                      fontWeight: FontWeight.w500,
                      fontSize: 0.035 * (height - width))),
              Text(" Overview",
                  style: TextStyle(
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w300,
                      fontSize: 0.03 * (height - width))),
            ],
          ),
          leading: IconButton(
              onPressed: () {
                // Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MainScreen(passed_index: 1)),
                    (route) => false);
              },
              icon: Icon(Icons.arrow_back, color: Colors.black, size: 25)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          controller: _Datascrollcontroller,
          child: Container(
            color: Colors.black12,

            //   width: width,
            //  height: height,
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
                            height: 0.23 * height,
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
                                    'Current Power Generation',
                                    style: TextStyle(
                                        fontSize: 0.04 * (height - width),
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black),
                                  ),
                                  SizedBox(height: height * 0.001),
                                  Text(
                                    'of ${widget.Plantname}',
                                    style: TextStyle(
                                        fontSize: 0.025 * width,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.black),
                                  ),
                                  // SizedBox(height: height * 0.01),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        // widget.CurrentPowerofPS.toStringAsFixed(
                                        //     2),
                                        widget.CurrentPowerofPS >= 1000
                                            ? (widget.CurrentPowerofPS / 1000)
                                                .toStringAsFixed(2)
                                            : widget.CurrentPowerofPS
                                                .toStringAsFixed(2),

                                        style: TextStyle(
                                            fontSize: 0.2 * (height - width),
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
                                        widget.CurrentPowerofPS >= 1000
                                            ? 'MW'
                                            : ' kW',
                                        style: TextStyle(
                                            fontSize: 0.045 * (height - width),
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
                                  SizedBox(height: height * 0.005),
                                  // Container(
                                  //   width: 0.95 * width,
                                  //   padding: EdgeInsets.only(left: 15),
                                  //   child: Row(
                                  //     mainAxisAlignment:
                                  //         MainAxisAlignment.center,
                                  //     children: [
                                  //       Text(
                                  //         'STATUS: ',
                                  //         textAlign: TextAlign.center,
                                  //         style: TextStyle(
                                  //             fontSize:
                                  //                 0.025 * (height - width),
                                  //             fontWeight: FontWeight.normal,
                                  //             color: Colors.blueGrey),
                                  //       ),
                                  //       Text(
                                  //         Plant_status,
                                  //         textAlign: TextAlign.center,
                                  //         style: TextStyle(
                                  //             fontSize:
                                  //                 0.025 * (height - width),
                                  //             fontWeight: FontWeight.bold,
                                  //             color: Plant_status == 'ONLINE'
                                  //                 ? Colors.green
                                  //                 : Colors.redAccent),
                                  //       ),
                                  //     ],
                                  //   ),
                                  // ),
                                ]),
                          ),
                          SizedBox(height: height * 0.01),
                          Card(
                            color: Colors.blueGrey.shade300,
                            elevation: 2,
                            child: Container(
                              width: 0.95 * width,
                              height: 0.055 * height,
                              padding: EdgeInsets.all(5),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('Total Output Power'.toUpperCase(),
                                            style: TextStyle(
                                              fontSize:
                                                  0.023 * (height - width),
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black54,
                                            )),
                                        SizedBox(
                                          height: 0.008 * height,
                                        ),
                                        Text(
                                            '${widget.ENERGY_TOTAL.substring(0, widget.ENERGY_TOTAL.indexOf('.') + 3)} kWh',
                                            style: TextStyle(
                                                fontSize:
                                                    0.024 * (height - width),
                                                fontWeight: FontWeight.w500,
                                                color: Colors.white)),
                                      ]),
                                  Card(
                                    margin: EdgeInsets.all(2),
                                    child: Icon(
                                      Icons.flash_on,
                                      size: 0.07 * (height - width),
                                      color: Colors.amber,
                                    ),
                                  ),
                                  Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text('Installed Capacity'.toUpperCase(),
                                            style: TextStyle(
                                              fontSize:
                                                  0.023 * (height - width),
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black54,
                                            )),
                                        SizedBox(
                                          height: 0.008 * height,
                                        ),
                                        Text(
                                            "${widget.DesignPower!.toStringAsFixed(1)} kW",
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
                          SizedBox(height: height * 0.01),

                          SizedBox(
                            width: width,
                            child: Container(
                              color: Colors.black,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        Icon(Icons.alarm_on_sharp,
                                            size: width / 15,
                                            color: Colors.blueGrey),
                                        SizedBox(
                                          width: width * 0.01,
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              'Mean Trouble-Free Uptime',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      0.02 * (height - width),
                                                  color: Colors.white),
                                            ),
                                            SizedBox(
                                              height: height * 0.008,
                                            ),
                                            Text(
                                              widget.Average_troublefree_operationtime !=
                                                      null
                                                  ? widget.Average_troublefree_operationtime
                                                          .toString() +
                                                      ' minutes'
                                                  : '0 minutes',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      0.024 * (height - width),
                                                  color: Colors
                                                      .greenAccent.shade200),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        Icon(Icons.alarm_on_sharp,
                                            size: width / 15,
                                            color: Colors.blueGrey),
                                        SizedBox(
                                          width: width * 0.01,
                                        ),
                                        Column(
                                          children: [
                                            Text(
                                              'Continuous Trouble-Free Uptime',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      0.02 * (height - width),
                                                  color: Colors.white),
                                            ),
                                            SizedBox(
                                              height: height * 0.008,
                                            ),
                                            Text(
                                              widget.Continuous_troublefree_operationtime !=
                                                      null
                                                  ? widget.Continuous_troublefree_operationtime
                                                          .toString() +
                                                      ' minutes'
                                                  : '0 minutes',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize:
                                                      0.024 * (height - width),
                                                  color: Colors
                                                      .greenAccent.shade200),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: width,
                            height: 0.43 * height,
                            color: Colors.grey[900],
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
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
                                                  child: Text('No Data',
                                                      style: TextStyle(
                                                          color: Colors
                                                              .grey.shade500,
                                                          fontSize: 50,
                                                          fontWeight: FontWeight
                                                              .w100))),
                                            ),
                                    ),
                                  ),
                                  // Row(
                                  //   mainAxisAlignment: MainAxisAlignment.center,
                                  //   children: [
                                  //     Icon(
                                  //       Icons
                                  //           .keyboard_double_arrow_down_outlined,
                                  //       color: Colors.white,
                                  //       size: width / 15,
                                  //     ),
                                  //   ],
                                  // )
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
                              "Power Today",
                              widget.ENERGY_TODAY.substring(
                                      0, widget.ENERGY_TODAY.indexOf('.') + 3) +
                                  ' kWh',
                              'Total Power',
                              widget.ENERGY_TOTAL.substring(
                                      0, widget.ENERGY_TOTAL.indexOf('.') + 3) +
                                  ' kWh',
                              Icon(Icons.flash_on,
                                  color: Theme.of(context).primaryColor),
                              Icon(Icons.flash_on,
                                  color: Theme.of(context).primaryColor)),
                          SizedBox(
                            height: height / 200,
                          ),
                          _display(
                              height,
                              width,
                              "Monthly Power",
                              widget.ENERGY_MONTH.substring(
                                      0, widget.ENERGY_MONTH.indexOf('.') + 2) +
                                  ' kWh',

                              // double.parse(energyProceed.substring(
                              //     1, energyProceed.length)),
                              'Yearly Power',
                              widget.ENERGY_YEAR.substring(
                                      0, widget.ENERGY_YEAR.indexOf('.') + 2) +
                                  ' kWh',
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
                              "COAL Saved",
                              widget.ENERGY_COAL.substring(
                                      0, widget.ENERGY_COAL.indexOf('.') + 3) +
                                  ' kg',
                              'Profits',
                              //+ '' + widget.currency!,
                              widget.ENERGY_PROCEEDS.substring(
                                  0, widget.ENERGY_PROCEEDS.indexOf('.') + 2),
                              Icon(
                                Icons.graphic_eq,
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
                              "Reduce CO2",
                              widget.ENERGY_CO2.substring(
                                      0, widget.ENERGY_CO2.indexOf('.') + 3) +
                                  ' kg',
                              'Reduce SO2',
                              widget.ENERGY_SO2.substring(
                                      0, widget.ENERGY_SO2.indexOf('.') + 3) +
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
                              "Ambient temperature",
                              widget.CURRENT_TEMP + ' °C',
                              'Solar irradiance',
                              widget.CURRENT_RADIANT + ' kW/m2 ',
                              Icon(
                                Icons.wb_sunny_rounded,
                                color: Theme.of(context).primaryColor,
                              ),
                              Icon(Icons.brightness_7,
                                  color: Theme.of(context).primaryColor)),
                          SizedBox(
                            height: height / 30,
                          ),
                          // _chartData.length != 0
                          //     ? Container(
                          //         width: width,
                          //         color: Colors.grey[200],
                          //         height: height / 3,
                          //         child: _piechart(width, height),
                          //       )
                          //     : Container(),
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
        DateTime(2022, 7, 8, 3, 20),
        '0',
      ),
      Chartinfo(
        DateTime(2022, 7, 8, 3, 30),
        '0',
      ),
      Chartinfo(
        DateTime(2022, 7, 8, 3, 40),
        '0',
      ),
      Chartinfo(
        DateTime(2022, 7, 8, 4, 10),
        '0',
      ),
      Chartinfo(
        DateTime(2022, 7, 8, 4, 30),
        '0',
      ),
      Chartinfo(
        DateTime(2022, 7, 8, 5, 40),
        '0',
      ),
      Chartinfo(
        DateTime(2022, 7, 8, 5, 50),
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

  // var Yvalues_list = new List<int>.generate(100, (i) => i + 1);

  Future FetchCurrentPlantDATANEW() async {
    var Jsonresponse_currentplantData =
        await PlantcurrentDataQuery(PID: widget.PlantID!);

    if (Jsonresponse_currentplantData['err'] == 0) {
      QueryPlantCurrentDataNew _QPCD =
          new QueryPlantCurrentDataNew.fromJson(Jsonresponse_currentplantData);

      if (_QPCD.err == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            duration: Duration(milliseconds: 1500),
            backgroundColor: Colors.green,
            content: Text("Powerstation information Updated ...",
                style: TextStyle(fontSize: 12, color: Colors.white))));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            duration: Duration(milliseconds: 1500),
            backgroundColor: Colors.red,
            content: Text("${_QPCD.desc} ",
                style: TextStyle(fontSize: 12, color: Colors.white))));
      }
      setState(() {
        widget.ENERGY_TODAY = _QPCD.dat?[0].val;
        widget.ENERGY_MONTH = _QPCD.dat?[1].val;
        widget.ENERGY_YEAR = _QPCD.dat?[2].val;
        widget.ENERGY_TOTAL = _QPCD.dat?[3].val;
        widget.ENERGY_PROCEEDS = _QPCD.dat?[4].val;
        widget.ENERGY_COAL = _QPCD.dat?[5].val;
        widget.ENERGY_CO2 = _QPCD.dat?[6].val;
        widget.ENERGY_SO2 = _QPCD.dat?[7].val;
        widget.CURRENT_TEMP = _QPCD.dat?[8].val;
        widget.CURRENT_RADIANT = _QPCD.dat?[9].val;
        widget.BATTERY_SOC = _QPCD.dat![10].val.toString();
      });
    }
  }

  Future fetch_Cont_avgtime() async {
    var Jsonresponse_Continuoustroublefreeoperationtime =
        await ContinuoustroublefreeoperationtimeQuery(
            PID: int.parse(widget.PlantID!));
    Continuoustroublefreeoperationtime _CTFOT =
        new Continuoustroublefreeoperationtime.fromJson(
            Jsonresponse_Continuoustroublefreeoperationtime);

    var Jsonresponse_Averagetroublefreeoperationtime =
        await AveragetroublefreeoperationtimeQuery(
            PID: int.parse(widget.PlantID!));
    Averagetroublefreeoperationtime _ATFOT =
        new Averagetroublefreeoperationtime.fromJson(
            Jsonresponse_Averagetroublefreeoperationtime);

    setState(() {
      widget.Continuous_troublefree_operationtime = _CTFOT.dat!.minutes ?? 0000;
      widget.Average_troublefree_operationtime = _ATFOT.dat!.minutes ?? 0000;
    });
  }

  Future fetchCurrentPlantStats() async {
    String Current_outpowerofPS;
    Current_outpowerofPS =
        await CurrentActivePowerofPSQuery(PID: int.parse(widget.PlantID!));

    setState(() {
      //current power  data of power station

      widget.CurrentPowerofPS = double.parse(Current_outpowerofPS);
      widget.last_updated = DateTime.now();

      switch (int.parse(widget.Plant_status!)) {
        case 0:
          {
            Plant_status = 'ONLINE';
          }
          break;
        case 1:
          {
            Plant_status = 'OFFLINE';
          }
          break;
        case 4:
          {
            Plant_status = 'WARNING';
          }
          break;
        case 7:
          {
            Plant_status = 'ATTENTION';
          }
          break;
      }
    });
  }

  /////////////////Daily Power Generation in Month////////////
  Future fetchDailyPGIMonth() async {
    // formatted current datetime // YYYY-MM
    String yearmonth = DateTime.now().year.toString() +
        DateTime.now().month.toString().padLeft(2, '0');

    var Jsonresponse_DailyPGinMonth = await DailyPGinMonthQuery(
        // format yyyy-mm
        yearmonth: date.text == '' || date.text.length <= 6
            ? yearmonth
            : date.text.substring(0, 7),
        PID: widget.PlantID!);
    DailyPGinMonth _DPGIM =
        new DailyPGinMonth.fromJson(Jsonresponse_DailyPGinMonth);

    if (_DPGIM.err == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          duration: Duration(milliseconds: 500),
          backgroundColor: Colors.green,
          content: Text("Data Updated Successfully...",
              style: TextStyle(fontSize: 12, color: Colors.white))));
    } else {
      Fluttertoast.showToast(
          msg: " ${_DPGIM.desc} ",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 2,
          textColor: Colors.white,
          fontSize: 18.0);
    }

    /// updating chartData list with Daily powergeneration in month query data
    setState(() {
      _chartData.clear();
      // _chartData = <Chartinfo>[];
      for (int i = 0; i < _DPGIM.dat!.perday!.length; i++) {
        if (_DPGIM.dat!.perday![i].val == "0.0000") continue;

        _chartData.add(Chartinfo(_DPGIM.dat!.perday![i].ts,
            double.parse(_DPGIM.dat!.perday![i].val!).toStringAsFixed(1)));

        //  print(_chartData[i].name1);
      }
    });
  }

  /////////////////Daily Power Generation in Month//////end//////
  ///
  ////////////////////Monthly Power Generation in year//// start////////
  Future fetchMonthlyPGinyear() async {
    // formatted current datetime // YYYY
    String year = DateTime.now().year.toString();

    var Jsonresponse_MonthlyPGinyear = await MonthlyPGinyearQuery(
        // format yyyy
        year: date.text == '' || date.text.length > 4
            ? year
            : date.text.substring(0, 4),
        PID: widget.PlantID!);
    MonthlyPGinyear _MPGIY =
        new MonthlyPGinyear.fromJson(Jsonresponse_MonthlyPGinyear);

    if (_MPGIY.err == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          duration: Duration(milliseconds: 500),
          backgroundColor: Colors.green,
          content: Text("Data Updated Successfully...",
              style: TextStyle(fontSize: 12, color: Colors.white))));
    } else {
      Fluttertoast.showToast(
          msg: " ${_MPGIY.desc} ",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 2,
          textColor: Colors.white,
          fontSize: 18.0);
    }

    /// updating chartData list with Monthly Power Generation in year query data
    setState(() {
      _chartData.clear();
      for (int i = 0; i < _MPGIY.dat!.permonth!.length; i++) {
        if (_MPGIY.dat!.permonth![i].val == "0.0000") continue;

        _chartData.add(Chartinfo(_MPGIY.dat!.permonth![i].ts,
            double.parse(_MPGIY.dat!.permonth![i].val!).toStringAsFixed(1)));
      }
    });
  }

  /////////////////Monthly Power Generation in year//////end//////
  ///
  /// ////////////////////Annual Power Generation in year//// start////////
  Future fetchAnnualPg() async {
    var Jsonresponse_AnnualPg = await AnnualPgQuery(PID: widget.PlantID!);
    AnnualPg _APG = new AnnualPg.fromJson(Jsonresponse_AnnualPg);

    if (_APG.err == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          duration: Duration(milliseconds: 500),
          backgroundColor: Colors.green,
          content: Text("Data Updated Successfully...",
              style: TextStyle(fontSize: 12, color: Colors.white))));
    } else {
      Fluttertoast.showToast(
          msg: " ${_APG.desc} ",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 2,
          textColor: Colors.white,
          fontSize: 18.0);
    }

    /// updating chartData list with Annual Power Generation in year query data
    setState(() {
      _chartData.clear();
      for (int i = 0; i < _APG.dat!.peryear!.length; i++) {
        _chartData.add(Chartinfo(_APG.dat!.peryear![i].ts,
            double.parse(_APG.dat!.peryear![i].val!).toStringAsFixed(1)));
      }
    });
  }

  /////////////////Annual Power Generation in year//////end//////
  ///
  /////////////////ActiveOuputPowerOneDay////////////
  Future fetchActiveOuputPowerOneDay() async {
    // formatted current datetime // YYYY-MM-DD
    String yearmonthdate = DateTime.now().year.toString() +
        DateTime.now().month.toString().padLeft(2, '0') +
        DateTime.now().day.toString().padLeft(2, '0');

    var Jsonresponse_ActiveOuputPowerOneDay = await ActiveOuputPowerOneDayQuery(
        // format yyyy-mm-dd
        Date: date.text == '' || date.text.length <= 8
            ? yearmonthdate
            : date.text.substring(0, 10),
        PID: widget.PlantID!);
    ActiveOuputPowerOneDay _AOPOD = new ActiveOuputPowerOneDay.fromJson(
        Jsonresponse_ActiveOuputPowerOneDay);

    if (_AOPOD.err == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          duration: Duration(milliseconds: 500),
          backgroundColor: Colors.green,
          content: Text("Data Updated Successfully...",
              style: TextStyle(fontSize: 12, color: Colors.white))));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: Duration(milliseconds: 500),
          backgroundColor: Colors.black,
          content: Text("${_AOPOD.desc}",
              style: TextStyle(fontSize: 12, color: Colors.white))));
    }

    /// updating chartData list with Daily powergeneration in month query data
    setState(() {
      _chartData.clear();
      // _chartData = <Chartinfo>[];
      print('outputPower length: ${_AOPOD.dat?.outputPower!.length}');
      if (_AOPOD.dat?.outputPower!.length != null) {
        for (int i = 0; i < _AOPOD.dat!.outputPower!.length; i++) {
          //newchange
          if (_AOPOD.dat!.outputPower![i].val == "0.0000") continue;

          _chartData.add(Chartinfo(
              _AOPOD.dat!.outputPower![i].ts,
              double.parse(_AOPOD.dat!.outputPower![i].val!)
                  .toStringAsFixed(1)));
        }
      }
    });
  }

  ///////////////// ActiveOuputPowerOneDay//////end//////
  ///
  ////////////////////////////////////////////////////////////////////////////////////
  /////////////////////////////////////////////////////////////////////////////////
  Future<void> _refreshData() async {
    await Future.delayed(Duration(milliseconds: 1500));
    fetchCurrentPlantStats();
    FetchCurrentPlantDATANEW();
    fetch_Cont_avgtime();
    fetchActiveOuputPowerOneDay();
  }
  ///////////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////
}

class Chartinfo {
  Chartinfo(this.chartinfocategory, this.name1);
  final DateTime? chartinfocategory;
  final String name1;
  // Color color;
}
