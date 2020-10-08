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

  ShroomLocation changeCoords(int id, LatLng coords) {
    var shroom = _shrooms.firstWhere((element) => id == element.id );
    shroom.lat = coords.latitude;
    shroom.long = coords.longitude;

    //notifyListeners?
    //doesnt seem to be needed
    return shroom;
  }
}