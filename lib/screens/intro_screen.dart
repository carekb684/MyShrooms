import 'package:flutter/material.dart';
import 'package:intro_slider/intro_slider.dart';
import 'package:intro_slider/slide_object.dart';
import 'package:my_shrooms/inheritedwidgets/settings_prefs.dart';
import 'package:my_shrooms/screens/home_map.dart';
import 'package:my_shrooms/util/color_from_hex.dart';
import 'package:provider/provider.dart';

class IntroScreen extends StatefulWidget {
  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  List<Slide> slides = new List();

  SettingsPrefs setPrefs;

  @override
  void initState() {
    super.initState();

    slides.add(Slide(
      title: "Welcome to",
      styleTitle: TextStyle(fontFamily: "Pacifico", color: Colors.white, fontSize: 40),
      description: "This app will help you keep track of your most hidden, hard to find mushroom spots!",
      styleDescription: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
      pathImage: "assets/images/my_shroom_splash_image.png",
      backgroundColor: HexColor.fromHex("325411"),
      ),
    );
    slides.add(Slide(
      title: "GPS",
      styleTitle: TextStyle(fontFamily: "Pacifico", color: Colors.white, fontSize: 40),
      description: "This app uses gps to track where you find mushrooms. Please accept the gps permissions request :)",
      styleDescription: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
      pathImage: "assets/images/maps_cartoon.png",
      backgroundColor: HexColor.fromHex("325411"),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setPrefs = Provider.of<SettingsPrefs>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return IntroSlider(
      slides: slides,
      onDonePress: startApp,
      onSkipPress: startApp,
    );
  }

  void startApp() {
    setPrefs.prefs.setBool("introScreen", true);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (BuildContext context) => HomeMap()));
  }
}
