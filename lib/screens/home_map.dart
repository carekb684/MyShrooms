import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:highlighter_coachmark/highlighter_coachmark.dart';
import 'package:image/image.dart';
import 'package:location/location.dart';
import 'package:my_shrooms/animations/add_shrooms_transition.dart';
import 'package:my_shrooms/custom_widget/maps_marker.dart';
import 'package:my_shrooms/inheritedwidgets/settings_prefs.dart';
import 'package:my_shrooms/inheritedwidgets/shroom_locations.dart';
import 'package:my_shrooms/models/shroom_location.dart';
import 'package:my_shrooms/screens/add_shrooms.dart';
import 'package:my_shrooms/screens/edit_shroom.dart';
import 'package:my_shrooms/screens/map_drawer.dart';
import 'package:my_shrooms/screens/view_image.dart';
import 'package:my_shrooms/screens/widgets/thumbnail_image_picker.dart';
import 'package:my_shrooms/services/db_helper.dart';
import 'package:my_shrooms/util/datehelper.dart';
import 'package:my_shrooms/util/filehelper.dart';
import 'package:ndialog/ndialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeMap extends StatefulWidget {
  @override
  _HomeMapState createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _introAddKey = GlobalObjectKey("introAdd");

  Completer<GoogleMapController> _controller = Completer();
  List<MyMarker> _markers = [];
  LocationData currentLocation;
  Location location = Location();

  PermissionStatus permissionGranted;
  bool denied = false;

  DBHelper db;
  ShroomLocationsData shroomLocData;
  SettingsPrefs setPrefs;

  int redrawId;





  @override
  void initState() {
    super.initState();
    setInitialLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      highlightIntro();
    });

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = Provider.of<DBHelper>(context);
    setPrefs = Provider.of<SettingsPrefs>(context, listen: true);
    shroomLocData = Provider.of<ShroomLocationsData>(context);
    addShroomPins(shroomLocData.shroomsLoc);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      key: _scaffoldKey,
      endDrawer: MapDrawer(),
      endDrawerEnableOpenDragGesture: false,
      body: Stack(
          children: [

            SafeArea(child: getMap()),

            requestPermissionButton(),

            Positioned(
              key: _introAddKey,
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
                      onPressed: onAddShroomsPressed,
                    )
                ),
              ),
            ),

            Positioned(
              right: 5, top:5,
              child: SafeArea(
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.menu, color: Colors.white),
                      iconSize: 25,
                      onPressed: ()=> _scaffoldKey.currentState.openEndDrawer(),
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
      myLocationButtonEnabled: false,
      compassEnabled: false,
      initialCameraPosition: getInitLocation(),
      onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);
      },
    );
  }

  void setInitialLocation() async {

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        setState(() {
          denied = true;
        });
        return;
      }
    }

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
      if(filterWithSettings(shroom)) {
        var bytes = await drawShroomPin(shroom, 150);
        addMarker(shroom, BitmapDescriptor.fromBytes(bytes));
      }
    }
  }

  Future<Uint8List> drawShroomPin(ShroomLocation shroom, int height) async{
    Uint8List imageBytesResized;
    if (shroom.photo == null) {
      //get placeholder
      ByteData bytes = await rootBundle.load('assets/images/shroom_placeholder.png');
      imageBytesResized = bytes.buffer.asUint8List();
    } else {
      var bytes = File(FileHelper.getPhotoPath(shroom.photo, shroom.id)).readAsBytesSync();
      var image = decodeImage(bytes);

      image = copyResizeCropSquare(image, height); //might cause rotation...
      image = bakeOrientation(image); //fixes rotation....

      imageBytesResized = Uint8List.fromList(encodePng(image));
    }

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
    Paint paintCircle = Paint()..color = isPastRemindDate(shroom.remindDays) ? Colors.green : Colors.red;
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
          FlatButton(child: Text("Cancel", style: TextStyle(color: Colors.black38),), onPressed: () => dragRestoreOldLoc(shroomId, context)),
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
    removeFromMarkers(shroomId);

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
              onTap: () => showShroomDetails(shroom),
              markerId: MarkerId(shroom.id.toString()),
              position: LatLng(shroom.lat, shroom.long),
              icon: bitmap));

    });
  }

  void showShroomDetails(ShroomLocation shroom) {

    showModalBottomSheet<dynamic>(
        isScrollControlled: true,
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, modalSetState) {

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
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 15),
                    child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                  margin: EdgeInsets.only(top: 8,),
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white54,),
                                  child: IconButton(
                                    icon: Icon(Icons.delete_forever_outlined, color: Theme.of(context).colorScheme.primary,),
                                    padding: EdgeInsets.zero,
                                    iconSize: 25,
                                    onPressed: () => onTapDelete(shroom),
                                  )),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(shroom.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.onPrimary),),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                margin: EdgeInsets.only(top: 8,),
                                width: 35,
                                height: 35,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.white54,),
                                child: IconButton(
                                  icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary,),
                                  padding: EdgeInsets.zero,
                                  iconSize: 25,
                                  onPressed: () => onPressEdit(shroom, modalSetState),
                                )),
                            ),
                          ),
                      ],),

                      SizedBox(height: 5),
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
          },);
        }
    );
  }

  Widget getImageThumb(ShroomLocation shroom) {
    if (shroom.photo == null) {
      return Container();
    }
    return Thumbnail(initImage: File(FileHelper.getPhotoPath(shroom.photo, shroom.id)), clickImagePicker: false,);
  }

  Widget getLastPickDateText(String remindDate) {
    int days = DateHelper.getDaysCountFromStringDate(remindDate);

    String daysText = days == 0 ? "now" : days == 1 ? "in $days day" : "in $days days";

    return Text("Can be repicked $daysText" + " ($remindDate)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white54));
  }


  bool isPastRemindDate(String remindDays) {
    DateTime remindDate = DateTime.parse(remindDays);
    return remindDate.isBefore(DateTime.now());
  }

  bool alreadyDrawn(ShroomLocation shroom) {
    for (MyMarker marker in _markers) {
      if (shroom.id.toString() == marker.markerId.value) {
        return true;
      }
    }
    return false;
  }

  void onAddShroomsPressed() async {
    var result = await Navigator.push(context, SlideInRightTransition(
        duration: Duration(milliseconds: 1500),
        pageBuilder: (context, animation, secondaryAnimation){
          return AddShrooms(transitionAnimation: animation);
        },
      ),
    );

    if (result != null) {
      ShroomLocation shroom = result as ShroomLocation;
      var googleMapController = await _controller.future;
      googleMapController.moveCamera(CameraUpdate.newLatLngZoom(LatLng(shroom.lat, shroom.long), 18));
      showShroomDetails(shroom);
    }

  }

  void onTapDelete(ShroomLocation shroom) async {
    await NAlertDialog(
        onDismiss: () {},
        dialogStyle: DialogStyle(titleDivider: false),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text("Are you sure you want to delete this spot?"),
        ),
        actions: <Widget>[
          FlatButton(child: Text("Cancel", style: TextStyle(color: Colors.black38),), onPressed: () => Navigator.pop(context)),
          FlatButton(child: Text("Delete"), onPressed: () => deleteShroom(shroom.id, shroom.photo, shroom.name)),
        ],
    ).show(context);
  }

  void removeFromMarkers(int id) {
    _markers.removeWhere((element) => id.toString() == element.markerId.value);
  }

  void deleteShroom(int id, String photo, String name) {
    db.deleteShroomLocation(id);
    removeFromMarkers(id);
    shroomLocData.delete(id);

    //only delete from prefs if it was the last one with name
    if (shroomLocData.shroomsLoc.where((element) => element.name == name).isEmpty) setPrefs.remove(name);

    if(photo != null) File(FileHelper.getPhotoPath(photo, id)).delete();

    Navigator.pop(context);
    Navigator.pop(context);
  }

  void onPressEdit(ShroomLocation shroom, modalSetState) async{
    var mapController = await _controller.future;
    mapController.hideMarkerInfoWindow(MarkerId(shroom.id.toString()));

    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) =>
        EditShroom(shroom))).then((value) {
          modalSetState(() {});
          if (value != -1){
            redrawMarker(value);
          }
        });
  }

  void redrawMarker(int id) async{
    //remove old marker
    removeFromMarkers(id);

    ShroomLocation shroom = shroomLocData.shroomsLoc.firstWhere((element) => id == element.id);
    var bytes = await drawShroomPin(shroom, 150);
    addMarker(shroom, BitmapDescriptor.fromBytes(bytes));
  }

  bool filterWithSettings(ShroomLocation shroom) {
    if(setPrefs.settings.onlyRegrows) {
      if (DateHelper.getDaysCountFromStringDate(shroom.remindDays) != 0) {
        if (alreadyDrawn(shroom)) {
          setState(() {
            removeFromMarkers(shroom.id);
          });
        }
        return false;
        }
      }

    if(setPrefs.settings.displayShrooms[shroom.name]) {
      return true;
    } else {
      if (alreadyDrawn(shroom)) {
        setState(() {
          removeFromMarkers(shroom.id);
        });
      }
      return false;
    }
  }

  Widget requestPermissionButton() {
    if(denied) {
          return Padding(
            padding: EdgeInsets.only(top: 100),
            child: Align(
              alignment: Alignment.center,
              child: Column(
                children: [
                  RaisedButton(
                    onPressed: () async{
                      permissionGranted = await location.requestPermission();
                      if (permissionGranted != PermissionStatus.granted) {
                        denied = true;
                      } else {
                        setState(() {
                          denied = false;
                          setInitialLocation();
                        });
                      }
                    },
                    color: Theme.of(context).colorScheme.background,
                    child: Text("Request permission again", style: TextStyle(color: Theme.of(context).colorScheme.onBackground, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 10),
                  Text("If the button doesn't work, you", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                  Text("have to go into your phone settings and", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                  Text("enable the permission for this app.", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );

    }
    return Container();
  }

  void highlightIntro() {
    var intro = setPrefs.prefs.get("introHighlight");
    if (intro != null && intro) return;

    _controller.future.then((value) {
      CoachMark coachMark = CoachMark();
      RenderBox target = _introAddKey.currentContext.findRenderObject();
      Rect markRect = target.localToGlobal(Offset.zero) & target.size;
      markRect = Rect.fromCircle(center: markRect.center, radius: markRect.longestSide * 0.6);
      coachMark.show(
          targetContext: _introAddKey.currentContext,
          markRect: markRect,
          children: [
            Positioned(
                top: markRect.bottom + 15,
                left: 10,
                child: Text("Tap to add a new mushroom spot",
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    )))
          ],
          duration: null,
          onClose: () {
            setPrefs.prefs.setBool("introHighlight", true);
          });

    });
  }



}
