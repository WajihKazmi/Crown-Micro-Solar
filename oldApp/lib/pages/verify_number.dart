import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:crownmonitor/pages/verify_otp.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VerifyNumber extends StatefulWidget {
  bool fromregisterscreen = false;
  bool fromforgetpassscreen = false;
  VerifyNumber(
      {Key? key,
      required this.fromforgetpassscreen,
      required this.fromregisterscreen})
      : super(key: key);

  @override
  VerifyNumberState createState() {
    return VerifyNumberState();
  }
}

class VerifyNumberState extends State<VerifyNumber> {
  final GlobalKey<FormState> formKeyLogin = GlobalKey<FormState>();
  bool _autovalidate = false;

  late String verificationId = "";

  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController(); // text: '3222152033'
  String initialCountry = 'PK';
  PhoneNumber number = PhoneNumber(isoCode: 'PK');
  String dialcode = "+92";

  bool _isKeyboardOpen = false;
  @protected
  void initState() {
    super.initState();

    var keyboardVisibilityController = KeyboardVisibilityController();

    keyboardVisibilityController.onChange.listen((bool visible) {
      setState(() {
        _isKeyboardOpen = visible;
      });
    });
  }

  @override
  void setState(ui.VoidCallback fn) {
    // TODO: implement setState
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return MaterialApp(
      home: Scaffold(
        body: Stack(
          alignment: AlignmentDirectional.topCenter,
          children: <Widget>[
            Container(
                padding: const EdgeInsets.all(60),
                width: 300,
                child: _isKeyboardOpen
                    ? Container()
                    : Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.fitWidth,
                      )),
            Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // SizedBox(height: 100,),
                Container(
                  child: Text(AppLocalizations.of(context)!.enter_your_email,
                      style: TextStyle(
                        fontSize: 0.05 * (height - width),
                        fontWeight: FontWeight.normal,
                        color: Colors.blue,
                      )),
                ),
                SizedBox(
                  height: 5,
                ),
                widget.fromforgetpassscreen
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          AppLocalizations.of(context)!.recieve_your_six_digit_code_change_password,
                          style: TextStyle(
                            fontSize: 0.04 * (height - width),
                            fontWeight: FontWeight.w300,
                            color: Colors.black,
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.recieve_your_six_digit_code_proceed,
                        style: TextStyle(
                          fontSize: 0.04 * (height - width),
                          fontWeight: FontWeight.w300,
                          color: Colors.black,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                const SizedBox(height: 50),
                Form(
                  key: formKeyLogin,
                  child: Container(
                    margin: const EdgeInsets.only(right: 20, left: 20),
                    width: 380,
                    child: TextFormField(
                    controller: emailController,
                    autofocus: false,
                    // validator: (value) => Validations.minLength(value, 'Full name', 2),
                    validator: (val) {
                      if ( !RegExp(
                      r"^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$").hasMatch(val!.trim())) {
                        return 'Please enter a valid email';
                      } else if (val.isEmpty) {
                        return 'Email required';
                      } else
                        return null;
                    },
                    decoration: const InputDecoration(
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius:
                                BorderRadius.all(Radius.circular(40))),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius:
                                BorderRadius.all(Radius.circular(40))),
                        hintText: "abc@example.com",
                        // labelText: "Enter your email",
                        fillColor: Color(0xffF4F4F4),
                        filled: true),
                  ),
                  ),
                )
              ],
            )),
            widget.fromforgetpassscreen
                ? Container()
                : Positioned(
                    bottom: 80,
                    left: 20,
                    right: 20,
                    child: Directionality(
                      textDirection: ui.TextDirection.rtl,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: <TextSpan>[
                            TextSpan(
                                text: AppLocalizations.of(context)!.tap_register_to_agree,
                                style: TextStyle(
                                  fontSize: 0.03 * (height - width),
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black45,
                                )),
                            TextSpan(
                                text: AppLocalizations.of(context)!.term_condition_and_privacy_policy,
                                style: TextStyle(
                                    fontSize: 0.03 * (height - width),
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
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
                      // Navigator.pushAndRemoveUntil(
                      //     context,
                      //     MaterialPageRoute(
                      //         builder: (context) =>
                      //             VerifyOTP(verificationId: verificationId),
                      //         maintainState: true),
                      //     (route) => false);
                      if (formKeyLogin.currentState!.validate()) {
                        formKeyLogin.currentState!.save();
                        _autovalidate = false;

                        EasyLoading.show(status: 'Loading');
                        print(" the number: ${dialcode + phoneNumberController.text}");

                        EasyLoading.show(status: 'Loading');
                        
                        Map<String, String> headers = {
                          'Content-Type': 'application/json',
                          'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C'
                        };
                        
                        final body = jsonEncode({
                          "Email": emailController.text,
                        });

                        await http.post(Uri.parse('https://apis.crown-micro.net/api/MonitoringApp/PushShortCode'),
                                headers: headers,
                                body: body)
                            .then((response) async {

                          if (response.statusCode == 200) {
                            
                            // setState(() {
                            //   this.verificationId = verificationId;
                            // });
                            await EasyLoading.dismiss();
                            await Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => VerifyOTP(
                                        fromforgetpassscreen: widget.fromforgetpassscreen,
                                        // verificationId: verificationId,
                                        emailAddress: emailController.text),
                                    maintainState: true),
                                (route) => false);
                          }

                        });

                        // FirebaseAuth.instance.verifyPhoneNumber(
                        //   //phoneNumber: '+92' + phoneNumberController.text,
                        //   phoneNumber:
                        //       dialcode + phoneNumberController.text,
                        //   verificationCompleted: (phoneAuthCredential) async {
                        //     print('>>>> >>>>>>>>>>>>>>>>>>>>>>>> success');
                        //     await EasyLoading.dismiss();
                        //     // setState(() {

                        //     // });
                        //     //signInWithPhoneAuthCredential(phoneAuthCredential);
                        //   },
                        //   verificationFailed: (verificationFailed) async {
                        //     print('>>>> >>>>>>>>>>>>>>>>>>>>>>>> failed');
                        //     await EasyLoading.dismiss();

                        //     //testing ********************* ----------------------------------///
                        //     // await Navigator.pushAndRemoveUntil(
                        //     //   context,
                        //     //   MaterialPageRoute(
                        //     //       builder: (context) => VerifyOTP(
                        //     //         fromforgetpassscreen: widget.fromforgetpassscreen,
                        //     //           verificationId: verificationId,
                        //     //           phoneNumber:
                        //     //               '+92' + phoneNumberController.text),
                        //     //       maintainState: true),
                        //     //   (route) => false);

                        //     //testing ********************* ---------------------------------//

                        //     // setState(() {
                        //     //   // showLoading = false;
                        //     // });
                        //   },
                        //   codeSent: (verificationId, resendingToken) async {
                        //     setState(() {
                        //       this.verificationId = verificationId;
                        //     });
                        //     await EasyLoading.dismiss();
                        //     await Navigator.pushAndRemoveUntil(
                        //         context,
                        //         MaterialPageRoute(
                        //             builder: (context) => VerifyOTP(
                        //                 fromforgetpassscreen:
                        //                     widget.fromforgetpassscreen,
                        //                 verificationId: verificationId,
                        //                 phoneNumber:
                        //                     dialcode + phoneNumberController.text),
                        //             maintainState: true),
                        //         (route) => false);
                        //   },
                        //   codeAutoRetrievalTimeout: (verificationId) async {},
                        // );
                      } else {
                        if (this.mounted) setState(() => _autovalidate = true);
                      }
                    },
                    child: Text(
                      widget.fromforgetpassscreen ? AppLocalizations.of(context)!.get_otp : AppLocalizations.of(context)!.register,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void showMessage(String errorMessage) {
    showDialog(
        context: context,
        builder: (BuildContext builderContext) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text(errorMessage),
            actions: [
              TextButton(
                child: const Text("Ok"),
                onPressed: () async {
                  Navigator.of(builderContext).pop();
                },
              )
            ],
          );
        }).then((value) {});
  }

  @override
  void dispose() {
    phoneNumberController.dispose();
    super.dispose();
  }
}
