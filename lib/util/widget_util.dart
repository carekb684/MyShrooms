import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class WidgetUtil {


  static BoxDecoration boxDecorationBlur(BuildContext context, Color color) {
    return BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: 20.0,
              offset: Offset(0, 10)
          )
        ]
    );
  }
}