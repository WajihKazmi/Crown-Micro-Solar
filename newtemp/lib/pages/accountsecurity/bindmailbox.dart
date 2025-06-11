import 'package:flutter/material.dart';

class MailboxBinding extends StatefulWidget {
  const MailboxBinding({Key? key}) : super(key: key);

  @override
  _MailboxBindingState createState() => _MailboxBindingState();
}

class _MailboxBindingState extends State<MailboxBinding> {
  final TextEditingController email = TextEditingController();

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
                Text(name, style: Theme.of(context).textTheme.bodyLarge),
                new Flexible(
                  child: TextField(
                      controller: controller,
                      style: Theme.of(context).textTheme.bodyLarge,
                      enabled: enable,
                      obscureText: ispassword,
                      textAlign: TextAlign.end,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: hint,
                          hintStyle: Theme.of(context).textTheme.bodyMedium,
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

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title: Text(
            'MailBox Binding',
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    'Please enter the email address you want to bind, after verification, you can use the email to retrieve the password of the smartClient account',
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
              _textfield(width, height, 'New password', 'Please enter email',
                  true, email, false),
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
                    onPressed: () {},
                    child: Text(
                      'Send Authentication Code',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )),
            ],
          ),
        )));
  }
}
