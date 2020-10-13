import 'package:flutter/material.dart';
import 'package:my_shrooms/animations/fade_in.dart';

class AddShroomHeader extends StatelessWidget {
  AddShroomHeader(this.text);

  String text;

  @override
  Widget build(BuildContext context) {
    return Container(
        width: double.infinity,
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30),),
            image: DecorationImage(image: AssetImage('assets/images/myShrooomHeader.png'), fit: BoxFit.fill)
        ),
        child:
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SafeArea(child: IconButton(icon: Icon(Icons.close), color: Theme.of(context).colorScheme.onPrimary, onPressed: ()=> Navigator.pop(context))),

            SizedBox(height: 30),

            Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Column( crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeAnimation(0.5,
                      Text(text,
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),),
                    ),
                    FadeAnimation(0.8,
                      Text("mushroom spot",
                        style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),),
                    ),
                  ],)
            ),

            SizedBox(height: 25),

          ],
        )
    );
  }
}