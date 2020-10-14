import 'package:flutter/material.dart';
import 'package:my_shrooms/custom_widget/counter.dart';
import 'package:super_tooltip/super_tooltip.dart';

class RepickCounter extends StatefulWidget {
  RepickCounter(Key key, {this.initCount}) : super(key: key);
  int initCount;

  @override
  RepickCounterState createState() => RepickCounterState(initCount);
}

class RepickCounterState extends State<RepickCounter> {
  SuperTooltip tooltip;


  RepickCounterState(int initCount) {
    counterValue = initCount == null ? 5 : initCount;
  }

  int counterValue;


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: closeToolTip,
      child: Column(
        children: [
          Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Can be repicked in $counterValue days",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                  //builder to get widget context for showing tooltip
                  Builder(builder: (context) {
                    return IconButton(
                      icon: Icon(Icons.help_outline, color: Colors.black),
                      onPressed: () => onTapTooltip(context),
                    );
                  }),
                ],
              )),
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
      ),
    );
  }

  void onTapTooltip(BuildContext context) {
    if (tooltip != null && tooltip.isOpen) {
      tooltip.close();
      return;
    }
    tooltip = SuperTooltip(
      popupDirection: TooltipDirection.up,
      content: Material(
        child: Text("Estimate when the mushrooms will have regrown after picking them."
            " The pins on the map will have a green color when the date has passed so you know when to go back to this spot!", softWrap: true,),
      ),
    );
    tooltip.show(context);
  }

  Future<bool> closeToolTip() async {
    if (tooltip != null && tooltip.isOpen) {
      tooltip.close();
      return false;
    }
    return true;
  }

}
