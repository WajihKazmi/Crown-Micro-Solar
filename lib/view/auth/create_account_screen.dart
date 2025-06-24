import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_text_fields.dart';
import '../../../core/utils/app_buttons.dart';
import '../common/bordered_icon_button.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({Key? key}) : super(key: key);

  static const String routeName = AppRoutes
      .createAccount; // Assuming you have a route defined for this screen

  @override
  _CreateAccountScreenState createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _wifiModulePNController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  // Add a variable for the selected role
  String? _selectedRole;

  @override
  void dispose() {
    _userIdController.dispose();
    _emailController.dispose();
    _wifiModulePNController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _continue() {
    // TODO: Implement logic to handle continue button tap
    print('Continue button tapped');
    // You might navigate to the next screen or process the data here
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BorderedIconButton(
          icon: Icons.arrow_back_ios_new,
          onTap: () => Navigator.of(context).pop(),
          margin: const EdgeInsets.only(left: 16.0),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10.0),
                  Text(
                    'Create Profile',
                    style: theme.textTheme.displaySmall!
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 40.0),
                  // User ID Field
                  Text('User ID', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 5.0),
                  AppTextField(
                    controller: _userIdController,
                    hintText: 'Enter your User ID',
                    // TODO: Add validator for User ID
                  ),
                  const SizedBox(height: 15.0),

                  // Phone Number Field with Country Code (Placeholder)
                  Text('Phone Number', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 5.0),
                  Row(
                    children: [
                      // TODO: Implement Country Code Picker
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5)),
                        child: Text('+1',
                            style: theme.textTheme.titleMedium), // Placeholder
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: AppTextField(
                          controller: _phoneNumberController,
                          hintText: 'Enter your phone number',
                          keyboardType: TextInputType.phone,
                          // TODO: Add validator for Phone Number
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15.0),
                  // Email Address Field
                  Text('WiFi Module PN', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 5.0),
                  AppTextField(
                    controller: _wifiModulePNController,
                    hintText: 'e.g W0011223344556',
                    keyboardType: TextInputType.text,
                    // TODO: Add validator for Email Address
                  ),
                  const SizedBox(height: 15.0),

                  // Role Selection (Placeholder)
                  Text('Role', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 5.0),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical:
                            5), // Adjust padding to align with text fields
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5)),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                          border: InputBorder.none, // Remove default underline
                          contentPadding: EdgeInsets.zero),
                      hint: Text('Select your role'),
                      value: _selectedRole,
                      items: <String>['User', 'Installer'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRole = newValue;
                        });
                      },
                      // TODO: Add validator for Role
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  // Continue Button
                  AppButtons.primaryButton(
                    context: context,
                    onTap: _continue,
                    text: 'Continue',
                    isFilled: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
