import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class ApiTester {
  String? _token;
  String? _secret;
  int? _userId;
  final String salt = "12345678";

  // App info (dummy for test)
  final String source = "1";
  final String app_id = "test.app";
  final String app_version = "1.0.0";
  final String app_client = "android";

  Future<void> testLogin(String username, String password) async {
    print("\n=== Testing Login ===");
    final url =
        Uri.parse('https://apis.crown-micro.net/api/MonitoringApp/Login');
    final headers = {
      'Content-Type': 'application/json',
      'x-api-key': 'C5BFF7F0-B4DF-475E-A331-F737424F013C'
    };
    final body = jsonEncode(
        {"UserName": username, "Password": password, "IsAgent": false});
    final response = await http.post(url, headers: headers, body: body);
    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");
    if (response.statusCode == 200) {
      final jsonResp = json.decode(response.body);
      _token = jsonResp['Token'];
      _secret = jsonResp['Secret'];
      _userId = jsonResp['UserID'];
      print(
          "Login successful!\nToken: $_token\nSecret: $_secret\nUserID: $_userId");
    } else {
      print("Login failed.");
    }
  }

  Future<void> testDessMonitorApis() async {
    print("\n=== Testing Dess Monitor APIs ===");
    if (_token == null || _secret == null) {
      print("Token or Secret missing. Please login first.");
      return;
    }
    // 1. List Plants
    final plantAction =
        "&action=webQueryPlants&orderBy=ascPlantName&page=0&pagesize=100";
    final plantPostaction =
        "&source=$source&app_id=$app_id&app_version=$app_version&app_client=$app_client";
    final plantData = salt + _secret! + _token! + plantAction + plantPostaction;
    final plantSign = sha1.convert(utf8.encode(plantData)).toString();
    final plantUrl =
        'http://api.dessmonitor.com/public/?sign=$plantSign&salt=$salt&token=$_token$plantAction$plantPostaction';
    final plantResponse = await http.post(Uri.parse(plantUrl),
        headers: {'Content-Type': 'application/json'});
    print("\nPlant List Response: ${plantResponse.body}");
    int? pid;
    try {
      final plantJson = json.decode(plantResponse.body);
      if (plantJson['dat'] != null &&
          plantJson['dat']['plant'] is List &&
          plantJson['dat']['plant'].isNotEmpty) {
        pid = plantJson['dat']['plant'][0]['pid'];
        print("Using Plant ID: $pid");
      }
    } catch (e) {
      print('Error parsing plant info: $e');
    }
    if (pid == null) {
      print("No valid Plant ID found. Cannot proceed with further API calls.");
      return;
    }
    // 2. List Devices for Plant
    final deviceAction =
        "&action=webQueryDeviceEs&status=0101&page=0&pagesize=100&plantid=$pid";
    final devicePostaction =
        "&source=$source&app_id=$app_id&app_version=$app_version&app_client=$app_client";
    final deviceData =
        salt + _secret! + _token! + deviceAction + devicePostaction;
    final deviceSign = sha1.convert(utf8.encode(deviceData)).toString();
    final deviceUrl =
        'http://api.dessmonitor.com/public/?sign=$deviceSign&salt=$salt&token=$_token$deviceAction$devicePostaction';
    final deviceResponse = await http.post(Uri.parse(deviceUrl),
        headers: {'Content-Type': 'application/json'});
    print("\nDevice List Response: ${deviceResponse.body}");
    String? pn, sn;
    int? devcode, devaddr;
    String deviceSource = "device list";
    try {
      final deviceJson = json.decode(deviceResponse.body);
      if (deviceJson['dat'] != null &&
          deviceJson['dat']['device'] is List &&
          deviceJson['dat']['device'].isNotEmpty) {
        final dev = deviceJson['dat']['device'][0];
        pn = dev['pn'];
        sn = dev['sn'];
        devcode = dev['devcode'];
        devaddr = dev['devaddr'];
        print(
            "Using Device PN: $pn, SN: $sn, devcode: $devcode, devaddr: $devaddr (from device list)");
      }
    } catch (e) {
      print('Error parsing device info: $e');
    }
    // If not found, try plant warnings/alarms
    if (pn == null || sn == null || devcode == null || devaddr == null) {
      print(
          "No valid device found in device list. Trying plant warnings/alarms...");
      final warnAction =
          "&action=webQueryPlantsWarning&i18n=en_US&page=0&pagesize=100&plantid=$pid";
      final warnData =
          salt + _secret! + _token! + warnAction + devicePostaction;
      final warnSign = sha1.convert(utf8.encode(warnData)).toString();
      final warnUrl =
          'http://api.dessmonitor.com/public/?sign=$warnSign&salt=$salt&token=$_token$warnAction$devicePostaction';
      final warnResponse = await http.post(Uri.parse(warnUrl),
          headers: {'Content-Type': 'application/json'});
      print("\nPlant Warnings/Alarms Response: ${warnResponse.body}");
      try {
        final warnJson = json.decode(warnResponse.body);
        if (warnJson['dat'] != null &&
            warnJson['dat']['warning'] is List &&
            warnJson['dat']['warning'].isNotEmpty) {
          final warn = warnJson['dat']['warning'][0];
          pn = warn['pn'];
          sn = warn['sn'];
          devcode = warn['devcode'];
          devaddr = warn['devaddr'];
          deviceSource = "plant warnings/alarms";
          print(
              "Using Device PN: $pn, SN: $sn, devcode: $devcode, devaddr: $devaddr (from plant warnings/alarms)");
        }
      } catch (e) {
        print('Error parsing plant warnings/alarms: $e');
      }
    }
    // 3. Plant Output/Profit
    final outputAction =
        "&action=queryPlantActiveOuputPowerOneDay&plantid=$pid&date=2024-01-01";
    final outputPostaction = plantPostaction;
    final outputData =
        salt + _secret! + _token! + outputAction + outputPostaction;
    final outputSign = sha1.convert(utf8.encode(outputData)).toString();
    final outputUrl =
        'http://api.dessmonitor.com/public/?sign=$outputSign&salt=$salt&token=$_token$outputAction$outputPostaction';
    final outputResponse = await http.post(Uri.parse(outputUrl),
        headers: {'Content-Type': 'application/json'});
    print("\nPlant Output Response: ${outputResponse.body}");
    // 4. Profit Statistic
    final profitAction =
        "&action=queryPlantsProfitStatisticOneDay&lang=zh_CN&date=2024-01-01";
    final profitData =
        salt + _secret! + _token! + profitAction + outputPostaction;
    final profitSign = sha1.convert(utf8.encode(profitData)).toString();
    final profitUrl =
        'http://api.dessmonitor.com/public/?sign=$profitSign&salt=$salt&token=$_token$profitAction$outputPostaction';
    final profitResponse = await http.post(Uri.parse(profitUrl),
        headers: {'Content-Type': 'application/json'});
    print("\nProfit Statistic Response: ${profitResponse.body}");
    // 5. Device Parameters (if device found)
    if (pn != null && sn != null && devcode != null && devaddr != null) {
      print(
          "\nProceeding with device API tests using values from $deviceSource");
      final paramAction =
          "&action=queryDeviceParsEs&source=1&devcode=$devcode&pn=$pn&devaddr=$devaddr&sn=$sn&i18n=en_US";
      final paramData = salt + _secret! + _token! + paramAction;
      final paramSign = sha1.convert(utf8.encode(paramData)).toString();
      final paramUrl =
          'http://web.shinemonitor.com/public/?sign=$paramSign&salt=$salt&token=$_token$paramAction';
      final paramResponse = await http.post(Uri.parse(paramUrl),
          headers: {'Content-Type': 'application/json'});
      print("\nDevice Parameters Response: ${paramResponse.body}");
      // 6. Device Control Fields
      final ctrlFieldAction =
          "&action=queryDeviceCtrlField&pn=$pn&sn=$sn&devcode=$devcode&devaddr=$devaddr&i18n=en_US";
      final ctrlFieldData = salt + _secret! + _token! + ctrlFieldAction;
      final ctrlFieldSign = sha1.convert(utf8.encode(ctrlFieldData)).toString();
      final ctrlFieldUrl =
          'http://web.shinemonitor.com/public/?sign=$ctrlFieldSign&salt=$salt&token=$_token$ctrlFieldAction';
      final ctrlFieldResponse = await http.post(Uri.parse(ctrlFieldUrl),
          headers: {'Content-Type': 'application/json'});
      print("\nDevice Control Fields Response: ${ctrlFieldResponse.body}");
      // 7. Device Data One Day
      final dataAction =
          "&action=queryDeviceDataOneDayPaging&pn=$pn&sn=$sn&devaddr=$devaddr&devcode=$devcode&date=2024-01-01&page=0&pagesize=200&i18n=en_US";
      final dataData = salt + _secret! + _token! + dataAction;
      final dataSign = sha1.convert(utf8.encode(dataData)).toString();
      final dataUrl =
          'http://web.shinemonitor.com/public/?sign=$dataSign&salt=$salt&token=$_token$dataAction';
      final dataResponse = await http.post(Uri.parse(dataUrl),
          headers: {'Content-Type': 'application/json'});
      print("\nDevice Data One Day Response: ${dataResponse.body}");
    } else {
      print("No valid device found for parameter/data tests.");
    }
    // 8. Plant Warnings/Alarms
    final warnAction =
        "&action=webQueryPlantsWarning&i18n=en_US&page=0&pagesize=100&plantid=$pid";
    final warnData = salt + _secret! + _token! + warnAction + plantPostaction;
    final warnSign = sha1.convert(utf8.encode(warnData)).toString();
    final warnUrl =
        'http://api.dessmonitor.com/public/?sign=$warnSign&salt=$salt&token=$_token$warnAction$plantPostaction';
    final warnResponse = await http.post(Uri.parse(warnUrl),
        headers: {'Content-Type': 'application/json'});
    print("\nPlant Warnings/Alarms Response: ${warnResponse.body}");
  }

  Future<void> runAllTests(String username, String password) async {
    print("Starting API Tests...");
    await testLogin(username, password);
    await testDessMonitorApis();
    print("\nAPI Tests completed!");
  }
}

void main() async {
  final tester = ApiTester();
  await tester.runAllTests('aatif100', 'hamza1');
}
