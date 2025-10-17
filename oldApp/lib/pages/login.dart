import 'dart:convert';
import 'dart:io';

import 'package:crownmonitor/pages/mainscreen.dart';
import 'package:crownmonitor/pages/verify_number.dart';
import 'package:crownmonitor/pages/wificonfiguration.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_switch/sliding_switch.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  @override
  LoginPageState createState() {
    return LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> formKeyBasicInfo = GlobalKey<FormState>();
  bool _autovalidate = false;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordNoController = TextEditingController();
  bool hidepass = true;
  bool rememberME = false;
  bool isAgent = false;

  @override
  void initState() {
    getsavedaccount();
    super.initState();
    //get saved account
  }

  void getsavedaccount() async {
    final prefs = await SharedPreferences.getInstance();
    String? usr, pass;
    usr = await prefs.getString('Username');
    pass = await prefs.getString('pass');
    if (usr != null && pass != null) {
      setState(() {
        usernameController.value = (TextEditingValue(text: usr!));
        passwordNoController.value = (TextEditingValue(text: pass!));
        // rememberME = true;
        // hidepass = true;
      });
    }
  }

  getdata() async {
    String salt = "12345678";
    String secret = "e216fe6d765ebbd05393ba598c8d0ac20b4d2122";
    String token =
        "4f07ebae2a2cb357608bb1c920924f7dd50536b00c09fb9d973441777ac66b4b";

    String action = "&action=queryCollectorInfo&pn=Q0819510312095";

    var data = salt + secret + token + action;
    print(data);

    var sign = utf8.encode(data);

    var output = sha1.convert(sign).toString();

    //   print(output);
    try {
      await callapi(output, salt, token, "Q0819510312095");
    } catch (e) {
      print(e);
    }
  }

  Future callapi(String sign, String salt, String token, String pn) async {
    String url =
        "http://api.dessmonitor.com/public/?sign=$sign&salt=${salt}&token=${token}&action=queryCollectorInfo&pn=${pn}";

    print(url);
    var response = await http.get(Uri.parse(url));

    print(response.body);

    if (response.statusCode >= 400) {
      throw ('Error');
    } else {
      print(response.body);
    }
  }

  authenticate() async {
    ///test//
    String urlrequest;

    ///test//
    final prefs = await SharedPreferences.getInstance();
    EasyLoading.show(status: 'Loading');
    var jsonResponse = null;
    var jsonResponseAgent = null;
    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C'
    };
    final body = jsonEncode({
      "Username": usernameController.text.toString(),
      "Password": passwordNoController.text.toString(),
      "IsAgent": isAgent
    });
    try {
      await http
          .post(
              Uri.parse('https://apis.crown-micro.net/api/MonitoringApp/Login'),
              headers: headers,
              body: body)
          .then((response) async {
        if (response.statusCode == 200) {
          jsonResponse = json.decode(response.body);
          if (!isAgent && jsonResponse['Token'] != null) {
            prefs.setString('token', jsonResponse['Token']);
            prefs.setString('Secret', jsonResponse['Secret']);
            prefs.setString('UserID', jsonResponse['UserID'].toString());
            prefs.setBool('loggedin', true);

            //test//
            // if (rememberME) {
            //   prefs.setString('Username', usernameController.text.toString());
            //   prefs.setString('pass', passwordNoController.text.toString());
            // } else {
            //   await prefs.remove('Username');
            //   await prefs.remove('pass');
            // }
            //test//

            EasyLoading.dismiss();
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => MainScreen()),
                (route) => false);
          } else if (isAgent && jsonResponse['Agentslist'] != null) {
            prefs.setBool('isInstaller', isAgent);
            await prefs.setString('Agentslist', jsonEncode(jsonResponse));

            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  actions: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                  title: Text('Tap to login',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: "Roboto",
                        letterSpacing: 1,
                        color: Colors.red,
                      )),
                  content: SizedBox(
                    width: 200,
                    height: 300,
                    child: ListView.builder(
                      physics: BouncingScrollPhysics(),
                      itemCount: jsonResponse['Agentslist'].length,
                      itemBuilder: (BuildContext context, int index) {
                        return ListTile(
                          trailing: Icon(Icons.arrow_right),
                          title: Text(
                              'SN: ${jsonResponse['Agentslist'][index]['SNNumber']}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Roboto",
                                letterSpacing: 1,
                                color: Colors.black,
                              )),
                          subtitle: Text(
                              'Username: ${jsonResponse['Agentslist'][index]['Username']}'
                                  .toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                fontFamily: "Roboto",
                                letterSpacing: 1,
                                color: Colors.black,
                              )),
                          onTap: () async {
                            EasyLoading.show(status: 'Loading');

                            final agent_body = jsonEncode({
                              "Username": jsonResponse['Agentslist'][index]
                                  ['Username'],
                              "Password": jsonResponse['Agentslist'][index]
                                  ['Password'],
                            });

                            await http
                                .post(
                                    Uri.parse(
                                        'https://apis.crown-micro.net/api/MonitoringApp/Login'),
                                    headers: headers,
                                    body: agent_body)
                                .then((responseAgent) async {
                              if (responseAgent.statusCode == 200) {
                                jsonResponseAgent =
                                    json.decode(responseAgent.body);
                                if (jsonResponseAgent['Token'] != null) {
                                  prefs.setString(
                                      'token', jsonResponseAgent['Token']);
                                  prefs.setString(
                                      'Secret', jsonResponseAgent['Secret']);
                                  prefs.setString('UserID',
                                      jsonResponseAgent['UserID'].toString());
                                  prefs.setBool('loggedin', true);

                                  EasyLoading.dismiss();
                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => MainScreen()),
                                      (route) => false);
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            );
          } else {
            EasyLoading.dismiss();
            showMessage('User Not found', true);
          }
        } else {
          showMessage(jsonResponse, true);
        }
        print(prefs.get('token'));
      });
    } catch (e) {
      EasyLoading.dismiss();
      showMessage(e.toString(), true);
    }
  }

  ///////////'''''''''''''''//for testing only///////////////////////////////////////////////////////''''''''''''''''''
  testauth() async {
    final prefs = await SharedPreferences.getInstance();
    EasyLoading.show(status: 'Loading');

    /////////////////only for TEsting /////////////////////
    ////remove after done///////////
    prefs.setString('token',
        "76ff6bb242961c695174aab83223b1a4f03b0e83dfcdbcc29e3192c02c6d587f");
    prefs.setString('Secret', "f3f24ac7bbb99df81ca71ec1980cc11e54efab4c");
    prefs.setBool('loggedin', true);
    EasyLoading.dismiss();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
        (route) => false);
    ///////////////////only for testing///////////////////////////
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    Color getColor(Set<WidgetState> states) {
      const Set<WidgetState> interactiveStates = <WidgetState>{
        WidgetState.pressed,
        WidgetState.hovered,
        WidgetState.focused,
      };
      if (states.any(interactiveStates.contains)) {
        return Colors.blue;
      }
      return Colors.red;
    }

    return Scaffold(
      body: Form(
          key: formKeyBasicInfo,
          autovalidateMode: _autovalidate
              ? AutovalidateMode.always
              : AutovalidateMode.disabled,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.only(left: 20),
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
                  height: 20,
                ),
                Image.asset('assets/login_banner.jpg'),
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  width: MediaQuery.of(context).size.width,
                  child: Text(
                    // "Mobile #",
                    AppLocalizations.of(context)!.username,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                TextFormField(
                  controller: usernameController,
                  autofocus: false,
                  // validator: (value) => Validations.minLength(value, 'Full name', 2),
                  decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.all(Radius.circular(40))),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.all(Radius.circular(40))),
                      // hintText: "+1 123 xx xxx",
                      // labelText: "Enter your Mobile #",
                      hintText: AppLocalizations.of(context)!.enter_username,
                      // labelText: "Enter your Username",
                      fillColor: Color(0xffF4F4F4),
                      filled: true),
                ),
                const SizedBox(
                  height: 30,
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
                          borderRadius: BorderRadius.all(Radius.circular(40))),
                      enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.all(Radius.circular(40))),
                      hintText: AppLocalizations.of(context)!.enter_password,
                      // labelText: "Enter your password",
                      border: OutlineInputBorder(),
                      fillColor: Color(0xffF4F4F4),
                      filled: true),
                ),
                const SizedBox(
                  height: 2,
                ),
                Row(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[

                        Switch(
                          activeTrackColor: Theme.of(context).primaryColor,
                          value: isAgent,
                          onChanged: (value) {
                            setState(() {
                              isAgent = value;
                            });
                          },
                        ),
                        SizedBox(width: 20),
                        Text(
                          'User Mode',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontSize: 15,
                          ),
                        ),

                      ],
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (BuildContext context) => VerifyNumber(
                                  fromregisterscreen: false,
                                  fromforgetpassscreen: true,
                                )));
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 15),
                        child: Text(AppLocalizations.of(context)!.forgot_password,
                            style: TextStyle(
                                fontSize: 0.03 * (height - width),
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),


                // SlidingSwitch(
                //   value: false,
                //   width: (MediaQuery.of(context).size.width - 40),
                //   onChanged: (bool value) {
                //     print(value);
                //   },
                //   height: 45,
                //   animationDuration: const Duration(milliseconds: 400),
                //   onTap: () {
                //     setState(() {
                //       isAgent = !isAgent;
                //     });
                //   },
                //   onDoubleTap: () {},
                //   onSwipe: () {
                //     setState(() {
                //       isAgent = !isAgent;
                //     });
                //   },
                //   textOff: AppLocalizations.of(context)!.toggle_user,
                //   textOn: AppLocalizations.of(context)!.toggle_installer,
                //   colorOn: Theme.of(context).primaryColor,
                //   colorOff: Theme.of(context).primaryColor,
                //   background: const Color(0xffF4F4F4),
                //   buttonColor: const Color(0xfff7f5f7),
                //   inactiveColor: const Color(0xff636f7b),
                // ),

                const SizedBox(
                  height: 20,
                ),
                Material(
                    elevation: 5.0,
                    borderRadius: BorderRadius.circular(40.0),
                    color: Theme.of(context).primaryColor,
                    child: MaterialButton(
                      minWidth: (MediaQuery.of(context).size.width - 40),
                      // padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                      onPressed: () async {
                        // Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //         builder: (context) => MainScreen())
                        //         );
                        await authenticate();
                      },
                      child: Text(
                        AppLocalizations.of(context)!.sign_in,
                        style: TextStyle(color: Colors.white),
                      ),
                    )),

                const SizedBox(
                  height: 20,
                ),

                Material(
                    // elevation: 5.0,
                    borderRadius: BorderRadius.circular(40.0),
                    color: const Color(0xffF4F4F4),
                    child: MaterialButton(
                      minWidth: (MediaQuery.of(context).size.width - 40),
                      // padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                      onPressed: () async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Wificonfiguration(),
                                maintainState: true));
                      },
                      child: Text(AppLocalizations.of(context)!.wifi_config),
                    )),
                const SizedBox(
                  height: 10,
                ),
                Material(
                    // elevation: 5.0,
                    borderRadius: BorderRadius.circular(40.0),
                    color: const Color(0xffF4F4F4),
                    child: MaterialButton(
                      minWidth: (MediaQuery.of(context).size.width - 40),
                      // padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                      onPressed: () async {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => VerifyNumber(
                                      fromregisterscreen: true,
                                      fromforgetpassscreen: false,
                                    ),
                                maintainState: true));
                      },
                      child: Text(AppLocalizations.of(context)!.register),
                    )),
                const SizedBox(
                  height: 30,
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.technical_support_tap,
                        style: TextStyle(
                            fontSize: 0.04 * width,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey.shade600)),
                    GestureDetector(
                      child: Icon(FontAwesomeIcons.whatsapp,
                          color: Colors.green, size: 32.0),
                      onTap: () async {
                        openwhatsapp('+923376322444');
                        // var uri = Uri.parse("https://wa.me/message/ZAIL7R6INAOYD1");
                        // await launchUrl(uri);
                      },
                    ),
                    Text(AppLocalizations.of(context)!.technical_support_icon,
                        style: TextStyle(
                            fontSize: 0.04 * width,
                            fontWeight: FontWeight.normal,
                            color: Colors.grey.shade600)),
                  ],
                ),
                // Material(
                //     elevation: 5.0,
                //     borderRadius: BorderRadius.circular(40.0),
                //     color: Theme.of(context).primaryColor,
                //     child: MaterialButton(
                //       minWidth: (MediaQuery.of(context).size.width - 40),
                //       // padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                //       onPressed: () async {
                //         // Navigator.push(
                //         //     context,
                //         //     MaterialPageRoute(
                //         //         builder: (context) => MainScreen())
                //         //         );
                //         await testauth();
                //       },
                //       child: const Text(
                //         'FOR Testing',
                //         style: TextStyle(color: Colors.white),
                //       ),
                //     )),
                const SizedBox(
                  height: 50,
                ),
              ],
            ),
          )),
    );
  }

  openwhatsapp(whatsapp) async {
    whatsapp = whatsapp.replaceAll('+', "");
    Uri whatsappURlAndroid =
        Uri.parse("whatsapp://send?phone=" + whatsapp + "&text=hello");

    Uri whatappURLIos =
        Uri.parse("https://wa.me/$whatsapp?text=${Uri.parse("hello")}");
    if (Platform.isIOS) {
      // for iOS phone only
      if (!await launchUrl(whatappURLIos))
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: new Text("whatsapp not installed")));
    } else {
      // android , web
      if (!await launchUrl(whatsappURlAndroid))
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: new Text("whatsapp not installed")));
    }
  }

  void showMessage(String errorMessage, bool isSuccess) {
    showDialog(
        context: context,
        builder: (BuildContext builderContext) {
          return AlertDialog(
            title: Text("Error",
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold)),
            content: Text(errorMessage,
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
}
