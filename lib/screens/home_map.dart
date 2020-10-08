import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart';
import 'package:location/location.dart';
import 'package:my_shrooms/inheritedwidgets/shroom_locations.dart';
import 'package:my_shrooms/models/shroom_location.dart';
import 'package:my_shrooms/screens/add_shrooms.dart';
import 'package:my_shrooms/services/db_helper.dart';
import 'package:my_shrooms/util/stringhelper.dart';
import 'package:provider/provider.dart';

class HomeMap extends StatefulWidget {
  @override
  _HomeMapState createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {

  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = Set<Marker>();
  LocationData currentLocation;
  Location location = Location();

  DBHelper db;
  ShroomLocationsData shroomLocData;

  //Future<List<ShroomLocation>> fShrooms;


  @override
  void initState() {
    super.initState();
    setInitialLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = Provider.of<DBHelper>(context);
    shroomLocData = Provider.of<ShroomLocationsData>(context);
    addShroomPins(shroomLocData.shroomsLoc);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Stack(
          children: [

            SafeArea(child: getMap()),


            Positioned(
              left: 5, top:5,
              child: SafeArea(
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.add, color: Colors.white),
                      iconSize: 25,
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => AddShrooms())),
                    )
                ),
              ),
            ),

          ]
      ),
    );
  }

  Widget getMap() {
    return currentLocation == null ? Container() : GoogleMap(
      tiltGesturesEnabled: false,
      mapType: MapType.hybrid,
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      compassEnabled: false,
      initialCameraPosition: getInitLocation(),
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
    );
  }

  void setInitialLocation() async {
    var locationData = await location.getLocation();
    setState(() {
      currentLocation = locationData;
    });

  }

  getInitLocation() {
    return CameraPosition(zoom: 14.4746, target: LatLng(currentLocation.latitude, currentLocation.longitude));
  }

  void addShroomPins(List<ShroomLocation> shrooms) {
    for (ShroomLocation shroom in shrooms) {

      drawShroomPin(shroom, 150).then((bytes) {
        setState(() {
          _markers.add(
              Marker(
                  onTap: () => print("test"),
                  markerId: MarkerId(shroom.id.toString()),
                  position: LatLng(shroom.lat, shroom.long),
                  icon: BitmapDescriptor.fromBytes(bytes)));
        });
      });

    }
  }

  Future<Uint8List> drawShroomPin(ShroomLocation shroom, int height) async{
    if (shroom.photo == null) {

    }

    var bytes = File(StringHelper.getPhotoPath(shroom.photo, shroom.id)).readAsBytesSync();
    var image = decodeImage(bytes);
    image = copyResizeCropSquare(image, height);

    Uint8List imageBytesResized = Uint8List.fromList(encodePng(image));

    //bytes to ui.Image
    Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(imageBytesResized, (result) {
      completer.complete(result);
    });

    ui.Image imageDone = await completer.future;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    final radius = 10.0; //20 diameter
    final circleImageMargin = 30;
    final center = Offset(imageDone.width / 2, (imageDone.height + circleImageMargin).toDouble());

    // The circle should be paint before or it will be hidden by the path
    Paint paintCircle = Paint()..color = Colors.black;
    Paint paintBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paintCircle);
    canvas.drawCircle(center, radius, paintBorder);

    var drawImageWidth = 0.0;
    var drawImageHeight =  0.0;
    Path path = Path()..addOval(Rect.fromLTWH(drawImageWidth, drawImageHeight, imageDone.width.toDouble(), imageDone.height.toDouble()));
    canvas.clipPath(path);

    canvas.drawImage(imageDone, Offset(drawImageWidth, drawImageHeight), Paint());

    final img = await pictureRecorder.endRecording().toImage(imageDone.width, (imageDone.height + (radius * 2) + circleImageMargin).ceil());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data.buffer.asUint8List();
  }


  /*
  Future<Uint8List> getImageFromBytesSize(Uint8List bytes, int height) async {
    var image = decodeImage(bytes);
    var originalH = image.height;
    var originalW = image.width;
    image = copyResizeCropSquare(image, height);


    if (originalH < originalW) image = copyRotate(image, 90); //TODO TEMP BUG?


    Uint8List imageBytesResized = Uint8List.fromList(encodePng(image));

    //bytes to ui.Image
    Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(imageBytesResized, (result) {
      completer.complete(result);
    });

    ui.Image imageDone = await completer.future;
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);


    final radius = 10.0; //20 diameter
    final circleImageMargin = 30;
    final center = Offset(imageDone.width / 2, (imageDone.height + circleImageMargin).toDouble());

    // The circle should be paint before or it will be hidden by the path
    Paint paintCircle = Paint()..color = Colors.black;
    Paint paintBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, paintCircle);
    canvas.drawCircle(center, radius, paintBorder);

    var drawImageWidth = 0.0;
    var drawImageHeight =  0.0;
    Path path = Path()..addOval(Rect.fromLTWH(drawImageWidth, drawImageHeight, imageDone.width.toDouble(), imageDone.height.toDouble()));
    canvas.clipPath(path);

    canvas.drawImage(imageDone, Offset(drawImageWidth, drawImageHeight), Paint());

    final img = await pictureRecorder.endRecording().toImage(imageDone.width, (imageDone.height + (radius * 2) + circleImageMargin).ceil());
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data.buffer.asUint8List();
  }

   */

}
