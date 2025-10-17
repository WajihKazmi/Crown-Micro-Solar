import 'package:crownmonitor/pages/plant.dart' as plantspage;
import 'package:flutter/material.dart';

import '../Models/CollectorDevicesStatus.dart';

class addcollectorscreen extends StatefulWidget {
  String? PID;
  String? PN;

  addcollectorscreen({Key? key, this.PID, this.PN}) : super(key: key);

  @override
  State<addcollectorscreen> createState() => _addcollectorscreenState();
}

class _addcollectorscreenState extends State<addcollectorscreen> {
  late TextEditingController name = new TextEditingController();
  late TextEditingController Pn_number = new TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Pn_number.text = widget.PN!;
  }

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

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Datalogger',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 25)),
      ),
      body: Container(
        padding: EdgeInsets.all(15),
        width: width,
        height: height,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Enter Datalogger Name",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              SizedBox(
                height: 15,
              ),
              TextField(
                onSubmitted: (String value) {
                  setState(() {
                    name.text = value;
                  });
                },
                controller: name,
                decoration: new InputDecoration(
                  contentPadding: EdgeInsets.all(10),
                  fillColor: Colors.white,
                  filled: true,
                  hintText: 'Enter Datalogger Name',
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
              SizedBox(
                height: 5,
              ),
              TextField(
                onSubmitted: (String value) {
                  setState(() {
                    Pn_number.text = value;
                  });
                },
                controller: Pn_number,
                decoration: new InputDecoration(
                  contentPadding: EdgeInsets.all(10),
                  fillColor: Colors.white,
                  filled: true,
                  hintText: 'Enter Pn Number ( 14 digits )',
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
              ElevatedButton(
                  child: Text("Add"),
                  onPressed: () async {
                    var json = await AddCollectortoplant(
                        PN: Pn_number.text, name: name.text, PID: widget.PID!);

                    if (json['err'] == 6) {
                      Showsnackbar("Parameter Error", 5000, Colors.red);
                      Navigator.of(context).pop();
                    } else if (json['err'] == 259) {
                      Showsnackbar("Invalid PN", 5000, Colors.red);
                      Navigator.of(context).pop();
                    } else if (json['err'] == 11) {
                      Showsnackbar(
                          "No permissions (possible reason only the plant owner can add)",
                          5000,
                          Colors.red);
                      Navigator.of(context).pop();
                    } else if (json['err'] == 260) {
                      Showsnackbar("Power station not found", 5000, Colors.red);
                      Navigator.of(context).pop();
                    } else {
                      Showsnackbar(
                          'Datalogger Added Successfully', 2000, Colors.green);
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => plantspage.Plant(
                                  passedindex: 3,
                                  collector_callback: true,
                                  PlantID: widget.PID,
                                )),
                      );
                    }
                  }),
            ]),
      ),
    );
  }
}
