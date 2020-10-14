import 'dart:async';
import 'dart:io';

import 'package:my_shrooms/inheritedwidgets/settings_prefs.dart';
import 'package:my_shrooms/screens/add_shrooms.dart';
import 'package:my_shrooms/util/datehelper.dart';
import 'package:my_shrooms/util/file_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:my_shrooms/custom_widget/counter.dart';
import 'package:my_shrooms/inheritedwidgets/shroom_locations.dart';
import 'package:my_shrooms/models/shroom_location.dart';
import 'package:my_shrooms/screens/widgets/add_shroom_header.dart';
import 'package:my_shrooms/screens/widgets/enter_shroom_name.dart';
import 'package:my_shrooms/screens/widgets/remind_repick_counter.dart';
import 'package:my_shrooms/screens/widgets/thumbnail_image_picker.dart';
import 'package:my_shrooms/services/db_helper.dart';
import 'package:my_shrooms/util/filehelper.dart';
import 'package:my_shrooms/util/widget_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditShroom extends StatefulWidget {
  EditShroom(ShroomLocation shroom) {
    this.shroom = shroom;
  }

  ShroomLocation shroom;

  @override
  _EditShroomState createState() => _EditShroomState(shroom);
}

class _EditShroomState extends State<EditShroom> {
  Completer<String> dirPath = Completer();
  ShroomLocationsData shroomLocData;
  DBHelper db;
  SettingsPrefs setPrefs;

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<EnterShroomNameState> nameKey = new GlobalKey<EnterShroomNameState>();
  GlobalKey<ThumbnailState> thumbnailKey = new GlobalKey<ThumbnailState>();
  File thumbInitImage;
  GlobalKey<RepickCounterState> repickKey = new GlobalKey<RepickCounterState>();

  _EditShroomState(ShroomLocation shroom) {
    pickCount = shroom.pickCount;
  }
  int pickCount;


  @override
  void initState() {
    super.initState();

    KeyboardVisibility.onChange.listen((bool visible) {
      if (!visible && context != null) FocusScope.of(context).unfocus(); //if keyboard dismiss remove focus from textField
    });

    if(widget.shroom.photo != null) thumbInitImage = File(FileHelper.getPhotoPath(widget.shroom.photo, widget.shroom.id));

    getApplicationDocumentsDirectory().then((value) => dirPath.complete('${value.path}/Pictures'));
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
          child: Column(children: [
            AddShroomHeader("Edit your"),
            SizedBox(height: 40),

            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 15),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  EnterShroomName(nameKey, initText: widget.shroom.name,),
                  SizedBox(height: 40),
                  Thumbnail(key: thumbnailKey, initImage: thumbInitImage,),
                  SizedBox(height: 30),
                  RepickCounter(repickKey, initCount: DateHelper.getDaysCountFromStringDate(widget.shroom.remindDays)),
                  SizedBox(height: 20),

                  Align(
                      alignment: Alignment.center,
                      child: Text("Total times picked", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground))),
                  Align(
                    alignment: Alignment.center,
                    child: Counter(
                      textPadding: 10,
                      textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      buttonSize: 40,
                      iconColor: Theme.of(context).colorScheme.onPrimary,
                      color: Theme.of(context).colorScheme.primary,
                      initialValue: pickCount, minValue: 0, maxValue: 50, step: 1, decimalPlaces: 0,
                      onChanged: (value) {
                        setState(() {
                          pickCount = value;
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

                ]),
              ),
            ),

          ]),
        ),
      ),
    );
  }

  void onPressSave() async{
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();

    File image = thumbnailKey.currentState.image;
    bool newImage = thumbnailKey.currentState.newImage;
    int remindDays = repickKey.currentState.counterValue;

    var directory = await dirPath.future;
    String remindDate = DateTime.now().add(Duration(days: remindDays)).toIso8601String().split("T").first;
    String oldRemindDate = widget.shroom.remindDays;
    String oldName = widget.shroom.name;
    String newName = nameKey.currentState.shroomName;

    var shroom = widget.shroom..
    pickCount = pickCount..
    name = newName..
    remindDays = remindDate;

    db.updateShroomLocation(shroom);
    shroomLocData.updateShroom(shroom);

    if(oldName != newName) {
      if (shroomLocData.shroomsLoc.where((element) => element.name == oldName).isEmpty) setPrefs.prefs.remove(oldName);
      setPrefs.prefs.setBool(newName, true);
    }

    int id = -1;
    //need to redraw?
    if(newImage) {
      String imagePath = '$directory/shroomlocation_.'+image.extension;
      shroom.photo = imagePath;
      await FileHelper.storeImageLocally(image, shroom.id, directory);
      id = shroom.id;
    } else {
      int oldRemindCount = DateHelper.getDaysCountFromStringDate(oldRemindDate);
      if ((oldRemindCount != 0 && remindDays == 0) || (oldRemindCount == 0 && remindDays != 0)) {
        //remindCount has been changed so a redraw is needed for pin color (red/green)
        id = shroom.id;
      }
    }



    Navigator.pop(context, id);

  }
}
