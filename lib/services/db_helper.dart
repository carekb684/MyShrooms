import 'package:my_shrooms/models/shroom_location.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {

  static final String LOCATIONS_TABLE = "shroom_location";
  static final String LOCATIONS_CREATE =
      "CREATE TABLE shroom_location(id INTEGER PRIMARY KEY AUTOINCREMENT,"
      " name TEXT, pickCount INTEGER,"
      " remindDays TEXT, lat DOUBLE,"
      " long DOUBLE, photo INTEGER)";

  Database db;
  DBHelper({this.db});

  static Future<Database> init() async {
    return openDatabase(
      join(await getDatabasesPath(), 'shroom_location.db'),
      onCreate: (db, version) {
        db.execute(LOCATIONS_CREATE);
      },
      onUpgrade: (db, oldVersion, newVersion) {
        if (oldVersion < newVersion) {
          db.execute("DROP TABLE IF EXISTS shroom_location");
          db.execute(LOCATIONS_CREATE);
        }
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 19,
    );
  }


  Future<int> deleteShroomLocation(int id) {
    var future = db.delete(LOCATIONS_TABLE, where: "id = ?", whereArgs: [id]);
    return future;
  }



  Future<int> insertShroomLocation(ShroomLocation shroom) async {
    var future = await db.insert(LOCATIONS_TABLE, shroom.toMap(), conflictAlgorithm: ConflictAlgorithm.fail);
    return future;
  }

  void updateShroomLocation(ShroomLocation shroom) {
    db.update(LOCATIONS_TABLE, shroom.toMap(), where: "id = ?", whereArgs: [shroom.id]);
  }


  Future<List<ShroomLocation>> getShroomLocations() async {
    List<Map<String, dynamic>> maps = await db.query(LOCATIONS_TABLE);

    return List.generate(maps.length, (index) {
      return ShroomLocation.fromMap(maps[index]);
    });
  }



}