import 'dart:async';

import 'package:crownmonitor/Models/DeviceCtrlFieldseModel.dart';
import 'package:crownmonitor/Models/DeviceDataOneDayQuery.dart' as DDOD;
import 'package:crownmonitor/pages/alarmmanagement.dart';
import 'package:crownmonitor/pages/deviceenergyFlows.dart';
import 'package:crownmonitor/pages/downloadreportscreen.dart';
import 'package:crownmonitor/pages/plant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'
    as picker;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../datepickermodel.dart';
import 'DataControl.dart';
//import 'data.dart';

class deviceinfopage extends StatefulWidget {
  int? PID;
  String? Plantname;
  String? PN;
  String? SN;
  int? status;
  int? devcode;
  int? devaddr;
  String? alias;
  int? load;
  String? firmware;

  /// new DEQ varaiables
  String? outputpower;
  String? energytoday;

  String? energyyear;
  String? energytotal;

  deviceinfopage(
      {Key? key,
      this.firmware,
      this.load,
      this.energytoday,
      this.energytotal,
      this.energyyear,
      this.outputpower,
      this.alias,
      this.devaddr,
      this.devcode,
      this.PID,
      this.Plantname,
      this.PN,
      this.SN,
      this.status})
      : super(key: key);

  @override
  _deviceinfopageState createState() => _deviceinfopageState();
}

class _deviceinfopageState extends State<deviceinfopage> {
  @override
  late TextEditingController Titletext = new TextEditingController();
  final TextEditingController name = new TextEditingController();

  DateTime date1 = new DateTime(int.parse(DateTime.now().year.toString()),
      DateTime.now().month.toInt(), DateTime.now().day.toInt());

  DateTimeRange daterange = DateTimeRange(
      start: DateTime(DateTime.now().year, 01, 01),
      end: DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day));

  String? StartDate;
  String? EndDate;
  List<String> _alltypes = ['All types', 'Fault', 'Alarm', 'Error']; // Option 2
  late String _selectedalltypes = 'All types';
  String _selectedalltypes_converted = '0101';
  List<String> _alldevices = [
    'All devices',
    'Invertor',
    'Env-monitor',
    'Smart meters',
    'Combining manifolds',
    'Camera',
    'Battery',
    'Charger',
    'Energy storage machine',
    'Anti-islanding',
  ]; // Option 2
  late String _selectedalldevices = 'All devices';
  String _selectedalldevices_coverted = '0101';
  List<String> _allstatus = [
    'All status',
    'Untreated',
    'Processed'
  ]; // Option 2
  late String _selectedallstatus = 'All status';
  String _selectedallstatus_converted = '0101';

  String selectedoption = 'realtimeflow'; //'diagram';
  late int indexpos = 0;
  late ZoomPanBehavior zoomPanBehavior;
  String chart_label = 'Time';
  late List<bool> isSelected;
  late TextEditingController date = new TextEditingController();
  late TextEditingController datediagram = new TextEditingController();
  late List<Chartinfo> _chartData;
  int? Radiobuttonvalue;
  DDOD.DeviceDataOneDayQuery? DeviceDataoneday;
  DDOD.DeviceDataOneDayQuery? DeviceDataoneday2;
  DDOD.DeviceenergyQuint? DEQ;
  int currentpagenumber = 1;
  bool Loading_Data = false;
  bool Device_Dataoneday_loaded = false;

  List? keyparamfields_list = [];
  String? selectedparameter_name, selectedparm_unit;
  String? keyparam_date = DateFormat('y-M-d').format(DateTime.now());
  bool iskeychartdataloaded = false;
  //List<DropdownMenuItem<String>> devkeyparam = [];

  void getpara_name_unit(String value) {
    for (var item in keyparamfields_list!) {
      if (item["e0"] == value) {
        setState(() {
          selectedparameter_name = item["e1"];
          selectedparm_unit = item["e3"];
          // print("************************");
          // print(selectedparameter_name);
          // print(selectedparm_unit);
        });
      }
    }
  }

  Future fetchdevicekeyparameters() async {
    var response = await fetchkeyparametersfields(
      devcode: widget.devcode!,
    );
    if (response != null) {
      keyparamfields_list = response['dat'];
      _selectedalltypes = keyparamfields_list![0]['e0'];
      //unit and name
      selectedparameter_name = keyparamfields_list![0]['e1'];
      selectedparm_unit = keyparamfields_list![0]['e3'];
      fetchdevchartfield();
    }
  }

  // Device Energy Quint one day
  Future fetchDeviceEnergyQuint() async {
    var response = await DDOD.DeviceEnergyQuintiyoneday_Query(context,
        PN: widget.PN!,
        SN: widget.SN!,
        devaddr: widget.devaddr!.toString(),
        devcode: widget.devcode!.toString(),
        date: date.text);
    setState(() {
      DEQ = response;
      // DEQ = new DDOD.DeviceenergyQuint(
      //     energytoday: widget.energytoday,
      //     energytotal: widget.energytotal,
      //     energyyear: widget.energyyear);
    });
  }

  Future fetchDevicedataoneDay() async {
    String pagenumber = '0';
    setState(() {
      currentpagenumber = 1;
      Loading_Data = true;
    });

    DeviceDataoneday = await DDOD.DeviceDataOneDay_Query(
        PN: widget.PN!,
        SN: widget.SN!,
        devaddr: widget.devaddr!.toString(),
        devcode: widget.devcode!.toString(),
        date: date.text,
        pagenumber: pagenumber);
    if (DeviceDataoneday?.err == 0) {
      if (DeviceDataoneday!.dat!.total! > 200) {
        pagenumber = '1';
        DeviceDataoneday2 = await DDOD.DeviceDataOneDay_Query(
            PN: widget.PN!,
            SN: widget.SN!,
            devaddr: widget.devaddr!.toString(),
            devcode: widget.devcode!.toString(),
            date: date.text,
            pagenumber: pagenumber);
        if (DeviceDataoneday2?.err == 0) {
          DeviceDataoneday?.dat?.row?.addAll(DeviceDataoneday2!.dat!.row!);
          pagenumber = '2';
          DeviceDataoneday2 = await DDOD.DeviceDataOneDay_Query(
              PN: widget.PN!,
              SN: widget.SN!,
              devaddr: widget.devaddr!.toString(),
              devcode: widget.devcode!.toString(),
              date: date.text,
              pagenumber: pagenumber);
          if (DeviceDataoneday2?.err == 0) {
            DeviceDataoneday?.dat?.row?.addAll(DeviceDataoneday2!.dat!.row!);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                duration: Duration(milliseconds: 800),
                backgroundColor: Colors.green,
                content: SizedBox(
                  height: 18,
                  child: Center(
                    child: Text(
                        AppLocalizations.of(context)!.data_updated_successfully,
                        style: TextStyle(
                            fontSize: 0.035 *
                                (MediaQuery.of(context).size.height -
                                    MediaQuery.of(context).size.width),
                            color: Colors.white)),
                  ),
                )));
            setState(() {
              Loading_Data = false;
              Device_Dataoneday_loaded = true;
            });
          }
        }
      } else if (DeviceDataoneday!.dat!.total! > 100) {
        pagenumber = '1';
        DeviceDataoneday2 = await DDOD.DeviceDataOneDay_Query(
            PN: widget.PN!,
            SN: widget.SN!,
            devaddr: widget.devaddr!.toString(),
            devcode: widget.devcode!.toString(),
            date: date.text,
            pagenumber: pagenumber);
        if (DeviceDataoneday2?.err == 0) {
          DeviceDataoneday?.dat?.row?.addAll(DeviceDataoneday2!.dat!.row!);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              duration: Duration(milliseconds: 800),
              backgroundColor: Colors.green,
              content: SizedBox(
                height: 18,
                child: Center(
                  child: Text(
                      AppLocalizations.of(context)!.data_updated_successfully,
                      style: TextStyle(
                          fontSize: 0.035 *
                              (MediaQuery.of(context).size.height -
                                  MediaQuery.of(context).size.width),
                          color: Colors.white)),
                ),
              )));
          setState(() {
            Loading_Data = false;
            Device_Dataoneday_loaded = true;
          });
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: Duration(milliseconds: 800),
          backgroundColor: Colors.green,
          content: SizedBox(
            height: 18,
            child: Center(
              child: Text(
                  AppLocalizations.of(context)!.data_updated_successfully,
                  style: TextStyle(
                      fontSize: 0.035 *
                          (MediaQuery.of(context).size.height -
                              MediaQuery.of(context).size.width),
                      color: Colors.white)),
            ),
          )));
      setState(() {
        Loading_Data = false;
        Device_Dataoneday_loaded = true;
      });
    } else if (DeviceDataoneday?.err == 12) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: Duration(milliseconds: 800),
          backgroundColor: Colors.black,
          content: SizedBox(
            height: 18,
            child: Center(
              child: Text(AppLocalizations.of(context)!.no_record_found,
                  style: TextStyle(
                      fontSize: 0.035 *
                          (MediaQuery.of(context).size.height -
                              MediaQuery.of(context).size.width),
                      color: Colors.white)),
            ),
          )));
      setState(() {
        Loading_Data = false;
        //testing added 1 august
        Device_Dataoneday_loaded = true;
      });
    }
  }

  void Showsnackbar(String message, int milliseconds, Color? color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: color,
          content: Text(
            '${message}',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 0.035 *
                    (MediaQuery.of(context).size.height -
                        MediaQuery.of(context).size.width)),
          ),
          duration: Duration(milliseconds: milliseconds),
        ),
      );
    }
  }

  Widget _datetime(double width, double height) {
    return Container(
      color: Theme.of(context).primaryColor,
      child: Row(
        children: [
          Container(
            child: new Flexible(
              child: _centerdate(width, height),
            ),
          ),
        ],
      ),
    );
  }

  Future PickDateRange() async {
    DateTimeRange? newdaterange = await showDateRangePicker(
        initialEntryMode: DatePickerEntryMode.calendarOnly,
        context: context,
        initialDateRange: daterange,
        firstDate: DateTime(2015, 01, 01),
        lastDate: DateTime(date1.year, 12, date1.day));

    if (newdaterange == null) return;
    setState(() {
      daterange = newdaterange;
      StartDate = DateFormat('yyyy-MM-dd').format(newdaterange.start);
      EndDate = DateFormat('yyyy-MM-dd').format(newdaterange.end);
      Titletext.text =
          'From: ${DateFormat('yyyy-MM-dd').format(newdaterange.start)}  TO: ${DateFormat('yyyy-MM-dd').format(newdaterange.end)}';
    });
  }

  Widget _centerdate(double x, double y) {
    return TextField(
      textAlignVertical: TextAlignVertical.center,
      enabled: false,
      textAlign: TextAlign.center,
      controller: Titletext,
      style: Theme.of(context).textTheme.titleSmall,
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
          AreaSeries<Chartinfo, dynamic>(
              name: AppLocalizations.of(context)!.power,
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
          // ColumnSeries<Chartinfo, String>(
          //     width: 0.4,
          //     spacing: 0.01,
          //     name: 'Energy',
          //     borderRadius: BorderRadius.only(
          //         topLeft: Radius.circular(5), topRight: Radius.circular(5)),
          //     //enableTooltip: true,
          //     color: Theme.of(context).primaryColor,
          //     dataSource: _chartData,
          //     xValueMapper: (Chartinfo exp, _) =>
          //         exp.chartinfocategory.toString(),
          //     yValueMapper: (Chartinfo exp, _) => double.parse(exp.name1),
          //     dataLabelSettings: DataLabelSettings(
          //         isVisible: true,
          //         textStyle: TextStyle(
          //             color: Colors.white,
          //             fontWeight: FontWeight.bold,
          //             fontSize: 12)),
          //     markerSettings: MarkerSettings(
          //       isVisible: false,
          //     )),
        ],
        primaryXAxis: DateTimeCategoryAxis(
            labelStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.normal,
                fontSize: 0.018 * (height - width)),
            //labelPlacement: LabelPlacement.onTicks,
            majorGridLines: MajorGridLines(
                width: 1, color: Colors.white10, dashArray: <double>[5, 5]),
            title: AxisTitle(
                text: AppLocalizations.of(context)!.time_hrs,
                textStyle: TextStyle(
                    color: Colors.deepOrange,
                    fontFamily: 'Roboto',
                    fontSize: width * 0.03,
                    fontWeight: FontWeight.w300)),
            /////
            dateFormat: DateFormat.H(),
            intervalType: DateTimeIntervalType.hours,
            interval: 12
            //labelRotation: 0
            // intervalType: DateTimeIntervalType.hours,
            //                   interval: 1
            ),
        //  CategoryAxis(
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
            // visibleMinimum: 1,
            // plotOffset: 1,
            majorGridLines: MajorGridLines(
                width: 0, color: Colors.transparent, dashArray: <double>[2, 2]),
            title: AxisTitle(
                text:
                    selectedparameter_name! + " ( " + selectedparm_unit! + " )",
                textStyle: TextStyle(
                    color: Colors.deepOrange,
                    fontFamily: 'Roboto',
                    fontSize: width * 0.03,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300))),
      ),
    );
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
                    // fetchActiveOuputPowerOneDay();
                  });
                } else if (indexpos == 1) {
                  date1 = new DateTime(date1.year, date1.month - 1, date1.day);
                  date.text = date1.year.toString() +
                      '-' +
                      date1.month.toString().padLeft(2, '0');
                  setState(() {
                    //  fetchDailyPGIMonth();
                  });
                } else if (indexpos == 2) {
                  date1 = new DateTime(date1.year - 1, date1.month, date1.day);

                  date.text = date1.year.toString();
                  setState(() {
                    // fetchMonthlyPGinyear();
                  });
                } else if (indexpos == 3) {
                  date.clear();
                  setState(() {
                    //  fetchAnnualPg();
                  });
                }
              },
              child: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: width / 20,
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
                    //   fetchActiveOuputPowerOneDay();
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
                    //  fetchDailyPGIMonth();
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
                    //  fetchMonthlyPGinyear();
                  });
                } else if (index == 3) {
                  indexpos = 3;
                  date.clear();
                  setState(() {
                    chart_label = 'Year';
                    // fetchAnnualPg();
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
              child: Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: width / 20),
            )),
      ],
    );
  }

  Widget customdropdown(double width, height) {
    return Container(
      width: 0.9 * width,
      height: 30,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: DropdownButtonHideUnderline(
            child: DropdownButton(
          style: TextStyle(
              fontSize: 0.028 * (height - width), color: Colors.grey.shade900),
          // dropdownColor: Colors.grey[700],
          icon: Icon(
            Icons.keyboard_arrow_down_sharp,
            size: 20,
            color: Colors.grey,
          ),
          value: _selectedalltypes,
          onChanged: (newValue) {
            setState(() {
              _selectedalltypes = newValue.toString();
              getpara_name_unit(newValue.toString());
              fetchdevchartfield();
              print(newValue);
            });
          },
          items: List.generate(
            keyparamfields_list!.length,
            (int index) {
              return new DropdownMenuItem<String>(
                value: keyparamfields_list![index]['e0'],
                child: Text(keyparamfields_list![index]['e1'],
                    style: TextStyle(
                      fontSize: 0.03 * (height - width),
                    )),
              );
            },
          ),
        )),
      ),
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
                                  .format(DateTime.parse(datediagram.text))
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
                              setState(() {
                                keyparam_date =
                                    DateFormat('y-MM-dd').format(datepick);
                                datediagram.text = keyparam_date!;
                                fetchdevchartfield();
                                print('datepicked: $keyparam_date');
                              });

                              // date.text = datepick.year.toString() +
                              //     '-' +
                              //     datepick.month.toString().padLeft(2, '0') +
                              //     '-' +
                              //     datepick.day.toString().padLeft(2, '0');

                              // fetchActiveOuputPowerOneDay();
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
                              date.text = datepick.year.toString();
                              // fetchMonthlyPGinyear();
                            },
                          );
                        }
                      }),
                ),
        ),
        //   child: TextButton(
        //     onPressed: () {
        //       if (indexpos == 0) {
        //         DatePicker.showPicker(
        //           context,
        //           pickerModel: YearMonthDayModel(
        //             currentTime: DateTime.now(),
        //             maxTime: DateTime.now(),
        //             minTime: DateTime(2015),
        //             locale: LocaleType.en,
        //           ),
        //           theme: DatePickerTheme(
        //               headerColor: Theme.of(context).primaryColor,
        //               backgroundColor: Color(0xffF4F4F4),
        //               itemStyle: TextStyle(color: Colors.black, fontSize: 10),
        //               doneStyle: TextStyle(color: Colors.white, fontSize: 16)),
        //           locale: LocaleType.en,
        //           onChanged: (date) {
        //             print('change $date');
        //           },
        //           onConfirm: (datepick) {
        //             date.text = datepick.year.toString() +
        //                 '-' +
        //                 datepick.month.toString().padLeft(2, '0') +
        //                 '-' +
        //                 datepick.day.toString().padLeft(2, '0');
        //             // fetchCurrentPlantStats();
        //             fetchActiveOuputPowerOneDay();
        //           },
        //         );
        //       } else if (indexpos == 1) {
        //         DatePicker.showPicker(
        //           context,
        //           pickerModel: YearMonthModel(
        //             currentTime: DateTime.now(),
        //             maxTime: DateTime.now(),
        //             minTime: DateTime(2015),
        //             locale: LocaleType.en,
        //           ),
        //           theme: DatePickerTheme(
        //               headerColor: Theme.of(context).primaryColor,
        //               backgroundColor: Color(0xffF4F4F4),
        //               itemStyle: TextStyle(color: Colors.black, fontSize: 10),
        //               doneStyle: TextStyle(color: Colors.white, fontSize: 16)),
        //           locale: LocaleType.en,
        //           onChanged: (date) {
        //             print('change $date');
        //           },
        //           onConfirm: (datepick) {
        //             date.text = datepick.year.toString() +
        //                 '-' +
        //                 datepick.month.toString().padLeft(2, '0');

        //             fetchDailyPGIMonth();
        //           },
        //         );
        //       } else if (indexpos == 2) {
        //         DatePicker.showPicker(
        //           context,
        //           pickerModel: YearModel(
        //             currentTime: DateTime.now(),
        //             maxTime: DateTime.now(),
        //             minTime: DateTime(2015),
        //             locale: LocaleType.en,
        //           ),
        //           theme: DatePickerTheme(
        //               headerColor: Theme.of(context).primaryColor,
        //               backgroundColor: Color(0xffF4F4F4),
        //               itemStyle: TextStyle(color: Colors.black, fontSize: 10),
        //               doneStyle: TextStyle(color: Colors.white, fontSize: 16)),
        //           locale: LocaleType.en,
        //           onChanged: (date) {
        //             print('change $date');
        //           },
        //           onConfirm: (datepick) {
        //             date.text = datepick.year.toString();
        //             fetchMonthlyPGinyear();
        //           },
        //         );
        //       }
        //     },
        //     child: TextField(
        //         enabled: false,
        //         decoration: InputDecoration(
        //             border: InputBorder.none,
        //             contentPadding: EdgeInsets.only()),
        //         textAlign: TextAlign.center,
        //         controller: date,
        //         style: Theme.of(context).textTheme.subtitle1),
        //   ),
        // ),
        SizedBox(
          height: height / 100,
        ),
      ],
    );
  }

  ///////////////// DAte and its toggle buttons ////////////////

  Widget _toggle_for_data(double width, double height) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      //crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
            // width: width / 12,
            child: TextButton(
          onPressed: () {
            setState(() {
              date1 = new DateTime(date1.year, date1.month, date1.day - 1);
              date.text = date1.year.toString() +
                  '-' +
                  date1.month.toString().padLeft(2, '0') +
                  '-' +
                  date1.day.toString().padLeft(2, '0');

              if (selectedoption == 'data') {
                fetchDevicedataoneDay();
              }
            });
          },
          child: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 20,
          ),
        )),
        SizedBox(width: width / 2, child: _toggledown_for_data(width, height)),
        SizedBox(
            // DAte text under toggle
            // width: width / 12,
            child: TextButton(
          onPressed: () {
            setState(() {
              date1 = new DateTime(date1.year, date1.month, date1.day + 1);
              date.text = date1.year.toString() +
                  '-' +
                  date1.month.toString().padLeft(2, '0') +
                  '-' +
                  date1.day.toString().padLeft(2, '0');

              if (selectedoption == 'data') {
                fetchDevicedataoneDay();
              }
            });
          },
          child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
        )),
      ],
    );
  }

  Widget _toggledown_for_data(double width, double height) {
    return TextButton(
      onPressed: () {
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
              itemStyle: TextStyle(color: Colors.black, fontSize: 10),
              doneStyle: TextStyle(color: Colors.white, fontSize: 16)),
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
            if (selectedoption == 'data') {
              fetchDevicedataoneDay();
            }
          },
        );
      },
      child: TextField(
          enabled: false,
          decoration: null,
          textAlign: TextAlign.center,
          controller: date,
          style: Theme.of(context).textTheme.titleSmall),
    );
  }

  //////////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////
  ///
  //new chart variables
  var _trackballBehavior;
  final List<Color> color = <Color>[];
  final List<double> stops = <double>[];
  late LinearGradient gradientColors;

  /// deviceinfo init
  @override
  void initState() {
    // DeviceActiveOuputPowerOneDayQuery(
    //   Date: '2025-03-07',
    //   PN: widget.PN!,
    //   SN: widget.SN!,
    //   devaddr: widget.devaddr.toString(),
    //   devcode: widget.devcode.toString(),
    // );
    Titletext.text = 'Last Updated : ${DateFormat('yyyy-MM-dd').format(date1)}';
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
    datediagram.text = DateTime.now().toString();

    ///////////*******testing************************
    // date.text = '2022-04-16';
    // widget.status = 1; //online
    ///////************************/////// */

    isSelected = [true, false, false, false];
    focusToggle = [
      focusNodeButton1,
      focusNodeButton2,
      focusNodeButton3,
      focusNodeButton4,
    ];
    //data widget variables
    fetchDevicedataoneDay();
    //diagram widget varaiables
    fetchDeviceEnergyQuint();
    fetchdevicekeyparameters();
    //fetchActiveOuputPowerOneDay();
    //fetchDailyPGIMonth();

    //realtimeflows widget variables

    if (widget.status != 1) {
      fetchdeviceenergyflows();
      realtimetimer = new Timer.periodic(Duration(seconds: 30), (timer) async {
        if (widget.status != 1) {
          setState(() {
            fetcheddeviceflows = false;
          });
          await fetchdeviceenergyflows();
        }
      });
    }

    super.initState();
  }

  Timer? realtimetimer;

  FocusNode focusNodeButton1 = FocusNode();
  FocusNode focusNodeButton2 = FocusNode();
  FocusNode focusNodeButton3 = FocusNode();
  FocusNode focusNodeButton4 = FocusNode();

  late List<FocusNode> focusToggle;

  deviceenergyflows? DEF;
  List? esParameters_list;
  bool fetcheddeviceflows = false;
  DateTime? lastfetched_realtime;

  fetchdeviceenergyflows() async {
    var response1 = await fetchdeviceparamES(
        PN: widget.PN!,
        SN: widget.SN,
        devcode: widget.devcode.toString(),
        devadr: widget.devaddr);
    if (response1 != null) {
      esParameters_list = response1['dat']['parameter'];
    }

    var response = await fetchdevenrgyflows(
        PN: widget.PN!,
        SN: widget.SN,
        devcode: widget.devcode!,
        devadr: widget.devaddr);
    if (response != null) {
      DEF = response;

      setState(() {
        lastfetched_realtime = DateTime.now();
        fetcheddeviceflows = true;
      });
    }
  }

  @override
  void dispose() {
    focusNodeButton1.dispose();
    focusNodeButton2.dispose();
    focusNodeButton3.dispose();
    focusNodeButton4.dispose();

    if (realtimetimer != null) {
      realtimetimer!.cancel();
    }

    super.dispose();
  }

  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    if (mounted) {
      super.setState(fn);
    }
  }

  Future<void> _refreshData() async {
    await Future.delayed(Duration(milliseconds: 100));
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (BuildContext context) => deviceinfopage(
              PID: widget.PID,
              PN: widget.PN,
              SN: widget.SN,
              Plantname: widget.Plantname,
              status: widget.status,
              devcode: widget.devcode,
              devaddr: widget.devaddr,
              alias: widget.alias,
            )));
  }

  // Callback function to update page number
  void nextPage() {
    setState(() {
      currentpagenumber = currentpagenumber + 1;
    });
  }

  // Callback function to update page number
  void previousPage() {
    setState(() {
      currentpagenumber = currentpagenumber - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    print('Date selected:  ${date.text}');

    //////gradient
    color.add(Colors.orange[400]!);
    color.add(Colors.red[700]!);
    color.add(Colors.red);
    stops.add(0.0);
    stops.add(0.5);
    stops.add(1.0);

    gradientColors = LinearGradient(colors: color, stops: stops);

    //////////////////////////// change Name and Delete Button  Setup //////////////Start///////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    // set up delete  button
    Widget DelButton = ElevatedButton(
        child: Text(AppLocalizations.of(context)!.confirm_delete),
        onPressed: () async {
          var json = await DeletedeviceQuery(
            context,
            SN: widget.SN!,
            PN: widget.PN!,
            devcode: widget.devcode!.toString(),
            devaddr: widget.devaddr!.toString(),
          );
          if (json['err'] == 0 || json['err'] == 258) {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.device_delete,
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => Plant(
                          passedindex: 3,
                        )),
                (route) => false);
          } else {
            Fluttertoast.showToast(
                msg: "Error: ${json['desc']}",
                toastLength: Toast.LENGTH_SHORT,
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
          var json = await ModifyDeviceinfoQuery(context,
              SN: widget.SN!,
              PN: widget.PN!,
              devcode: widget.devcode!.toString(),
              devaddr: widget.devaddr!.toString(),
              alias: name.text.replaceAll(RegExp(r' '), ""));
          if (json['err'] == 0) {
            Fluttertoast.showToast(
                msg: AppLocalizations.of(context)!.alias_changed_sucessfully,
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.CENTER,
                backgroundColor: Colors.green,
                timeInSecForIosWeb: 2,
                textColor: Colors.white,
                fontSize: 15.0);
            Navigator.of(context, rootNavigator: true).pop();
            Navigator.of(context).pop();
            // setState(() {
            //   widget.alias = name.text.replaceAll(RegExp(r' '), "");
            // });
            // Navigator.pushAndRemoveUntil(
            //     context,
            //     MaterialPageRoute(
            //         builder: (context) => Plant(
            //               passedindex: 3,
            //             )),
            //     (route) => false);
          } else {
            Fluttertoast.showToast(
                msg: "Error: ${json['desc']}",
                toastLength: Toast.LENGTH_SHORT,
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

    // set up the AlertDialog
    AlertDialog Delete_alert = AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.are_you_sure,
        style: TextStyle(fontSize: 30),
      ),
      content: Text(
        AppLocalizations.of(context)!.this_will_delete_device_data,
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

    AlertDialog Changename_alert = AlertDialog(
      title: Text(
        AppLocalizations.of(context)!.enter_new_alias,
        style: TextStyle(fontSize: 20),
      ),
      content: TextField(
        textAlign: TextAlign.center,
        onSubmitted: (String value) {
          setState(() {
            if (value == "") {
              name.text = widget.alias!;
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
          hintText: widget.alias != null
              ? AppLocalizations.of(context)!
                  .current_name(widget.alias as Object)
              : null,
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

    //////////////////////////////////change Name and Delete Button  Setup //////////////End//////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////

    // print('daterange: ${daterange}');
    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              icon: Icon(
                Icons.arrow_back,
                color: Colors.white,
              )),
          actions: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Card(
                elevation: 5,
                child: Container(
                  decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(20)),
                  width: 0.30 * width,
                  child: OutlinedButton(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.download), // Add your desired icon here
                          SizedBox(
                              width:
                                  5), // Adjust the spacing between icon and text
                          Text(
                            AppLocalizations.of(context)!.download_report,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 0.025 * (height - width),
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      onPressed: () async {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => downloadreport(
                                  Pn: widget.PN!,
                                )));
                      }),
                ),
              ),
            ),
          ],
          backgroundColor: Theme.of(context).primaryColor,
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AppLocalizations.of(context)!.tabs_device,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 0.03 * (height - width),
                    color: Colors.white),
              ),
              // SizedBox(
              //   width: 8,
              // ),
              // Text(
              //   'Plant: ${widget.Plantname}'.toUpperCase(),
              //   style: TextStyle(
              //       fontWeight: FontWeight.w600,
              //       fontSize: 0.025 * (height - width)),
              // ),
            ],
          ),
          centerTitle: false,
          elevation: 0,
        ),
        body: Container(
          height: height,
          color: Colors.grey.shade200,
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Column(children: [
              // Container(
              //   height: height / 55,
              //   color: Colors.black,
              //   child: Center(
              //       child: Text(
              //     '${Titletext.text}',
              //     style: TextStyle(
              //         color: Colors.white,
              //         letterSpacing: 2,
              //         fontWeight: FontWeight.w600,
              //         fontSize: 0.022 * (height - width)),
              //   )),
              // ),
              Container(
                color: Colors.grey.shade600, //Theme.of(context).primaryColor,
                padding: EdgeInsets.all(4),
                width: width / 1,
                height: 50, //height / 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              elevation: 1,
                              shape: StadiumBorder(),
                              backgroundColor: Colors.black),
                          // child: Text(AppLocalizations.of(context)!.setting,
                          //   style: TextStyle(
                          //       color: Colors.white,
                          //       fontSize: 0.025 * (height - width)),
                          // ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.settings,
                                color: Colors.white,
                              ), // Add your desired icon here
                              SizedBox(
                                  width:
                                      5), // Adjust the spacing between icon and text
                            ],
                          ),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) => datacontrol(
                                    PN: widget.PN,
                                    SN: widget.SN,
                                    devaddr: widget.devaddr,
                                    devcode: widget.devcode)));
                          }),
                    ),

                    SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              elevation: 1,
                              shape: StadiumBorder(),
                              backgroundColor: Colors.black),
                          // child: Text(AppLocalizations.of(context)!.edit_alias,
                          //   style: TextStyle(
                          //       color: Colors.white,
                          //       fontSize: 0.025 * (height - width)),
                          // ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Icon(
                                Icons.edit,
                                color: Colors.white,
                              ), // Add your desired icon here
                              SizedBox(
                                  width:
                                      5), // Adjust the spacing between icon and text
                            ],
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Changename_alert;
                              },
                            );
                          }),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              elevation: 1,
                              shape: StadiumBorder(),
                              backgroundColor: Colors.black),
                          // child: Text(AppLocalizations.of(context)!.dialogue_btn_delete,
                          //   style: TextStyle(
                          //       color: Colors.red,
                          //       fontSize: 0.025 * (height - width)),
                          // ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Icon(
                                Icons.delete,
                                color: Colors.white,
                              ), // Add your desired icon here
                              SizedBox(
                                  width:
                                      5), // Adjust the spacing between icon and text
                            ],
                          ),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return Delete_alert;
                              },
                            );
                          }),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              elevation: 1,
                              shape: StadiumBorder(),
                              backgroundColor: Colors.black),
                          // child: Text(AppLocalizations.of(context)!.alarm_with_space,
                          //   style: TextStyle(
                          //       color: Colors.red,
                          //       fontSize: 0.025 * (height - width)),
                          // ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Icon(
                                Icons.alarm,
                                color: Colors.white,
                              ), // Add your desired icon here
                              SizedBox(
                                  width:
                                      5), // Adjust the spacing between icon and text
                            ],
                          ),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (BuildContext context) =>
                                  AlarmManagement(
                                      PID: widget.PID.toString(),
                                      Plantname: widget.Plantname,
                                      SN: widget.SN),
                            ));
                          }),
                    ),

                    // SizedBox(
                    //   width: 5,
                    // ),
                    // OutlinedButton(
                    //     style: OutlinedButton.styleFrom(
                    //         elevation: 1,
                    //         shape: StadiumBorder(),
                    //         backgroundColor: Colors.white38),
                    //     child: Text(
                    //       'Parameter Magnification Config',
                    //       style: TextStyle(
                    //           color: Colors.white, fontSize: 0.025 * width),
                    //     ),
                    //     onPressed: () {
                    //       Navigator.of(context).push(MaterialPageRoute(
                    //           builder: (BuildContext context) =>
                    //               parammagconfig(
                    //                   PN: widget.PN,
                    //                   SN: widget.SN,
                    //                   devaddr: widget.devaddr,
                    //                   devcode: widget.devcode)));
                    //     }),
                  ],
                ),
              ),
              Container(
                height: 27,
                color: Colors.grey.shade900,
                padding: EdgeInsets.all(5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Text(
                    //   'PN: ${widget.PN}',
                    //   style: TextStyle(
                    //       color: Colors.white,
                    //       fontWeight: FontWeight.w600,
                    //       fontSize: 0.025 * (height - width)),
                    // ),
                    // SizedBox(
                    //   width: 3,
                    // ),
                    widget.alias != null
                        ? Text(
                            AppLocalizations.of(context)!
                                .alias_with_val(widget.alias as Object),
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.normal,
                                letterSpacing: 1.5,
                                fontSize: 12),
                          )
                        : Text(''),
                    // SizedBox(
                    //   width: 3,
                    // ),
                    // Text(
                    //   'SN: ${widget.SN}',
                    //   style: TextStyle(
                    //       color: Colors.white,
                    //       fontWeight: FontWeight.w600,
                    //       fontSize: 0.025 * (height - width)),
                    // ),
                  ],
                ),
              ),
              Container(
                color: Colors.grey.shade800, //Theme.of(context).primaryColor,
                padding: EdgeInsets.all(8),
                //width: width / 1,
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: selectedoption == 'diagram'
                            ? Colors.grey.shade900
                            : Colors.grey.shade800,
                        borderRadius:
                            BorderRadius.circular(16.0), // Adjust as needed
                      ),
                      child: OutlinedButton(
                          child: Text(
                            AppLocalizations.of(context)!.diagram,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 0.033 * (height - width),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedoption = 'diagram';
                            });
                          }),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: selectedoption == 'realtimeflow'
                            ? Colors.grey.shade900
                            : Colors.grey.shade800,
                        borderRadius:
                            BorderRadius.circular(16.0), // Adjust as needed
                      ),
                      child: OutlinedButton(
                          child: Text(
                            AppLocalizations.of(context)!.realtime_status,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 0.033 * (height - width),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedoption = 'realtimeflow';
                              _refreshData(); //new
                            });
                          }),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: selectedoption == 'data'
                            ? Colors.grey.shade900
                            : Colors.grey.shade800,
                        borderRadius:
                            BorderRadius.circular(16.0), // Adjust as needed
                      ),
                      child: OutlinedButton(
                          child: Text(
                            AppLocalizations.of(context)!.data,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 0.033 * (height - width),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              selectedoption = 'data';
                              date.text = DateTime.now().year.toString() +
                                  '-' +
                                  DateTime.now()
                                      .month
                                      .toString()
                                      .padLeft(2, '0') +
                                  '-' +
                                  DateTime.now().day.toString().padLeft(2, '0');
                            });
                          }),
                    ),
                  ],
                ),
              ),
              selectedoption == 'diagram' || selectedoption == 'realtimeflow'
                  ? Container()
                  : Card(
                      elevation: 2,
                      child: Container(
                          height: 35,
                          color: Colors.blueGrey,
                          //padding: EdgeInsets.all(5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _toggle_for_data(width, height),
                            ],
                          )),
                    ),
              selectedoption == 'diagram'
                  ? iskeychartdataloaded
                      ? Diagramwidget(
                          dropdown: customdropdown(width, height),
                          height: height,
                          width: width,
                          toggle: _toggle(width, height),
                          toggledown: _toggledown(width, height),
                          chart: _chart(width, height),
                          DeviceEenergyQ: DEQ,
                          chartData: _chartData,
                        )
                      : Center(
                          child: Padding(
                          padding: const EdgeInsets.only(top: 100),
                          child: Center(
                              child: Column(
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 4,
                              ),
                              SizedBox(
                                height: 15,
                              ),
                              Text(AppLocalizations.of(context)!.fetching_data,
                                  style: TextStyle(
                                      fontSize: 0.05 * (height - width),
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue.shade500))
                            ],
                          )),
                        ))
                  : selectedoption == 'data'
                      ? DataWidget(
                          height: height,
                          width: width,
                          DeviceDataoneday: DeviceDataoneday,
                          current_pagenumber: currentpagenumber,
                          loading_data: Loading_Data,
                          onNextPage: nextPage,
                          onPreviousPage: previousPage,
                        )
                      : selectedoption == 'realtimeflow' &&
                              Device_Dataoneday_loaded == true &&
                              fetcheddeviceflows == true

                          ///TODO remove ss realtimelogic fixed
                          ? realtimeflow(
                              width: width,
                              height: height,
                              lastfetched: lastfetched_realtime,
                              esparam_list: esParameters_list,
                              DEF: DEF,
                              DeviceDataoneday: DeviceDataoneday,
                              Device_dataoneday_Loaded:
                                  Device_Dataoneday_loaded,
                              plant_status: widget.status,
                              PID: widget.PID,
                              Plantname: widget.Plantname,
                              PN: widget.PN,
                              SN: widget.SN,
                              devaddr: widget.devaddr,
                              devcode: widget.devcode,
                            )
                          : widget.status == 1
                              ? Center(
                                  child: Padding(
                                  padding: EdgeInsets.only(top: 0.2 * height),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.wifi_off_outlined,
                                        size: 0.3 * width,
                                        color: Colors.grey.shade400,
                                      ),
                                      Text(
                                          AppLocalizations.of(context)!
                                              .device_offline,
                                          style: TextStyle(
                                              fontSize: 0.06 * (height - width),
                                              fontWeight: FontWeight.w800,
                                              color: Colors.red.shade500)),
                                    ],
                                  ),
                                ))
                              : Center(
                                  child: Padding(
                                  padding: const EdgeInsets.only(top: 100),
                                  child: Center(
                                      child: Column(
                                    children: [
                                      CircularProgressIndicator(
                                        strokeWidth: 4,
                                      ),
                                      SizedBox(
                                        height: 15,
                                      ),
                                      Text(
                                          AppLocalizations.of(context)!
                                              .fetching_data,
                                          style: TextStyle(
                                              fontSize: 0.05 * (height - width),
                                              fontWeight: FontWeight.w500,
                                              color: Colors.blue.shade500))
                                    ],
                                  )),
                                )),
            ]),
          ),
        ));
  }

  Future fetchdevchartfield() async {
    iskeychartdataloaded = false;
    setState(() {});
    // formatted current datetime // YYYY-MM-DD
    //String date = DateFormat('y-M-d').format(DateTime.now());
    //print(keyparam_date);

    var Jsonresponse = await fetchChartFieldDetailData(
      // format yyyy-mm-dd
      Date: keyparam_date,
      field: _selectedalltypes,
      PN: widget.PN!,
      SN: widget.SN!,
      devadr: widget.devaddr!.toString(),
      devcode: widget.devcode!,
    );

    if (Jsonresponse['dat'] != null) {
      Showsnackbar(AppLocalizations.of(context)!.data_updated_successfully, 500,
          Colors.green);
      setState(() {
        _chartData.clear();
        // _chartData = <Chartinfo>[];

        for (int i = 0; i < Jsonresponse['dat'].length; i++) {
          //try

          if (Jsonresponse['dat'][i]['val'] == "-") continue;

          _chartData.add(Chartinfo(
              DateTime.parse(Jsonresponse['dat'][i]['key']),
              double.parse(Jsonresponse['dat'][i]['val']).toStringAsFixed(1)));
          print("ss");
        }

        iskeychartdataloaded = true;
      });
    } else if (Jsonresponse['err'] == 12) {
      Showsnackbar(
          AppLocalizations.of(context)!.no_record_found, 1000, Colors.black);
      setState(() {
        iskeychartdataloaded = true;
        _chartData.clear();
      });
    } else if (Jsonresponse == null) {
      Showsnackbar(
          AppLocalizations.of(context)!.no_record_found, 1000, Colors.black);
      setState(() {
        _chartData.clear();
      });
    }
  }

  ///devinfo class end
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

////////******************************************/////////

class DataWidget extends StatefulWidget {
  DataWidget({
    Key? key,
    required this.height,
    required this.width,
    required this.DeviceDataoneday,
    required this.current_pagenumber,
    required this.loading_data,
    required this.onPreviousPage,
    required this.onNextPage,
  }) : super(key: key);

  double height;
  double width;
  int current_pagenumber;
  bool loading_data;
  final Function onPreviousPage;
  final Function onNextPage;

  DDOD.DeviceDataOneDayQuery? DeviceDataoneday;

  @override
  _DataWidgetState createState() => _DataWidgetState();
}

class _DataWidgetState extends State<DataWidget> {
  int? totalrowsnumber = 0;
  int? totalnumerofdata = 0;

  _deviceinfopageState dd = new _deviceinfopageState();

  @override
  void initState() {
    // TODO: implement initState

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    totalrowsnumber = widget.DeviceDataoneday?.dat?.row?.length;
    totalnumerofdata = widget.DeviceDataoneday?.dat?.total;
    print(height);

    // print('Rows Length : ${widget.DeviceDataoneday?.dat?.row?.length}');
    // print('current page number : ${widget.current_pagenumber}');
    // print('total rows number : ${totalrowsnumber}');

    return Container(
      // height: widget.height / 1.42,
      // height: height < 800
      //     ? height / 1.41
      //     : height < 1000
      //         ? height / 1.42
      //         : height,
      height: height,
      color: Colors.black26,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            elevation: 2,
            child: Container(
                height: 40, // widget.height / 25,
                color: Colors.white54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                        width: widget.width / 3,
                        padding: EdgeInsets.all(5),
                        child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                widget.current_pagenumber >= 2
                                    ? widget.onPreviousPage()
                                    : widget.current_pagenumber;
                              });
                            },
                            child:
                                Text(AppLocalizations.of(context)!.previous))),
                    Container(
                        padding: EdgeInsets.all(5),
                        child: Row(
                          children: [
                            Text(
                              '${widget.current_pagenumber} of ${widget.DeviceDataoneday?.dat?.row?.length ?? 0}',
                              style: TextStyle(
                                fontWeight: FontWeight.w300,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        )),
                    Container(
                        width: widget.width / 3,
                        padding: EdgeInsets.all(5),
                        child: OutlinedButton(
                            onPressed: () {
                              if (widget.current_pagenumber <
                                  totalrowsnumber!.toDouble()) {
                                widget.onNextPage();
                                // setState(() {
                                //     widget.current_pagenumber =  widget.current_pagenumber + 1;
                                //     print(widget.current_pagenumber);
                                // });
                              }
                            },
                            child: Text(AppLocalizations.of(context)!.next))),
                  ],
                )),
          ),
          widget.loading_data
              ? Container(
                  padding: EdgeInsets.only(top: 15),
                  color: Colors.white,
                  width: widget.width,
                  height: widget.height / 1.53,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Center(
                        child: CircularProgressIndicator(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          AppLocalizations.of(context)!.requesting_data,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: width * 0.05,
                              fontWeight: FontWeight.w300),
                        ),
                      )
                    ],
                  ),
                )
              : widget.DeviceDataoneday?.err == 0
                  ? Expanded(
                      child: Container(
                        padding: EdgeInsets.only(top: 0),
                        color: Colors.white,
                        width: widget.width,
                        // height: widget.height / 1.53,
                        child: ListView.builder(
                            padding: EdgeInsets.only(bottom: 0.5 * height),
                            itemCount:
                                widget.DeviceDataoneday?.dat?.title!.length,
                            itemBuilder: (BuildContext, int index) {
                              return Column(
                                children: [
                                  Card(
                                    elevation: 2,
                                    child: Container(
                                      color: Colors.grey.shade800,
                                      height: widget.height / 20,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          index == 0
                                              ? Divider()
                                              : Container(
                                                  padding: EdgeInsets.only(
                                                      left: 5, top: 12),
                                                  width: 0.35 * width,
                                                  height: widget.height / 1.58,
                                                  color:
                                                      Colors.blueGrey.shade100,
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Container(
                                                        height:
                                                            30, //0.08 * height,
                                                        width: 0.32 * width,
                                                        // color: Colors.green,
                                                        child: widget
                                                                    .DeviceDataoneday
                                                                    ?.dat
                                                                    ?.title?[
                                                                        index]
                                                                    .title ==
                                                                'Battery Voltage'
                                                            ? Text(
                                                                '${widget.DeviceDataoneday?.dat?.title?[index].title}'
                                                                    .toUpperCase(), //AppLocalizations.of(context)!.current_batt_voltage,
                                                                maxLines: 2,
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade800,
                                                                    fontSize: 0.024 *
                                                                        (height -
                                                                            width),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w800))
                                                            : Text(
                                                                '${widget.DeviceDataoneday?.dat?.title?[index].title}'
                                                                    .toUpperCase(),
                                                                maxLines: 2,
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .grey
                                                                        .shade800,
                                                                    fontSize: 0.024 *
                                                                        (height -
                                                                            width),
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w800)),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                          index == 0
                                              ? Text('')
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Container(
                                                      height:
                                                          40, // 0.08 * height,
                                                      // width: 0.46 * width,
                                                      // color: Colors.amber.shade200,
                                                      padding: EdgeInsets.only(
                                                          top: 14,
                                                          left: 5,
                                                          right: 10,
                                                          bottom: 2),
                                                      child: widget
                                                                  .DeviceDataoneday
                                                                  ?.dat
                                                                  ?.title?[
                                                                      index]
                                                                  .title ==
                                                              'Machine model'
                                                          ? Text('ELEGO 6 IP65',
                                                              maxLines: 2,
                                                              textAlign:
                                                                  TextAlign.end,
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 0.024 *
                                                                      (height -
                                                                          width),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400))
                                                          : Text('${widget.DeviceDataoneday?.dat?.row?[widget.current_pagenumber - 1].field?[index]}',
                                                              maxLines: 2,
                                                              textAlign:
                                                                  TextAlign.end,
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 0.024 * (height - width),
                                                                  fontWeight: FontWeight.w400)),
                                                    ),
                                                    widget
                                                                .DeviceDataoneday
                                                                ?.dat
                                                                ?.title?[index]
                                                                .unit ==
                                                            null
                                                        ? Text('')
                                                        : Container(
                                                            padding:
                                                                EdgeInsets.all(
                                                                    14),
                                                            height:
                                                                40, // 0.05 * height,
                                                            width: 0.15 * width,
                                                            // color: Colors.amber.shade100,
                                                            child: Text(
                                                              ' ${widget.DeviceDataoneday?.dat?.title?[index].unit}'
                                                                  .toUpperCase(),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .lightGreenAccent
                                                                      .shade400,
                                                                  fontSize:
                                                                      9, //0.021 *(height - width),
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .normal),
                                                            )),
                                                  ],
                                                )
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 1,
                                  )
                                ],
                              );
                            }),
                      ),
                    )
                  : Container(
                      padding: EdgeInsets.only(top: 250),
                      child: Center(
                          child: Text(AppLocalizations.of(context)!.msg_no_data,
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 50,
                                  fontWeight: FontWeight.w100))),
                    ),
        ],
      ),
    );
  }
}

class Diagramwidget extends StatelessWidget {
  Diagramwidget(
      {Key? key,
      required this.height,
      required this.width,
      required this.toggle,
      required this.toggledown,
      required this.chart,
      required this.DeviceEenergyQ,
      required this.chartData,
      required this.dropdown})
      : super(key: key);

  final double height;
  final double width;
  final Widget toggle;
  final Widget toggledown;
  final Widget chart;
  final Widget dropdown;
  final DDOD.DeviceenergyQuint? DeviceEenergyQ;
  var chartData;

  @override
  Widget build(BuildContext context) {
    return Container(
      //height: height < 800 ? height / 1.32 : height / 1.35,
      height: height,
      color: Colors.black38,
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: height / 40,
            ),
            Card(
              color: Colors.white70,
              elevation: 2,
              child: Container(
                height: height / 20,
                padding: EdgeInsets.all(5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppLocalizations.of(context)!.current_power,
                              style: TextStyle(
                                fontSize: 0.025 * (height - width),
                                fontWeight: FontWeight.w800,
                                color: Colors.black54,
                              )),
                          SizedBox(
                            height: 4,
                          ),
                          Text(
                              '${DeviceEenergyQ?.outputpower!.substring(0, DeviceEenergyQ!.outputpower!.indexOf('.') + 3) ?? '0'} kW',
                              style: TextStyle(
                                  fontSize: 0.022 * (height - width),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue)),
                        ]),
                    Card(
                      child: Icon(
                        Icons.flash_on,
                        size: 0.03 * height,
                        color: Colors.amber,
                      ),
                    ),
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(AppLocalizations.of(context)!.power_today,
                              style: TextStyle(
                                fontSize: 0.025 * (height - width),
                                fontWeight: FontWeight.w800,
                                color: Colors.black54,
                              )),
                          SizedBox(
                            height: 2,
                          ),
                          Text(
                              "${DeviceEenergyQ?.energytoday!.substring(0, DeviceEenergyQ!.energytoday!.indexOf('.') + 3) ?? '0'} kWh",
                              style: TextStyle(
                                  fontSize: 0.022 * (height - width),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue)),
                        ]),
                  ],
                ),
              ),
            ),
            Card(
              color: Colors.white70,
              elevation: 2,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(children: [
                      Text(AppLocalizations.of(context)!.year_power,
                          style: TextStyle(
                            fontSize: 0.026 * (height - width),
                            fontWeight: FontWeight.w800,
                            color: Colors.black54,
                          )),
                      SizedBox(
                        height: 2,
                      ),
                      //'${widget.totalenergy_all.substring(0, widget.totalenergy_all.indexOf('.') + 3)} kWh',
                      Text(
                          '${DeviceEenergyQ?.energyyear!.substring(0, DeviceEenergyQ!.energyyear!.indexOf('.') + 3) ?? '---'} kWh',
                          style: TextStyle(
                              fontSize: 0.022 * (height - width),
                              fontWeight: FontWeight.w500,
                              color: Colors.blue)),
                    ]),
                    Column(children: [
                      Text(AppLocalizations.of(context)!.month_power,
                          style: TextStyle(
                            fontSize: 0.026 * (height - width),
                            fontWeight: FontWeight.w800,
                            color: Colors.black54,
                          )),
                      SizedBox(
                        height: 2,
                      ),
                      Text(
                          '${DeviceEenergyQ?.energymonth!.substring(0, DeviceEenergyQ!.energymonth!.indexOf('.') + 3) ?? '---'} kWh',
                          style: TextStyle(
                              fontSize: 0.022 * (height - width),
                              fontWeight: FontWeight.w500,
                              color: Colors.blue)),
                    ]),
                    Column(children: [
                      Text(AppLocalizations.of(context)!.total_power,
                          style: TextStyle(
                            fontSize: 0.026 * (height - width),
                            fontWeight: FontWeight.w800,
                            color: Colors.black54,
                          )),
                      SizedBox(
                        height: 2,
                      ),
                      Text(
                          '${DeviceEenergyQ?.energytotal!.substring(0, DeviceEenergyQ!.energytotal!.indexOf('.') + 3) ?? '---'} kWh',
                          style: TextStyle(
                              fontSize: 0.022 * (height - width),
                              fontWeight: FontWeight.w500,
                              color: Colors.blue)),
                    ]),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: height / 150,
            ),

            ///chart
            Card(
              color: Colors.grey.shade800,
              child: Container(
                width: width,
                height: height / 2,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      dropdown,
                      SizedBox(
                        height: 10,
                      ),
                      // toggle,
                      toggledown,
                      Center(
                        child: Container(
                          width: width / 0.9,
                          height: height / 3,
                          child: chartData.length != 0
                              ? chart
                              : Container(
                                  padding: EdgeInsets.only(top: 0),
                                  child: Center(
                                      child: Text(
                                          AppLocalizations.of(context)!
                                              .msg_no_data,
                                          style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 50,
                                              fontWeight: FontWeight.w100))),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: height / 80,
            ),
            Card(
              color: Colors.grey.shade800,
              child: Container(
                width: width,
                height: height / 20,
                child: Center(
                  child:
                      Text(AppLocalizations.of(context)!.device_param_analysis,
                          style: TextStyle(
                            fontSize: 0.04 * (height - width),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          )),
                ),
              ),
            ),
            SizedBox(
              height: 0.5 * height,
            ),
          ],
        ),
      ),
    );
  }
}

class realtimeflow extends StatefulWidget {
  DDOD.DeviceDataOneDayQuery? DeviceDataoneday;
  bool Device_dataoneday_Loaded;
  //plantinfo for refresh
  int? plant_status;
  int? PID;
  String? Plantname;
  String? PN;
  String? SN;
  int? devcode;
  int? devaddr;
  String? alias;
  deviceenergyflows? DEF;
  List? esparam_list;
  DateTime? lastfetched;
  dynamic width, height;

  realtimeflow({
    Key? key,
    this.width,
    this.height,
    this.lastfetched,
    this.esparam_list,
    this.DEF,
    this.DeviceDataoneday,
    required this.Device_dataoneday_Loaded,
    this.plant_status,
    this.alias,
    this.devaddr,
    this.devcode,
    this.PID,
    this.Plantname,
    this.PN,
    this.SN,
  }) : super(key: key);

  @override
  State<realtimeflow> createState() => _realtimeflowState();
}

List<DDOD.Title>? LT;
//image
Image Realtime_img = Image.asset('assets/ALL.gif', fit: BoxFit.fill);
//indexes
int? indexof_BT_capacity;
int? indexof_BT_charging_status;
int? indexof_BT_current_btvoltage;

int? indexof_Loadstatus;
int? indexof_Load_voltage;
int? indexof_Load_power;
int? indexof_Load_percent;
int? indexof_Grid_voltage;
int? indexof_Grid_frequency;
int? indexof_Solar_pv1;
int? indexof_Solar_pv2;
int? indexof_Solar_pv1power;
int? indexof_Solar_pv2power;
int? indexof_Solar_PVpower;
int? indexof_Model;
//varaibles
String? _Model;
double? _Grid_voltage;
double? _gridfrequency;
double? _Solar_pv1;
double? _Solar_pv2;
double? _Solar_PVpower, pv1power, pv2power;
String? _BT_charging_status;
double? _Load_power;
double? _batteryvoltage, _loadvoltage;

deviceinfopage dd = new deviceinfopage();

class _realtimeflowState extends State<realtimeflow> {
  int? totalrowsnumber;
  String? InverterModel;

  @override
  void setState(VoidCallback fn) {
    // TODO: implement setState
    if (mounted) {
      super.setState(fn);
    }
  }

//new logic
  checkStatus() {
    //status
    Lstatus = widget.DEF!.dat!.bcStatus![0].status;
    Gstatus = widget.DEF!.dat!.gdStatus![0].status;
    BCstatus = widget.DEF!.dat!.btStatus![0].status;
    BPstatus = widget.DEF!.dat!.btStatus![1].status;

    for (var item in widget.DEF!.dat!.pvStatus!) {
      if (item.status! > 0) {
        PVstatus = 1;
      } else {
        PVstatus = 0;
      }
    }

    //value unit
    Lvalue = double.parse(widget.DEF!.dat!.bcStatus![0].val!);
    Lunit = widget.DEF!.dat!.bcStatus![0].unit;

    Gvalue = double.parse(widget.DEF!.dat!.gdStatus![0].val!);
    Gunit = widget.DEF!.dat!.gdStatus![0].unit;

    PVvalue = double.parse(widget.DEF!.dat!.pvStatus![0].val!);

    BCvalue = double.parse(widget.DEF!.dat!.btStatus![0].val!);
    Bcunit = widget.DEF!.dat!.btStatus![0].unit;

    //load
    Lstatus == 0
        ? loadflowimage = null
        : Lstatus! < 0
            ? loadflowimage = rightflow
            : loadflowimage = leftflow;
    //PV
    PVstatus == 0 ? pvflowimage = null : pvflowimage = rightflow;
    //battery
    BCstatus == -1
        ? batteryflowimage = downflow
        : BCstatus! == 1
            ? batteryflowimage = upflow
            : batteryflowimage = null;
    //grid
    Gstatus == 0
        ? gridflowimage = null
        : Gstatus! < 0
            ? gridflowimage = leftflow
            : gridflowimage = rightflow;
  }

  /////------energyflow variables--------///////

  ///Images
  Image rightflow = Image.asset('assets/rightflow.gif',
      width: 90, height: 30, fit: BoxFit.fill);
  Image leftflow = Image.asset('assets/leftflow.gif',
      width: 90, height: 30, fit: BoxFit.fill);
  Image upflow = Image.asset('assets/upflow.gif', width: 30, fit: BoxFit.fill);
  Image downflow =
      Image.asset('assets/downflow.gif', width: 30, fit: BoxFit.fill);

  //Images widget and variables
  Image? batteryflowimage, loadflowimage, pvflowimage, gridflowimage;
  Widget? batteryflow() => batteryflowimage ?? null;
  Widget? loadflow() => loadflowimage ?? null;
  Widget? pvflow() => pvflowimage ?? null;
  Widget? gridflow() => gridflowimage ?? null;

  ///Load active Power
  int? Lstatus;
  String? Lunit;
  double? Lvalue;

  ///Grid active power
  int? Gstatus;
  String? Gunit;
  double? Gvalue;

  /// Battery capacity
  int? BCstatus;
  String? Bcunit;
  double? BCvalue;

  /// Battery active power
  int? BPstatus;
  double? BPvalue;

  //PV output power
  int? PVstatus;
  double? PVvalue;
  ////////------energyflow variables--------///////

  @override
  void initState() {
    // TODO: implement initState

    ///////------------------------NEW logic------------------/////////////
    /// to get model if available
    if (widget.DeviceDataoneday!.dat != null) {
      LT = widget.DeviceDataoneday!.dat!.title;
      indexof_Model = LT!.indexWhere((element) => element.title == 'Model');
      if (indexof_Model! > 1) {
        _Model = widget.DeviceDataoneday!.dat!.row![0].field![indexof_Model!];
      }
      //to get grid voltage and frequency if available
      indexof_Grid_voltage = LT!.indexWhere((element) =>
          element.title == 'Grid Voltage' || element.title == 'Grid voltage');
      if (indexof_Grid_voltage! > 1) {
        _Grid_voltage = double.parse(widget
            .DeviceDataoneday!.dat!.row![0].field![indexof_Grid_voltage!]);
      }
      indexof_Grid_frequency = LT!.indexWhere((element) =>
          element.title == 'Grid Frequency' ||
          element.title == 'Grid frequency');
      if (indexof_Grid_frequency! > 1) {
        _gridfrequency = double.parse(widget
            .DeviceDataoneday!.dat!.row![0].field![indexof_Grid_frequency!]);
      }
      //load
      indexof_Load_voltage = LT!.indexWhere((element) =>
          element.title == 'AC Output Voltage' ||
          element.title == 'AC output voltage');
      if (indexof_Load_voltage! > 1) {
        _loadvoltage = double.parse(widget
            .DeviceDataoneday!.dat!.row![0].field![indexof_Load_voltage!]);
      }
      //battery
      indexof_BT_current_btvoltage =
          LT!.indexWhere((element) => element.title == 'Battery Voltage');
      if (indexof_BT_current_btvoltage! > 1) {
        _batteryvoltage = double.parse(widget.DeviceDataoneday!.dat!.row![0]
            .field![indexof_BT_current_btvoltage!]);
      }
      //pv param
      indexof_Solar_pv1 = LT!.indexWhere((element) =>
          element.title == 'PV1 Input Voltage' ||
          element.title == 'PV1 Input voltage');
      if (indexof_Solar_pv1! > 1) {
        _Solar_pv1 = double.parse(
            widget.DeviceDataoneday!.dat!.row![0].field![indexof_Solar_pv1!]);
      }
      indexof_Solar_pv2 = LT!.indexWhere((element) =>
          element.title == 'PV2 Input voltage' ||
          element.title == 'PV2 Input Voltage');
      if (indexof_Solar_pv2! > 1) {
        _Solar_pv2 = double.parse(
            widget.DeviceDataoneday!.dat!.row![0].field![indexof_Solar_pv2!]);
      }
      indexof_Solar_PVpower =
          LT!.indexWhere((element) => element.title == 'PV Charging Power');
      if (indexof_Solar_PVpower! > 1) {
        _Solar_PVpower = double.parse(widget
            .DeviceDataoneday!.dat!.row![0].field![indexof_Solar_PVpower!]);
      }

      indexof_Solar_pv1power = LT!.indexWhere((element) =>
          element.title == 'PV1 Charging Power' ||
          element.title == 'PV1 Input Power');
      if (indexof_Solar_pv1power! > 1) {
        pv1power = double.parse(widget
            .DeviceDataoneday!.dat!.row![0].field![indexof_Solar_pv1power!]);
      }
      indexof_Solar_pv2power = LT!.indexWhere((element) =>
          element.title == 'PV2 Charging power' ||
          element.title == 'PV2 Input power');
      if (indexof_Solar_pv2power! > 1) {
        pv2power = double.parse(widget
            .DeviceDataoneday!.dat!.row![0].field![indexof_Solar_pv2power!]);
      }
    }

    //////////////
    checkStatus();
    //////////----------------------------------------------///////////////

    super.initState();
  }

  Future<void> _refreshData() async {
    await Future.delayed(Duration(milliseconds: 100));
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (BuildContext context) => deviceinfopage(
              PID: widget.PID,
              PN: widget.PN,
              SN: widget.SN,
              Plantname: widget.Plantname,
              status: widget.plant_status,
              devcode: widget.devcode,
              devaddr: widget.devaddr,
              alias: widget.alias,
            )));
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    //print('width = ${width}');

    return Container(
      //height: height / 1.35,
      // height: height < 800 ? height / 1.32 : height / 1.35,
      padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight + 80),
      height: height,
      width: width,
      color: Colors.white,
      child: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: height * 0.005),
              Column(
                children: [
                  Container(
                    width: 0.95 * width,
                    height: 0.04 * height,
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade400,
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: Offset(2, 2),
                          )
                        ],
                        borderRadius: BorderRadius.circular(2)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            child: Text(
                              'Last updated: ${DateFormat('h:mm a').format(widget.lastfetched!)}'
                                  .toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 0.03 * (height - width),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                        ]),
                  ),
                  SizedBox(height: height * 0.005),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade400,
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: Offset(2, 2),
                            )
                          ],
                          borderRadius: BorderRadius.circular(20)),
                      child: Center(
                        child: Container(
                          width: 350,
                          height: 210,
                          padding: const EdgeInsets.all(15),
                          child: widget.plant_status ==
                                  1 ///////if plant_status offline
                              ? Center(
                                  child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.wifi_off_outlined,
                                      size: 0.3 * width,
                                      color: Colors.grey.shade400,
                                    ),
                                    Text(
                                        AppLocalizations.of(context)!
                                            .device_offline,
                                        style: TextStyle(
                                            fontSize: 0.1 * width,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.red.shade500)),
                                  ],
                                ))
                              // ? ClipRRect(
                              //     // borderRadius: BorderRadius.circular(8.0),
                              //     child: Image.asset('assets/offline.gif',
                              //         fit: BoxFit.fill),
                              //   )
                              : Stack(
                                  alignment: AlignmentDirectional.center,
                                  children: [
                                      // flows
                                      Positioned(
                                          top: 28,
                                          left: 44,
                                          child: gridflow() ?? Container()),
                                      Positioned(
                                          top: 72,
                                          left: 44,
                                          child: pvflow() ?? Container()),
                                      Positioned(
                                          top: 60,
                                          right: 42,
                                          child: loadflow() ?? Container()),
                                      Positioned(
                                          bottom: 48,
                                          right: 140,
                                          child: batteryflow() ?? Container())

                                      //  ,Positioned(bottom: 50,right:165,
                                      //   child: Image.asset('assets/upflow.gif',width: 25, fit: BoxFit.fill)),
                                      //text
                                      ,
                                      Gstatus == 0 ||
                                              _Grid_voltage == null ||
                                              _gridfrequency == null
                                          ? Container()
                                          : Positioned(
                                              top: 3,
                                              left: 65,
                                              child: Column(
                                                children: [
                                                  Text(
                                                      _Grid_voltage!
                                                              .toStringAsFixed(
                                                                  1) +
                                                          " V",
                                                      style: TextStyle(
                                                          fontSize: 0.022 *
                                                              (height - width),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black)),
                                                  SizedBox(
                                                    height: 1,
                                                  ),
                                                  Text(
                                                      _gridfrequency!
                                                              .round()
                                                              .toString() +
                                                          " Hz",
                                                      style: TextStyle(
                                                          fontSize: 0.022 *
                                                              (height - width),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black)),
                                                ],
                                              )),
                                      //pv text
                                      PVstatus! <= 0
                                          ? Container()
                                          : _Solar_PVpower != null
                                              ? PVpositionedwidget(
                                                  PVvalue: _Solar_PVpower,
                                                  height: height,
                                                  width: width,
                                                  bottom: 58,
                                                  left: 72,
                                                )
                                              : pv1power != null &&
                                                      pv2power != null
                                                  ? PVpositionedwidget(
                                                      PVvalue:
                                                          pv1power! + pv2power!,
                                                      height: height,
                                                      width: width,
                                                      bottom: 58,
                                                      left: 72,
                                                    )
                                                  : pv1power != null &&
                                                          pv2power == null
                                                      ? PVpositionedwidget(
                                                          PVvalue: pv1power!,
                                                          height: height,
                                                          width: width,
                                                          bottom: 58,
                                                          left: 72,
                                                        )
                                                      : Container(),

                                      PVstatus! <= 0
                                          ? Container()
                                          : _Solar_pv1 != null &&
                                                  _Solar_pv2 != null
                                              ? Positioned(
                                                  bottom: 70,
                                                  left: 65,
                                                  child: Text(
                                                      // max(_Solar_pv1!, _Solar_pv2!)
                                                      (_Solar_pv1! + _Solar_pv2!)
                                                              .round()
                                                              .toString() +
                                                          " V",
                                                      style: TextStyle(
                                                          fontSize: 0.022 *
                                                              (height - width),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black)))
                                              : _Solar_pv1 != null &&
                                                      _Solar_pv2 == null
                                                  ? Positioned(
                                                      bottom: 70,
                                                      left: 65,
                                                      child: Text(
                                                          _Solar_pv1!
                                                                  .round()
                                                                  .toString() +
                                                              " V",
                                                          style: TextStyle(
                                                              fontSize: 0.022 *
                                                                  (height -
                                                                      width),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .black)))
                                                  : Container(),

                                      Lstatus == 0 || Lvalue == null
                                          ? Container()
                                          : Positioned(
                                              top: 35,
                                              right: 55,
                                              child: Column(
                                                children: [
                                                  Lunit == 'W'
                                                      ? Text(Lvalue!.toStringAsFixed(0) + " W",
                                                          style: TextStyle(
                                                              fontSize: 0.022 *
                                                                  (height -
                                                                      width),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.black))
                                                      : Text(
                                                          Lvalue! < 1
                                                              ? (Lvalue! * 1000)
                                                                      .round()
                                                                      .toString() +
                                                                  " W"
                                                              : Lvalue!.toStringAsFixed(1) +
                                                                  " kW",
                                                          style: TextStyle(
                                                              fontSize: 0.022 *
                                                                  (height -
                                                                      width),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .black)),
                                                  SizedBox(
                                                    height: 1,
                                                  ),
                                                  _loadvoltage ==
                                                              null ||
                                                          Lstatus == 0
                                                      ? Container()
                                                      : Text(
                                                          _loadvoltage!
                                                                  .round()
                                                                  .toString() +
                                                              " V",
                                                          style: TextStyle(
                                                              fontSize: 0.022 *
                                                                  (height -
                                                                      width),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.black))
                                                ],
                                              )),
                                      // BCstatus! >= 0
                                      //     ? Container()
                                      //     : Positioned(
                                      //         bottom: 0.035 * height,
                                      //         right: 0.25 * width,
                                      //         child: Text("Charging",
                                      //             style: TextStyle(
                                      //                 fontSize: 10,
                                      //                 fontWeight: FontWeight.bold,
                                      //                 color: Colors.green)))
                                      //foreground
                                      //,
                                      ClipRRect(
                                        // borderRadius: BorderRadius.circular(8.0),
                                        child: Image.asset(
                                            'assets/forgroundrealtimeflow.png',
                                            // width: 0.8 * width,
                                            //height: 180,
                                            //width: 0.8 * width, //300
                                            fit: BoxFit.fill),
                                        //  Image.asset('assets/BM_G_P_Charging.gif',
                                        //     fit: BoxFit.fill)
                                        // Realtime_img
                                      )
                                    ]),
                        ),
                      ),
                    ),
                  ),
                  _Model == null
                      ? Container()
                      : Container(
                          width: 0.95 * width,
                          height: 25,
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                              color: Colors.blue,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade400,
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: Offset(2, 2),
                                )
                              ],
                              borderRadius: BorderRadius.circular(2)),
                          child: Container(
                            child: Text(
                              '${_Model}'.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                  color: Colors.white),
                            ),
                          ),
                        )
                ],
              ),
              SizedBox(height: 5),
              SizedBox(height: height * 0.004),
              Container(
                width: 0.95 * width,
                height: 180,
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade400,
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: Offset(1, 1),
                      )
                    ],
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.battery_capacity,
                        style: TextStyle(
                            fontSize: 0.03 * (height - width),
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      Divider(),
                      // SizedBox(
                      //   height: 5,
                      // ),

                      Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: new CircularPercentIndicator(
                          radius: 32,
                          lineWidth: 8.0,
                          animation: true,
                          percent: BCvalue! / 100,
                          center: new Text(
                            BCvalue.toString() + '%',
                            style: new TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 10),
                          ),
                          circularStrokeCap: CircularStrokeCap.round,
                          progressColor: Colors.lightGreenAccent.shade700,
                        ),
                      ),
                      SizedBox(
                        height: 5,
                      ),

                      //  SizedBox(height: height * 0.001),

                      _batteryvoltage == null
                          ? Container()
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.battery_voltage,
                                  style: TextStyle(
                                      fontSize: 0.025 * (height - width),
                                      fontWeight: FontWeight.w800,
                                      color: Colors.grey.shade500),
                                ),
                                Text(
                                  _batteryvoltage.toString() + ' V',
                                  style: TextStyle(
                                      fontSize: 0.03 * (height - width),
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue),
                                ),
                              ],
                            ),
                      Spacer(),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.charging_status,
                            style: TextStyle(
                                fontSize: 0.025 * (height - width),
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade900),
                          ),
                          SizedBox(height: height * 0.002),
                          Text(
                            BCstatus! >= 0 ? "Not Charging" : "Charging",
                            style: TextStyle(
                                fontSize: 0.03 * (height - width),
                                fontWeight: FontWeight.bold,
                                color: Colors.blue),
                          ),
                        ],
                      ),
                      Spacer(),
                    ]),
              ),
              SizedBox(
                height: 5,
              ),
              ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: EdgeInsets.all(8),
                itemCount: widget.esparam_list!.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: 0.95 * width,
                    height: 80,
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade400,
                            blurRadius: 10,
                            spreadRadius: 1,
                            offset: Offset(1, 1),
                          )
                        ],
                        borderRadius: BorderRadius.circular(20)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.esparam_list![index]['name']}'
                                .toUpperCase(),
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.black),
                          ),
                          Divider(),

                          SizedBox(
                            height: 5,
                          ),

                          //  SizedBox(height: height * 0.001),

                          Container(
                            width: 0.95 * width,
                            padding: EdgeInsets.only(left: 15),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${double.parse(widget.esparam_list![index]['val']).toStringAsFixed(1)}'
                                      .toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  '${widget.esparam_list![index]['unit']}'
                                      .toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black26),
                                )
                              ],
                            ),
                          ),

                          Spacer(),
                        ]),
                  ),
                ),
              ),
              SizedBox(
                height: 100,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PVpositionedwidget extends StatelessWidget {
  const PVpositionedwidget(
      {Key? key,
      required this.PVvalue,
      required this.height,
      required this.width,
      required this.bottom,
      required this.left})
      : super(key: key);

  final double? PVvalue;
  final double height;
  final double width;
  final double bottom, left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
        bottom: bottom,
        left: left,
        child: Text(
            PVvalue! < 1000
                ? PVvalue!.toStringAsFixed(0) + " W"
                : (PVvalue! / 1000).toStringAsFixed(1) + " kW",
            style: TextStyle(
                fontSize: 0.022 * (height - width),
                fontWeight: FontWeight.bold,
                color: Colors.black)));
  }
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

class Chartinfo {
  Chartinfo(this.chartinfocategory, this.name1);
  final DateTime? chartinfocategory;
  final String name1;
  // Color color;
}
