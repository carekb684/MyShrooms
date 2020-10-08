import 'package:flutter/cupertino.dart';
import 'package:my_shrooms/models/shroom_location.dart';

class ShroomLocationsData with ChangeNotifier {
  ShroomLocationsData(List<ShroomLocation> shrooms) {
    _shrooms = shrooms;
  }

  List<ShroomLocation> _shrooms;

  List<ShroomLocation> get shroomsLoc {
    return _shrooms;
  }

  void add(ShroomLocation shroom) {
    _shrooms.add(shroom);
    notifyListeners();
  }
}