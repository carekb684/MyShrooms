import 'package:flutter/material.dart';

class SlideInAnimation extends StatelessWidget {

  SlideInAnimation({this.child, this.begin, this.end, this.interval, this.animation});

  Widget child;
  Offset begin;
  Offset end;
  Animation<double> animation;
  Interval interval;

  @override
  Widget build(BuildContext context) {

    return AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return SlideTransition(
            child: child,
            position: Tween<Offset>(begin: begin, end: end).animate(
                CurvedAnimation(
                  curve: interval,
                  parent: animation,
                )));
        },
        child: child,
    );
  }

}
