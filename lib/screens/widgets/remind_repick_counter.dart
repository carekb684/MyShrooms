import 'package:flutter/material.dart';
import 'package:my_shrooms/custom_widget/counter.dart';

class RepickCounter extends StatefulWidget {
  RepickCounter(Key key, {this.initCount}) : super(key: key);
  int initCount;

  @override
  RepickCounterState createState() => RepickCounterState(initCount);
}

class RepickCounterState extends State<RepickCounter> {

  RepickCounterState(int initCount) {
    counterValue = initCount == null ? 5 : initCount;
  }

  int counterValue;


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
            alignment: Alignment.center,
            child: Text("Can be repicked in $counterValue days", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground))),
        Align(
          alignment: Alignment.center,
          child: Counter(
            textPadding: 10,
            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            buttonSize: 40,
            iconColor: Theme.of(context).colorScheme.onPrimary,
            color: Theme.of(context).colorScheme.primary,
            initialValue: counterValue, minValue: 0, maxValue: 50, step: 1, decimalPlaces: 0,
            onChanged: (value) {
              setState(() {
                counterValue = value;
              });
            },
          ),
        ),
      ],
    );
  }
}
