import 'dart:io';

import 'package:flutter/material.dart';

class ViewImageFullScreen extends StatelessWidget {
  ViewImageFullScreen({this.image});

  File image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
          fit: StackFit.expand,
          children: [

            Image.file(image, fit:BoxFit.fill,),

            Positioned(
              left: 5, top:5,
              child: SafeArea(
                child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black.withOpacity(0.3),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      iconSize: 25,
                      onPressed: () => Navigator.pop(context),
                    )
                ),
              ),
            )
          ]
      ),
    );
  }
}
