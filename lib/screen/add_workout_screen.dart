
import 'package:flutter/material.dart';
import 'package:sisyphus/db/bodyparts_workouts.dart';
import '../db/db_helper.dart';
import '../db/workouts.dart';

class AddWorkoutScreen extends StatefulWidget {
  const AddWorkoutScreen({Key? key}) : super(key: key);

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final textController = TextEditingController();
  late String createdAt;
  late String updatedAt;
  late String dropdownValue;
  final List<String> bodyparts = ['가슴', '등', '어깨', '팔', '하체'];

  @override
  void initState() {
    dropdownValue = bodyparts.first;
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {Navigator.pop(context);},
        ),
        title: Text('운동 추가')
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('추가할 운동이름은 ?'),
                  TextField(controller: textController),
                  SizedBox(height: 40,),
                  Text('운동 부위를 골라주세요.'),
                  SizedBox(height: 10,),
                  DropdownButton(
                    value: dropdownValue,
                    items: bodyparts.map((String value) {
                      return DropdownMenuItem(
                          value: value,
                          child: Text(value)
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        dropdownValue = value!;
                      });
                    }
                  ),
                  SizedBox(height: 20,),
                ],
              ),
              ElevatedButton(
                  onPressed: () async {
                    createdAt = DateTime.now().toIso8601String();
                    updatedAt = DateTime.now().toIso8601String();
                    if(textController.text != null && dropdownValue != null) {
                      var workoutID = await DBHelper.instance.insertWorkouts(Workouts(name: textController.text, created_at: createdAt, updated_at: updatedAt));
                      await DBHelper.instance.insertBodypartsWorkouts(BodypartsWorkouts(workout: workoutID, bodypart: dropdownValue, createdAt: createdAt, updatedAt: updatedAt));
                      setState(() {
                        textController.clear();
                        dropdownValue = bodyparts.first;
                      });
                    }
                  },
                  child: Text('운동 추가하기')
              )
            ],
          ),
        ),
      )
    );
  }


}






