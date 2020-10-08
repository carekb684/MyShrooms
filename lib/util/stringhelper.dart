class StringHelper {

  static String getPhotoPath(String name, int id) {
    List<String> list = name.split(".");
    list[list.length - 2] = list[list.length - 2] + "$id";
    return list.join(".");

  }
}