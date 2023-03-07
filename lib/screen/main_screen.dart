import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sisyphus/screen/add_workout_screen.dart';
import 'package:sisyphus/screen/show_workout_screen.dart';
import '../db/evaluations.dart';
import '../db/sets.dart';
import '../db/db_helper.dart';
import '../db/workouts.dart';
import 'package:collection/collection.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  Timer? countTimer;
  Duration myDuration = Duration(days: 5);
  bool isStart = false;

  late int weight;
  late int reps;
  late List<Workouts> workouts;
  late List<Sets> sets;
  late Workouts nowWorkout;

  int id = 0;

  List<int> setIDs = [];
  List<int> completedWeights = [];
  List<int> completedReps = [];
  List<String> completedTypes = [];

  late List<TodaySet> todaySets;

  late int averageWeight;
  late int averageReps;

  @override
  void initState() {
    weight = 100;
    reps = 5;
    todaySets = [];
    averageWeight = 0;
    averageReps = 0;
    nowWorkout = Workouts(id:1 , created_at: '초기값', updated_at: '초기값', name: '');
    getFirstWorkout();
    super.initState();
  }


  void setAverageWeightReps() async {
    // 해당 운동을 했던 세트 조회
    sets = await DBHelper.instance.recentSet(nowWorkout.id!);
    // 해당 세트들이 수행된 날짜리스트
    final dates = sets.map((e) => e.date).toList();
    print('dates: $dates');
    List<int> setNumbers = [];

    for(int i = 0; i < dates.length; i++) {
      var temp = await DBHelper.instance.recentSetNumber(dates[i], nowWorkout.id!);
      setNumbers.add(temp!);
    }
    // var setNumbers = await DBHelper.instance.recentSetNumber(dates[0], nowWorkout.id!);
    print('setNumbers: $setNumbers');

    final recentWeights = sets.map((set) => set.weight!).toList();
    final recentReps = sets.map((set) => set.targetNumTime).toList();
    setState(() {
      averageWeight = recentWeights.average.round();
      averageReps = recentReps.average.round();

      weight = averageWeight;
      reps = averageReps;
    });

  }
  void getFirstWorkout() async {
    workouts = await DBHelper.instance.getWorkouts();
    setState(() {
      nowWorkout = (workouts.toList()..shuffle()).first;
    });
    setCompletedWeightsSetsEvaluations();

  }

  void setCompletedWeightsSetsEvaluations() async {
    setAverageWeightReps();

    todaySets = [];
    int setNumber = 1;

    List<Item>sets = await DBHelper.instance.getTodaySet(nowWorkout.id!);
    sets.forEach((element) async {
      TodaySet todaySet = TodaySet();
      todaySet.number = setNumber++;
      todaySet.completedWeight = element.weight;
      todaySet.completedRep = element.target_num_time;

      List<Item>evaluations = await DBHelper.instance.getTodayEvaluation(element.id!);

      evaluations.forEach((value) {
        todaySet.completedType = value.type!;
      });

      setState(() {
        todaySets.add(todaySet);
      });
    });


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
      body: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            workoutSelect(),
            workoutInfo(),
            counter(),
            controlPanel(),
          ],
        )
      )

    );
  }

  Widget workoutSelect() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () {
            setState(() {
              nowWorkout = (workouts.toList()..shuffle()).first;
            });
            setCompletedWeightsSetsEvaluations();
          }, icon: Icon(Icons.arrow_back_ios_outlined)),
          IconButton(onPressed: () {
            setState(() {
              nowWorkout = (workouts.toList()..shuffle()).first;
            });
            setCompletedWeightsSetsEvaluations();
          }, icon: Icon(Icons.arrow_forward_ios_outlined))

      ],
      ),
    );
  }

  Widget workoutInfo() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(nowWorkout.name, style: TextStyle(fontSize: 20),)
        ],
      ),
    );
  }
  Widget counter() {

    String strDigits(int n) => n.toString().padLeft(2, '0');
    final days = strDigits(myDuration.inDays);
    final hours = strDigits(myDuration.inHours.remainder(24));
    final minutes = strDigits(myDuration.inMinutes.remainder(60));
    final seconds = strDigits(myDuration.inSeconds.remainder(60));
    late int setID;
    //일단 다 clear 한것으로.
    String type = 'clear';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$minutes:$seconds',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 50),
        ),
        const SizedBox(height: 20),
        isStart == false ?
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              fixedSize: const Size(150, 150),
              shape: const CircleBorder()
          ),
          onPressed: startTimer,
          child: const Text(
            '시작',
            style: TextStyle(
              fontSize: 30,
            ),
          ),
        ):
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              fixedSize: const Size(150, 150),
              shape: const CircleBorder()
          ),
          onPressed: () async {
            DateFormat formatter = DateFormat('yyyy-MM-dd');

            if (countTimer == null || countTimer!.isActive) {
              resetTimer();
            }
            setID = await DBHelper.instance.insertSets(Sets(workout: nowWorkout.id, targetNumTime: this.reps, weight: this.weight, date: formatter.format(DateTime.now()), createdAt: DateTime.now().toIso8601String(), updatedAt: DateTime.now().toIso8601String()));
            await DBHelper.instance.insertEvaluations(Evaluations(set: setID, type: type, resultNumTime: this.reps, createdAt: DateTime.now().toIso8601String(), updatedAt: DateTime.now().toIso8601String()));
            setCompletedWeightsSetsEvaluations();
            },
          child: const Text('종료', style: TextStyle(fontSize: 30),
          ),
        ),
      ],
    );
  }

  Widget controlPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
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
        ),
        ListView.builder(
            shrinkWrap: true,
            itemCount: todaySets.length,
            itemBuilder: (BuildContext context, int index) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(todaySets[index].number.toString() + 'SET'),
                  Text(todaySets[index].completedWeight.toString() + 'KG'),
                  Text(todaySets[index].completedRep.toString() + '회'),
                  Text(todaySets[index].completedType.toString())
                ],
              );
            }
        )

      ],
    );

  }

  void startTimer() {
    countTimer =
        Timer.periodic(Duration(seconds: 1), (_) => setCountUp());
    setState(() => isStart = true);
  }
  // Step 4
  void stopTimer() {
    setState(() => countTimer!.cancel());

  }
  // Step 5
  void resetTimer() {
    stopTimer();
    setState(() => myDuration = Duration(days: 5));
    setState(() => isStart = false);

  }
  // Step 6
  void setCountDown() {
    final reduceSecondsBy = 1;
    setState(() {
      final seconds = myDuration.inSeconds - reduceSecondsBy;
      if (seconds < 0) {
        countTimer!.cancel();
      } else {
        myDuration = Duration(seconds: seconds);
      }
    });
  }

  void setCountUp() {
    final addSecondsBy = 1;
    setState(() {
      final seconds = myDuration.inSeconds + addSecondsBy;
      myDuration = Duration(seconds: seconds);
    });
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
}

class TodaySet {
  int? number;
  int? completedWeight;
  int? completedRep;
  String? completedType;

  TodaySet({ this.number, this.completedWeight, this.completedRep, this.completedType});

}


