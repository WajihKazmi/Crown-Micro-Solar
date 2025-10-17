import 'package:crownmonitor/Models/DeviceCtrlFieldseModel.dart';
import 'package:crownmonitor/pages/DataControlSubmenu.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class datacontrol extends StatefulWidget {
  String? PN;
  String? SN;
  int? devcode;
  int? devaddr;
  datacontrol({Key? key, this.PN, this.SN, this.devaddr, this.devcode})
      : super(key: key);

  @override
  _datacontrolState createState() => _datacontrolState();
}

class _datacontrolState extends State<datacontrol> {
  @override
  void initState() {
    super.initState();
    loadCollectorDevicesStatusQuery();
  }

  bool isLoading = true;
  var ps_info = null;
  
  Future loadCollectorDevicesStatusQuery() async {
    
    final data = await DeviceCtrlFieldseModelQuery(context, SN: widget.SN!, PN: widget.PN!, devcode: widget.devcode!.toString(), devaddr: widget.devaddr!.toString());

    setState(() {
      isLoading = false;
      ps_info = data;
    });
  }

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
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 25)),
        backgroundColor: Theme.of(context).primaryColor,
        title: Row(
          children: [
            Text(AppLocalizations.of(context)!.data_control,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 0.035 * (height - width))),
            SizedBox(
              width: 8,
            ),
            Text(AppLocalizations.of(context)!.fields,
              style: TextStyle(
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  fontSize: 0.035 * (height - width)),
            ),
          ],
        ),
      ),
      body: Container(
          height: height,
          child: Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: isLoading ? Center(child: CircularProgressIndicator())
              : Container(
                child:  
                  ps_info?['err'] == 1 
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                            child: Text(AppLocalizations.of(context)!.failed_no_device,
                                style: TextStyle(
                                    fontSize: 0.035 * width,
                                    fontWeight: FontWeight.bold))),
                      )
                    : ps_info?['err'] == 6
                        ?  Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                                child: Text(AppLocalizations.of(context)!.parameter_error,
                                    style: TextStyle(
                                        fontSize: 0.035 * width,
                                        fontWeight: FontWeight.bold))),
                          ) 
                      : ps_info?['err'] == 404
                          ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                                child: Text(AppLocalizations.of(context)!.no_response_from_server,
                                    style: TextStyle(
                                        fontSize: 0.035 * width,
                                        fontWeight: FontWeight.bold))),
                          )
                        : ps_info?['err'] == 258
                          ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Center(
                                child: Text(AppLocalizations.of(context)!.device_could_not_found,
                                    style: TextStyle(
                                        fontSize: 0.035 * width,
                                        fontWeight: FontWeight.bold))),
                          )
                          : ps_info?['err'] == 260
                            ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(
                                  child: Text(AppLocalizations.of(context)!.power_station_not_found,
                                      style: TextStyle(
                                          fontSize: 0.035 * width,
                                          fontWeight: FontWeight.bold))))
                            : ps_info?['err'] == 257
                              ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                    child: Text(AppLocalizations.of(context)!.collector_not_found,
                                        style: TextStyle(
                                            fontSize: 0.035 * width,
                                            fontWeight: FontWeight.bold))),
                              )
                            : ps_info?['err'] == 12
                              ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                    child: Text(AppLocalizations.of(context)!.no_record_found,
                                        style: TextStyle(
                                            fontSize: 0.035 * width,
                                            fontWeight: FontWeight.bold))),
                              )
                              :  (ps_info?['err'] == 0 && ps_info?['dat']['field'] != null) 
                                ? buildCtrlFieldList(DeviceCtrlFieldseModel.fromJson(ps_info!), width, height)
                              : ps_info?['err'] != 0
                                ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                      child: Text(
                                          AppLocalizations.of(context)!.no_response_from_server,
                                          style: TextStyle(
                                              fontSize: 0.035 * width,
                                              fontWeight: FontWeight.bold))),
                                )
                              : Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Center(
                                    child: Text(AppLocalizations.of(context)!.error_system_exception,
                                        style: TextStyle(
                                            fontSize: 0.035 * width,
                                            fontWeight: FontWeight.bold))),
                              )
                          )
              )));
  }

  Widget buildCtrlFieldList(DeviceCtrlFieldseModel ctrlField, double width, double height) {
    return ListView.builder(
        physics: BouncingScrollPhysics(),
        itemCount: ctrlField.dat!.field?.length,
        itemBuilder: (context, index) {
          final ctrlfield = ctrlField.dat?.field?[index];
          // var itemslength = ctrlField.dat?.field?[index].item?.length;
          List<Item> items = [];

          if (ctrlField.dat!.field![index].item != null) {
            for (int i = 0;
                i < ctrlField.dat!.field![index].item!.length;
                i++) {
              items.add(ctrlField.dat!.field![index].item![i]);
            }
          }

          // if (ctrlField.dat!.field![index].item != null) {
          //   for (int i = 0;
          //       i < ctrlField.dat!.field![index].item!.length;
          //       i++) {
          //     items.add({
          //       'key: "${ctrlField.dat!.field![index].item![i].key}"',
          //       'val: "${ctrlField.dat!.field![index].item![i].val}"'
          //     });
          //   }
          // }

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: new BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.all(Radius.circular(2.0)),
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
              leading: Icon(
                Icons.edit_attributes,
                color: Colors.greenAccent.shade400,
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${ctrlfield?.name}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      )),
                ],
              ),
              trailing: Icon(Icons.arrow_right),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => datacontrolsubmenu(
                          PN: widget.PN,
                          SN: widget.SN,
                          devaddr: widget.devaddr,
                          devcode: widget.devcode,
                          id: ctrlfield?.id,
                          fieldname: ctrlfield?.name,
                          unit: ctrlfield?.unit,
                          hint: ctrlfield?.hint,
                          items: items,
                        )));
              },
            ),
          );
        });
  }
}