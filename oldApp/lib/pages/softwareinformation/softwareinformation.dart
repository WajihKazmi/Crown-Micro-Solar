import 'package:flutter/material.dart';

class SoftwareInfo extends StatefulWidget {
  const SoftwareInfo({Key? key}) : super(key: key);

  @override
  _SoftwareInfoState createState() => _SoftwareInfoState();
}

class _SoftwareInfoState extends State<SoftwareInfo> {
  @override
  Widget build(BuildContext context) {
    String version = '5.9.2';
    String introduction =
        'This is an information query and operation software for the users power station. The data presented by the software are all data collected in reliable and real-time.';
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
            'Software Information',
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
                height: height / 10,
              ),
              ListTile(
                dense: true,
                title: Text('Introduction',
                    style: TextStyle(
                        fontSize: 0.035 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600)),
                subtitle: Text(introduction,
                    style: TextStyle(
                        fontSize: 0.03 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600)),
                onTap: () {},
              ),
              ListTile(
                dense: true,
                title: Text('Version',
                    style: TextStyle(
                        fontSize: 0.035 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600)),
                trailing: Text(version,
                    style: TextStyle(
                        fontSize: 0.035 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600)),
                onTap: () {},
              ),
              ListTile(
                dense: true,
                title: Text('Share',
                    style: TextStyle(
                        fontSize: 0.035 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600)),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: width / 25,
                ),
                onTap: () {},
              ),

              ListTile(
                dense: true,
                title: Text('Privacy Policy',
                    style: TextStyle(
                        fontSize: 0.035 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600)),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: width / 25,
                ),
                onTap: () {},
              ),
            ],
          ),
        )));
  }
}
