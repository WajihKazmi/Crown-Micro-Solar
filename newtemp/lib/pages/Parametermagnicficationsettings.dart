import 'package:crownmonitor/Models/DeviceCtrlFieldseModel.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class parammagconfig extends StatefulWidget {
  String? PN;
  String? SN;
  int? devcode;
  int? devaddr;
  parammagconfig({
    Key? key,
    this.PN,
    this.SN,
    this.devaddr,
    this.devcode,
  }) : super(key: key);

  @override
  _parammagconfigState createState() => _parammagconfigState();
}

class _parammagconfigState extends State<parammagconfig> {
  int Radiobuttonvalue = 0;
  bool isloading = false;
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    print(Radiobuttonvalue);

    Widget NamechangeButton = Container(
        width: width / 1.5,
        child: ElevatedButton(
            child: Text("Update Value"),
            onPressed: () async {
              print(Radiobuttonvalue);
              print(widget.SN);
              print(widget.PN);
              print(widget.devcode!);
              print(widget.devaddr!);
              setState(() {
                isloading = true;
              });
              if (Radiobuttonvalue == 0) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    duration: Duration(milliseconds: 1500),
                    backgroundColor: Colors.red,
                    content: Container(
                      width: width,
                      height: 0.02 * height,
                      child: Text('No value selected.',
                          style: TextStyle(
                              fontSize: 0.04 * width, color: Colors.white)),
                    )));
                setState(() {
                  isloading = false;
                });
              } else {
                var json = await ChangebackflowQuery(context,
                    SN: widget.SN!,
                    PN: widget.PN!,
                    devcode: widget.devcode!.toString(),
                    devaddr: widget.devaddr!.toString(),
                    backflow: Radiobuttonvalue.toString());
                if (json['err'] == 0) {
                  setState(() {
                    isloading = false;
                  });
                  Fluttertoast.showToast(
                      msg: "Value Updated Successfully",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      backgroundColor: Colors.green,
                      timeInSecForIosWeb: 2,
                      textColor: Colors.white,
                      fontSize: 15.0);
                } else if (json['err'] == 263) {
                  setState(() {
                    isloading = false;
                  });
                  Fluttertoast.showToast(
                      msg: "Collector Offline",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      backgroundColor: Colors.green,
                      timeInSecForIosWeb: 2,
                      textColor: Colors.white,
                      fontSize: 15.0);
                } else {
                  setState(() {
                    isloading = false;
                  });
                  Fluttertoast.showToast(
                      msg: "${json['desc']}",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.CENTER,
                      timeInSecForIosWeb: 2,
                      textColor: Colors.white,
                      fontSize: 15.0);
                }
              }
            }));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Parameter configuration Setup >',
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
      body: isloading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Container(
              width: width,
              padding: EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    elevation: 2,
                    color: Colors.grey.shade800,
                    child: Container(
                      width: width,
                      padding: EdgeInsets.all(10),
                      child: Center(
                        child: Text(
                          "Parameter Configuration (Magnification)",
                          style: TextStyle(fontSize: 15, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Radio(
                              value: 10,
                              groupValue: Radiobuttonvalue,
                              onChanged: (value) {
                                setState(() {
                                  Radiobuttonvalue = 10;
                                });
                              }),
                          Text(
                            '10',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Radio(
                              value: 20,
                              groupValue: Radiobuttonvalue,
                              onChanged: (value) {
                                setState(() {
                                  Radiobuttonvalue = 20;
                                });
                              }),
                          Text(
                            '20',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Radio(
                              value: 40,
                              groupValue: Radiobuttonvalue,
                              onChanged: (value) {
                                setState(() {
                                  Radiobuttonvalue = 40;
                                });
                              }),
                          Text(
                            '40',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Radio(
                              value: 60,
                              groupValue: Radiobuttonvalue,
                              onChanged: (value) {
                                setState(() {
                                  Radiobuttonvalue = 60;
                                });
                              }),
                          Text(
                            '60',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Radio(
                              value: 80,
                              groupValue: Radiobuttonvalue,
                              onChanged: (_) {
                                setState(() {
                                  Radiobuttonvalue = 80;
                                });
                              }),
                          Text(
                            '80',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Radio(
                              value: 100,
                              groupValue: Radiobuttonvalue,
                              onChanged: (_) {
                                setState(() {
                                  Radiobuttonvalue = 100;
                                });
                              }),
                          Text(
                            '100',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Radio(
                              value: 160,
                              groupValue: Radiobuttonvalue,
                              onChanged: (_) {
                                setState(() {
                                  Radiobuttonvalue = 160;
                                });
                              }),
                          Text(
                            '160',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Radio(
                              value: 200,
                              groupValue: Radiobuttonvalue,
                              onChanged: (_) {
                                setState(() {
                                  Radiobuttonvalue = 200;
                                });
                              }),
                          Text(
                            '200',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  NamechangeButton,
                ],
              )),
    );
  }
}
