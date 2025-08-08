import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crown_micro_solar/presentation/models/alarm/alarm_model.dart';
import 'package:crown_micro_solar/presentation/repositories/alarm_repository.dart';

void main() {
  group('Alarm Repository Tests', () {
    test('AlarmRepository returns sample alarms when credentials are missing',
        () async {
      // Test that our actual repository implementation returns sample data
      final repository = AlarmRepository();
      final alarms = await repository.getWarnings('test_plant_id');

      // Verify we get sample alarms
      expect(alarms.isNotEmpty, true);
      expect(alarms.length, greaterThanOrEqualTo(3));

      // Check that sample alarms have correct structure
      for (final alarm in alarms) {
        expect(alarm.id.isNotEmpty, true);
        expect(alarm.sn.isNotEmpty, true);
        expect(alarm.desc.isNotEmpty, true);
        expect(alarm.level, greaterThanOrEqualTo(0));
      }

      print(
          '✓ AlarmRepository sample data test passed - ${alarms.length} sample alarms returned');

      // Print sample alarm details to verify structure
      if (alarms.isNotEmpty) {
        final firstAlarm = alarms.first;
        print(
            'Sample alarm: ID=${firstAlarm.id}, SN=${firstAlarm.sn}, Description=${firstAlarm.desc}, Level=${firstAlarm.level}');
      }
    });

    test('Warning model fields are accessible', () {
      // Create a test warning to verify all fields work
      final warning = Warning(
        id: 'test-123',
        sn: 'SAMPLE001',
        pn: 'W003016815655',
        devcode: 530,
        desc: 'Test alarm description',
        level: 1,
        code: 1001,
        gts: DateTime.now(),
        handle: false,
      );

      // Verify all expected fields are accessible
      expect(warning.id, equals('test-123'));
      expect(warning.sn, equals('SAMPLE001'));
      expect(warning.desc, equals('Test alarm description'));
      expect(warning.level, equals(1));
      expect(warning.handle, equals(false));

      // Test helper methods
      expect(warning.deviceType, equals('Inverter')); // devcode 530
      expect(warning.severityText, equals('Error')); // level 1
      expect(warning.statusText, equals('Untreated')); // handle false

      print('✓ Warning model test passed - all fields accessible');
    });

    test('Warning model JSON serialization works', () {
      final warning = Warning(
        id: 'test-456',
        sn: 'SAMPLE002',
        pn: 'W003016815656',
        devcode: 530,
        desc: 'Test JSON alarm',
        level: 0,
        code: 1002,
        gts: DateTime.now(),
        handle: true,
      );

      // Test toJson
      final json = warning.toJson();
      expect(json['id'], equals('test-456'));
      expect(json['desc'], equals('Test JSON alarm'));
      expect(json['handle'], equals(true));

      // Test fromJson
      final fromJson = Warning.fromJson(json);
      expect(fromJson.id, equals(warning.id));
      expect(fromJson.desc, equals(warning.desc));
      expect(fromJson.handle, equals(warning.handle));

      print('✓ Warning JSON serialization test passed');
    });
  });

  group('Alarm UI Integration Tests', () {
    testWidgets('Basic alarm display widget works',
        (WidgetTester tester) async {
      // Create sample warnings for UI test
      final warnings = [
        Warning(
          id: '1',
          sn: 'SAMPLE001',
          pn: 'W003016815655',
          devcode: 530,
          desc: 'Grid Connection Fault',
          level: 2,
          code: 1001,
          gts: DateTime.now().subtract(Duration(hours: 2)),
          handle: false,
        ),
        Warning(
          id: '2',
          sn: 'SAMPLE002',
          pn: 'W003016815656',
          devcode: 530,
          desc: 'High Temperature Warning',
          level: 0,
          code: 1002,
          gts: DateTime.now().subtract(Duration(hours: 5)),
          handle: true,
        ),
      ];

      // Create a simple test widget that displays alarms
      final testWidget = MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text('Alarm Management')),
          body: warnings.isEmpty
              ? Center(child: Text('No alarms found'))
              : ListView.builder(
                  itemCount: warnings.length,
                  itemBuilder: (context, index) {
                    final alarm = warnings[index];
                    return ListTile(
                      title: Text(alarm.desc),
                      subtitle:
                          Text('Device: ${alarm.sn} - ${alarm.severityText}'),
                      trailing: Icon(
                        alarm.handle ? Icons.check_circle : Icons.warning,
                        color: alarm.handle ? Colors.green : Colors.orange,
                      ),
                    );
                  },
                ),
        ),
      );

      // Build the widget
      await tester.pumpWidget(testWidget);

      // Verify that alarms are displayed
      expect(find.text('Grid Connection Fault'), findsOneWidget);
      expect(find.text('High Temperature Warning'), findsOneWidget);

      // Verify device serial numbers are shown
      expect(find.textContaining('SAMPLE001'), findsOneWidget);
      expect(find.textContaining('SAMPLE002'), findsOneWidget);

      // Verify that "No alarms found" message is NOT shown
      expect(find.text('No alarms found'), findsNothing);

      // Verify that warning and check icons are present
      expect(
          find.byIcon(Icons.warning), findsOneWidget); // One unresolved alarm
      expect(find.byIcon(Icons.check_circle),
          findsOneWidget); // One resolved alarm

      print('✓ Basic alarm UI test passed - alarms displayed correctly');
    });

    testWidgets('Empty alarm list shows "No alarms found"',
        (WidgetTester tester) async {
      final warnings = <Warning>[];

      final testWidget = MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: Text('Alarm Management')),
          body: warnings.isEmpty
              ? Center(child: Text('No alarms found'))
              : ListView.builder(
                  itemCount: warnings.length,
                  itemBuilder: (context, index) => Container(),
                ),
        ),
      );

      await tester.pumpWidget(testWidget);

      // Should show "No alarms found" when list is empty
      expect(find.text('No alarms found'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);

      print(
          '✓ Empty alarm list test passed - "No alarms found" message displayed');
    });
  });
}
