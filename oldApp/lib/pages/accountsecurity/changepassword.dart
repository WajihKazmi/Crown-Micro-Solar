import 'dart:convert';
import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_rc4/simple_rc4.dart';

class ChangePassword extends StatefulWidget {
  final String? username;
  const ChangePassword({Key? key, this.username}) : super(key: key);

  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  ////// Text Editing Controller /////////
  final TextEditingController currentaccount = TextEditingController();
  final TextEditingController oldpassword = TextEditingController();
  final TextEditingController newpassword = TextEditingController();
  final TextEditingController confirmpassword = TextEditingController();

  //variables
  final String newpassword_converted = '';

  ///////////////////////////Calling Change password interface///////////////////////////////
  Future ChnagePassword() async {
    var jsonResponse = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final Secret = prefs.getString('Secret') ?? '';
    print('token: $token');
    print('Secret: $Secret');
    String salt = "12345678";

    ///conversion///////
    var oldpass = utf8.encode(oldpassword.text);
    print('Old password: ${oldpassword.text}');
    var sha1_conv_oldpass = sha1.convert(oldpass).toString();

    var newpass = utf8.encode(newpassword.text);
    print('New password: ${newpassword.text}');
    var sha1_conv_newpass = sha1.convert(newpass).toString();

    var rc4 = RC4.fromBytes(utf8.encode(sha1_conv_oldpass));
    var rc4encoded = rc4.encodeBytes(utf8.encode(sha1_conv_newpass));
    var sha1newpass = hex.encode(rc4encoded);

    print('rc4 password: $sha1newpass');
    ///--------------test--------------------------7-4-22/////
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  String appName = packageInfo.appName;
  String packageName = packageInfo.packageName;
  String version = packageInfo.version;
  String buildNumber = packageInfo.buildNumber;
  String platform = Platform.isAndroid ? "android" : "ios";
  String Source = "1";

  String postaction =
      "&source=$Source&app_id=$packageName&app_version=$version&app_client=$platform";
  //////------------------------//////////////////////////////////
  

    String action = "&action=updatePassword&newpwd=" + sha1newpass;
    print('action: $action');
    var data = salt + Secret + action + postaction;
    var output = utf8.encode(data);
    var sign = sha1.convert(output).toString();
    print('Sign: $sign');
    String url =
        'http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}' + action + postaction;
    print(url);

    try {
      await http.post(Uri.parse(url)).then((response) {
        if (response.statusCode == 200) {
          jsonResponse = json.decode(response.body);
          if (jsonResponse['err'] == 0) {
            showMessage('Success', 'Password Changed Successfully.', true);
            Fluttertoast.showToast(
                msg: "Password Changed Succefully",
                toastLength: Toast.LENGTH_LONG,
                gravity: ToastGravity.CENTER,
                timeInSecForIosWeb: 2,
                backgroundColor: Colors.green,
                textColor: Colors.white,
                fontSize: 24.0);

            Navigator.pop(context);
          } else {
            showMessage('Error', '${jsonResponse['desc'].toString()}', true);
          }
        }
        print('passwordchange APIrequest response : ${jsonResponse}');
        print('APIrequest statucode : ${response.statusCode}');
      });
    } catch (e) {
      showMessage('Error', e.toString(), true);
    }
  }
  //////////////////////////////Calling Change password interface///////////////////////////////

  void showMessage(String title, String errorMessage, bool isSuccess) {
    showDialog(
        context: context,
        builder: (BuildContext builderContext) {
          return AlertDialog(
            title: Text(title),
            content: Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            actions: [
              TextButton(
                child: Text("Ok"),
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
  void setState(VoidCallback fn) {
    // TODO: implement setState
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  Widget _textfield(double width, double height, String name, String hint,
      bool enable, TextEditingController controller, bool ispassword) {
    return Column(
      children: [
        Container(
          height: height / 20,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(name,
                    style: TextStyle(
                        fontSize: 0.035 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600)),
                new Flexible(
                  child: TextField(
                      controller: controller,
                      style: TextStyle(
                          fontSize: 0.025 * width,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600),
                      enabled: enable,
                      obscureText: ispassword,
                      textAlign: TextAlign.end,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: hint,
                          hintStyle: TextStyle(
                              fontSize: 0.025 * width,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey.shade400),
                          fillColor: Colors.white,
                          filled: true)),
                )
              ],
            ),
          ),
        ),
        SizedBox(
          height: height / 250,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    currentaccount.text = widget.username!;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(
            'Change Password',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Icon(
              Icons.arrow_back,
              size: 25,
              color: Colors.white,
            ),
          ),
        ),
        body: Container(
            child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: height / 100,
              ),
              // Padding(
              //   padding: const EdgeInsets.all(8.0),
              //   child: Text(
              //       'Set SmartClient password can log in directly with account SmartClient',
              //       style: Theme.of(context).textTheme.bodyText1),
              // ),
              _textfield(width, height, 'Current account', 'user', false,
                  currentaccount, false),
              SizedBox(
                height: height / 1000,
              ),
              _textfield(width, height, 'Old password',
                  'Please Enter the old password', true, oldpassword, true),
              SizedBox(
                height: height / 1000,
              ),
              _textfield(width, height, 'New password',
                  'Please Enter the New password', true, newpassword, true),
              SizedBox(
                height: height / 1000,
              ),
              _textfield(
                  width,
                  height,
                  'Confirm password',
                  'Please Enter the Confirm password',
                  true,
                  confirmpassword,
                  true),
              SizedBox(
                height: height / 10,
              ),
              Material(
                  // elevation: 5.0,
                  borderRadius: BorderRadius.circular(5.0),
                  color: Theme.of(context).primaryColor,
                  child: MaterialButton(
                    minWidth: (MediaQuery.of(context).size.width - 280),
                    // padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    onPressed: () {
                      if (newpassword.text.length <= 5) {
                        Fluttertoast.showToast(
                            msg:
                                "New Password must be atleast 6 charachter long",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 2,
                            textColor: Colors.white,
                            fontSize: 24.0);
                      } else if (newpassword.text == confirmpassword.text) {
                         // ChnagePassword();         ///TODO implement logic to change password accroding to crown
                      } else {
                        Fluttertoast.showToast(
                            msg:
                                "New Password and Confirm Password does not match!",
                            toastLength: Toast.LENGTH_LONG,
                            gravity: ToastGravity.CENTER,
                            timeInSecForIosWeb: 2,
                            textColor: Colors.white,
                            fontSize: 24.0);
                      }
                    },
                    child: Text(
                      'Change Password',
                      style: TextStyle(
                          fontSize: 0.045 * width,
                          fontWeight: FontWeight.normal,
                          color: Colors.white),
                    ),
                  )),
            ],
          ),
        )));
  }
}
