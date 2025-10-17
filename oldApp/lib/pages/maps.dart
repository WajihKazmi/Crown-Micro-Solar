// import 'dart:async';

// import 'package:flutter/material.dart';

// import 'package:google_maps_flutter/google_maps_flutter.dart';

// import '../Models/Powerstation_Query_Response.dart';
// import 'package:crownmonitor/pages/plant.dart' as plantspage;
// import 'createpowerstat.dart';

// class Map extends StatefulWidget {
//   Response? ALLPSINFO;

//   Map({Key? key, this.ALLPSINFO}) : super(key: key);

//   @override
//   _MapState createState() => _MapState();
// }

// class _MapState extends State<Map> {
//   late Completer<GoogleMapController> _controller = Completer();
//   late GoogleMapController _googleMapController;
//   int markerID = 0;
//   bool Loading_data = true;

//   @override
//   void setState(VoidCallback fn) {
//     // TODO: implement setState
//     if (mounted) {
//       super.setState(fn);
//     }
//   }

//   @override
//   void dispose() {
//     // TODO: implement dispose
//     super.dispose();
//     _googleMapController.dispose();
//   }

//   //getting Plants List ///
//   Future fetchplants_list() async {
//     dynamic response = await ListofPowerStationQuery(context,
//         status: 5, orderby: 'ascPlantName', Plantname: '');
//     setState(() {
//       widget.ALLPSINFO = Response.fromJson(response);
//       Loading_data = false;
//       print(widget.ALLPSINFO);
//     });
//   }

//   //////////////////////////////////////////

//   // static final CameraPosition _kGooglePlex = CameraPosition(
//   //   target: LatLng(37.42796133580664, -122.085749655962),
//   //   zoom: 14.4746,
//   // );

//   // static final CameraPosition _kLake = CameraPosition(
//   //     bearing: 192.8334901395799,
//   //     target: LatLng(37.43296265331129, -122.08832357078792),
//   //     tilt: 59.440717697143555,
//   //     zoom: 19.151926040649414);

//   Set<Marker> _markers = {};

//   late BitmapDescriptor mapMarker;

//   void _setcustomMarker() async {
//     mapMarker = await BitmapDescriptor.fromAssetImage(
//         ImageConfiguration(), 'assets/marker.png');
//   }

//   @override
//   void initState() {
//     super.initState();
//     fetchplants_list();
//     _setcustomMarker();
//   }

//   void _onMapCreated(GoogleMapController controller) {
//     _googleMapController = controller;
//     _controller.complete(controller);

//     // setState(() {
//     //   _markers.add(Marker(
//     //       markerId: MarkerId('id-1'),
//     //       position: LatLng(
//     //         24.9113,
//     //         67.1335,
//     //       ),
//     //       infoWindow: InfoWindow(title: 'Plant', snippet: 'Plant Location'),
//     //       icon: mapMarker));
//     // });

//     //new//
//     widget.ALLPSINFO != null
//         ? setState(() {
//             widget.ALLPSINFO!.dat!.plant!.forEach((element) {
//               _markers.add(
//                 Marker(
//                     zIndex: 10,
//                     markerId: MarkerId('${element.name}_${DateTime.now().millisecondsSinceEpoch}'),
//                     position: LatLng(
//                       double.parse(element.address!.lat!),
//                       double.parse(element.address!.lon!),
//                     ),
//                     infoWindow: InfoWindow(
//                         onTap: (() {
//                           Navigator.pushAndRemoveUntil(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (BuildContext context) =>
//                                       plantspage.Plant(
//                                         Plantname: element.name,
//                                         Plant_status: element.status.toString(),
//                                         Country: element.address?.country,
//                                         province: element.address?.province,
//                                         City: element.address?.city,
//                                         County: element.address?.county,
//                                         town: element.address?.town,
//                                         village: element.address?.village,
//                                         address: element.address?.address,
//                                         lon: element.address?.lon,
//                                         lat: element.address?.lat,
//                                         timezone: element.address?.timezone
//                                             .toString(),
//                                         Unitprofit: element.profit?.unitProfit,
//                                         currency: element.profit?.currency,
//                                         coalsaved: element.profit?.coal,
//                                         so2emission: element.profit?.so2,
//                                         co2emission: element.profit?.co2,
//                                         DesignCompany: element.designCompany,
//                                         DesignPower:
//                                             double.parse(element.nominalPower!),
//                                         Annual_Planned_Power: double.parse(
//                                             element.energyYearEstimate!),
//                                         picbig: element.picBig,
//                                         picsmall: element.picSmall,
//                                         installed_date: element.install,
//                                         Average_troublefree_operationtime: 0,
//                                         Continuous_troublefree_operationtime: 0,
//                                         PlantID: element.pid.toString(),
//                                       )),
//                               (route) => false);
//                         }),
//                         title: '${element.name}'.toUpperCase(),
//                         snippet:
//                             'Status: ${element.status == 0 ? 'ONLINE' : element.status == 1 ? 'OFFLINE' : element.status == 4 ? 'WARNING' : 'ATTENTION'}'),
//                     icon: mapMarker),
//               );
//             });
//           })
//         : setState(() {
//             _markers.add(Marker(
//                 markerId: MarkerId('id-1'),
//                 position: LatLng(
//                   0,
//                   0,
//                 ),
//                 infoWindow: InfoWindow(title: '', snippet: ''),
//                 icon: mapMarker));
//           });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final height = MediaQuery.of(context).size.height;

//     final width = MediaQuery.of(context).size.width;
//     Future.delayed(Duration(seconds: 3), () {
//       if (_markers.isNotEmpty && !Loading_data) {
//         _googleMapController.showMarkerInfoWindow(_markers.first.markerId);
//       }
//     });

//     return new Scaffold(
//       // body: GoogleMap(
//       //   mapType: MapType.hybrid,
//       //   initialCameraPosition: _kGooglePlex,
//       //   onMapCreated: (GoogleMapController controller) {
//       //     _controller.complete(controller);
//       //   },
//       // ),
//       // floatingActionButton: FloatingActionButton.extended(
//       //   onPressed: _goToTheLake,
//       //   label: Text('To the lake!'),
//       //   icon: Icon(Icons.directions_boat),
//       // ));

//       body: Container(
//         height: height,
//         child: Column(
//           children: [
//             Container(
//                 height: 0.85 * height,
//                 child: widget.ALLPSINFO != null
//                     ? GoogleMap(
//                         onMapCreated: _onMapCreated,
//                         markers: _markers,
//                         initialCameraPosition: CameraPosition(
//                           target: widget.ALLPSINFO != null
//                               ? LatLng(
//                                   double.parse(widget
//                                       .ALLPSINFO!.dat!.plant![0].address!.lat!),
//                                   double.parse(widget
//                                       .ALLPSINFO!.dat!.plant![0].address!.lon!),
//                                 )
//                               : LatLng(
//                                   0,
//                                   0,
//                                 ),
//                           zoom: 14,
//                         ),
//                       )
//                     : Loading_data
//                         ? Center(
//                             child: Padding(
//                             padding: const EdgeInsets.only(top: 100),
//                             child: Center(
//                                 child: CircularProgressIndicator(
//                               strokeWidth: 4,
//                             )),
//                           ))
//                         : Center(
//                             child: Padding(
//                             padding: EdgeInsets.only(top: 0.1 * height),
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Divider(),
//                                 Icon(
//                                   Icons.storage_outlined,
//                                   size: 0.3 * width,
//                                   color: Colors.grey.shade400,
//                                 ),
//                                 Text('no Plant Exist'.toUpperCase(),
//                                     style: TextStyle(
//                                         fontSize: 0.06 * (height - width),
//                                         fontWeight: FontWeight.w800,
//                                         color: Colors.red.shade500)),
//                                 Text(
//                                     'Tap the green icon below to + add plant'
//                                         .toUpperCase(),
//                                     style: TextStyle(
//                                         fontSize: 0.022 * (height - width),
//                                         fontWeight: FontWeight.w800,
//                                         color: Colors.grey.shade500)),
//                                 SizedBox(
//                                   height: 0.04 * height,
//                                 ),
//                                 TextButton(
//                                     onPressed: () async {
//                                       Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                               builder: (context) =>
//                                                   CreatePowerStation()));
//                                     },
//                                     child: Column(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.center,
//                                       children: [
//                                         Icon(
//                                           Icons.add_circle_outline,
//                                           color: Colors.lightGreen,
//                                           size: 0.085 * height,
//                                         ),
//                                         SizedBox(height: 3),
//                                         Text('Add Plant'.toUpperCase(),
//                                             style: TextStyle(
//                                                 color: Colors.green,
//                                                 fontSize:
//                                                     0.05 * (height - width),
//                                                 fontWeight: FontWeight.bold)),
//                                       ],
//                                     )),
//                                 Divider(),
//                               ],
//                             ),
//                           ))),
//             widget.ALLPSINFO != null
//                 ? Column(
//                     children: [
//                       Container(
//                         height: 0.02 * height,
//                         padding: EdgeInsets.all(2),
//                         child: Center(
//                             child: Text(
//                           'List of PLants'.toUpperCase(),
//                           style: TextStyle(
//                               color: Colors.grey.shade900,
//                               fontSize: 0.028 * (height - width),
//                               fontWeight: FontWeight.normal),
//                         )),
//                       ),
//                       Container(
//                         height: 0.06 * height,
//                         width: width,
//                         decoration: BoxDecoration(
//                             color: Colors.grey.shade100,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.grey.shade300,
//                                 spreadRadius: 5,
//                                 blurRadius: 7,
//                                 offset: Offset(0, 0),
//                               )
//                             ]),
//                         child: Container(
//                           padding: EdgeInsets.only(top: 5, bottom: 5, left: 10),
//                           child: Center(
//                             child: ListView.builder(
//                                 shrinkWrap: true,
//                                 scrollDirection: Axis.horizontal,
//                                 itemCount: widget.ALLPSINFO!.dat!.total,
//                                 itemBuilder: (BuildContext context, int index) {
//                                   return Card(
//                                     elevation: 3,
//                                     color: Colors.white70,
//                                     child: TextButton.icon(
//                                       onPressed: () {
//                                         _googleMapController.animateCamera(
//                                             CameraUpdate.newCameraPosition(
//                                                 CameraPosition(
//                                           target: LatLng(
//                                             double.parse(widget.ALLPSINFO!.dat!
//                                                 .plant![index].address!.lat!),
//                                             double.parse(widget.ALLPSINFO!.dat!
//                                                 .plant![index].address!.lon!),
//                                           ),
//                                           zoom: 16,
//                                         )));
//                                         _googleMapController
//                                             .showMarkerInfoWindow(MarkerId(
//                                                 '${widget.ALLPSINFO!.dat!.plant![index].name}'));
//                                       },
//                                       icon: Icon(
//                                         Icons.storage_outlined,
//                                         size: 0.025 * height,
//                                         color: Colors.grey.shade600,
//                                       ),
//                                       label: Text(
//                                         '${widget.ALLPSINFO!.dat!.plant![index].name}'
//                                             .toUpperCase(),
//                                         style: TextStyle(
//                                             color: Colors.grey.shade700,
//                                             fontSize: 0.03 * (height - width),
//                                             fontWeight: FontWeight.normal),
//                                       ),
//                                     ),
//                                   );
//                                 }),
//                           ),

//                           //width: 0.3 * width,
//                           // child: ListTile(
//                           //     visualDensity: VisualDensity.compact,
//                           //     minLeadingWidth: 10,
//                           //     title: Text(
//                           //       'CROWN',
//                           //       style: TextStyle(
//                           //           color: Colors.white,
//                           //           fontSize: 0.025 * (height - width),
//                           //           fontWeight: FontWeight.normal),
//                           //     ),
//                           //     leading: Icon(
//                           //       Icons.storage_outlined,
//                           //       size: 0.018 * height,
//                           //       color: Colors.grey.shade400,
//                           //     )),
//                         ),
//                       ),
//                     ],
//                   )
//                 : Container()
//           ],
//         ),
//       ),
//     );
//   }

//   // Future<void> _goToTheLake() async {
//   //   final GoogleMapController controller = await _controller.future;
//   //   controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
//   // }
// }
