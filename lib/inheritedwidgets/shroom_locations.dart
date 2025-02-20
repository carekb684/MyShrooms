import 'package:flutter/cupertino.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  void delete(int id) {
    _shrooms.removeWhere((element) => element.id == id);
    notifyListeners();
  }

  ShroomLocation changeCoords(int id, LatLng coords) {
    var shroom = _shrooms.firstWhere((element) => id == element.id );
    shroom.lat = coords.latitude;
    shroom.long = coords.longitude;

    return shroom;
  }

  void updateShroom(ShroomLocation inShroom) {
    int index = _shrooms.indexWhere((element) => inShroom.id == element.id );
    _shrooms[index] = inShroom;
  }
}