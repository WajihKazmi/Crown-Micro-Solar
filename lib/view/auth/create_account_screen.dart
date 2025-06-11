import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_text_fields.dart';
import '../../../core/utils/app_buttons.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({Key? key}) : super(key: key);

  static const String routeName = AppRoutes.createAccount; // Assuming you have a route defined for this screen

  @override
  _CreateAccountScreenState createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final TextEditingController _userIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  // Add a variable for the selected role
  String? _selectedRole;

  @override
  void dispose() {
    _userIdController.dispose();
    _emailController.dispose();
    _mobileNumberController.dispose();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text('Create Profile'),
        centerTitle: true,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Image Section
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          // TODO: Add logic to display user's selected image or a placeholder
                          backgroundImage: AssetImage('assets/images/default_avatar.png'), // Placeholder image
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              // TODO: Implement logic to pick a profile image
                              print('Pick image tapped');
                            },
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary, // Use theme's primary color
                                  shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2)
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: theme.colorScheme.onPrimary, // Use theme's onPrimary color
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
                  const SizedBox(height: 10.0),

                  // Email Address Field
                  Text('Email Address', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 5.0),
                  AppTextField(
                    controller: _emailController,
                    hintText: 'Enter your email address',
                    keyboardType: TextInputType.emailAddress,
                     // TODO: Add validator for Email Address
                  ),
                  const SizedBox(height: 10.0),

                  // Mobile Number Field
                   Text('Mobile Number', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 5.0),
                  AppTextField(
                    controller: _mobileNumberController,
                    hintText: 'Enter your mobile number',
                     keyboardType: TextInputType.phone,
                     // TODO: Add validator for Mobile Number
                  ),
                   const SizedBox(height: 10.0),

                  // Phone Number Field with Country Code (Placeholder)
                   Text('Phone Number', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 5.0),
                   Row(
                    children: [
                      // TODO: Implement Country Code Picker
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5)
                        ),
                        child: Text('+1', style: theme.textTheme.titleMedium), // Placeholder
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
                   const SizedBox(height: 10.0),

                  // Role Selection (Placeholder)
                   Text('Role', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 5.0),
                   Container(
                     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5), // Adjust padding to align with text fields
                     decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(5)
                        ),
                     child: DropdownButtonFormField<String>(
                       decoration: InputDecoration(
                         border: InputBorder.none, // Remove default underline
                          contentPadding: EdgeInsets.zero
                       ),
                       hint: Text('Select your role'),
                       value: _selectedRole,
                       items: <String>['Admin', 'User', 'Installer', 'Other'].map((String value) {
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
