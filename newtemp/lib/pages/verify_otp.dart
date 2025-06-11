import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:crownmonitor/pages/forgotpassword.dart';
import 'package:crownmonitor/pages/register.dart';
import 'package:crownmonitor/pages/verify_number.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class VerifyOTP extends StatefulWidget {
  // final String verificationId;
  final String emailAddress;
  bool fromforgetpassscreen = false;

  VerifyOTP({required this.emailAddress, required this.fromforgetpassscreen});

  @override
  VerifyOTPState createState() => VerifyOTPState();
}

class VerifyOTPState extends State<VerifyOTP> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int val = 1;

  final TextEditingController controller = TextEditingController();
  String initialCountry = 'PK';
  PhoneNumber number = PhoneNumber(isoCode: 'PK');

  TextEditingController ctrl1 = new TextEditingController();
  TextEditingController ctrl2 = new TextEditingController();
  TextEditingController ctrl3 = new TextEditingController();
  TextEditingController ctrl4 = new TextEditingController();
  TextEditingController ctrl5 = new TextEditingController();
  TextEditingController ctrl6 = new TextEditingController();

  FocusNode focusNode1 = FocusNode();
  FocusNode focusNode2 = FocusNode();
  FocusNode focusNode3 = FocusNode();
  FocusNode focusNode4 = FocusNode();
  FocusNode focusNode5 = FocusNode();
  FocusNode focusNode6 = FocusNode();
  String code = "";
  int countdown = 300;

  bool verified = false;
  bool isLoading = false;

  bool _isKeyboardOpen = false;

  @protected
  void initState() {
    super.initState();

    startStopWatch();

    var keyboardVisibilityController = KeyboardVisibilityController();

    keyboardVisibilityController.onChange.listen((bool visible) {
      if (mounted) setState(() => _isKeyboardOpen = visible);
    });
  }

  void verifyCode() async {

    if (code.length != 6) {
      showMessage("Type Six Digit Code", false);

      return;
    } else {
      
      try {
        EasyLoading.show(status: 'Verifying');
                        
        Map<String, String> headers = {
          'Content-Type': 'application/json',
          'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C'
        };
        
        final body = jsonEncode({
          "Email": widget.emailAddress,
          "ShortCode": code
        });

        await http.post(Uri.parse('https://apis.crown-micro.net/api/MonitoringApp/VerifyShortCode'),
                headers: headers,
                body: body)
            .then((response) async {

          if (response.statusCode == 200) {
            EasyLoading.dismiss();
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => widget.fromforgetpassscreen
                        ? forgotpassword(
                            emailAddress: widget.emailAddress,
                            ischangingpass: false,
                          )
                        : RegisterPage(emailAddress: widget.emailAddress),
                    maintainState: true),
                (route) => false);
          }
        });

      } catch (e) {
        EasyLoading.dismiss();
        print(e);
        showMessage('Error! Code Not verified', false);
      }
    }
  }

  // void signInWithPhoneAuthCredential(PhoneAuthCredential phoneAuthCredential) async {
  //   if (code.length != 6) {
  //     showMessage("Type Six Digit Code", false);

  //     return;
  //   } else {
      

  //     try {
  //       EasyLoading.show(status: 'Verifying');
  //       final authCredential =
  //           await _auth.signInWithCredential(phoneAuthCredential);

  //       if (authCredential.user != null) {
  //         EasyLoading.dismiss();
  //         Navigator.pushAndRemoveUntil(
  //             context,
  //             MaterialPageRoute(
  //                 builder: (context) => widget.fromforgetpassscreen
  //                     ? forgotpassword(
  //                         phonenumber: widget.phoneNumber,
  //                         ischangingpass: false,
  //                       )
  //                     : RegisterPage(phoneNumber: widget.phoneNumber),
  //                 maintainState: true),
  //             (route) => false);
  //       }
  //     } on FirebaseAuthException catch (e) {
  //       EasyLoading.dismiss();
  //       print(e);
  //       showMessage('Error! Code Not verified', false);
  //     }
  //   }
  // }

  var swtach = Stopwatch();

  final duration = const Duration(seconds: 1);

  void startTimer() {
    Timer(duration, keepRunning);
  }

  void keepRunning() {
    if (swtach.isRunning) {
      startTimer();
    }

    if (mounted) {
      setState(() {
        countdown = countdown - 1;
      });
    }

    if (verified) stopStopWatch();

    if (countdown == 0 && !verified) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => VerifyNumber(
                    fromregisterscreen: false,
                    fromforgetpassscreen: widget.fromforgetpassscreen,
                  ),
              maintainState: true),
          (route) => false);
    }
  }

  void startStopWatch() {
    swtach.start();
    startTimer();
  }

  void stopStopWatch() {
    swtach.stop();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: <Widget>[
            Container(
                padding: EdgeInsets.all(60),
                width: 400,
                child: _isKeyboardOpen
                    ? Container()
                    : Image.asset('assets/logo.png', fit: BoxFit.fitWidth)),
            Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // SizedBox(height: 100,),
                Container(
                  child: Text("Verify Phone Number",
                      style: TextStyle(
                          fontSize: 0.04 * (height - width),
                          color: Colors.blue,
                          fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 5,
                ),
                Container(
                  width: 250,
                  child: Text(
                    "Enter the OTP you have received",
                    style: TextStyle(
                        fontSize: 0.035 * (height - width),
                        color: Colors.grey,
                        fontWeight: FontWeight.normal),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: 50),
                Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      getField("1", ctrl1, focusNode1),
                      SizedBox(width: 5.0),
                      getField("2", ctrl2, focusNode2),
                      SizedBox(width: 5.0),
                      getField("3", ctrl3, focusNode3),
                      SizedBox(width: 5.0),
                      getField("4", ctrl4, focusNode4),
                      SizedBox(width: 5.0),
                      getField("5", ctrl5, focusNode5),
                      SizedBox(width: 5.0),
                      getField("6", ctrl6, focusNode6),
                      SizedBox(width: 5.0),
                    ],
                  ),
                )
              ],
            )),
            Positioned(
              bottom: _isKeyboardOpen ? 80 : 200,
              left: 60,
              right: 60,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: "OTP code expires",
                        style: TextStyle(color: Colors.grey, letterSpacing: 1)),
                    TextSpan(
                        text: ' ' + countdown.toString() + ' ',
                        style: TextStyle(color: Colors.grey, letterSpacing: 1)),
                    TextSpan(
                        text: "seconds",
                        style: TextStyle(color: Colors.grey, letterSpacing: 1)),
                    TextSpan(
                        text: ' ',
                        style: TextStyle(color: Colors.grey, letterSpacing: 1)),
                    TextSpan(
                        text: "Didn't get the code?",
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                    TextSpan(
                        text: ' ',
                        style: TextStyle(color: Colors.grey, letterSpacing: 1)),
                    TextSpan(
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => VerifyNumber(
                                          fromregisterscreen: false,
                                          fromforgetpassscreen:
                                              widget.fromforgetpassscreen,
                                        ),
                                    maintainState: true),
                                (route) => false);
                          },
                        text: "Resend Code",
                        style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Material(
                  elevation: 5.0,
                  borderRadius: BorderRadius.circular(40.0),
                  color: const Color(0xffE51837),
                  child: MaterialButton(
                    minWidth: (MediaQuery.of(context).size.width - 40),
                    // padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    onPressed: () async {
                      verifyCode();                      
                    },
                    child: const Text(
                      'Continue',
                      style: TextStyle(color: Colors.white),
                    ),
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget getField(String key, TextEditingController ctrl, FocusNode fn) =>
      SizedBox(
        height: 40.0,
        width: 35.0,
        child: TextField(
          key: Key(key),
          controller: ctrl,
          expands: false,
          autofocus: key.contains("1") ? true : false,
          focusNode: fn,
          onChanged: (String value) {
            if (value.length == 1) {
              code += value;
              switch (code.length) {
                case 1:
                  FocusScope.of(context).requestFocus(focusNode2);
                  break;
                case 2:
                  FocusScope.of(context).requestFocus(focusNode3);
                  break;
                case 3:
                  FocusScope.of(context).requestFocus(focusNode4);
                  break;
                case 4:
                  FocusScope.of(context).requestFocus(focusNode5);
                  break;
                case 5:
                  FocusScope.of(context).requestFocus(focusNode6);
                  break;
                default:
                  FocusScope.of(context).requestFocus(FocusNode());
                  break;
              }
            } else {
              clearAll();
              FocusScope.of(context).requestFocus(focusNode1);
            }
          },
          // maxLengthEnforced: false,
          textAlign: TextAlign.center,
          cursorColor: Colors.black,
          keyboardType: TextInputType.number,
          style: TextStyle(
              fontSize: 20.0, fontWeight: FontWeight.w600, color: Colors.black),
          decoration: InputDecoration(
              contentPadding: const EdgeInsets.only(
                  bottom: 10.0, top: 10.0, left: 4.0, right: 4.0),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  borderSide: BorderSide(color: Colors.blue, width: 2.25)),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5.0),
                  borderSide: BorderSide(color: Colors.blue))),
        ),
      );

  signIn(String verificationId) async {
    // SessionManager prefs = SessionManager();

    // if (code.length != 6) {
    //   showMessage("Type Six Digit Code", false);
    //   return;
    // }

    // await EasyLoading.show(status: '');

    // try {
    //   final AuthCredential credential = PhoneAuthProvider.credential(
    //     verificationId: verificationId,
    //     smsCode: code
    //   );

    //   final User user = (await _auth.signInWithCredential(credential)).user;

    //   if (user != null) {
    //     if (this.mounted) setState(() => verified = true);

    //     UserService userRestSrv = UserService();

    //     DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    //     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    //     String token = await FirebaseMessaging.instance.getToken();
    //     var result = await userRestSrv.login(user.phoneNumber, androidInfo.brand, androidInfo.androidId, token, user.uid);

    //     if (result == null) {
    //       await EasyLoading.dismiss();
    //       await EasyLoading.showToast('Internal Server Error', duration: Duration(seconds: 3));
    //       Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Login(), maintainState: true), (route) => false);
    //     }

    //     if (result.data['status']["ResponseCode"] == "01") {
    //       await EasyLoading.dismiss();
    //       await EasyLoading.showToast(result.data['status']["responseDescription"], duration: Duration(seconds: 3));
    //       Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Login(), maintainState: true), (route) => false);
    //     }

    //     if (result.data['status']['responseDescription'] == 'Success') {
    //       await prefs.setLoggedIn();
    //       await EasyLoading.dismiss();

    //       if (result.data['userProfile'] == null) {

    //         Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => BasicInfo(user.phoneNumber, user.uid), maintainState: true), (route) => false);

    //       } else {
    //         await prefs.setUserProfile(result.data['userProfile']);

    //         if (result.data['driver'] != null) await prefs.setDriverProfile(result.data['driver']);

    //         if (result.data['listVehicles'] != null) await prefs.setVehicle(result.data['listVehicles']);

    //         Navigator.pushNamed(context, '/profile-type');
    //       }

    //     }

    //   } else {
    //     this.clearAll();

    //     await EasyLoading.dismiss();

    //     showMessage("Failed to verify phone code, please try again", false);
    //   }
    // } catch (e) {
    //   print(e);
    //   await EasyLoading.dismiss();
    //   Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => Login(), maintainState: true), (route) => false);
    // }
  }

  void showMessage(String errorMessage, bool isSuccess) {
    showDialog(
        context: context,
        builder: (BuildContext builderContext) {
          return AlertDialog(
            title: Text(
              "Error",
              style: Theme.of(context).textTheme.displaySmall,
            ),
            content: Text(
              errorMessage,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            actions: [
              TextButton(
                child: Text("OK"),
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

  clearAll() {
    ctrl1.clear();
    ctrl2.clear();
    ctrl3.clear();
    ctrl4.clear();
    ctrl5.clear();
    ctrl6.clear();
    code = '';
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
