import 'dart:convert';

import 'package:crownmonitor/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class forgotpassword extends StatefulWidget {
  String emailAddress = '';
  bool ischangingpass = false;
  forgotpassword(
      {Key? key, required this.emailAddress, required this.ischangingpass})
      : super(key: key);

  @override
  State<forgotpassword> createState() => _forgotpasswordState();
}

class _forgotpasswordState extends State<forgotpassword> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmpasswordController =
      TextEditingController();
  bool hidepass = true;
  final GlobalKey<FormState> _formkey = new GlobalKey<FormState>();
  int UID = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    emailController.text = widget.emailAddress;
    getUid();
  }

  void getUid() async {
    EasyLoading.show(status: 'Loading');
    var jsonResponse = null;
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C'
    };
    final body = jsonEncode({
      "Email": widget.emailAddress,
    });
    try {
      await http
          .post(
              Uri.parse(
                  'https://apis.crown-micro.net/api/MonitoringApp/GetUserID'),
              headers: headers,
              body: body)
          .then((response) async {
        if (response.statusCode == 200) {
          jsonResponse = json.decode(response.body);
          setState(() {
            UID = jsonResponse;
          });
          print("UID is >> $UID");
          if (jsonResponse != null) {
            EasyLoading.dismiss();
            // showMessage("Success", 'UID is >> $jsonResponse', true);
            // Navigator.pushAndRemoveUntil(
            //     context,
            //     MaterialPageRoute(builder: (context) => LoginPage()),
            //     (route) => false);
          } else {
            EasyLoading.dismiss();
            showMessage("Error", 'Server Error', true);
          }
        } else {
          EasyLoading.dismiss();
          showMessage("Error", "There is no user account linked to this ${widget.emailAddress} number.", true);
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false);
        }
      });
    } catch (e) {
      EasyLoading.dismiss();
      showMessage("Error", e.toString(), true);
    }
  }

  void updatepassword() async {
    EasyLoading.show(status: 'Loading');
    var jsonResponse = null;
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C'
    };
    final body =
        jsonEncode({"UserID": UID, "Password": passwordController.text});
    try {
      await http
          .post(
              Uri.parse(
                  'https://apis.crown-micro.net/api/MonitoringApp/UpdatePassword'),
              headers: headers,
              body: body)
          .then((response) async {
        if (response.statusCode == 200) {
          jsonResponse = json.decode(response.body);
          print(jsonResponse);
          print(jsonResponse['ResponseCode']);

          if (jsonResponse != null && jsonResponse['ResponseCode'] == "00") {
            EasyLoading.dismiss();
            
            if (widget.ischangingpass) {
              final prefs = await SharedPreferences.getInstance();
              prefs.setBool('loggedin', false);
            }
            await showMessage(
                "Success", 'Your password is updated successfully.', true);

            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (route) => false);
          } else {
            EasyLoading.dismiss();
            showMessage("Error", 'Server Error', true);
          }
        } else {
          EasyLoading.dismiss();
          showMessage("Error", "No response from server", true);
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
              (route) => false);
        }
      });
    } catch (e) {
      EasyLoading.dismiss();
      showMessage("Error", e.toString(), true);
    }
  }

  showMessage(String title, errorMessage, bool isSuccess) async {
    showDialog(
        context: context,
        builder: (BuildContext builderContext) {
          return AlertDialog(
            title: Text(title,
                style: TextStyle(
                    fontSize: 15,
                    color: title == "Success" ? Colors.green : Colors.black,
                    fontWeight: FontWeight.bold)),
            content: Text(errorMessage ?? "",
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold)),
            actions: [
              TextButton(
                child: Text("Ok",
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold)),
                onPressed: () async {
                  Navigator.of(builderContext).pop();
                },
              )
            ],
          );
        }).then((value) {
      // setState(() {
      //   isLoading = false;
      // });
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
          // leading: IconButton(
          //     onPressed: () {
          //       // Navigator.pop(context);
          //       Navigator.pushAndRemoveUntil(
          //           context,
          //           MaterialPageRoute(
          //               builder: (context) => MainScreen(passed_index: 1)),
          //           (route) => false);
          //     },
          //     icon: Icon(Icons.arrow_back, color: Colors.white, size: 25)),
          backgroundColor: Theme.of(context).primaryColor,
          centerTitle: false,
          automaticallyImplyLeading: true,
          title: Text(
              widget.ischangingpass ? AppLocalizations.of(context)!.change_password : AppLocalizations.of(context)!.forgot_password,
              style: TextStyle(
                fontSize: 0.045 * (height - width),
                fontWeight: FontWeight.bold,
                color: Colors.white
              ))),
      body: Form(
        key: _formkey,
        child: Container(
          height: height,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: MediaQuery.of(context).size.width,
                    child: Text(AppLocalizations.of(context)!.email,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextFormField(
                    controller: emailController,
                    autofocus: false,
                    readOnly: true,

                    style: TextStyle(
                        fontSize: 0.04 * (height - width),
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.normal),
                    // validator: (value) => Validations.minLength(value, 'Full name', 2),
                    decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius:
                                BorderRadius.all(Radius.circular(40))),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius:
                                BorderRadius.all(Radius.circular(40))),
                        // hintText: "+1 123 xx xxx",
                        // labelText: "Enter your Mobile #",
                        // hintText: "Enter Username",
                        // labelText: "Enter your Username",

                        fillColor: Color(0xffF4F4F4),
                        filled: true),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Divider(),
                  const SizedBox(
                    height: 5,
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: MediaQuery.of(context).size.width,
                    child: Text(AppLocalizations.of(context)!.new_password,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextFormField(
                    obscureText: hidepass,
                    controller: passwordController,
                    autofocus: false,
                    validator: (val) {
                      if (!val!.isEmpty && val.length < 6) {
                        return 'Password must be at least 6 digits long';
                      } else if (val.isEmpty) {
                        return 'Password required';
                      } else
                        return null;
                    },

                    style: TextStyle(
                        fontSize: 0.035 * (height - width),
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.normal),
                    // validator: (value) => Validations.minLength(value, 'Full name', 2),
                    decoration: InputDecoration(
                        suffixIcon: GestureDetector(
                          onTap: (() {
                            setState(() {
                              hidepass = !hidepass;
                            });
                          }),
                          child: Icon(
                            !hidepass ? Icons.visibility_off : Icons.visibility,
                            color: Colors.black54,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius:
                                BorderRadius.all(Radius.circular(40))),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius:
                                BorderRadius.all(Radius.circular(40))),
                        hintText: AppLocalizations.of(context)!.enter_new_password,
                        // labelText: "Enter your password",
                        border: OutlineInputBorder(),
                        fillColor: Color(0xffF4F4F4),
                        filled: true),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: MediaQuery.of(context).size.width,
                    child: Text(AppLocalizations.of(context)!.confirm_password,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextFormField(
                    obscureText: hidepass,
                    controller: confirmpasswordController,
                    autofocus: false,
                    validator: (val) {
                      if (!val!.isEmpty && val != passwordController.text) {
                        return 'Password does not match.';
                      } else if (val.isEmpty) {
                        return 'Confirm Password required';
                      } else
                        return null;
                    },
                    style: TextStyle(
                        fontSize: 0.035 * (height - width),
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.normal),
                    // validator: (value) => Validations.minLength(value, 'Full name', 2),
                    decoration: InputDecoration(
                        suffixIcon: GestureDetector(
                          onTap: (() {
                            setState(() {
                              hidepass = !hidepass;
                            });
                          }),
                          child: Icon(
                            !hidepass ? Icons.visibility_off : Icons.visibility,
                            color: Colors.black54,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius:
                                BorderRadius.all(Radius.circular(40))),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius:
                                BorderRadius.all(Radius.circular(40))),
                        hintText: "Confirm Password",
                        // labelText: "Enter your password",
                        border: OutlineInputBorder(),
                        fillColor: Color(0xffF4F4F4),
                        filled: true),
                  ),
                  const SizedBox(
                    height: 25,
                  ),
                  Material(
                      // elevation: 5.0,
                      borderRadius: BorderRadius.circular(40.0),
                      color:
                          Theme.of(context).primaryColor, //Color(0xffF4F4F4),
                      child: MaterialButton(
                        minWidth: (MediaQuery.of(context).size.width - 40),
                        // padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                        onPressed: () async {
                          if (!_formkey.currentState!.validate()) {
                            print("failed");
                            return;
                          }
                          print("success");
                          print(
                              "UID : $UID    password: ${passwordController.text}");
                          updatepassword();
                        },
                        child: Text(AppLocalizations.of(context)!.change_password,
                          style: TextStyle(
                              fontSize: 0.04 * (height - width),
                              color: Colors.white,
                              fontWeight: FontWeight.normal),
                        ),
                      )),
                  const SizedBox(
                    height: 30,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
