import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_shrooms/inheritedwidgets/shroom_locations.dart';
import 'package:my_shrooms/models/shroom_location.dart';
import 'package:my_shrooms/screens/home_map.dart';
import 'package:my_shrooms/services/db_helper.dart';
import 'package:my_shrooms/util/color_from_hex.dart';
import 'package:provider/provider.dart';
import 'package:random_color_scheme/random_color_scheme.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:math' as math;

void main() {
  runApp(
    DevicePreview(
    enabled: false,
    builder: (context) => MyApp(),
  ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  DBHelper dbHelper;
  List<ShroomLocation> shroomLocations;

  @override
  void initState() {
    super.initState();
    getDB();
  }

  void getDB() async {
    final Future<Database> future = DBHelper.init();

    future.then((value){
      dbHelper = DBHelper(db: value);
      dbHelper.getShroomLocations().then((value){
        setState(() {
          shroomLocations = value;
        });
      });


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
    if (dbHelper == null) {
      return Container(
        color: HexColor.fromHex("#325411"),
      );
    } else {
      return MultiProvider(
        providers: [
          Provider<DBHelper>( create: (_) => dbHelper),
          ChangeNotifierProvider<ShroomLocationsData>( create: (_) => ShroomLocationsData(shroomLocations)),
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
