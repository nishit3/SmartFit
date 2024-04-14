import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';

import '../models/posture_types.dart';


class CurrentPosture extends StatefulWidget
{
  const CurrentPosture({super.key});

  @override
  State<CurrentPosture> createState() {
    return _CurrentPostureState();
  }

}

class _CurrentPostureState extends State<CurrentPosture>
{
  String textToBePassed='Connected to SmartFit Device';
  bool isConnecting = true;
  late BluetoothDevice smartFit;
  PostureTypes postureType = PostureTypes.ACTIVE;
  late double leftRightAngle;
  late double frontBackAngle;
  Color cardColor = Colors.yellow;
  String displayMsg="You are actively moving.";
  late int todayGoodPostureSecond;
  late PostureTypes prevPostureType;
  bool isLoading=true;
  late int todayBadPostureSecond;
  String goodPostureMsg = "Great Posture !!";
  String badPostureMsg = "Posture not looking great !";
  String activePostureMsg = "You are actively moving.";
  var now = DateTime.now();
  var formatter = DateFormat('yyyy-MM-dd');
  late String formattedDate;
  final DatabaseReference ref = FirebaseDatabase.instance.ref("${FirebaseAuth.instance.currentUser!.uid}/Posture_Data");




  Future<void> getTodayPostureData() async
  {
    final ref1 = await ref.child("$formattedDate/goodPostureCount").get();
    final ref2 = await ref.child("$formattedDate/badPostureCount").get();

    if(ref1.value==null || ref2.value==null)
    {
      await ref.child(formattedDate).update({
        "goodPostureCount": 0,
        "badPostureCount": 0
      });
      todayGoodPostureSecond = 0;
      todayBadPostureSecond = 0;
    }
    else
    {
      todayGoodPostureSecond = ref1.value as int;
      todayBadPostureSecond = ref2.value as int;
    }
  }

  void initiateClassVariables()
  {
    String type = textToBePassed.substring(0, textToBePassed.indexOf("A"));
    leftRightAngle = double.parse(textToBePassed.substring(textToBePassed.indexOf("B")+1, textToBePassed.length-1));
    frontBackAngle = double.parse(textToBePassed.substring(textToBePassed.indexOf("A")+1, textToBePassed.indexOf("B")));
    switch (type)
    {
      case "g": postureType = PostureTypes.GOOD;cardColor=Colors.green;displayMsg=goodPostureMsg;break;
      case "bl": postureType = PostureTypes.BAD_LEFT;cardColor=Colors.red;displayMsg=badPostureMsg;break;
      case "br": postureType = PostureTypes.BAD_RIGHT;cardColor=Colors.red;displayMsg=badPostureMsg;break;
      case "bf": postureType = PostureTypes.BAD_FRONT;cardColor=Colors.red;displayMsg=badPostureMsg;break;
      case "bb": postureType = PostureTypes.BAD_BACK;cardColor=Colors.red;displayMsg=badPostureMsg;break;
      case "a": postureType = PostureTypes.ACTIVE;cardColor=Colors.yellow;displayMsg=activePostureMsg;break;
    }
  }

  Future<void> sendDataToFBRealTimeDB() async
  {
    if(postureType==PostureTypes.GOOD)
    {
      await ref.child(formattedDate).update({
        "goodPostureCount": todayGoodPostureSecond+1,
      });
    }
    else if(postureType==PostureTypes.BAD_BACK || postureType==PostureTypes.BAD_FRONT || postureType==PostureTypes.BAD_LEFT || postureType==PostureTypes.BAD_RIGHT)
    {
      await ref.child(formattedDate).update({
        "badPostureCount": todayBadPostureSecond+1,
      });
    }
  }

  void doInitialSetup() async
  {
    formattedDate = formatter.format(now);
    initiateClassVariables();
    await getTodayPostureData();
    await sendDataToFBRealTimeDB();
  }


  void enableBlueTooth() async
  {
    if (await FlutterBluePlus.isAvailable == false) {
      return;
    }

    if (Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }

    await FlutterBluePlus.adapterState
        .map((s){return s;})
        .where((s) => s == BluetoothAdapterState.on)
        .first;
  }

  void listenToSmartFitBLE() async
  {
    List<BluetoothService> services = await smartFit.discoverServices();
    for (var service in services) {
      if(service.uuid.toString() == Guid("4fafc201-1fb5-459e-8fcc-c5c9c331914b").toString())
        {
          for(BluetoothCharacteristic char in service.characteristics)
            {
              if(char.uuid.toString() == Guid("beb5483e-36e1-4688-b7f5-ea07361b26a8").toString())
                {
                  List<int> newValue = await char.read(timeout: 3);
                  setState(() {
                    textToBePassed = String.fromCharCodes(newValue);
                    doInitialSetup();
                  });
                  break;
                }
            }
          break;
        }
    }
    Timer.periodic(const Duration(seconds: 20), (timer) { listenToSmartFitBLE();});
  }

  void findAndConnectToSmartFitBLE() async
  {
    // setState(() {
    //   isConnecting=true;
    // });
    Set<DeviceIdentifier> seen = {};
    var subscription = FlutterBluePlus.scanResults.listen(
            (results) async {
          for (ScanResult r in results) {
            if (seen.contains(r.device.remoteId) == false) {
              if(r.device.localName == "SmartFit")
                {
                  smartFit = r.device;
                  smartFit.connectionState.listen((BluetoothConnectionState state) async {
                    await smartFit.connect();
                    setState(() {
                      isConnecting=false;
                    });
                  });
                  break;
                }
            }
          }
        },
    );
    await FlutterBluePlus.startScan();
  }

  @override
  void initState() {
    enableBlueTooth();
    findAndConnectToSmartFitBLE();
    super.initState();
  }

  @override
  void dispose() {
    Navigator.pop(context);
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {

    if(!isConnecting) listenToSmartFitBLE();
    return (isConnecting || textToBePassed=='Connected to SmartFit Device')? const Center(
      child:  Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: Colors.red), SizedBox(height: 25),Text("Connecting To SmartFit Device, Kindly Wait\n              (Power On SmartFit Device)")],))
    :
        Container(
          padding: const EdgeInsets.all(10),
          // child: Text(textToBePassed),
          child: Card(
              color: cardColor,
              elevation: 20.00,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Container(
                padding: const EdgeInsets.fromLTRB(15,30,20,20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(displayMsg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Container(height: 20,),
                    if (postureType==PostureTypes.BAD_RIGHT) Text("Tilted Right Side By $leftRightAngle°",style: const TextStyle(color: Colors.white),)
                    else if (postureType==PostureTypes.BAD_LEFT) Text("Tilted Left Side By $leftRightAngle°",style: const TextStyle(color: Colors.white),)
                    else if (postureType==PostureTypes.BAD_FRONT) Text("Tilted Front Side By $frontBackAngle°",style: const TextStyle(color: Colors.white),)
                      else if (postureType==PostureTypes.BAD_BACK) Text("Tilted Back Side By $frontBackAngle°",style: const TextStyle(color: Colors.white),),
                    Container(height: 20,),
                  ],
                ),
              )
          ),
        );
  }
}

