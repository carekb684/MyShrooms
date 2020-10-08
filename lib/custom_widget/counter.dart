import 'package:flutter/material.dart';

typedef void CounterChangeCallback(num value);

class Counter extends StatelessWidget {

  final CounterChangeCallback onChanged;

  Counter({
    Key key,
    @required num initialValue,
    @required this.minValue,
    @required this.maxValue,
    @required this.onChanged,
    @required this.decimalPlaces,
    this.color,
    this.textStyle,
    this.step = 1,
    this.buttonSize = 25,
    this.iconColor = Colors.black,
    this.textPadding = 4.0,
  })  : assert(initialValue != null),
        assert(minValue != null),
        assert(maxValue != null),
        assert(maxValue > minValue),
        assert(initialValue >= minValue && initialValue <= maxValue),
        assert(step > 0),
        selectedValue = initialValue,
        super(key: key);

  ///min value user can pick
  final num minValue;

  ///max value user can pick
  final num maxValue;

  /// decimal places required by the counter
  final int decimalPlaces;

  ///Currently selected integer value
  num selectedValue;

  /// if min=0, max=5, step=3, then items will be 0 and 3.
  final num step;

  /// indicates the color of fab used for increment and decrement
  Color color;

  //icon color
  Color iconColor;

  //textPadding
  double textPadding;

  /// text syle
  TextStyle textStyle;

  final double buttonSize;

  void _incrementCounter() {
    if (selectedValue + step <= maxValue) {
      onChanged((selectedValue + step));
    }
  }

  void _decrementCounter() {
    if (selectedValue - step >= minValue) {
      onChanged((selectedValue - step));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    color = color ?? themeData.accentColor;
    textStyle = textStyle ?? new TextStyle(
      fontSize: 20.0,
    );

    return new Container(
      padding: new EdgeInsets.all(4.0),
      child: new Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          new SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: FloatingActionButton(
              heroTag: "btn1",
              onPressed: _decrementCounter,
              elevation: 2,
              tooltip: 'Decrement',
              child: Icon(Icons.remove, color: iconColor,),
              backgroundColor: color,
            ),
          ),
          new Container(
            padding: EdgeInsets.symmetric(horizontal: textPadding),
            child: new Text(
                '${num.parse((selectedValue).toStringAsFixed(decimalPlaces))}',
                style: textStyle
            ),
          ),
          new SizedBox(
            width: buttonSize,
            height: buttonSize,
            child: FloatingActionButton(
              heroTag: "btn2",
              onPressed: _incrementCounter,
              elevation: 2,
              tooltip: 'Increment',
              child: Icon(Icons.add, color: iconColor),
              backgroundColor: color,
            ),
          ),
        ],
      ),
    );
  }
}