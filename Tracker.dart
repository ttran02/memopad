/*
Last Edit: Thanh
Date: 5/10
Modify: Add funtions to save and retrieve steps from shared preferences
 */
import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepData{
  final DateTime date;
  int step;

  StepData({required this.date, required this.step});
  // Retrieve data from shared preferences
  factory StepData.fromJson(Map<String, dynamic> json) {
    return StepData(
      date: DateTime.parse(json['date']),
      step: json['step']
    );
  }
  // convert data to json string
  Map<String, dynamic> toJson() {
    return {
      'date' : DateTime.now().toIso8601String(),
      'step' : step
    };
  }
}

class Tracker extends StatefulWidget {
  const Tracker({super.key});
  @override
  _StepState createState() => _StepState();
}

class _StepState extends State<Tracker> {
  late Stream<StepCount> _stepCountStream;
  late String todayStep = '0';
  late int step;
  List<StepData> allStepRecord = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }
  // event change
  void onStepChange(StepCount event) {
    setState(() {
      step = event.steps;
    });
  }
  // event error
  void onStepError(error) {
    print(error);
    setState(() {
      todayStep = 'Step Count not available';
    });
  }

  Future<void> initPlatformState() async {
    if (await Permission.activityRecognition.request().isGranted) {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(onStepChange).onError(onStepError);
    } else {
      
    }
    if (!mounted) return;
  }
  // add to list
  void addRecord(StepData record) {
    allStepRecord.add(record);
  }
  // get step count records
  Future<String> countStep() async {
    String count = '';
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String? jsonData = pref.getString('records');
      DateTime lastDate;
      DateTime currDate;

      if(jsonData != null) {
        List<dynamic> jsonList = jsonDecode(jsonData);
        allStepRecord = jsonList.map((e) => StepData.fromJson(e)).toList();

        if (allStepRecord.isEmpty) {
          lastDate = DateTime.now();
        } else {
          lastDate = allStepRecord.last.date;
        }
        currDate = DateTime.now();
        
        if (lastDate.year == currDate.year && lastDate.month == currDate.month && lastDate.day == currDate.day) {
          allStepRecord.last.step = step;
          count = (step - allStepRecord[allStepRecord.length - 2].step).toString();
          _saveRecord();
        } else {
          count = (step - allStepRecord.last.step).toString();
          addRecord(StepData(date: currDate, step: step));
          _saveRecord();
        }
      }
    } catch(e) {
      print('Error loading step records: $e');
      count = 'Step Count not available';
    }
    return count;
  }
  // get today's step count
  String getStep() {
    Future<String> s = countStep();
    s.then((value) {
      todayStep = value;
    },);
    return todayStep;
  }
  // save to shared preference
  Future<void> _saveRecord() async {
    try {
      SharedPreferences pref = await SharedPreferences.getInstance();
      String json = jsonEncode(allStepRecord);
      await pref.setString('record', json);
    } catch(e) {
      print('Error saving records: $e');
    }
  }

  
  // build UI
  @override
  Widget build(BuildContext context) {
    return Row(
      
      children: [
      const Text('Steps Taken: ',
          style: 
            TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.bold)),
      Text(getStep(),
        style: 
          const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))
    ]);
  }
}
