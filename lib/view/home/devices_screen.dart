import 'package:flutter/material.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: Text('Devices Page Coming Soon', style: TextStyle(fontSize: 20)),
          ),
          // Bottom padding for bottom navigation bar
          const SizedBox(height: 72),
        ],
      ),
    );
  }
} 