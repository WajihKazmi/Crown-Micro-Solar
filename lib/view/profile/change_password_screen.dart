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
    final oldPwd = oldpassword.text; // keep exact old password (no trim)
    final newPwd = newpassword.text.trim();
    final confirmPwd = confirmpassword.text.trim();

    if (newPwd.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New Password must be at least 6 characters long', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPwd != confirmPwd) {
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
    final success = await authViewModel.changePassword(oldPwd, newPwd);

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

  Widget _textfield(double width, double height, String label, String hint,
      bool enabled, TextEditingController controller, bool isPassword) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: controller,
        enabled: enabled,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
      ),
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
                  'Please enter your old password', true, oldpassword, true),
              SizedBox(
                height: height / 1000,
              ),
              _textfield(width, height, 'New password',
                  'Please enter your new password', true, newpassword, true),
              SizedBox(
                height: height / 1000,
              ),
              _textfield(width, height, 'Confirm password',
                  'Re-enter new password', true, confirmpassword, true),
              SizedBox(
                height: 24,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(gen.AppLocalizations.of(context).change_password),
                  ),
                ),
              ),
            ],
          ),
        )));
  }
}