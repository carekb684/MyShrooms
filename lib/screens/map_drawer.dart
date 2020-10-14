import 'package:flutter/material.dart';
import 'package:my_shrooms/inheritedwidgets/shroom_locations.dart';
import 'package:my_shrooms/models/shroom_location.dart';
import 'package:my_shrooms/services/db_helper.dart';
import 'package:provider/provider.dart';

class MapDrawer extends StatefulWidget {
  @override
  _MapDrawerState createState() => _MapDrawerState();
}

class _MapDrawerState extends State<MapDrawer> {
  double drawerWidth;

  DBHelper db;
  ShroomLocationsData shroomLocData;
  Set<String> shroomNames;

  bool onlyGrown = false;


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    db = Provider.of<DBHelper>(context);
    shroomLocData = Provider.of<ShroomLocationsData>(context);
    shroomNames = shroomLocData.shroomsLoc.map((e) => e.name).toSet();
  }

  @override
  Widget build(BuildContext context) {

    drawerWidth = MediaQuery.of(context).size.width - 56;

    return Drawer(
        child: Container( color: Theme.of(context).colorScheme.primary,
          child: SafeArea(
              child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                    children: [
                      SizedBox(height: 10,),
                      Text("Filters", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),),
                      SizedBox(height: 5,),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                              width: drawerWidth / 2,
                              child: Text("Only show potential regrown spots", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary))),

                          Switch(
                            activeColor: Colors.white,
                            value: onlyGrown,
                            onChanged: (value) {
                              setState(() {
                                onlyGrown = value;
                              });
                            },
                          ),
                        ],),

                      SizedBox(height: 10,),
                      Text("Display only", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),),
                      //SizedBox(height: 5,),

                      getShroomNameList(),


                    ],
    ),
                  ))),
        ));
  }

  Widget getShroomNameList() {

    return ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: shroomNames.length,
        itemBuilder: (context, index) {
          String name = shroomNames.elementAt(index);

          return CheckboxListTile(
            value: false,
            title: Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),),
            contentPadding: EdgeInsets.only(top:0, left:0, bottom: 0, right:20),
            onChanged: (value) {
              setState(() {

              });
            },
          );
        }
    );
  }
}
