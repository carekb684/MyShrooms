import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:location/location.dart';
import 'package:my_shrooms/animations/add_shroom_slide_animation.dart';
import 'package:my_shrooms/inheritedwidgets/settings_prefs.dart';
import 'package:my_shrooms/inheritedwidgets/shroom_locations.dart';
import 'package:my_shrooms/models/shroom_location.dart';
import 'package:my_shrooms/screens/widgets/add_shroom_header.dart';
import 'package:my_shrooms/screens/widgets/enter_shroom_name.dart';
import 'package:my_shrooms/screens/widgets/remind_repick_counter.dart';
import 'package:my_shrooms/screens/widgets/thumbnail_image_picker.dart';
import 'package:my_shrooms/services/db_helper.dart';
import 'package:my_shrooms/util/datehelper.dart';
import 'package:my_shrooms/util/file_extension.dart';
import 'package:my_shrooms/util/filehelper.dart';
import 'package:my_shrooms/util/widget_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  GlobalKey<EnterShroomNameState> nameKey = new GlobalKey<EnterShroomNameState>();
  GlobalKey<ThumbnailState> thumbnailKey = new GlobalKey<ThumbnailState>();
  GlobalKey<RepickCounterState> repickKey = new GlobalKey<RepickCounterState>();

  Completer<String> dirPath = Completer();

  DBHelper db;
  ShroomLocationsData shroomLocData;
  SettingsPrefs setPrefs;



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
    setPrefs = Provider.of<SettingsPrefs>(context, listen: false);
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
                  child: AddShroomHeader("Add your"),
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
                      //######
                      //MUSHROOM NAME
                      SlideInAnimation(
                          animation: widget.transitionAnimation,
                          begin: Offset(-1.2, 0), end: Offset(0,0),
                          interval: Interval(0.4, 1.0, curve: Curves.easeOutCubic),
                          child: EnterShroomName(nameKey),
                      ),

                      SizedBox(height: 40),
                      //######
                      //TAKE A PHOTO

                      SlideInAnimation(
                          animation: widget.transitionAnimation,
                          begin: Offset(1.2, 0), end: Offset(0,0),
                          interval: Interval(0.4, 1.0, curve: Curves.easeOutCubic),
                          child: Thumbnail(key: thumbnailKey),
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
                            RepickCounter(repickKey),

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

  void onPressSave() async{
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();

    File image = thumbnailKey.currentState.image;
    int count = repickKey.currentState.counterValue;

    var directory = await dirPath.future;
    var currentLocation = await locationData.future;

    String remindDate = DateHelper.getRemindDate(count);

    var shroom = ShroomLocation(name: nameKey.currentState.shroomName, pickCount: 1, long: currentLocation.longitude,
        lat: currentLocation.latitude, remindDays: remindDate, photo: image != null ? '$directory/shroomlocation_.'+image.extension : null);
    var id = db.insertShroomLocation(shroom);

    id.then((id) async {
      if (image != null) {
        await FileHelper.storeImageLocally(image, id, directory);
      }
      shroom.id = id;
      setPrefs.setBool(shroom.name, true);
      shroomLocData.add(shroom);

      Navigator.pop(context, shroom);
    });


  }



  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

}


