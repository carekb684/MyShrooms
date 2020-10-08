import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class FadeAnimation extends StatelessWidget {
  final double delay;
  final Widget child;
  MultiTween tween;

  FadeAnimation(this.delay, this.child){
    tween = MultiTween();
    tween.add("opacity", Tween(begin: 0.0, end: 1.0), Duration(milliseconds: 500));
    tween.add("translateY", Tween(begin: -30.0, end: 0.0), Duration(milliseconds: 500), Curves.easeOut);

  }

  @override
  Widget build(BuildContext context) {

/*
    final oldTween = MultiTrackTween([
      Track("opacity").add(Duration(milliseconds: 500), Tween(begin: 0.0, end: 1.0)),
      Track("translateY").add(
          Duration(milliseconds: 500), Tween(begin: -30.0, end: 0.0),
          curve: Curves.easeOut)
    ]);
*/
    return CustomAnimation(
      delay: Duration(milliseconds: (500 * delay).round()),
      duration: tween.duration,
      tween: tween,
      child: child,
      builder: (context, child, value) => Opacity(
          opacity: value.get("opacity"),
          child: Transform.translate(
              offset: Offset(0, value.get("translateY")),
              child: child
          ),
        )
    );
/*
    return ControlledAnimation(
      delay: Duration(milliseconds: (500 * delay).round()),
      duration: tween.duration,
      tween: tween,
      child: child,
      builderWithChild: (context, child, animation) => Opacity(
        opacity: animation["opacity"],
        child: Transform.translate(
            offset: Offset(0, animation["translateY"]),
            child: child
        ),
      ),
    );

 */
  }
}