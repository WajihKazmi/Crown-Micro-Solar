import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class contactinfoscreen extends StatefulWidget {
  const contactinfoscreen({Key? key}) : super(key: key);

  @override
  _contactinfoscreenState createState() => _contactinfoscreenState();
}

class _contactinfoscreenState extends State<contactinfoscreen> {
  @override
  Widget build(BuildContext context) {
    String Mail = 'support@crown-micro.net';
    String url = 'https://crownmicroglobal.com';
    String whatsapp = '+923376322444';

    // final TextEditingController version = TextEditingController();
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: AppBar(
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
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(
            'Contact Information',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          centerTitle: true,
        ),
        body: Container(
            child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: height / 20,
              ),

              Container(
                color: Colors.transparent,
                width: 0.6 * width,
                child: Container(
                    color: Colors.transparent,
                    child: Image(
                        image: AssetImage('assets/crown-black-logo.png'))),
              ),

              //  Image(image: AssetImage('assets/app_icon.png'))),
              SizedBox(
                height: height / 30,
              ),
              Divider(),
              SizedBox(
                height: height / 50,
              ),
              RichText(
                  text: TextSpan(children: [
                TextSpan(
                    style: TextStyle(
                        fontSize: 0.04 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600),
                    text: "Website:      "),
                TextSpan(
                    style: TextStyle(
                        fontSize: 0.04 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.blue.shade600),
                    text: url,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final Uri url = Uri.parse("https://crown-micro.com/pk-en/");
                        if (!await launchUrl(url)) throw 'Could not launch $url';
                      }),
              ])),
              SizedBox(
                height: height / 50,
              ),
              Divider(),
              SizedBox(
                height: height / 50,
              ),
              RichText(
                  text: TextSpan(children: [
                TextSpan(
                    style: TextStyle(
                        fontSize: 0.04 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600),
                    text: "Email:      "),
                TextSpan(
                    style: TextStyle(
                        fontSize: 0.04 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.blue.shade600),
                    text: Mail,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () async {
                        final Uri params = Uri(
                            scheme: 'mailto', path: 'support@crown-micro.net');
                        //String url = params.toString();
                        if (!await launchUrl(params)) throw 'Could not launch $url';
                      }),
              ])),
              SizedBox(
                height: height / 50,
              ),
              Divider(),
              // SizedBox(
              //   height: height / 50,
              // ),
              // RichText(
              //     text: TextSpan(children: [
              //   TextSpan(
              //       style: TextStyle(
              //           fontSize: 0.04 * width,
              //           fontWeight: FontWeight.normal,
              //           color: Colors.grey.shade600),
              //       text: "Whatsapp:      "),
              //   TextSpan(
              //       style: TextStyle(
              //           fontSize: 0.04 * width,
              //           fontWeight: FontWeight.normal,
              //           color: Colors.blue.shade600),
              //       text: whatsapp,
              //       recognizer: TapGestureRecognizer()
              //         ..onTap = () async {
              //           var whatsapp_url =Uri.parse("whatsapp://send?phone=$whatsapp&text=");
              //           if (!await launchUrl(whatsapp_url)) throw 'Could not launch $url';
              //         }),
              // ])),
              // SizedBox(
              //   height: height / 50,
              // ),
              // Divider(),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Technical Support tap ', 
                    style: TextStyle(
                        fontSize: 0.04 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600)
                  ),

                  GestureDetector(
                    child: Icon(FontAwesomeIcons.whatsapp, 
                    color: Colors.green, size: 32.0), 
                    onTap: () async {
                      openwhatsapp('+923376322444');
                      // var uri = Uri.parse("https://wa.me/message/ZAIL7R6INAOYD1");
                      // await launchUrl(uri);
                    },
                  ),

                  Text(' Icon ', 
                    style: TextStyle(
                        fontSize: 0.04 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600)
                  ),
                ],
              ),

              SizedBox(
                height: height / 50,
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Support Videos ', 
                    style: TextStyle(
                        fontSize: 0.04 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600)
                  ),

                  GestureDetector(
                    child: Icon(FontAwesomeIcons.youtube, 
                    color: Colors.green, size: 32.0), 
                    onTap: () async {
                      openUrl("https://youtube.com/@crownmicrocustomercare");
                    },
                  ),

                  Text(' Icon ', 
                    style: TextStyle(
                        fontSize: 0.04 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600)
                  ),
                ],
              ),

              SizedBox(
                height: height / 50,
              ),
              Divider(),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(child: Icon(FontAwesomeIcons.facebook, color: Colors.blue, size: 32.0), onTap: () async {
                    openUrl("https://www.facebook.com/crownmicroglobal");
                  },),

                  GestureDetector(child: Icon(FontAwesomeIcons.youtube, color: Colors.red, size: 32.0), onTap: () async {
                    openUrl("https://www.youtube.com/channel/UCtIXOaaxeXbDnfj-3gieZtg");
                  },),

                  GestureDetector(child: Icon(FontAwesomeIcons.linkedin, color: Colors.blue, size: 32.0), onTap: () async {
                    openUrl("https://www.linkedin.com/in/crown-micro-global-ba95271b6/");
                  },),

                  GestureDetector(child: Icon(FontAwesomeIcons.instagram, color: Colors.red, size: 32.0), onTap: () async {
                    openUrl("https://www.instagram.com/crownmicroglobal/");
                  },),
                ],
              )
            ],
          ),
        )));
  }

  openwhatsapp(whatsapp) async {
    whatsapp = whatsapp.replaceAll('+', "");
    Uri whatsappURlAndroid = Uri.parse("whatsapp://send?phone=" + whatsapp + "&text=hello");
    
    Uri whatappURLIos = Uri.parse("https://wa.me/$whatsapp?text=${Uri.parse("hello")}");
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

  Future<void> openUrl(String url) async {
    final _url = Uri.parse(url);
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $_url');
    }
  }
}
