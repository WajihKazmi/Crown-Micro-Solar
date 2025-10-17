import 'package:crownmonitor/Models/queryPlantWarning.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class AlarmManagementALLPLants extends StatefulWidget {
  String? PID;
  AlarmManagementALLPLants({Key? key, this.PID}) : super(key: key);

  @override
  _AlarmManagementALLPLantsState createState() =>
      _AlarmManagementALLPLantsState();
}

class _AlarmManagementALLPLantsState extends State<AlarmManagementALLPLants> {
  late TextEditingController date = new TextEditingController();

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
      date.text =
          'From: ${DateFormat('yyyy-MM-dd').format(newdaterange.start)}  TO: ${DateFormat('yyyy-MM-dd').format(newdaterange.end)}';
    });
  }

  Widget _centerdate(double x, double y) {
    return TextField(
      textAlignVertical: TextAlignVertical.center,
      enabled: false,
      textAlign: TextAlign.center,
      controller: date,
      style: Theme.of(context).textTheme.titleSmall,
    );
  }

  // @override
  // void initState() {
  //   date.text = 'Total Alarms';
  //   super.initState();
  // }

  bool isLoading = true;

  var ps_info = null;

  @override
  void initState() {
    super.initState();
    loadPlantAlarms();
  }

  Future loadPlantAlarms() async {
    
    setState(() {
      isLoading = true;
    });

    final data = await PlantWarningALLplantsQuery(devtype: _selectedalldevices_coverted, level: _selectedalltypes_converted, handle: _selectedallstatus_converted, Sdate: StartDate, Edate: EndDate);
    setState(() {
      isLoading = false;
      ps_info = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    print('daterange: ${daterange}');
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
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppLocalizations.of(context)!.alarm_management,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 0.035 * (height - width))),
              SizedBox(
                width: 8,
              ),
              Text(
                AppLocalizations.of(context)!.tabs_plant,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 0.035 * (height - width)),
              ),
            ],
          ),
          centerTitle: true,
          elevation: 0,
        ),
        body: Column(children: [
          _datetime(width, height),
          Container(
            color: Colors.grey.shade600, //Theme.of(context).primaryColor,
            padding: EdgeInsets.all(5),
            width: double.infinity,
            height: height / 20,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                      child: Text(
                        'Today',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        TodayRAnge();
                      }),
                  SizedBox(
                    width: 5,
                  ),
                  OutlinedButton(
                      child: Text(
                        'Yesterday',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        YesterdayRAnge();
                      }),
                  SizedBox(
                    width: 5,
                  ),
                  OutlinedButton(
                      child: Text(
                        'Week',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        weekRAnge();
                      }),
                  SizedBox(
                    width: 5,
                  ),
                  OutlinedButton(
                      child: Text(
                        'Month',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        MonthRAnge();
                      }),
                  SizedBox(
                    width: 5,
                  ),
                  OutlinedButton(
                      child: Text(
                        'Year',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        yearRAnge();
                      }),
                  SizedBox(
                    width: 5,
                  ),
                  OutlinedButton(
                      child: Text(
                        'Total',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        TotalRange();
                      }),
                  SizedBox(
                    width: 5,
                  ),
                  OutlinedButton(
                      child: Text(
                        'Pick Date Range',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        PickDateRange();
                      }),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: width / 4.35,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      style: TextStyle(
                          fontSize: 0.028 * (height - width),
                          color: Colors.grey.shade900),
                      // dropdownColor: Colors.grey[700],
                      icon: Icon(
                        Icons.keyboard_arrow_down_sharp,
                        size: width / 20,
                        color: Colors.grey,
                      ),
                      value: _selectedalltypes,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedalltypes = newValue.toString();
                          switch (newValue) {
                            case "All types":
                              {
                                _selectedalltypes_converted = '0101';
                              }
                              break;
                            case "Fault":
                              {
                                _selectedalltypes_converted = '2';
                              }
                              break;
                            case "Alarm":
                              {
                                _selectedalltypes_converted = '0';
                              }
                              break;
                            case "Error":
                              {
                                _selectedalltypes_converted = '1';
                              }
                              break;
                          }
                        });
                      },
                      items: _alltypes.map((location) {
                        return DropdownMenuItem(
                          child: new Text(location),
                          value: location,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              Container(
                  height: height / 20,
                  child: VerticalDivider(
                    color: Colors.grey[300],
                    thickness: 1.5,
                  )),
              Container(
                width: width / 2.35,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      style: TextStyle(
                          fontSize: 0.028 * (height - width),
                          color: Colors.grey.shade900),

                      // dropdownColor: Colors.grey[700],
                      icon: Icon(
                        Icons.keyboard_arrow_down_sharp,
                        size: width / 20,
                        color: Colors.grey,
                      ),
                      value: _selectedalldevices,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedalldevices = newValue.toString();
                          switch (newValue) {
                            case "All devices":
                              {
                                _selectedalldevices_coverted = '0101';
                              }
                              break;
                            case "Invertor":
                              {
                                _selectedalldevices_coverted = '512';
                              }
                              break;
                            case "Env-monitor":
                              {
                                _selectedalldevices_coverted = '768';
                              }
                              break;
                            case "Smart meters":
                              {
                                _selectedalldevices_coverted = '1024';
                              }
                              break;
                            case "Combining manifolds":
                              {
                                _selectedalldevices_coverted = '1280';
                              }
                              break;
                            case "Camera":
                              {
                                _selectedalldevices_coverted = '1536';
                              }
                              break;
                            case "Battery":
                              {
                                _selectedalldevices_coverted = '1792';
                              }
                              break;
                            case "Charger":
                              {
                                _selectedalldevices_coverted = '2048';
                              }
                              break;
                            case "Energy storage machine":
                              {
                                _selectedalldevices_coverted = '2304';
                              }
                              break;
                            case "Anti-islanding":
                              {
                                _selectedalldevices_coverted = '2560';
                              }
                              break;
                          }
                        });
                      },
                      items: _alldevices.map((location) {
                        return DropdownMenuItem(
                          child: new Text(location),
                          value: location,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              Container(
                  height: height / 20,
                  child: VerticalDivider(
                    color: Colors.grey[300],
                    thickness: 1.5,
                  )),
              // _dropdowns(_allstatus, _selectedallstatus, width),
              Container(
                width: width / 4.1,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton(
                      style: TextStyle(
                          fontSize: 0.028 * (height - width),
                          color: Colors.grey.shade900),

                      // dropdownColor: Colors.grey[700],
                      icon: Icon(
                        Icons.keyboard_arrow_down_sharp,
                        size: width / 20,
                        color: Colors.grey,
                      ),
                      value: _selectedallstatus,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedallstatus = newValue.toString();
                          switch (newValue) {
                            case "All status":
                              {
                                _selectedallstatus_converted = '0101';
                              }
                              break;
                            case "Untreated":
                              {
                                _selectedallstatus_converted = 'false';
                              }
                              break;
                            case "Processed":
                              {
                                _selectedallstatus_converted = 'true';
                              }
                              break;
                          }
                        });
                      },
                      items: _allstatus.map((location) {
                        return DropdownMenuItem(
                          child: new Text(location),
                          value: location,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
           Expanded(
              child: isLoading ? 
                Center(child: CircularProgressIndicator())
                  : Container(
                      child: ps_info?['err'] == 11 ?
                          Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                              child: Text(AppLocalizations.of(context)!.no_permission_to_operate_power_station,
                                  maxLines: 2,
                                  style: TextStyle(
                                      fontSize: 0.035 * width,
                                      fontWeight: FontWeight.bold))),
                        ) : ps_info?['err'] == 260 ?
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                  child: Text(AppLocalizations.of(context)!.power_station_not_found,
                                      style: TextStyle(
                                          fontSize: 0.035 * width,
                                          fontWeight: FontWeight.bold))),
                            ) : ps_info?['err'] == 404 ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                child: Text(AppLocalizations.of(context)!.no_response_from_server,
                                  style: TextStyle(
                                    fontSize: 0.025 * width,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ) : ps_info?['err'] == 264 ?
                                Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                    child: Text(AppLocalizations.of(context)!.device_alarm_not_found,
                                        style: TextStyle(
                                            fontSize: 20, fontWeight: FontWeight.bold))),
                              ): ps_info?['err'] == 12 ?
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Center(
                                        child: Text(AppLocalizations.of(context)!.no_record_found,
                                            style: TextStyle(
                                                fontSize: 0.035 * width,
                                                fontWeight: FontWeight.bold))),
                                  ) : (ps_info?['dat']['warning'] != null ?
                                        buildWarningList(QueryPlantWarning.fromJson(ps_info!), width, height)
                                      : Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Center(
                                              child: Text('Unhandled Exception'.toUpperCase(),
                                                  style: TextStyle(
                                                      fontSize: 0.035 * width,
                                                      fontWeight: FontWeight.bold))),
                                        )

                  )
                )
              )
        ]));
  }

  void TodayRAnge() {
    setState(() {
      date.text = AppLocalizations.of(context)!.alarm_today;
      StartDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      EndDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    });

    loadPlantAlarms();
  }

  void YesterdayRAnge() {
    setState(() {
      date.text = AppLocalizations.of(context)!.alarm_yesterday;
      StartDate = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 1)));
      EndDate = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 1)));
    });
    loadPlantAlarms();
  }

  void weekRAnge() {
    /// Find the first date of the week which contains the provided date.
    DateTime findFirstDateOfTheWeek(DateTime dateTime) {
      return dateTime.subtract(Duration(days: dateTime.weekday - 1));
    }

    /// Find last date of the week which contains provided date.
    DateTime findLastDateOfTheWeek(DateTime dateTime) {
      return dateTime
          .add(Duration(days: DateTime.daysPerWeek - dateTime.weekday));
    }

    setState(() {
      date.text = AppLocalizations.of(context)!.alarm_week;
      StartDate = DateFormat('yyyy-MM-dd')
          .format(findFirstDateOfTheWeek(DateTime.now()));
      EndDate = DateFormat('yyyy-MM-dd')
          .format(findLastDateOfTheWeek(DateTime.now()));
    });

    loadPlantAlarms();
  }

  void MonthRAnge() {
    DateTime D = DateTime.now();
    //Providing a day value of zero for the next month gives you the previous month's last day

    var firstDayOfMonth = new DateTime(D.year, D.month, 1);
    var LastDaymonth = new DateTime(D.year, D.month + 1, 0);

    setState(() {
      date.text = AppLocalizations.of(context)!.alarm_month;
      StartDate = DateFormat('yyyy-MM-dd').format(firstDayOfMonth);
      EndDate = DateFormat('yyyy-MM-dd').format(LastDaymonth);
    });

    loadPlantAlarms();
  }

  void yearRAnge() {
    DateTime D = DateTime.now();
    //Providing a day value of zero for the next month gives you the previous month's last day

    var firstDayOfyear = new DateTime(D.year, 1, 1);
    var LastDayyear = new DateTime(D.year + 1, 1, 0);

    setState(() {
      date.text = AppLocalizations.of(context)!.alarm_year;
      StartDate = DateFormat('yyyy-MM-dd').format(firstDayOfyear);
      EndDate = DateFormat('yyyy-MM-dd').format(LastDayyear);
    });
    loadPlantAlarms();
  }

  TotalRange() {
    setState(() {
      date.text = AppLocalizations.of(context)!.total_alarms_heading;
      StartDate = null;
      EndDate = null;
    });
    loadPlantAlarms();
  }

  Widget buildWarningList(
      QueryPlantWarning psinfo, double width, double height) {
    return ListView.separated(
        separatorBuilder: (context, index) => Divider(
              color: Colors.black,
            ),
        itemCount: psinfo.dat!.warning!.length,
        itemBuilder: (BuildContext context, int index) {
          final PSINFO = psinfo.dat!.warning![index];

          ////////////////////////////////////////////////////////////////////////////////////////
          // set up delete  button
          Widget DelButton = ElevatedButton(
              child: Text(AppLocalizations.of(context)!.confirm_delete),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    duration: Duration(milliseconds: 1500),
                    backgroundColor: Colors.green,
                    content: Container(
                      width: width,
                      height: 0.02 * height,
                      child: Text(AppLocalizations.of(context)!.alarm_deleted,
                          style: TextStyle(
                              fontSize: 0.04 * width, color: Colors.white)),
                    )));
                Navigator.of(context, rootNavigator: true).pop();
                var json = await DeletePlantWarningQuery(ID: PSINFO.id!);
                setState(() {});
              });
          Widget CancelButton = ElevatedButton(
            child: Text(AppLocalizations.of(context)!.btn_cancel),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
            },
          );
          // set up the Delete AlertDialog
          AlertDialog Delete_alert = AlertDialog(
            title: Text(AppLocalizations.of(context)!.delete_alarm,
              style: TextStyle(
                  fontSize: 0.05 * (height - width),
                  fontWeight: FontWeight.w900,
                  color: Colors.blue),
            ),
            content: Text(
              AppLocalizations.of(context)!.are_you_sure + '\n' +
              AppLocalizations.of(context)!.this_will_remove_alarm_list,
              style: TextStyle(
                  fontSize: 0.034 * (height - width),
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade800),
            ),
            actions: [
              DelButton,
              CancelButton,
            ],
          );
          //////////////////////////////////////////////////////////////////////////////////////

          return Container(
              child: ListTile(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // CircleAvatar(
                        //   backgroundColor: Colors.red[300],
                        //   radius: 0.04 * width,
                        //   child: Icon(
                        //     Icons.warning,
                        //     color: Colors.white,
                        //   ),
                        // ),
                        // SizedBox(
                        //   width: width / 60,
                        // ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SN: ${PSINFO.sn}',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 0.03 * (height - width),
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 1),
                            Container(
                              color: Colors.redAccent,
                              padding: EdgeInsets.all(5),
                              child: Text(
                                  '${(PSINFO.level == 0) ? AppLocalizations.of(context)!.warning_upper : (PSINFO.level == 1) ? AppLocalizations.of(context)!.error_upper : (PSINFO.level == 2) ? AppLocalizations.of(context)!.fault_upper : AppLocalizations.of(context)!.offline_upper}',
                                  style: TextStyle(
                                    fontSize: 0.025 * (height - width),
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  )),
                            )
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Code:${PSINFO.code}',
                      style: TextStyle(
                        fontSize: 0.025 * (height - width),
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    )
                  ],
                )
              ],
            ),
            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              // crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: height / 100,
                    ),
                    Row(
                      children: [
                        Text(AppLocalizations.of(context)!.occurence_time,
                          style: TextStyle(
                              fontSize: 0.025 * (height - width),
                              color: Colors.grey.shade900),
                        ),
                        Text(DateFormat.yMd().add_jm().format(PSINFO.gts!),
                            style: TextStyle(
                                fontSize: 0.03 * (height - width),
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                      ],
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Row(
                      children: [
                        Text(AppLocalizations.of(context)!.device_pn,
                            style: TextStyle(
                                fontSize: 0.025 * (height - width),
                                color: Colors.grey.shade900)),
                        Text('${PSINFO.pn}',
                            style: TextStyle(
                                fontSize: 0.03 * (height - width),
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                      ],
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Row(
                      children: [
                        Text(AppLocalizations.of(context)!.device_type,
                            style: TextStyle(
                                fontSize: 0.025 * (height - width),
                                color: Colors.grey.shade900)),
                        Text(
                            '${(PSINFO.devcode == 530) ? 'Inverter' : (PSINFO.devcode == 768) ? 'Env-monitor' : (PSINFO.devcode == 1024) ? 'Smart meter' : (PSINFO.devcode == 1280) ? 'Combining manifolds' : (PSINFO.devcode == 1536) ? 'Camera' : (PSINFO.devcode == 1792) ? 'Battery' : (PSINFO.devcode == 2048) ? 'Charger' : (PSINFO.devcode == 2452 || PSINFO.devcode == 2304) ? 'Energy storage machine' : (PSINFO.devcode == 2560) ? 'Anti-islanding' : (PSINFO.devcode == -1) ? 'Datalogger' : PSINFO.devcode}',
                            style: TextStyle(
                                fontSize: 0.03 * (height - width),
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                    SizedBox(
                      height: 2,
                    ),
                    Row(
                      children: [
                        Text(AppLocalizations.of(context)!.description,
                            style: TextStyle(
                                fontSize: 0.025 * (height - width),
                                color: Colors.grey.shade900)),
                        Container(
                          // color: Colors.blueGrey,
                          width: 0.55 * width,
                          child: Text('${PSINFO.desc}',
                              maxLines: 8,
                              style: TextStyle(
                                  fontSize: 0.03 * (height - width),
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black)),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                        '${(PSINFO.handle == true) ? 'Processed' : 'Untreated'}',
                        style: TextStyle(
                          fontSize: 0.03 * (height - width),
                          fontWeight: FontWeight.bold,
                          color:
                              PSINFO.handle == true ? Colors.green : Colors.red,
                        )),
                    IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return Delete_alert;
                            },
                          );
                        },
                        icon: Column(
                          children: [
                            Icon(
                              Icons.delete_forever,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                            // Text('Delete',
                            //     style: TextStyle(
                            //       fontSize: 9,
                            //       fontWeight: FontWeight.bold,
                            //       color: Colors.red,
                            //     )),
                          ],
                        ))
                  ],
                ),
              ],
            ),
          ));
        });
  }
}
