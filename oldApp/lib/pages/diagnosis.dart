import 'package:flutter/material.dart';

class Diagnosis extends StatefulWidget {
  const Diagnosis({Key? key}) : super(key: key);

  @override
  _DiagnosisState createState() => _DiagnosisState();
}

class _DiagnosisState extends State<Diagnosis> {
  Widget _backButton(double x, double y) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
        child: Row(
          children: <Widget>[
            Container(
              padding:
                  EdgeInsets.only(left: 0, top: y * 0.01, bottom: y * 0.01),
              child: Icon(Icons.keyboard_arrow_left, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final height = MediaQuery.of(context).size.height;
    return MaterialApp(
        home: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50.0),
        child: AppBar(
          title: Text(
            'Network Diagnosis',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          centerTitle: true,
          leading: Row(
            children: [_backButton(width, height)],
          ),
          backgroundColor: Colors.transparent,
          elevation: 0.0,
        ),
      ),
      body: Container(
          height: height,
          child: Stack(
            children: <Widget>[
              SizedBox(
                width: width,
                height: height / 3.8,
                child: Container(
                  color: Theme.of(context).primaryColor,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                            child: Icon(
                          Icons.wifi,
                          color: Colors.white,
                          size: 80,
                        )),
                        SizedBox(
                          height: 40,
                          width: 20,
                        ),
                      ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 220),
                child: Column(
                  children: [
                    Container(
                        child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          'Repair Suggestion',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 3,
                        ),
                        Material(
                            elevation: 5.0,
                            borderRadius: BorderRadius.circular(40.0),
                            color: Colors.blueGrey.shade800,
                            child: MaterialButton(
                              minWidth:
                                  (MediaQuery.of(context).size.width - 280),
                              // padding: EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                              onPressed: () {},
                              child: Text(
                                'Rediagnosis',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            )),
                      ],
                    )),
                  ],
                ),
              )
            ],
          )),
    ));
  }
}
