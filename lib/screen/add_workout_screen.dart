import 'package:flutter/material.dart';
import '../db/workouts/db_workouts_helper.dart';
import '../db/workouts/workouts.dart';

class AddWorkoutScreen extends StatefulWidget {
  const AddWorkoutScreen({Key? key}) : super(key: key);

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final textController = TextEditingController();
  late String createdAt;
  late String updatedAt;

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
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('추가할 운동은 ?'),
              TextField(controller: textController),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          createdAt = DateTime.now().toString();
          updatedAt = DateTime.now().toString();
          await DBWorkoutsHelper.instance.insert(Workouts(name: textController.text, created_at: createdAt, updated_at: updatedAt));
          setState(() {
            textController.clear();
          });
        },
        child: Icon(Icons.add),
      ),
    );
  }


}






