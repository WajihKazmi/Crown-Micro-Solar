import 'dart:convert';

import 'package:crownmonitor/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;

class RegisterPage extends StatefulWidget {

  final String emailAddress;

  RegisterPage({required this.emailAddress});

  @override
  RegisterPageState createState() {
    return RegisterPageState();
  }
}

class RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> formKeyBasicInfo = GlobalKey<FormState>();
  bool _autovalidate = false;
  final TextEditingController fullnameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController mobileNoController = TextEditingController();
  final TextEditingController passwordNoController = TextEditingController();
    final TextEditingController confirmpasswordNoController = TextEditingController();

  final TextEditingController serialNoController = TextEditingController();
  bool hidepass = true;

  @override
  void initState() {
    super.initState();
  }

  register() async {
    EasyLoading.show(status: 'Loading');
    var jsonResponse = null;
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C'
    };
    final body = jsonEncode({
      "Name": fullnameController.text.trim().toString(),
      "Email": widget.emailAddress,
      "MobileNo": mobileNoController.text.trim().toString(),
      "Username": usernameController.text.trim().toString(),
      "Password": passwordNoController.text.toString(),
      "SN": serialNoController.text.trim().toString()
    });

    await http.post(Uri.parse('https://apis.crown-micro.net/api/MonitoringApp/Register'), headers: headers, body: body).then((response) {
      if (response.statusCode == 200) {
        jsonResponse = json.decode(response.body);
        if (jsonResponse['Description'] == "Success") {
          EasyLoading.dismiss();
          showMessage('User Registered Successfully, Please Login', true);
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => LoginPage()));
        } else {
          EasyLoading.dismiss();

          showMessage('Sorry! Account registration failed' + "\nReason: "+ jsonResponse['Description'], false);
        }
      }
      print(response.body);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Form(
            key: formKeyBasicInfo,
            autovalidateMode: _autovalidate
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 40,bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        alignment: Alignment.topLeft,
                        child: Text(AppLocalizations.of(context)!.register,
                            style: Theme.of(context).textTheme.displayLarge),
                      ),
                      Container(
                        alignment: Alignment.topRight,
                        child: Image.asset(
                          'assets/app_icon.png',
                          height: 50,
                          width: 50,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: MediaQuery.of(context).size.width,
                    child: Text(
                      AppLocalizations.of(context)!.full_name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextFormField(
                    controller: fullnameController,
                    autofocus: false,
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
                        hintText: "John Alex",
                        // labelText: "Enter your full name",
                        fillColor: Color(0xffF4F4F4),
                        filled: true),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: MediaQuery.of(context).size.width,
                    child: Text(
                      AppLocalizations.of(context)!.mobile_no,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextFormField(
                    controller: mobileNoController,
                    autofocus: false,
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
                        hintText: "+92 300 1234567",
                        // labelText: "Enter your full name",
                        fillColor: Color(0xffF4F4F4),
                        filled: true),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: MediaQuery.of(context).size.width,
                    child: Text(
                      AppLocalizations.of(context)!.username,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextFormField(
                    controller: usernameController,
                    autofocus: false,
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
                        hintText: "user001",
                        // labelText: "Enter your Username",
                        fillColor: Color(0xffF4F4F4),
                        filled: true),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    width: MediaQuery.of(context).size.width,
                    child: Text(
                      AppLocalizations.of(context)!.password,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextFormField(
                    obscureText: hidepass,
                    controller: passwordNoController,
                    autofocus: false,
                     validator: (val) {
                      if (!val!.isEmpty && val.length < 6) {
                        return 'Password must be at least 6 digits long';
                      } else if (val.isEmpty) {
                        return 'Password required';
                      } else
                        return null;
                    },
                    // validator: (value) => Validations.minLength(value, 'Full name', 2),
                    decoration:  InputDecoration(
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
                        hintText: "Enter Password",
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
                    child: Text(
                      AppLocalizations.of(context)!.confirm_password,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextFormField(
                   obscureText: hidepass,
                    controller: confirmpasswordNoController,
                    autofocus: false,
                     validator: (val) {
                      if (!val!.isEmpty && val != passwordNoController.text) {
                        return  AppLocalizations.of(context)!.password_does_not_match;
                      } else if (val.isEmpty) {
                        return AppLocalizations.of(context)!.confirm_password_require;
                      } else
                        return null;
                    },
                    // validator: (value) => Validations.minLength(value, 'Full name', 2),
                    decoration:  InputDecoration(
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
                        hintText: AppLocalizations.of(context)!.confirm_password_require,
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
                    child: Text(
                      AppLocalizations.of(context)!.wifi_module_pn,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  TextFormField(
                    controller: serialNoController,
                    autofocus: false,
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
                        hintText: "e.g W0011223344556",
                        // labelText: "Enter your password",
                        border: OutlineInputBorder(),
                        fillColor: Color(0xffF4F4F4),
                        filled: true),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Material(
                      elevation: 5.0,
                      borderRadius: BorderRadius.circular(40.0),
                      color: Theme.of(context).primaryColor,
                      child: MaterialButton(
                        minWidth: (MediaQuery.of(context).size.width - 40),
                        // padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                        onPressed: () async {
                           
                           if (!formKeyBasicInfo.currentState!.validate()) {
                            return;
                          }

                          await register();
                        },
                        child: Text(AppLocalizations.of(context)!.register,
                          style: TextStyle(color: Colors.white),
                        ),
                      )),
                ],
              ),
            )),
      ),
    );
  }

  void showMessage(String errorMessage, bool isSuccess) {
    showDialog(
        context: context,
        builder: (BuildContext builderContext) {
          return AlertDialog(
            title: Text( isSuccess ? "Success":"Error", style: TextStyle(
                    fontSize: 15,
                    color:isSuccess ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold)),
            content: Text(
              errorMessage,
              style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold),
            ),
            actions: [
              TextButton(
                child: Text("Ok", style: TextStyle(
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
}
