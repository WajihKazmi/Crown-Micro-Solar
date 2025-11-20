import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crown_micro_solar/presentation/viewmodels/auth_viewmodel.dart';
import 'package:crown_micro_solar/l10n/app_localizations.dart' as gen;

class ChangePasswordScreen extends StatefulWidget {
  final String? username;
  const ChangePasswordScreen({Key? key, this.username}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  ////// Text Editing Controller /////////
  final TextEditingController currentaccount = TextEditingController();
  final TextEditingController oldpassword = TextEditingController();
  final TextEditingController newpassword = TextEditingController();
  final TextEditingController confirmpassword = TextEditingController();

  //variables
  final String newpassword_converted = '';

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.username != null) {
      currentaccount.text = widget.username!;
    }
  }

  Future<void> _changePassword() async {
    if (newpassword.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New Password must be at least 6 characters long', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newpassword.text != confirmpassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New Password and Confirm Password do not match!', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final success = await authViewModel.changePassword(oldpassword.text, newpassword.text);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password Changed Successfully', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      final error = authViewModel.error ?? 'Password change failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
                Text(name,
                    style: TextStyle(
                        fontSize: 0.035 * width,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey.shade600)),
                new Flexible(
                  child: TextField(
                      controller: controller,
                      style: TextStyle(
                          fontSize: 0.025 * width,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600),
                      enabled: enable,
                      obscureText: ispassword,
                      textAlign: TextAlign.end,
                      decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: hint,
                          hintStyle: TextStyle(
                              fontSize: 0.025 * width,
                              fontWeight: FontWeight.normal,
                              color: Colors.grey.shade400),
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
            gen.AppLocalizations.of(context).change_password,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white),
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
              _textfield(width, height, 'Current account', 'user', false,
                  currentaccount, false),
              SizedBox(
                height: height / 1000,
              ),
              _textfield(width, height, 'Old password',
                  'Please Enter the old password', true, oldpassword, true),
              SizedBox(
                height: height / 1000,
              ),
              _textfield(width, height, 'New password',
                  'Please Enter the New password', true, newpassword, true),
              SizedBox(
                height: height / 1000,
              ),
              _textfield(
                  width,
                  height,
                  'Confirm password',
                  'Please Enter the Confirm password',
                  true,
                  confirmpassword,
                  true),
              SizedBox(
                height: height / 10,
              ),
              Material(
                  elevation: 5.0,
                  borderRadius: BorderRadius.circular(5.0),
                  color: Theme.of(context).primaryColor,
                  child: MaterialButton(
                    minWidth: (MediaQuery.of(context).size.width - 280),
                    onPressed: _isLoading ? null : _changePassword,
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            gen.AppLocalizations.of(context).change_password,
                            style: TextStyle(
                                fontSize: 0.045 * width,
                                fontWeight: FontWeight.normal,
                                color: Colors.white),
                          ),
                  )),
            ],
          ),
        )));
  }
}