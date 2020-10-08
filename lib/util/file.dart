import 'dart:io';
import 'dart:convert';

extension FileExtension on File {

  String get extension {
    return this?.path?.split(".")?.last;
  }

  Future<String> getImageAsString() async{
    if (this == null) return null;

    var bytes = await this.readAsBytes();
    return base64.encode(bytes);
  }

}