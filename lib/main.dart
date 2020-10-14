import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_shrooms/inheritedwidgets/settings_prefs.dart';
import 'package:my_shrooms/inheritedwidgets/shroom_locations.dart';
import 'package:my_shrooms/models/settings.dart';
import 'package:my_shrooms/models/shroom_location.dart';
import 'package:my_shrooms/screens/home_map.dart';
import 'package:my_shrooms/services/db_helper.dart';
import 'package:my_shrooms/util/color_from_hex.dart';
import 'package:provider/provider.dart';
import 'package:random_color_scheme/random_color_scheme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:math' as math;

void main() {
  runApp(
    DevicePreview(
    enabled: true,
    builder: (context) => MyApp(),
  ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  SettingsPrefs setPrefs;
  DBHelper dbHelper;
  Completer<List<ShroomLocation>> shroomCompleter = Completer();
  List<ShroomLocation> shrooms;

  @override
  void initState() {
    super.initState();
    getDB();
    initPrefs();
  }

  void getDB() async {
    final Future<Database> future = DBHelper.init();
    Database db = await future;
      dbHelper = DBHelper(db: db);
      dbHelper.getShroomLocations().then((value){
        setState(() {
          shroomCompleter.complete(value);
        });
      });
  }

  void initPrefs() async {
    SharedPreferences sPrefs = await SharedPreferences.getInstance();
    if (!sPrefs.containsKey("onlyRegrows")) {
      sPrefs.setBool("onlyRegrows", false);
    }

    shrooms = await shroomCompleter.future;
    setupSettings(shrooms, sPrefs);
  }

  void setupSettings(List<ShroomLocation> shrooms, SharedPreferences sPrefs) {
    var settingsObj = Settings();
    settingsObj.onlyRegrows = sPrefs.get("onlyRegrows");

    Map<String, bool> settingsMap = {};
    for (ShroomLocation shroom in shrooms) {
      settingsMap[shroom.name] = sPrefs.get(shroom.name);
    }
    settingsObj.displayShrooms = settingsMap;

    setState(() {
      setPrefs = SettingsPrefs(prefs: sPrefs)..settings = settingsObj;
    });
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    return LoadDbThenShowPage(context);
  }

  Widget LoadDbThenShowPage(BuildContext context) {
    if (setPrefs == null) {
      return Container(
        color: HexColor.fromHex("#325411"),
      );
    } else {
      return MultiProvider(
        providers: [
          Provider<DBHelper>( create: (_) => dbHelper),
          ChangeNotifierProvider<ShroomLocationsData>( create: (_) => ShroomLocationsData(shrooms)),
          ChangeNotifierProvider<SettingsPrefs>( create: (_) => setPrefs),
        ],

        child: MaterialApp(
            locale: DevicePreview.of(context).locale,
            builder: DevicePreview.appBuilder,
            debugShowCheckedModeBanner: false,
            title: 'Flutter Demo',
            theme: ThemeData(
              colorScheme: randomColorSchemeLight(seed: getSeed(2925)), //seed: 2925 == nice green
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            home: HomeMap(),
            routes: {
              //"/profile": (context) => MyProfile(),
              "/screens.home": (context) => HomeMap(),
            }
        ),
      );
    }
  }

  int getSeed([int seed]) {
    if (seed == null) {
      seed = math.Random().nextInt(10000);
    }
    print("ColorScheme Seed: " + seed.toString());
    return seed;
  }



}
