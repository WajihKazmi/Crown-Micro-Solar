
import 'package:crownmonitor/pages/createpowerstat.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ShineMonitor {

  createPowerStation() async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token').toString();
    String secret = prefs.getString('Secret').toString();

    var action = "&action=reg&usr=";

    var signString = getSalt() + secret + token + action;
    
    // var sign =  "sign=" + sha1.convert(signString).toString();

    // return sign;
  }

  String getSalt() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}