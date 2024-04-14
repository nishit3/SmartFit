import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart_fit/data/exercise_data.dart';
import 'package:smart_fit/widget/single_exercise.dart';

class Exercises extends StatelessWidget
{
  const Exercises({super.key});

  @override
  Widget build(BuildContext context) {
    return  SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...exerciseData.map((e) => SingleExercise(title: e.title, image: e.image,)),
          const SizedBox(height: 20,)
        ],
      ),
    );
  }
}
