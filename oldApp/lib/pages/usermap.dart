// import 'package:flutter/material.dart';

// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class Usermap extends StatefulWidget {
//   String? lon;
//   String? lat;
//   String? Plantname;
//   String? Plant_status;
//   Usermap(
//       {Key? key,
//       required this.Plant_status,
//       required this.Plantname,
//       required this.lat,
//       required this.lon})
//       : super(key: key);

//   @override
//   _UsermapState createState() => _UsermapState();
// }

// class _UsermapState extends State<Usermap> {
//   Set<Marker> _markers = {};

//   late BitmapDescriptor mapMarker;
//   late GoogleMapController _googleMapController;

//   void _setcustomMarker() async {
//     mapMarker = await BitmapDescriptor.fromAssetImage(
//         ImageConfiguration(), 'assets/marker.png');
//   }

//   @override
//   void initState() {
//     super.initState();
//     _setcustomMarker();
//   }

//   void _onMapCreated(GoogleMapController controller) {
//     _googleMapController = controller;
//     if (widget.Plantname != null && widget.lat != null) {
//       setState(() {
//         _markers.add(Marker(
//             markerId: MarkerId('0'),
//             position: LatLng(
//               double.parse(widget.lat!),
//               double.parse(widget.lon!),
//             ),
//             infoWindow: InfoWindow(
//                 title: widget.Plantname!.toUpperCase(),
//                 snippet:
//                     'Status: ${widget.Plant_status == 0 ? 'ONLINE' : widget.Plant_status == 1 ? 'OFFLINE' : widget.Plant_status == 4 ? 'WARNING' : 'ATTENTION'}'),
//             icon: mapMarker));
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final height = MediaQuery.of(context).size.height;
//     Future.delayed(Duration(seconds: 3), () {
//       _googleMapController.showMarkerInfoWindow(_markers.first.markerId);
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
//         child: GoogleMap(
//           onMapCreated: _onMapCreated,
//           markers: _markers,
//           initialCameraPosition: widget.lat !=null ?
//           CameraPosition(
//             target: 
//             LatLng(
//               double.parse(widget.lat!),
//               double.parse(widget.lon!),
//             ),
//             zoom: 15,
//           ): CameraPosition(
//             target: 
//             LatLng(
//               0000,
//               0010,
//             ),
//             zoom: 15,
//           ),
//         ),
//       ),
//     );
//   }
// }
