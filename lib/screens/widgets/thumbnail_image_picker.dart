import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_shrooms/screens/view_image.dart';
import 'package:my_shrooms/util/widget_util.dart';

class Thumbnail extends StatefulWidget {

  Thumbnail({this.key, this.initImage, this.clickImagePicker = true}) : super(key: key);
  File initImage;
  bool clickView;
  bool clickImagePicker;
  Key key;


  @override
  ThumbnailState createState() => ThumbnailState(initImage);
}

class ThumbnailState extends State<Thumbnail> {

  ThumbnailState(File initImage) {
    image = initImage;
  }

  File image;

  final picker = ImagePicker();
  bool newImage = false;


  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.clickImagePicker ? getImage : viewImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: WidgetUtil.boxDecorationBlur(context, Colors.white),
        child: getPhotoOrPlaceholder(context),
      ),
    );

  }

  void viewImage() {
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => ViewImageFullScreen(image: image)));
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
        child: getThumbnail(),
    );
  }



  Widget getThumbnail() {
    return Center(
      child: Image.file(
        image,
        fit: BoxFit.fitWidth,
        width: double.infinity,
        filterQuality: FilterQuality.none,
      ),
    );
  }

}
