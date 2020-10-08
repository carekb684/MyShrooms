class ShroomLocation {

  ShroomLocation({this.id, this.name, this.lat, this.long, this.pickCount, this.remindDays, this.photo});

  int id;
  String name;
  double lat;
  double long;
  int pickCount;
  int remindDays;
  String photo;

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      "name": name,
      "lat": lat,
      "long": long,
      "pickCount": pickCount,
      "remindDays": remindDays,
      "photo": photo,
    };

    return map;
  }

  factory ShroomLocation.fromMap(Map<String, dynamic> map) {
    return ShroomLocation(
        id: map["id"], name: map["name"], lat: map["lat"],
        long: map["long"], pickCount: map["pickCount"],
        remindDays: map["remindDays"], photo: map["photo"]);
  }

}