import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';


class Statistics extends StatefulWidget
{
  const Statistics({super.key});

  @override
  State<Statistics> createState() {
    return _StatisticsState();
  }

}

class _StatisticsState extends State<Statistics>
{
  int todayGoodPostureSeconds = 0;
  int todayBadPostureSeconds = 0;
  bool isLoading=true;
  bool isDailyComparisonAvailable=true;
  var now = DateTime.now();
  var formatter = DateFormat('yyyy-MM-dd');
  late String formattedDate;
  late int todayGoodPostureSecond;
  late int todayBadPostureSecond;
  final DatabaseReference ref = FirebaseDatabase.instance.ref("${FirebaseAuth.instance.currentUser!.uid}/Posture_Data");



  List<ChartData> chartData = [];
  List<ColumnChartData> columnChartData = [];


  Future<void> setTodayPostureData() async
  {
    formattedDate = formatter.format(now);
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayDate = formatter.format(yesterday);
    final dayBeforeYesterday = now.subtract(const Duration(days: 2));
    final dayBeforeYesterdayDate = formatter.format(dayBeforeYesterday);
    final dayBeforeDayBeforeYesterday = now.subtract(const Duration(days: 3));
    final dayBeforeDayBeforeYesterdayDate = formatter.format(dayBeforeDayBeforeYesterday);
    final ref1 = await ref.child("$formattedDate/goodPostureCount").get();
    final ref2 = await ref.child("$formattedDate/badPostureCount").get();
    final todayData = await ref.child(formattedDate).get();
    final yesterdayData = await ref.child(yesterdayDate).get();
    final dayBeforeYesterdayData = await ref.child(dayBeforeYesterdayDate).get();
    final dayBeforeDayBeforeYesterdayData = await ref.child(dayBeforeDayBeforeYesterdayDate).get();

    if(ref1.value==null || ref2.value==null)
    {
      todayGoodPostureSecond = 50;
      todayBadPostureSecond = 200;
    }
    else
    {
      todayGoodPostureSecond = ref1.value as int;
      todayBadPostureSecond = ref2.value as int;
    }
    chartData=
    [
      ChartData('Good Posture', double.parse((todayGoodPostureSecond/50).toStringAsFixed(1)), Colors.green),
      ChartData('Bad Posture', double.parse((todayBadPostureSecond/200).toStringAsFixed(1)), Colors.red),
    ];



    if(todayData.value==null)
      {
        isDailyComparisonAvailable=false;
      }
    else
      {
        isDailyComparisonAvailable=true;
        columnChartData.add(ColumnChartData(0, double.parse((((todayData.value as Map<Object?, Object?>)["badPostureCount"] as int)/200).toStringAsFixed(1)),   double.parse((((todayData.value as Map<Object?, Object?>)["goodPostureCount"] as int)/50).toStringAsFixed(1))));
        if(yesterdayData.value != null)
          {
            double goodCount = double.parse((((yesterdayData.value as Map<Object?, Object?>)["goodPostureCount"] as int)/50).toStringAsFixed(1));
            double badCount = double.parse((((yesterdayData.value as Map<Object?, Object?>)["badPostureCount"] as int)/200).toStringAsFixed(1));
            columnChartData.add(ColumnChartData(1,badCount,goodCount));
          }
        if(dayBeforeYesterdayData.value != null)
        {
          double goodCount = double.parse((((dayBeforeYesterdayData.value as Map<Object?, Object?>)["goodPostureCount"] as int)/50).toStringAsFixed(1));
          double badCount = double.parse((((dayBeforeYesterdayData.value as Map<Object?, Object?>)["badPostureCount"] as int)/200).toStringAsFixed(1));
          columnChartData.add(ColumnChartData(2,badCount,goodCount));
        }
        if(dayBeforeDayBeforeYesterdayData.value != null)
        {
          double goodCount = double.parse((((dayBeforeDayBeforeYesterdayData.value as Map<Object?, Object?>)["goodPostureCount"] as int)/50).toStringAsFixed(1));
          double badCount = double.parse((((dayBeforeDayBeforeYesterdayData.value as Map<Object?, Object?>)["badPostureCount"] as int)/200).toStringAsFixed(1));
          columnChartData.add(ColumnChartData(3,badCount,goodCount));
        }
      }


    setState(() {});
  }

  void checkForChange() async
  {
    // setState(() {
    //   isLoading=true;
    // });
    await setTodayPostureData();
    setState(() {
      isLoading=false;
    });
  }

  @override
  void initState() {
    checkForChange();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Timer.periodic(const Duration(seconds: 20), (timer) { setTodayPostureData();});
    return isLoading?
    const Center(child: CircularProgressIndicator(color: Colors.red),)
        :
    Center(
        child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
                elevation: 30,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                margin: const EdgeInsets.fromLTRB(15, 25, 15, 0),
                color: Colors.blue,
                child: SfCircularChart(
                    title: ChartTitle(alignment: ChartAlignment.center, text: "Today's Posture (min)",textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                    series: <CircularSeries>[
                      // Render pie chart
                      PieSeries<ChartData, String>(
                          //radius: "50",
                          dataLabelSettings: const DataLabelSettings(isVisible: true,),
                          dataSource: chartData,
                          pointColorMapper:(ChartData data, _) => data.color,
                          xValueMapper: (ChartData data, _) => data.x,
                          yValueMapper: (ChartData data, _) => data.y
                      )
                    ]
                ),
              ),


            // if(isDailyComparisonAvailable)Card(
            //   elevation: 30,
            //   shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
            //   margin: const EdgeInsets.fromLTRB(15, 25, 15, 25),
            //   color: Colors.blue,
            //   child: SfCartesianChart(
            //       title: ChartTitle(alignment: ChartAlignment.center, text: "Avg Posture / Day (min)",textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
            //       enableSideBySideSeriesPlacement: false,
            //       series: <ChartSeries<ColumnChartData, int>>[
            //
            //         ColumnSeries<ColumnChartData, int>(
            //
            //             //dataLabelSettings: const DataLabelSettings(isVisible: true,),
            //             color: Colors.red,
            //             dataSource: columnChartData,
            //             xValueMapper: (ColumnChartData data, _) => data.x,
            //             yValueMapper: (ColumnChartData data, _) => data.y
            //         ),
            //
            //         ColumnSeries<ColumnChartData, int>(
            //             //dataLabelSettings: const DataLabelSettings(isVisible: true,),
            //             color: Colors.green,
            //             opacity: 0.9,
            //             width: 0.4,
            //             dataSource: columnChartData,
            //             xValueMapper: (ColumnChartData data, _) => data.x,
            //             yValueMapper: (ColumnChartData data, _) => data.y1
            //         )
            //
            //       ]
            //   ),
            // ),
            //const SizedBox(height: 30),
          ],
        ),
      ) 
    );
  }
}

class ChartData {
  ChartData(this.x, this.y, this.color);
  final String x;
  final double y;
  final Color color;
}

class ColumnChartData {
  ColumnChartData(this.x, this.y, this.y1);
  final int x;
  final double y;
  final double y1;
}

