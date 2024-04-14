import 'package:flutter/material.dart';

class SingleExercise extends StatelessWidget
{
  String title;
  AssetImage image;
  SingleExercise({super.key, required this.title, required this.image});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: const EdgeInsets.all(10),
          color: Colors.blue,
          elevation: 50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Column(
              children: [
                Image(image: image, fit: BoxFit.fill),
                const SizedBox(height: 5,),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20,),)
              ],
            ),

        ),
        const SizedBox(height: 10,),
      ],
    );
  }

}