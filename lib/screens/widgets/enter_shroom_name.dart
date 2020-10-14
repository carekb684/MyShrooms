import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:my_shrooms/inheritedwidgets/shroom_locations.dart';
import 'package:my_shrooms/models/shroom_location.dart';
import 'package:my_shrooms/services/db_helper.dart';
import 'package:my_shrooms/util/widget_util.dart';
import 'package:provider/provider.dart';

class EnterShroomName extends StatefulWidget {

  EnterShroomName(Key key, {this.initText}) : super(key: key);
  String initText;

  @override
  EnterShroomNameState createState() => EnterShroomNameState();
}

class EnterShroomNameState extends State<EnterShroomName> {
  final TextEditingController _typeAheadController = TextEditingController();

  ShroomLocationsData shroomLocData;
  DBHelper db;
  String shroomName;


  @override
  void initState() {
    super.initState();

    if (widget.initText != null) _typeAheadController.text = widget.initText;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = Provider.of<DBHelper>(context);
    shroomLocData = Provider.of<ShroomLocationsData>(context);
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text("Mushroom name", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
        ),

        SizedBox(height: 5,),
        Container(
          decoration: WidgetUtil.boxDecorationBlur(context, Colors.white),
          child: Container(
            padding: EdgeInsets.only(top: 6, bottom: 6, right: 6, left: 12),
            child: TypeAheadFormField(
              textFieldConfiguration: TextFieldConfiguration(
                  textCapitalization: TextCapitalization.sentences,
                  controller: this._typeAheadController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                  )
              ),
              validator: (value) => value.isEmpty ? "Please enter a name" : null,
              onSaved: (newValue) => shroomName = newValue,
              hideOnEmpty: true, hideOnLoading: true,
              suggestionsCallback: getNameSuggestions,
              suggestionsBoxVerticalOffset: 6.0,
              suggestionsBoxDecoration: SuggestionsBoxDecoration(elevation: 0, offsetX: -3),
              itemBuilder: (context, suggestion) {
                return ListTile(
                  title: Text(suggestion),
                );
              },
              transitionBuilder: (context, suggestionsBox, controller) {
                return suggestionsBox;
              },
              onSuggestionSelected: (suggestion) {
                this._typeAheadController.text = suggestion;
              },
            ),
          ),
        ),
      ],
    );
  }

  FutureOr<Iterable> getNameSuggestions(String pattern) {
    if (pattern.isEmpty) return [];
    List<ShroomLocation> list = shroomLocData.shroomsLoc;
    return list.where((element) => element.name.toLowerCase().startsWith(pattern.toLowerCase()) &&
        element.name.toLowerCase() != pattern.toLowerCase()).map((e) => e.name).toSet().map((e) => e);
  }
}