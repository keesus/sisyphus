import 'package:flutter/material.dart';
import 'package:sisyphus/screen/add_workout_screen.dart';
import 'package:sisyphus/screen/show_workout_screen.dart';
import '../db/workouts/db_workouts_helper.dart';
import '../countdown.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  late int weight;
  late int reps;
  int id = 0;


  @override
  void initState() {
    super.initState();

    weight = 100;
    reps = 5;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () { Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AddWorkoutScreen()));},
              icon: Icon(Icons.add)
          ),
          IconButton(
              onPressed: () { Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ShowWorkoutScreen()));},
              icon: Icon(Icons.list)
          ),
        ],
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center (
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CountDown(),
                ControlPanel(),
              ],
            )
      )
      )

    );
  }


  void addWeight(int weight) {
    setState(() {
      this.weight += weight;
    });
  }

  void reduceWeight(int weight) {
    setState(() {
      this.weight -= weight;
    });
  }

  void addReps(int number) {
    setState(() {
      this.reps += number;
    });
  }

  void reduceReps(int number) {
    setState(() {
      this.reps -= number;
    });
  }




  Widget ControlPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('벤치프레스', style: TextStyle(fontSize: 25)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
                child: Text('-10'),
                onPressed: () => reduceWeight(10)
            ),
            TextButton(
                child: Text('-5'),
                onPressed: () => reduceWeight(5)
            ),
            Text('$weight kg', style: TextStyle(fontSize: 20),),
            TextButton(
                child: Text('+5'),
                onPressed: () => addWeight(5)
            ),
            TextButton(
                child: Text('+10'),
                onPressed: () => addWeight(10)
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
                child: Text('-1'),
                onPressed: () => reduceReps(1)
            ),
            Text('$reps회', style: TextStyle(fontSize: 20),),
            TextButton(
                child: Text('+1'),
                onPressed: () => addReps(1)
            ),
          ],
        )
      ],
    );

  }

}



