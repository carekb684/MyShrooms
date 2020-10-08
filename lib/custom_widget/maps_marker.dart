import 'package:google_maps_flutter/google_maps_flutter.dart';

class MyMarker extends Marker {

  MyMarker({markerId, alpha, anchor, consumeTapEvents, draggable, flat, icon, infoWindow, position,
    rotation, visible, zIndex, onTap, onDragEnd}) :
        super(markerId: markerId, alpha: alpha, anchor: anchor, consumeTapEvents: consumeTapEvents,
          draggable: draggable, flat: flat, icon:icon, infoWindow:infoWindow, position: position,
        rotation: rotation, visible: visible, zIndex: zIndex, onTap: onTap, onDragEnd: onDragEnd,
  );


  @override
  bool operator==(other) {
    // Dart ensures that operator== isn't called with null
    // if(other == null) {
    //   return false;
    // }
    if(other is! MyMarker) {
      return false;
    }
    return markerId == (other as MyMarker).markerId;
  }
}