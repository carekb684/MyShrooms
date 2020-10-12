import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:my_shrooms/animations/add_shroom_slide_animation.dart';
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

  AddShrooms({this.transitionAnimation});
  final Animation<double> transitionAnimation;

  @override
  _AddShroomsState createState() => _AddShroomsState();
}

class _AddShroomsState extends State<AddShrooms> {
  Location location = Location();
  Completer<LocationData> locationData = Completer();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _typeAheadController = TextEditingController();
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
              //######
              //HEADER
              SlideInAnimation(
                  animation: widget.transitionAnimation,
                  begin: Offset(0, -1), end: Offset(0,0),
                  interval: Interval(0.3, 0.5, curve: Curves.easeOutCubic),
                  child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30),),
                          image: DecorationImage(image: AssetImage('assets/images/myShrooomHeader.png'), fit: BoxFit.fill)
                      ),
                      child:
                      //######
                      //MUSHROOM NAME
                      Column(
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

                      SlideInAnimation(
                          animation: widget.transitionAnimation,
                          begin: Offset(-1.2, 0), end: Offset(0,0),
                          interval: Interval(0.4, 1.0, curve: Curves.easeOutCubic),
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
                                  child: TypeAheadFormField(
                                    textFieldConfiguration: TextFieldConfiguration(
                                        textCapitalization: TextCapitalization.sentences,
                                        controller: this._typeAheadController,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                        )
                                    ),
                                    validator: (value) => value.isEmpty ? "Please enter a name" : null,
                                    onSaved: (newValue) => shroomName = newValue,
                                    hideOnEmpty: true, hideOnLoading: true,
                                    suggestionsCallback: getNameSuggestions,
                                    suggestionsBoxVerticalOffset: 6.0,
                                    suggestionsBoxDecoration: SuggestionsBoxDecoration(elevation: 0, offsetX: -3),
                                    itemBuilder: (context, suggestion) {
                                      return ListTile(
                                        title: Text(suggestion),
                                      );
                                    },
                                    transitionBuilder: (context, suggestionsBox, controller) {
                                      return suggestionsBox;
                                    },
                                    onSuggestionSelected: (suggestion) {
                                      this._typeAheadController.text = suggestion;
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ),

                      SizedBox(height: 40),
                      //######
                      //TAKE A PHOTO

                      SlideInAnimation(
                          animation: widget.transitionAnimation,
                          begin: Offset(1.2, 0), end: Offset(0,0),
                          interval: Interval(0.4, 1.0, curve: Curves.easeOutCubic),
                          child: InkWell(
                            onTap: getImage,
                            child: Container(
                              width: double.infinity,
                              height: 200,
                              decoration: WidgetUtil.boxDecorationBlur(context, Colors.white),
                              child: getPhotoOrPlaceholder(context),
                            ),
                          ),
                      ),

                      SizedBox(height: 30),

                      //#####
                      //REMIND TO REPICK + SAVE
                      SlideInAnimation(
                          animation: widget.transitionAnimation,
                          begin: Offset(0, 1), end: Offset(0,0),
                          interval: Interval(0.4, 1.0, curve: Curves.easeOutCubic),
                        child: Column(
                          children: [
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
                          ],
                        ),
                      ),

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
      Navigator.pop(context, shroom);
    });


  }

  Future<String> storeImageLocally(File image, int id, String directory) async{
    await Directory(directory).create(recursive: true);
    String filePath = '$directory/shroomlocation_$id.' + image.extension;
    await image.copy(filePath);

    return filePath;
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();


  FutureOr<Iterable> getNameSuggestions(String pattern) {
    if (pattern.isEmpty) return [];
    List<ShroomLocation> list = shroomLocData.shroomsLoc;
    return list.where((element) => element.name.toLowerCase().startsWith(pattern.toLowerCase()) &&
        element.name.toLowerCase() != pattern.toLowerCase()).map((e) => e.name);
  }
}
