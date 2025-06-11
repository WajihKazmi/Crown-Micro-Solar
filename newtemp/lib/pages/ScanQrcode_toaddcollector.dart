// import 'dart:developer';
// import 'dart:io';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';
// import 'package:permission_handler/permission_handler.dart' as PH;

// import '../Models/CollectorDevicesStatus.dart';
// import 'AddCollectorscreen.dart';
// import 'devices.dart';

// class Scanqrcode extends StatefulWidget {
//   String? PID;
//   Scanqrcode({Key? key, this.PID}) : super(key: key);

//   @override
//   State<Scanqrcode> createState() => _ScanqrcodeState();
// }

// class _ScanqrcodeState extends State<Scanqrcode> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   Barcode? result;
//   QRViewController? controller;
//   bool show_addcollectorscreen = false;
//   late TextEditingController name = new TextEditingController();
//   late TextEditingController Pn_number = new TextEditingController();

//   void Rrquestpermission() async {
//     var status = await PH.Permission.camera.status;
//     if (!status.isGranted) {
//       await PH.Permission.camera.request();
//     }
//   }

//   @override
//   void initState() {
//     // TODO: implement initState
//     super.initState();
//     Rrquestpermission();
//   }

//   @override
//   void reassemble() {
//     super.reassemble();

//     if (Platform.isAndroid) {
//       controller!.pauseCamera();
//     } else if (Platform.isIOS) {
//       controller!.resumeCamera();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     var scanArea = (MediaQuery.of(context).size.width < 400 ||
//             MediaQuery.of(context).size.height < 400)
//         ? 200.0
//         : 300.0;

//     Widget Showcollectorscreen() {
//       return addcollectorscreen(
//         PID: widget.PID,
//         PN: result!.code,
//       );
//     }

//     return show_addcollectorscreen
//         ? Showcollectorscreen()
//         : Scaffold(
//             appBar: AppBar(
//               title: Text(
//                 "Scan QRcode on the Device",
//                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
//               ),
//               backgroundColor: Theme.of(context).primaryColor,
//               leading: IconButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   icon: Icon(Icons.arrow_back, color: Colors.white, size: 25)),
//             ),
//             body: Column(
//               children: <Widget>[
//                 Expanded(
//                   flex: 5,
//                   child: QRView(
//                     key: qrKey,
//                     onQRViewCreated: _onQRViewCreated,
//                     overlay: QrScannerOverlayShape(
//                         borderColor: Colors.white,
//                         borderRadius: 10,
//                         borderLength: 40,
//                         borderWidth: 8,
//                         cutOutSize: scanArea),
//                     onPermissionSet: (ctrl, p) =>
//                         _onPermissionSet(context, ctrl, p),
//                   ),
//                 ),
//                 Expanded(
//                   flex: 1,
//                   child: Center(
//                     child: (result != null)
//                         ? Text(
//                             'Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}')
//                         : Text(
//                             'Scan the QR-Code',
//                             style: TextStyle(fontSize: 20),
//                           ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//   }

//   void _onQRViewCreated(QRViewController controller) {
//     setState(() {
//       this.controller = controller;
//     });

//     controller.scannedDataStream.listen((scanData) {
//       setState(() {
//         result = scanData;

//         if (result!.code!.length == 14) {
//           print(
//               '********************PN********************: ${result!.code!.length}');
//           show_addcollectorscreen = true;
//         }
//       });
//     });
//   }

//   void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
//     log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
//     if (!p) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('no Permission')),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }
// }
