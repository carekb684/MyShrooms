import 'package:flutter/material.dart';
import 'package:my_shrooms/inheritedwidgets/settings_prefs.dart';
import 'package:my_shrooms/inheritedwidgets/shroom_locations.dart';
import 'package:my_shrooms/models/settings.dart';
import 'package:my_shrooms/models/shroom_location.dart';
import 'package:my_shrooms/services/db_helper.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapDrawer extends StatefulWidget {
  @override
  _MapDrawerState createState() => _MapDrawerState();
}

class _MapDrawerState extends State<MapDrawer> {
  double drawerWidth;

  DBHelper db;
  SettingsPrefs setPrefs;
  ShroomLocationsData shroomLocData;

  Set<String> shroomNames;

  bool onlyGrown = false;



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = Provider.of<DBHelper>(context);
    shroomLocData = Provider.of<ShroomLocationsData>(context);
    shroomNames = shroomLocData.shroomsLoc.map((e) => e.name).toSet();

    setPrefs = Provider.of<SettingsPrefs>(context, listen: false);
    setupSettings();
  }

  @override
  void dispose() {
    //called when drawer is closed, postFrameCallback because home_map will redraw and notifyListeners
    // will trigger a setstate in the middle of build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setPrefs.notifyListeners();
    });

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    drawerWidth = MediaQuery.of(context).size.width - 56;

    return Drawer(
        child: Container( color: Theme.of(context).colorScheme.primary,
          child: SafeArea(
              child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                    children: [
                      SizedBox(height: 10,),
                      Text("Filters", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),),
                      SizedBox(height: 5,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                              width: drawerWidth / 2,
                              child: Text("Only show potential regrown spots", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary))),

                          Switch(
                            activeColor: Colors.white,
                            value: setPrefs.settings.onlyRegrows,
                            onChanged: (value) {
                              setState(() {
                                setPrefs.settings.onlyRegrows = value;
                                setPrefs.prefs.setBool("onlyRegrows", value);
                              });
                            },
                          ),
                        ],),

                      SizedBox(height: 10,),
                      Text("Display only", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),),
                      //SizedBox(height: 5,),

                      getShroomNameList(),


                    ],
                  ),
                  )
              )
          ),
        )
    );
  }

  Widget getShroomNameList() {

    return ListView(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: setPrefs.settings.displayShrooms.entries.map((e) => CheckboxListTile(
          value: e.value,
          title: Text(e.key, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),),
          contentPadding: EdgeInsets.only(top:0, left:0, bottom: 0, right:20),
          activeColor: Theme.of(context).colorScheme.background,
          dense: true,
          onChanged: (value) {
            setState(() {
              setPrefs.settings.displayShrooms[e.key] = value;
              setPrefs.prefs.setBool(e.key, value);
            });
            },
        )).toList(),

    );
  }

  void setupSettings() {
    var settingsObj = Settings();
    settingsObj.onlyRegrows = setPrefs.prefs.get("onlyRegrows");

    Map<String, bool> settingsMap = {};
    for (String name in shroomNames) {
      settingsMap[name] = setPrefs.prefs.get(name);
    }
    settingsObj.displayShrooms = settingsMap;
    setPrefs.settings = settingsObj;
  }
}
