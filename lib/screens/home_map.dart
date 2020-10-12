import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image/image.dart';
import 'package:location/location.dart';
import 'package:my_shrooms/custom_widget/maps_marker.dart';
import 'package:my_shrooms/inheritedwidgets/shroom_locations.dart';
import 'package:my_shrooms/models/shroom_location.dart';
import 'package:my_shrooms/screens/add_shrooms.dart';
import 'package:my_shrooms/screens/view_image.dart';
import 'package:my_shrooms/services/db_helper.dart';
import 'package:my_shrooms/util/stringhelper.dart';
import 'package:ndialog/ndialog.dart';
import 'package:provider/provider.dart';
import 'package:thumbnailer/thumbnailer.dart';

class HomeMap extends StatefulWidget {
  @override
  _HomeMapState createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {

  Completer<GoogleMapController> _controller = Completer();
  List<MyMarker> _markers = [];
  LocationData currentLocation;
  Location location = Location();

  DBHelper db;
  ShroomLocationsData shroomLocData;


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
      markers: Set<MyMarker>.from(_markers),
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

  void addShroomPins(List<ShroomLocation> shrooms) async {
    for (ShroomLocation shroom in shrooms) {

      drawShroomPin(shroom, 150).then((bytes) {
        addMarker(shroom, BitmapDescriptor.fromBytes(bytes));
      });

    }
  }

  Future<Uint8List> drawShroomPin(ShroomLocation shroom, int height) async{
    if (shroom.photo == null) {

    }

    var bytes = File(StringHelper.getPhotoPath(shroom.photo, shroom.id)).readAsBytesSync();
    var image = decodeImage(bytes);

    image = copyResizeCropSquare(image, height); //might cause rotation...
    image = bakeOrientation(image); //fixes rotation....

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

  Future<void> dragPinEnd(int shroomId, LatLng value, BuildContext context) async {
    await NAlertDialog(
        onDismiss: () {
          dragRestoreOldLoc(shroomId, context);
        },
        dialogStyle: DialogStyle(titleDivider: false),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text("Would you like to save this position?"),
        ),
        actions: <Widget>[
          FlatButton(child: Text("Cancel"), onPressed: () => dragRestoreOldLoc(shroomId, context)),
          FlatButton(child: Text("Save"), onPressed: () => saveNewDragLoc(shroomId, value, context)),
        ],
     ).show(context);
  }

  void saveNewDragLoc(int shroomId, LatLng value, BuildContext context) {
    ShroomLocation shroom = shroomLocData.changeCoords(shroomId, value);
    db.updateShroomLocation(shroom);

    Navigator.pop(context);
  }

  void dragRestoreOldLoc(int shroomId, BuildContext context) async{
    // get old marker for the marker icon (dont have to redraw)
    var oldMarker = _markers.firstWhere((element) => shroomId.toString() == element?.markerId.value);
    var icon = oldMarker.icon;

    // remove old marker and add new(cant change position)
    _markers.removeWhere((element) => shroomId.toString() == element?.markerId.value);

    //get shroom with old location
    var shroom = shroomLocData.shroomsLoc.firstWhere((element) => shroomId == element.id);

    //ugly solution to mark the object for rebuilding, otherwise it wont be rebuilt
    shroom.long += 0.0000000000001;
    addMarker(shroom, icon);

    Navigator.pop(context);
  }

  void addMarker(ShroomLocation shroom, BitmapDescriptor bitmap) {
    setState(() {
     _markers.add(
          MyMarker(
              infoWindow: InfoWindow(title: shroom.name),
              draggable: true,
              onDragEnd: (value) => dragPinEnd(shroom.id, value, context),
              onTap: () => onTapMarker(shroom),
              markerId: MarkerId(shroom.id.toString()),
              position: LatLng(shroom.lat, shroom.long),
              icon: bitmap));

    });
  }

  void onTapMarker(ShroomLocation shroom) {

    showModalBottomSheet<dynamic>(
        isScrollControlled: true,
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Wrap(
            children: [
              ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
              child: Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.primary,
                  //height: (56 * 6).toDouble(),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 15),
                    child: Column(children: [
                      SizedBox(height:20),
                      Text(shroom.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.onPrimary),),
                      getLastPickDateText(shroom.remindDays),
                      Text("Picked ${shroom.pickCount} time" + (shroom.pickCount != 1 ? "s" : ""), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white54)),
                      SizedBox(height: 20,),
                      Container(
                          height: 200,
                          child: getImageThumb(shroom),
                      ),
                      SizedBox(height: 40),

                    ],),
                  )
              ),
            ),
          ]
          );
        }
    );
  }

  Widget getImageThumb(ShroomLocation shroom) {
    File image;

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => ViewImageFullScreen(image: image))),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
        child: Thumbnail(
        dataResolver: () async {
          image = File(StringHelper.getPhotoPath(shroom.photo, shroom.id));
          return image.readAsBytes();
        },
        mimeType: "image/" + shroom.photo.split(".").last,
        widgetSize: double.infinity,
        ),
      ),
    );

  }

  Widget getLastPickDateText(String remindDays) {
    DateTime remindDate = DateTime.parse(remindDays);
    DateTime now = DateTime.now();
    now = DateTime(now.year, now.month, now.day, 0, 0, 0, 0, 0);

    int days = now.difference(remindDate).inDays;
    String daysText = days >= 0 ? "now" : days == -1 ? "in ${days.abs()} day" : "in ${days.abs()} days";

    return Text("Can be repicked $daysText" + " ($remindDays)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white54));
  }
}
