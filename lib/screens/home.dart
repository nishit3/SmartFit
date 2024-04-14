import 'package:flutter/material.dart';
import 'package:smart_fit/screens/profile.dart';
import 'package:smart_fit/widget/current_posture.dart';
import 'package:smart_fit/widget/exercises.dart';
import 'package:smart_fit/widget/statistics.dart';

class HomeScreen extends StatefulWidget
{
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() {
    return _HomeScreenState();
  }

}

class _HomeScreenState extends State<HomeScreen>
{
  int index=1;
  Widget currentContent = const CurrentPosture();
  String currentAppBarTitle = "SmartFit";


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(252, 242, 242, 1.0),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(255, 29, 38,0.9),
        title: Text(currentAppBarTitle,style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
              onPressed: (){
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen(),));
              },
              icon: const Icon(Icons.settings,color: Colors.white,size: 27,))
        ],
      ),



      body: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30,),
            Text("  Current Posture", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
            SizedBox(height: 40,),
            CurrentPosture(),
            SizedBox(height: 100,),
            Text("  Statistics", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),),
            SizedBox(height: 5,),
            Statistics(),
            // SizedBox(height: 100,),
            // Text("  Recommended Exercise",style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            // SizedBox(height: 5,),
            // Exercises(),
          ],
        ),
      ),



      // bottomNavigationBar: ConvexAppBar(
      //   style: TabStyle.textIn,
      //   initialActiveIndex: 1,
      //   items: const [
      //     TabItem(icon: Icons.watch_later_rounded, title: "Stats"),
      //     TabItem(icon: Icons.accessible, title: "Now"),
      //     TabItem(icon: Icons.accessibility_new_rounded, title: "Exercises"),
      //   ],
      //   onTap: (localIndex) {
      //     if(localIndex == 0)
      //     {
      //       setState(() {
      //         index = 0;
      //         currentAppBarTitle = "Statistics";
      //         currentContent = const Statistics();
      //       });
      //     }
      //     else if(localIndex == 1)
      //     {
      //       setState(() {
      //         index = 1;
      //         currentAppBarTitle = "SmartFit";
      //         currentContent = const CurrentPosture();
      //       });
      //     }
      //     if(localIndex == 2)
      //     {
      //       setState(() {
      //         index = 2;
      //         currentAppBarTitle = "Recommended Exercises";
      //         currentContent = const Exercises();
      //       });
      //     }
      //   },
      // ),
    );
  }

}