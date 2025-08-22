import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  const salt = '12345678';
  const secret = '0242d54e7eadff95d73c2bc403ebdbec8aabf6bc';
  const token =
      'dbcd1e5ecadf6c3bdb375ac9feea9982642347bd38c11d18d69a9fd7857092bf';
  const post = '&source=1&app_id=test.app&app_version=1.0.0&app_client=android';
  const action1 =
      '&action=webQueryDeviceEnergyFlowEs&devcode=2451&pn=W0030161815655&devaddr=1&sn=96342305102943';
  const action2 =
      '&action=queryDeviceDataOneDayPaging&pn=W0030161815655&sn=96342305102943&devcode=2451&devaddr=1&date=2025-08-22&page=0&pagesize=200&i18n=en_US';
  const actionYesterday =
      '&action=queryDeviceDataOneDayPaging&pn=W0030161815655&sn=96342305102943&devcode=2451&devaddr=1&date=2025-08-21&page=0&pagesize=200&i18n=en_US';

  String sig(String action) => sha1
      .convert(utf8.encode(salt + secret + token + action + post))
      .toString();

  print('SIGN1 (energy flow) = ' + sig(action1));
  print('SIGN2 (day paging) = ' + sig(action2));
  print('URL1 = http://api.dessmonitor.com/public/?sign=' +
      sig(action1) +
      '&salt=' +
      salt +
      '&token=' +
      token +
      action1 +
      post);
  print('URL2 = http://api.dessmonitor.com/public/?sign=' +
      sig(action2) +
      '&salt=' +
      salt +
      '&token=' +
      token +
      action2 +
      post);
  print('YESTERDAY_SIGN = ' + sig(actionYesterday));
  print('YESTERDAY_URL = http://api.dessmonitor.com/public/?sign=' +
      sig(actionYesterday) +
      '&salt=' +
      salt +
      '&token=' +
      token +
      actionYesterday +
      post);
}
