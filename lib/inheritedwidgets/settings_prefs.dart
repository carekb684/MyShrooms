import 'package:flutter/cupertino.dart';
import 'package:my_shrooms/models/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPrefs with ChangeNotifier {

  SettingsPrefs({this.prefs});
  SharedPreferences prefs;

  Settings settings;

  void notify() {
    notifyListeners();
  }
}