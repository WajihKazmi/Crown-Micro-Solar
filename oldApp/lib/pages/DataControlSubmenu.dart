import 'package:crownmonitor/Models/DeviceCtrlFieldseModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class datacontrolsubmenu extends StatefulWidget {
  String? PN;
  String? SN;
  String? id;
  String? fieldname;
  String? unit;
  String? hint;

  int? devcode;
  int? devaddr;
  List<Item>? items;

  datacontrolsubmenu(
      {Key? key,
      this.items,
      this.PN,
      this.SN,
      this.devaddr,
      this.devcode,
      this.id,
      this.fieldname,
      this.unit,
      this.hint})
      : super(key: key);

  @override
  _datacontrolsubmenuState createState() => _datacontrolsubmenuState();
}

class _datacontrolsubmenuState extends State<datacontrolsubmenu> {
  List<bool> checkboxvalue = [];
  String? selectedvalue;
  bool savebuttonenable = false;
  TextEditingController textbox = new TextEditingController();
  bool isLoading = false;
  List<String> items_vallist = [];
  String? ctrlvalue;
  int? Indexof_ctrlvalue;

  void genrateallcheckboxlistwith_false() {
    checkboxvalue.clear();
    for (var i = 0; i < widget.items!.length; i++) {
      if (widget.items![i].val == ctrlvalue) {
        checkboxvalue.add(true);
      } else
        checkboxvalue.add(false);
    }
  }

  Future FetchDeviceCtrlValue() async {
    setState(() {
      isLoading = true;
    });
    var response = await DevicecTRLvalueQuery(context,
        PN: widget.PN!,
        SN: widget.SN!,
        devaddr: widget.devaddr!.toString(),
        devcode: widget.devcode!.toString(),
        id: widget.id!);
    if (response['err'] == 0) {
      setState(() {
        ctrlvalue = response['dat']['val'];
        //  Indexof_ctrlvalue = widget.items?.(ctrlvalue!);

        if (widget.items?.length != null) {
          genrateallcheckboxlistwith_false();
          // //test///
          // for (var item in widget.items!) {
          //   if (item.val == ctrlvalue) {
          //     selectedvalue = item.key;
          //     print(selectedvalue);
          //     print(item.val);
          //   }
          // }
          // //test//
        }

        isLoading = false;
      });

      print(ctrlvalue);
    } else {
      print('no ctrl value found');

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState

    FetchDeviceCtrlValue();
    if (widget.items?.length != null) {
      genrateallcheckboxlistwith_false();
    }

    super.initState();
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
    // print('items : ${widget.items?[0].val}');
    print('items : ${widget.items}');
    print('item length :  ${widget.items?.length}');
    print('checkbox list values :  ${checkboxvalue}');
    print('hint : ${widget.hint}');

    print('keylist : ${items_vallist}');

    //print('item 2nd value :  ${widget.items![0]['key:']}');

    print('selected value :   ${selectedvalue}');

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Theme.of(context).primaryColor,
        title: Text('${widget.fieldname}',
            style: TextStyle(
                fontSize: 0.035 * (height - width), color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Card(
              elevation: 5,
              child: Container(
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.circular(20)),
                width: 0.2 * width,
                child: OutlinedButton(
                    child: Text(
                      'Set',
                      style: TextStyle(
                          fontSize: 0.035 * (height - width),
                          color: Color.fromARGB(255, 58, 58, 58)),
                    ),
                    onPressed: () async {
                      if (selectedvalue != null || !textbox.text.isEmpty) {
                        setState(() {
                          isLoading = true;
                        });

                        var jsonresponse = await UpdateDeviceFieldQuery(context,
                            SN: widget.SN!,
                            PN: widget.PN!,
                            ID: widget.id!,
                            Value: selectedvalue ?? textbox.text,
                            devcode: widget.devcode!.toString(),
                            devaddr: widget.devaddr!.toString());
                        print(jsonresponse);
                        if (jsonresponse['err'] == 0) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              backgroundColor: Colors.green,
                              content: Container(
                                width: width,
                                height: 0.02 * height,
                                child: Text(
                                    'Value Updated Successfuly'.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 0.04 * width,
                                        color: Colors.white)),
                              )));
                          setState(() {
                            isLoading = false;
                          });
                        } else if (jsonresponse['err'] == 263) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              backgroundColor: Colors.red,
                              content: Container(
                                width: width,
                                height: 0.02 * height,
                                child: Text('Collector Offline'.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 0.04 * width,
                                        color: Colors.white)),
                              )));
                          setState(() {
                            isLoading = false;
                          });
                        } else if (jsonresponse['err'] == 3) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              backgroundColor: Colors.red,
                              content: Container(
                                width: width,
                                height: 0.02 * height,
                                child: Text('ERROR SYSTEM EXCEPTION',
                                    style: TextStyle(
                                        fontSize: 0.04 * width,
                                        color: Colors.white)),
                              )));
                          setState(() {
                            isLoading = false;
                          });
                        } else if (jsonresponse['err'] == 1) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              backgroundColor: Colors.red,
                              content: Container(
                                width: width,
                                height: 0.02 * height,
                                child: Text(
                                    'failed (no device protocol)'.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 0.04 * width,
                                        color: Colors.white)),
                              )));
                          setState(() {
                            isLoading = false;
                          });
                        } else if (jsonresponse['err'] == 6) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              backgroundColor: Colors.red,
                              content: Container(
                                width: width,
                                height: 0.02 * height,
                                child: Text('parameter error'.toUpperCase(),
                                    style: TextStyle(
                                        fontSize: 0.04 * width,
                                        color: Colors.white)),
                              )));
                          setState(() {
                            isLoading = false;
                          });
                        }
                      } else {
                        setState(() {
                          isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            duration: Duration(milliseconds: 1500),
                            backgroundColor: Colors.red,
                            content: Container(
                              width: width,
                              height: 0.02 * height,
                              child: Text('No value selected.',
                                  style: TextStyle(
                                      fontSize: 0.04 * width,
                                      color: Colors.white)),
                            )));
                      }
                    }),
              ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ))
          : widget.items?.length != 0
              ? ListView.builder(
                  itemCount: widget.items?.length,
                  itemBuilder: (BuildContext context, int index) {
                    return CheckboxListTile(
                        secondary: Icon(
                          Icons.edit_attributes,
                          color: Colors.greenAccent.shade400,
                        ),
                        controlAffinity: ListTileControlAffinity.trailing,
                        title: Text(
                          '${widget.items![index].val}',
                          style: TextStyle(
                              color: Colors.grey.shade900,
                              fontWeight: FontWeight.w300,
                              fontSize: 15),
                        ),
                        value: checkboxvalue[index],
                        onChanged: (value) {
                          setState(() {
                            ctrlvalue = null;
                            genrateallcheckboxlistwith_false();

                            this.checkboxvalue[index] = value!;
                            selectedvalue = widget.items![index].key;
                          });
                        });
                  })
              : Container(
                  height: height,
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 2,
                        margin: EdgeInsets.all(10),
                        color: Colors.blueGrey.shade900,
                        child: Container(
                          padding: EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${widget.fieldname}',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 0.035 * (height - width)),
                              ),
                              widget.unit != null
                                  ? Text(
                                      ' ( ${widget.unit} )',
                                      style: TextStyle(
                                          color: Colors.white60,
                                          fontWeight: FontWeight.w300,
                                          fontSize: 0.032 * (height - width)),
                                    )
                                  : Text(''),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        child: Text(
                          ' Input Example: ${widget.hint}',
                          style: TextStyle(
                              color: Colors.grey.shade900,
                              fontWeight: FontWeight.w100,
                              fontSize: 0.038 * (height - width)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          child: Text(
                            ' Current Value: ${ctrlvalue}',
                            style: TextStyle(
                                color: Colors.blueGrey,
                                fontWeight: FontWeight.w400,
                                fontSize: 0.035 * (height - width)),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          textAlign: TextAlign.center,
                          onSubmitted: (String value) {
                            setState(() {
                              textbox.text = value;
                              selectedvalue = value;
                            });
                          },
                          controller: textbox,
                          decoration: new InputDecoration(
                            contentPadding: EdgeInsets.all(15),
                            fillColor: Colors.blueGrey.shade50,
                            filled: true,
                            hintText: 'Enter Value Here',
                            enabledBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0)),
                              borderSide: const BorderSide(
                                color: Colors.white,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0)),
                              // borderSide: BorderSide(color: Colo),
                            ),
                          ),
                          style: TextStyle(
                              color: Colors.grey.shade900,
                              fontWeight: FontWeight.w400,
                              fontSize: 0.035 * (height - width)),
                          textAlignVertical: TextAlignVertical.center,
                        ),
                      )
                    ],
                  ),
                ),
    );
  }
}

class ITEMS {
  String? key;
  String? val;

  ITEMS({this.key, this.val});
}
