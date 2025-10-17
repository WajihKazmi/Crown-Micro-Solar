import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Accountinfo_Screen extends StatefulWidget {
  ///variables///
  final String? uid;
  final String? username;
  final String? Role;
  final String? mobile;
  final String? email;
  final String? nickname;
  final String? Account_status;
  final String? Account_registration_time;
  final String? timezone;
  final String? Photo;

  const Accountinfo_Screen(
      {Key? key,
      this.Photo,
      this.uid,
      this.username,
      this.Role,
      this.mobile,
      this.email,
      this.nickname,
      this.Account_status,
      this.Account_registration_time,
      this.timezone})
      : super(key: key);

  @override
  _Accountinfo_ScreenState createState() => _Accountinfo_ScreenState();
}

class _Accountinfo_ScreenState extends State<Accountinfo_Screen> {
  double? valuesize;
  double? labelsize;
  @override
  Widget build(BuildContext context) {
    final TextEditingController version = TextEditingController();
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    valuesize = 15; //0.035 * (height - width);
    labelsize = 15; //0.03 * (height - width);

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
            AppLocalizations.of(context)!.account_information,
            style: TextStyle(
                fontSize: 0.045 * (height - width),
                fontWeight: FontWeight.bold,
                color: Colors.white
              )
          ),
          centerTitle: true,
        ),
        body: Container(
            color: Colors.white,
            padding: EdgeInsets.all(5),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: height / 30,
                  ),
                  Container(
                      color: Colors.transparent,
                      width: width / 1.8,
                      child: widget.Photo != null
                          ? CachedNetworkImage(
                              imageUrl: widget.Photo!,
                              placeholder: (_, url) =>
                                  new CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              imageBuilder: (context, imageProvider) =>
                                  CircleAvatar(
                                radius: 0.15 * height,
                                backgroundImage: imageProvider,
                              ),
                            )
                          : CircleAvatar(
                              backgroundColor: Colors.black26,
                              radius: 0.15 * width,
                              child: Icon(
                                Icons.account_circle_sharp,
                                size: 0.3 * width,
                                color: Colors.white,
                              ))),
                  SizedBox(
                    height: height / 20,
                  ),
                  fields(
                      label: AppLocalizations.of(context)!.username,
                      value: widget.username,
                      icon: Icons.person,
                      width: width,
                      labelsize: labelsize,
                      widget: widget,
                      valuesize: valuesize),
                  SizedBox(height: 1),
                  fields(
                      label: AppLocalizations.of(context)!.email,
                      value: widget.email,
                      icon: Icons.email,
                      width: width,
                      labelsize: labelsize,
                      widget: widget,
                      valuesize: valuesize),
                  SizedBox(height: 1),
                  fields(
                      label: AppLocalizations.of(context)!.mobile,
                      value: widget.mobile,
                      icon: Icons.phone_android,
                      width: width,
                      labelsize: labelsize,
                      widget: widget,
                      valuesize: valuesize),
                  SizedBox(height: 1),
                  fields(
                      label: AppLocalizations.of(context)!.role,
                      value: widget.Role,
                      icon: Icons.star_rate_outlined,
                      width: width,
                      labelsize: labelsize,
                      widget: widget,
                      valuesize: valuesize),
                  SizedBox(height: 1),
                  fields(
                      label: AppLocalizations.of(context)!.registerion_date,
                      value: widget.Account_registration_time,
                      icon: Icons.date_range_rounded,
                      width: width,
                      labelsize: labelsize,
                      widget: widget,
                      valuesize: valuesize),
                  fields(
                      label: AppLocalizations.of(context)!.timezone,
                      value: widget.timezone,
                      icon: Icons.access_time_filled_outlined,
                      width: width,
                      labelsize: labelsize,
                      widget: widget,
                      valuesize: valuesize),
                ],
              ),
            )));
  }
}

class fields extends StatelessWidget {
  const fields({
    Key? key,
    this.label,
    this.icon,
    this.value,
    required this.width,
    required this.labelsize,
    required this.widget,
    required this.valuesize,
  }) : super(key: key);

  final double width;
  final double? labelsize;
  final Accountinfo_Screen widget;
  final double? valuesize;
  final IconData? icon;
  final String? value, label;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: ListTile(
        tileColor: Colors.white54,
        leading: Icon(
          icon!,
          color: Colors.grey.shade400,
          size: 25,
        ),
        contentPadding: EdgeInsets.fromLTRB(15, 5, 20, 5),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label!,
              style: TextStyle(
                  fontSize: labelsize,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800),
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              value!,
              style: TextStyle(
                  fontSize: valuesize,
                  fontWeight: FontWeight.normal,
                  color: Colors.blueGrey),
            ),
          ],
        ),
        onTap: () {},
      ),
    );
  }
}
