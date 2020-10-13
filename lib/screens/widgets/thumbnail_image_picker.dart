import 'dart:io';

import 'package:my_shrooms/util/file.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_shrooms/util/filehelper.dart';
import 'package:my_shrooms/util/widget_util.dart';
import 'package:thumbnailer/thumbnailer.dart';

class ThumbnailImagePicker extends StatefulWidget {

  ThumbnailImagePicker(Key key, {this.initImage}) : super(key: key);
  File initImage;

  @override
  ThumbnailImagePickerState createState() => ThumbnailImagePickerState(initImage);
}

class ThumbnailImagePickerState extends State<ThumbnailImagePicker> {

  ThumbnailImagePickerState(File initImage) {
    image = initImage;
  }

  File image;
  final picker = ImagePicker();
  bool newImage = false;


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: getImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: WidgetUtil.boxDecorationBlur(context, Colors.white),
        child: getPhotoOrPlaceholder(context),
      ),
    );

  }

  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        image = File(pickedFile.path);
        newImage = true;
      } else {
        print('No image selected.');
      }
    });
  }

  Widget getPhotoOrPlaceholder(BuildContext context) {
    if (image == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Take a photo?", style: TextStyle(fontSize: 20, color: Colors.black54, fontWeight: FontWeight.bold)),
          Icon(Icons.camera_alt, color: Colors.black54, size: 40,),
        ],
      );
    }
    return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Thumbnail(
          dataResolver: () async {
            return image.readAsBytes();
          },
          mimeType: "image/" + image.extension,
          widgetSize: double.infinity,
        )
    );
  }

}
