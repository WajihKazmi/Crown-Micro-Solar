import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class aboutus extends StatefulWidget {
  const aboutus({Key? key}) : super(key: key);

  @override
  _aboutusState createState() => _aboutusState();
}

class _aboutusState extends State<aboutus> {
  @override
  Widget build(BuildContext context) {
    String introduction = AppLocalizations.of(context)!.about_us_introduction;

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
            AppLocalizations.of(context)!.about_us,
            style: Theme.of(context).textTheme.displayMedium,
          ),
          centerTitle: true,
        ),
        body: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: height / 40,
                  ),

                  Container(
                    color: Colors.transparent,
                    width: 0.3 * width,
                    child: Container(
                        color: Colors.transparent,
                        child: Image(
                            image: AssetImage('assets/crown-black-logo.png'))),
                  ),

                  //  Image(image: AssetImage('assets/app_icon.png'))),

                  Divider(),
                  Container(
                    width: 0.9 * width,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text( AppLocalizations.of(context)!.introduction,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 0.04 * (height - width),
                              fontWeight: FontWeight.normal,
                              color: Colors.black)),
                    ),
                  ),
                  Container(
                    width: 0.9 * width,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(introduction.toUpperCase(),
                          softWrap: true,
                          textAlign: TextAlign.start,
                          style: TextStyle(
                              fontSize: 0.03 * (height - width),
                              fontWeight: FontWeight.normal,
                              color: Colors.grey.shade500)),
                    ),
                  ),
                  Divider(),
                  Container(
                    padding: EdgeInsets.all(8),
                    color: Colors.transparent,
                    width: 1 * width,
                    //height: 0.8 * height,
                    child: Container(
                        color: Colors.transparent,
                        child: Image(
                          image: AssetImage('assets/aboutus (1).jpeg'),
                          fit: BoxFit.fill,
                        )),
                  ),
                  Divider(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                    color: Colors.transparent,
                    width: 1 * width,
                    //height: 0.8 * height,
                    child: Container(
                        color: Colors.transparent,
                        child: Image(
                          image: AssetImage('assets/aboutus (2).jpeg'),
                          fit: BoxFit.fill,
                        )),
                  ),
                  Divider(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                    color: Colors.transparent,
                    width: 1 * width,
                    //height: 0.8 * height,
                    child: Container(
                        color: Colors.transparent,
                        child: Image(
                          image: AssetImage('assets/aboutus (3).jpeg'),
                          fit: BoxFit.fill,
                        )),
                  ),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    color: Colors.black,
                    width: 1 * width,
                    //height: 0.8 * height,
                    child: Text(AppLocalizations.of(context)!.company_name,
                        softWrap: true,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 0.035 * (height - width),
                            fontWeight: FontWeight.normal,
                            color: Colors.white)),
                  ),
                ],
              ),
            )));
  }
}
