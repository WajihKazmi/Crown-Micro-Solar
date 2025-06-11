import 'package:crownmonitor/pages/forgotpassword.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccountSecurity extends StatefulWidget {
  final String? username,phonenumber;


  const AccountSecurity({Key? key, this.username , this.phonenumber}) : super(key: key);

  @override
  _AccountSecurityState createState() => _AccountSecurityState();
}

class _AccountSecurityState extends State<AccountSecurity> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(
            AppLocalizations.of(context)!.account_security,
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
              ListTile(
                dense: true,
                title: Text(AppLocalizations.of(context)!.change_password,
                    style: TextStyle(
                        fontSize: 0.035 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600)),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: width / 25,
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => forgotpassword(emailAddress: widget.phonenumber!,ischangingpass: true),
                          //ChangePassword(username: widget.username,)
                          ));
                },
              ),

              /////temporary commented
              ///
              // ListTile(
              //   dense: true,
              //   title: Text('Bind mailbox',
              //       style: Theme.of(context).textTheme.bodyText1),
              //   subtitle: Text('Unbound',
              //       style: Theme.of(context).textTheme.bodyText2),
              //   trailing: Icon(
              //     Icons.arrow_forward_ios,
              //     size: width / 25,
              //   ),
              //   onTap: () {
              //     Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //             builder: (context) => MailboxBinding()));
              //   },
              // ),
            ],
          ),
        )));
  }
}
