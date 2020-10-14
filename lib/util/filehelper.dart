import 'dart:io';
import 'package:my_shrooms/util/file_extension.dart';


class FileHelper {

  static String getPhotoPath(String name, int id) {
    List<String> list = name.split(".");
    list[list.length - 2] = list[list.length - 2] + "$id";
    return list.join(".");
  }

  static Future<String> storeImageLocally(File image, int id, String directory) async{
    await Directory(directory).create(recursive: true);
    String filePath = '$directory/shroomlocation_$id.' + image.extension;
    await image.copy(filePath);

    return filePath;
  }
}