import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:my_shrooms/animations/fade_in.dart';
import 'package:my_shrooms/custom_widget/counter.dart';
import 'package:my_shrooms/inheritedwidgets/shroom_locations.dart';
import 'package:my_shrooms/models/shroom_location.dart';
import 'package:my_shrooms/services/db_helper.dart';
import 'package:my_shrooms/util/widget_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:thumbnailer/thumbnailer.dart';
import 'package:my_shrooms/util/file.dart';

class AddShrooms extends StatefulWidget {
  @override
  _AddShroomsState createState() => _AddShroomsState();
}

class _AddShroomsState extends State<AddShrooms> {
  Location location = Location();
  Completer<LocationData> locationData = Completer();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String shroomName;

  File _image;
  final picker = ImagePicker();
  Completer<String> dirPath = Completer();

  DBHelper db;
  ShroomLocationsData shroomLocData;

  int _counterValue = 5;


  @override
  void initState() {
    super.initState();
    location.getLocation().then((value) => locationData.complete(value));

    getApplicationDocumentsDirectory().then((value) => dirPath.complete('${value.path}/Pictures'));

    KeyboardVisibility.onChange.listen((bool visible) {
      if (!visible && context != null) FocusScope.of(context).unfocus(); //if keyboard dismiss remove focus from textField
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    db = Provider.of<DBHelper>(context);
    shroomLocData = Provider.of<ShroomLocationsData>(context);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          color: Theme.of(context).colorScheme.background,
          child: Column(
            children: [
              //HEADER
              Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30),),
                    image: DecorationImage(image: AssetImage('assets/images/myShrooomHeader.png'), fit: BoxFit.fill)
                  ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SafeArea(child: IconButton(icon: Icon(Icons.close), color: Theme.of(context).colorScheme.onPrimary, onPressed: ()=> Navigator.pop(context))),

                    SizedBox(height: 30),

                    Padding(
                      padding: const EdgeInsets.only(left: 15),
                      child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FadeAnimation(0.5,
                            Text("Add your",
                              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),),
                          ),
                          FadeAnimation(0.8,
                            Text("mushroom spot",
                              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),),
                          ),
                      ],)
                    ),

                    SizedBox(height: 25),


                  ],
                )
              ),

              SizedBox(height: 40,),

              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 15),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 5),
                        child: Text("Mushroom name", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                      ),
                      SizedBox(height: 5,),
                      Container(
                        decoration: WidgetUtil.boxDecorationBlur(context, Colors.white),
                        child: Container(
                          padding: EdgeInsets.only(top: 6, bottom: 6, right: 6, left: 12),
                          child: TextFormField(
                            validator: (value) => value.isEmpty ? "Please enter a name" : null,
                            onSaved: (newValue) => shroomName = newValue,
                            decoration: InputDecoration(
                                border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 40),

                      InkWell(
                        onTap: getImage,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: WidgetUtil.boxDecorationBlur(context, Colors.white),
                          child: getPhotoOrPlaceholder(context),
                        ),
                      ),

                      SizedBox(height: 30),

                      Align(
                          alignment: Alignment.center,
                          child: Text("Remind me to repick in $_counterValue days", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground))),
                      Align(
                          alignment: Alignment.center,
                          child: Counter(
                            textPadding: 10,
                            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            buttonSize: 40,
                            iconColor: Theme.of(context).colorScheme.onPrimary,
                            color: Theme.of(context).colorScheme.primary,
                            initialValue: _counterValue, minValue: 0, maxValue: 50, step: 1, decimalPlaces: 0,
                            onChanged: (value) {
                              setState(() {
                                _counterValue = value;
                              });
                            },
                        ),
                      ),

                      SizedBox(height: 40),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 200,
                          decoration: WidgetUtil.boxDecorationBlur(context, Theme.of(context).colorScheme.primary),
                          child: RawMaterialButton(
                              child: Text("Save", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary)),
                              onPressed: onPressSave),
                        ),
                      ),
                      SizedBox(height: 40),

                  ],),
                ),
              )
            ],
          ),
        )
      ),
    );
  }


  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Widget getPhotoOrPlaceholder(BuildContext context) {
    if (_image == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Take a photo?", style: TextStyle(fontSize: 20, color: Colors.black54, fontWeight: FontWeight.bold)),
          Icon(Icons.camera_alt, color: Colors.black54, size: 40,),
        ],
      );
    }

    return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Thumbnail(
          dataResolver: () async {
            return _image.readAsBytes();
          },
          mimeType: "image/" + _image.extension,
          widgetSize: double.infinity,
        )
    );


  }


  void onPressSave() async{
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();


    var directory = await dirPath.future;
    var currentLocation = await locationData.future;
    String remindDate = DateTime.now().add(Duration(days: _counterValue)).toIso8601String().split("T").first;
    var shroom = ShroomLocation(name: shroomName, pickCount: 1, long: currentLocation.longitude,
        lat: currentLocation.latitude, remindDays: remindDate, photo: _image != null ? '$directory/shroomlocation_.'+_image.extension : null);
    var id = db.insertShroomLocation(shroom);

    id.then((id) async {
      if (_image != null) {
        await storeImageLocally(_image, id, directory);
      }

      shroom.id = id;
      shroomLocData.add(shroom);
      Navigator.pop(context);
    });


  }

  Future<String> storeImageLocally(File image, int id, String directory) async{
    await Directory(directory).create(recursive: true);
    String filePath = '$directory/shroomlocation_$id.' + image.extension;
    await image.copy(filePath);

    return filePath;
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

}
