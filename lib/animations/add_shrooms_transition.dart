import 'package:flutter/material.dart';
import 'package:my_shrooms/screens/add_shrooms.dart';

class SlideInRightTransition extends PageRouteBuilder {
  Duration duration;
  Widget Function(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) pageBuilder;

  SlideInRightTransition({this.duration, this.pageBuilder}) : super(
      pageBuilder: pageBuilder,
      transitionDuration: duration,
      transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Interval(0, 0.3, curve: Curves.easeInCubic))),
          child: child,
        );
      }
  );
}