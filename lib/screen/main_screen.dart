import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sisyphus/screen/add_workout_screen.dart';
import 'package:sisyphus/screen/workout_history_screen.dart';
import '../db/evaluations.dart';
import '../db/sets.dart';
import '../db/db_helper.dart';
import 'package:collection/collection.dart';

enum TimerType { UP, DOWN }
enum APP_STATUS { FINISH, IN_WORKOUT, IN_BREAK }

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  Timer? countTimer;
  Duration myDuration = Duration(minutes: 0, seconds: 00);
  bool wasPause = false;

  late APP_STATUS workoutMode;

  late int timerMinutes;
  late int timerSeconds;
  late int targetWeight;
  late int newWeight;
  late int targetReps;
  late int newReps;
  late int nowSetNumber;
  late String nowWorkoutName;
  late double _scale;

  late List<Map<String, dynamic>> todayCompletedWorkouts;
  late List<Map<String, dynamic>> todayTargetWorkouts;
  late List<Map<String, dynamic>> workoutList;

  late Map<String, List> todayCompletedWorkoutsInGroup;
  late int workoutIndex;


  final snackBar = SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: Duration(milliseconds: 500),
    content: const Text('이전에 수행한 세트를 모두 완료했어요.'),
    action: SnackBarAction(
      label: '',
      onPressed: () {
        // Some code to undo the change.
      },
    ),
  );

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    nowWorkoutName = '';
    targetWeight = 0;
    newWeight = 0;
    targetReps = 1;
    newReps = 0;
    todayCompletedWorkouts = [];
    todayTargetWorkouts = [];
    workoutList = [];
    workoutIndex = 0;
    timerMinutes = 0;
    timerSeconds = 0;
    nowSetNumber = 1;
    _scale = 100;

    setAppStatus(APP_STATUS.IN_BREAK);

    todayCompletedWorkoutsInGroup = {};
    setTodayCompletedWorkouts();
    setTargetWorkout();

    Future.delayed(const Duration(milliseconds: 300), () async{
      var temp = await DBHelper.instance.getCompletedSetsToday(todayTargetWorkouts[workoutIndex]['workout']);
      setNowSetNumber(temp + 1);
      setTargetWeightReps(todayTargetWorkouts[workoutIndex]['workout'], nowSetNumber);
    });

  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    var prefs = await SharedPreferences.getInstance();
    switch (state)  {
      case AppLifecycleState.resumed:
        print("app in resumed");
        setTodayCompletedWorkouts();
        if(wasPause == false) {

        } else {
          DateTime lastUnstoppedTimerValue = DateTime.parse(prefs.getString('timerStartTime')!);
          print(lastUnstoppedTimerValue);
          Duration timeElapsed = DateTime.now().difference(lastUnstoppedTimerValue);
          print('now: ' + DateTime.now().toString());
          print('timeElapsed: ' + timeElapsed.toString());
          if (todayCompletedWorkouts.length == 0) {
            resetTimer(0, 0);
          } else if (todayCompletedWorkouts.length > 0 ) {
            print("current duration: " + myDuration.toString());
            myDuration = myDuration + timeElapsed;
          }
          setState(() {
            wasPause = false;
          });
        }
        break;
      case AppLifecycleState.inactive:
        print("app in inactive");
        if(wasPause == false) {
          prefs.setString('timerStartTime', DateTime.now().toString());
        }
        break;
      case AppLifecycleState.paused:
        prefs.setString('timerStartTime', DateTime.now().toString());
        setState(() {
          wasPause = true;
        });
        print("app in paused");
        break;
      case AppLifecycleState.detached:
        print("app in detached");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    TextStyle _onWorkoutTextStyle = TextStyle(color: Colors.pink);
    TextStyle _onBreakTextStyle = TextStyle(color: Color(0xff04A777));

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: workoutMode == APP_STATUS.FINISH ? Container() : workoutMode == APP_STATUS.IN_BREAK ? Text('휴식중', style: _onBreakTextStyle,) : Text('운동중', style: _onWorkoutTextStyle,),
          actions: [
            IconButton(
                onPressed: () {
                  Navigator.push(context,MaterialPageRoute(
                      builder: (context) => AddWorkoutScreen()
                  )
                  ).then((value) {
                    //Navigation Stack이 다시 돌아왔을때 콜백
                    setTargetWorkout();
                    setState(() {
                      workoutIndex = 1;
                    });
                  }
                  );
                },
                icon: Icon(Icons.add)),
            IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => WorkoutHistoryScreen()
                      )
                  );
                },
                icon: Icon(Icons.history_rounded)),
          ],
          foregroundColor: Colors.black,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                workoutMode == APP_STATUS.IN_WORKOUT || workoutMode == APP_STATUS.IN_BREAK ? workoutInfo() : Container(),
                SizedBox(height: 20),
                workoutMode == APP_STATUS.IN_WORKOUT || workoutMode == APP_STATUS.IN_BREAK ? counter() : Container(),
                SizedBox(height: 20),
                workoutMode == APP_STATUS.IN_WORKOUT || workoutMode == APP_STATUS.IN_BREAK ? controlPanel(targetWeight, targetReps) : Container(),
                SizedBox(height: 20),
                workoutMode == APP_STATUS.IN_WORKOUT || workoutMode == APP_STATUS.IN_BREAK ? startStopButton() : Container(),
                SizedBox(height: 20),
                menuLabel('오늘의 운동'),
                todayCompletedSets()
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: workoutMode == APP_STATUS.IN_BREAK ? FloatingActionButton(
          child: Icon(Icons.stop),
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                    title: Text('운동을 종료할까요?'),
                    actions: [
                      TextButton(
                          onPressed: () {
                            setState(() {
                              if(countTimer != null) {
                                stopTimer();
                                resetTimer(0, 0);
                              }
                              setAppStatus(APP_STATUS.FINISH);
                            });
                            Navigator.of(context).pop();
                          },
                          child: const Text('네')
                      ),
                      TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('아니오')
                      )
                    ]
                )
            );
          },
        ): workoutMode == APP_STATUS.FINISH ? FloatingActionButton(
            child: Icon(Icons.play_arrow),
            onPressed: () async {
              setAppStatus(APP_STATUS.IN_BREAK);
              setTargetWorkout();
              var temp = await DBHelper.instance.getCompletedSetsToday(todayTargetWorkouts[workoutIndex]['workout']);
              setNowSetNumber(temp + 1);
              setTargetWeightReps(todayTargetWorkouts[workoutIndex]['workout'], nowSetNumber);
            }
        ) : Container()
    );
  }

  Widget menuLabel(String text) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Text(text, style: TextStyle(fontSize: 20, color: Colors.pink))
        ],
      ),
    );
  }
  Widget workoutInfo() {
    return Container(
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            nowWorkoutName,
            style: TextStyle(fontSize: 20),
          ),
          Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            workoutMode == APP_STATUS.IN_BREAK ? IconButton(
                onPressed: () async {
                  if(workoutIndex > 0) {
                    setWorkoutIndexDecrease();
                    setNowWorkoutName(todayTargetWorkouts[workoutIndex]['name']);
                  }
                  var temp = await DBHelper.instance.getCompletedSetsToday(todayTargetWorkouts[workoutIndex]['workout']);
                  setNowSetNumber(temp + 1);
                  setTargetWeightReps(todayTargetWorkouts[workoutIndex]['workout'], nowSetNumber);


                }, icon: Icon(Icons.arrow_back_ios_new_outlined)) : Container(),
            workoutMode == APP_STATUS.IN_BREAK ? IconButton(
                onPressed: () async {
                  if(workoutIndex < todayTargetWorkouts.length - 1 ) {
                    setWorkoutIndexIncrease();
                    setNowWorkoutName(todayTargetWorkouts[workoutIndex]['name']);
                  }
                  var temp = await DBHelper.instance.getCompletedSetsToday(todayTargetWorkouts[workoutIndex]['workout']);
                  setNowSetNumber(temp + 1);
                  setTargetWeightReps(todayTargetWorkouts[workoutIndex]['workout'], nowSetNumber);

                }, icon: Icon(Icons.arrow_forward_ios_outlined)) : Container()
          ],
        ),
      ]
      ),
    );
  }

  Widget startStopButton() {
    int setID;
    //일단 다 clear 한것으로
    String type = 'clear';

    return workoutMode == APP_STATUS.IN_BREAK
        ? ElevatedButton(
      style: ElevatedButton.styleFrom(
        primary: Color(0xff04A777),
        shape: const CircleBorder(),
        fixedSize: const Size(180, 180),
      ),
      onPressed: () {
        setAppStatus(APP_STATUS.IN_WORKOUT);
        if (countTimer != null) {
          setState(() {
            timerMinutes = 0;
            timerSeconds = 0;
          });
          resetTimer(this.timerMinutes, this.timerSeconds);
        }
        startTimer(TimerType.UP);
        _changeScale();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow_rounded, size: 90),
          Text('$nowSetNumber세트 시작' , style: TextStyle(fontSize: 20)),
        ],
      ),
    ) : ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        fixedSize: const Size(180, 180),
        animationDuration: Duration(milliseconds: 300),
      ),
      onPressed: () async {
        setAppStatus(APP_STATUS.IN_BREAK);
        setState((){
          setNowSetNumber(nowSetNumber + 1);
        });

        String strDigits(int n) => n.toString().padLeft(2, '0');
        final seconds = strDigits(myDuration.inSeconds.remainder(60));
        final minutes = strDigits(myDuration.inMinutes.remainder(60));

        print('[insert] workout:');
        print(todayTargetWorkouts[workoutIndex]['workout']);
        setID = await DBHelper.instance.insertSets(Sets(workout: todayTargetWorkouts[workoutIndex]['workout'], targetNumTime: this.targetReps, weight: this.targetWeight, createdAt: DateTime.now().toIso8601String(), updatedAt: DateTime.now().toIso8601String()));
        print('[insert] setID: $setID');

        await DBHelper.instance.insertEvaluations(Evaluations(set: setID, type: type, resultNumTime: this.targetReps, elapsedTime: '$minutes:$seconds', createdAt: DateTime.now().toIso8601String(), updatedAt: DateTime.now().toIso8601String()));

        if (countTimer == null || countTimer!.isActive) {
          setState(() {
            timerMinutes = 0;
            timerSeconds = 0;
          });
          resetTimer(this.timerMinutes, this.timerSeconds);
        }
        startTimer(TimerType.UP);

        setTodayCompletedWorkouts();
        setTargetWeightReps(todayTargetWorkouts[workoutIndex]['workout'], nowSetNumber);
        _scrollDown();
        _changeScale();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pause, size: 90),
          Text(
            '$nowSetNumber세트 종료',
            style: TextStyle(fontSize: 20),
          ),
        ],
      ),
    );
  }

  void _changeScale() {
    setState(() => _scale = _scale == 100 ? 120 : 100);
  }

  Widget counter() {
    String strDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = strDigits(myDuration.inMinutes.remainder(60));
    final seconds = strDigits(myDuration.inSeconds.remainder(60));
    return Container(
      height: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder(
            duration: Duration(milliseconds: 400),
              tween: Tween<double>(begin: _scale, end: _scale),
              builder: (_, double size, __) => Text('$minutes:$seconds', style: TextStyle(fontWeight: FontWeight.w100, color: Colors.black, fontSize: size))
          )
              // child: Text('$minutes:$seconds', style: const TextStyle(fontWeight: FontWeight.w100, color: Colors.black, fontSize: 80))),
        ],
      ),
    );
  }

  Widget todayCompletedSets() {
    return Column(
      children: [
        ListView.builder(
            reverse: true,
            shrinkWrap: true,
            controller: _scrollController,
            itemCount: todayCompletedWorkoutsInGroup.length,
            itemBuilder: (BuildContext context, int index) {
              return Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                    initiallyExpanded: false,
                    title: Text(todayCompletedWorkoutsInGroup.keys.toList()[index].toString()),
                    children: List<Widget>.generate(
                        todayCompletedWorkoutsInGroup.entries.toList()[index].value.length, (int i) {
                          return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text((todayCompletedWorkoutsInGroup.entries.toList()[index].value.length - i).toString() + '세트 '),
                          Text(todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['weight'].toString() + 'kg'),
                          Text(todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['target_num_time'].toString() + '회'),
                          Text(todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['type'].toString()),
                          Text(todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['elapsed_time'].toString()),
                          IconButton(
                              onPressed: () {
                                final textInputControllerWeight = TextEditingController();
                                final textInputControllerReps = TextEditingController();

                                var newWeight = todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['weight'];
                                var newReps = todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['target_num_time'];

                                showDialog(
                                    context: context,
                                    builder: (BuildContext context) => AlertDialog(
                                        title: Text('수정'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              keyboardType: TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.digitsOnly
                                              ],
                                              controller: textInputControllerWeight,
                                              decoration: InputDecoration(
                                                  hintText: '${newWeight}kg'
                                              ),
                                            ),
                                            TextField(
                                              keyboardType: TextInputType.number,
                                              controller: textInputControllerReps,
                                              decoration: InputDecoration(
                                                  hintText: '${newReps}회'
                                              ),
                                            )
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                if(textInputControllerWeight.text.length > 0) {
                                                  DBHelper.updateWeight(todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['id'], int.parse(textInputControllerWeight.text));
                                                }
                                                if(textInputControllerReps.text.length > 0) {
                                                  DBHelper.updateReps(todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['id'], int.parse(textInputControllerReps.text));
                                                }
                                                setTodayCompletedWorkouts();
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text('OK')
                                          )
                                        ]
                                    ));
                              },
                              icon: Icon(Icons.edit)
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext context) => AlertDialog(
                                title: Text('세트를 삭제합니다.'),
                                    actions: [
                                      TextButton(onPressed: () async {
                                        DBHelper.deleteSets(todayCompletedWorkoutsInGroup.entries.toList()[index].value.reversed.toList()[i]['id']);
                                        setTodayCompletedWorkouts();
                                        var temp = await DBHelper.instance.getCompletedSetsToday(todayTargetWorkouts[workoutIndex]['workout']);
                                        setNowSetNumber(temp + 1);
                                        print('삭제 후 set number: ' + nowSetNumber.toString());
                                        setTargetWeightReps(todayTargetWorkouts[workoutIndex]['workout'], nowSetNumber);
                                        Navigator.of(context).pop();
                                      }, child: Text('네')),
                                      TextButton(onPressed: () {
                                        Navigator.of(context).pop();
                                      }, child: Text('취소'))
                                    ],
                              ));
                            },
                          )
                        ],
                      );
                    })
                ),
              );
            }),
      ],
    );
  }

  Widget controlPanel(int targetWeight, int targetReps) {
    TextStyle _style = TextStyle(color: Color(0xff04A777));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 40,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(flex: 1, child: TextButton(child: Text('-10', style: _style,), onPressed: () => reduceWeight(10))),
              Expanded(flex: 1,child: TextButton(child: Text('-5', style: _style), onPressed: () => reduceWeight(5))),
              Expanded(flex: 1,child: TextButton(child: Text('-1', style: _style), onPressed: () => reduceWeight(1))),
              Expanded(flex: 2,child: Text(textAlign: TextAlign.center,'$targetWeight kg', style: TextStyle(fontSize: 20))),
              Expanded(flex: 1,child: TextButton(child: Text('+1', style: _style), onPressed: () => addWeight(1))),
              Expanded(flex: 1,child: TextButton(child: Text('+5', style: _style), onPressed: () => addWeight(5))),
              Expanded(flex: 1,child: TextButton(child: Text('+10', style: _style), onPressed: () => addWeight(10))),
            ],
          ),
        ),
        Container(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(child: Text('-5', style: _style), onPressed: () => reduceReps(5)),
              TextButton(child: Text('-1', style: _style), onPressed: () => reduceReps(1)),
              Text(
                '$targetReps회',
                style: TextStyle(fontSize: 20),
              ),
              TextButton(child: Text('+1', style: _style), onPressed: () => addReps(1)),
              TextButton(child: Text('+5', style: _style), onPressed: () => addReps(5)),

            ],
          ),
        )
      ],
    );
  }

  void setLatestWeightReps(int workoutID) async {
    var latestWeightReps = await DBHelper.instance.getLatestWeightsRepsToday(workoutID);
    if (latestWeightReps.isNotEmpty) {
      setNowWorkoutWeight(latestWeightReps.last['weight']);
      setNowWorkoutReps(latestWeightReps.last['reps']);
    } else {
      setNowWorkoutWeight(0);
      setNowWorkoutReps(0);
    }
  }

  void setTargetWeightReps(int workoutID, setInNumber) async {

    if(todayTargetWorkouts.length > 0 ) {
      var result = await DBHelper.instance.getWholeSetsInfo(todayTargetWorkouts);
      var resultInWorkoutGroup = groupBy(result, (Map obj) => obj['workout_id']);
      resultInWorkoutGroup.keys.forEachIndexed((index, element) {
        if(element == workoutID) {
          //이전 수행했던 세트정보가 있으면 해당 세트 정보로 업데이트
          if (resultInWorkoutGroup.entries.toList()[index].value.length >= setInNumber) {
            setNowWorkoutWeight(resultInWorkoutGroup.entries.toList()[index].value.toList()[setInNumber - 1]['weight']);
            setNowWorkoutReps(resultInWorkoutGroup.entries.toList()[index].value.toList()[setInNumber - 1]['reps']);
          }
          //이전 수행했던 세트정보가 없으면 가장 오늘 중 최신의 세트 정보로 업데이트
          else {
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            setLatestWeightReps(workoutID);
          }
        }
      });
    } else {
      setLatestWeightReps(workoutID);
    }
  }
  void setTargetWorkout() async {
    List<Map<String, dynamic>> recommendedWorkouts = await DBHelper.instance.getTodayTargetWorkoutId();
    List<Map<String, dynamic>> allWorkouts = await DBHelper.instance.getWorkouts();
    List<Map<String, dynamic>> targetWorkouts = List<Map<String, dynamic>>.from(recommendedWorkouts);

    List<int> targetWorkoutIDList = [];
    List<int> allWorkoutIDList = [];
    List<int> otherWorkouts = [];

    recommendedWorkouts.forEach((element) {
      targetWorkoutIDList.add(int.parse(element['workout'].toString()));
    });

    allWorkouts.forEach((element) {
      allWorkoutIDList.add(int.parse(element['workout'].toString()));
    });

    otherWorkouts = allWorkoutIDList.toSet().difference(targetWorkoutIDList.toSet()).toList();

    for (int i = 0; i < otherWorkouts.length; i++) {
      for (int j = 0; j < allWorkouts.length; j++) {
        if(allWorkouts[j]['workout'] == otherWorkouts[i]) {
          targetWorkouts.add(allWorkouts[j]);
        }
      }
    }

    if (recommendedWorkouts.length > 0) {
      setState(() {
        todayTargetWorkouts = targetWorkouts;
      });
    } else {
      setState(() {
        todayTargetWorkouts = allWorkouts;
      });
    }
    setNowWorkoutName(todayTargetWorkouts.first['name']);
  }

  void setNowWorkoutName(String workoutName) {
    setState(() {
      nowWorkoutName = workoutName;
    });
  }

  void setNowWorkoutWeight(int weight) {
    setState(() {
      targetWeight = weight;
    });
  }

  void setNowWorkoutReps(int reps) {
    setState(() {
      targetReps = reps;
    });
  }

  void setNowSetNumber(int number) {
    setState(() {
      nowSetNumber = number;
    });
  }
  void setWorkoutIndexIncrease() {
    if (workoutIndex < todayTargetWorkouts.length - 1 ) {
      setState(() {
        workoutIndex++;
      });
    }
  }
  void setWorkoutIndexDecrease() {
    setState(() {
      workoutIndex--;
    });
  }

  void setAppStatus(APP_STATUS status) {
    setState(() {
      workoutMode = status;
    });
  }

  void setTodayCompletedWorkouts() async {
    todayCompletedWorkoutsInGroup = {};
    List<Map<String, dynamic>> completedWorkouts = [];

    completedWorkouts = await DBHelper.instance.getCompletedWorkouts();

    setState(() {
      todayCompletedWorkouts = completedWorkouts;
    });
    todayCompletedWorkoutsInGroup = groupBy(todayCompletedWorkouts, (Map obj) => obj['name']).cast<String, List>();
  }

  void startTimer(TimerType type) {
    switch (type) {
      case TimerType.UP:
        countTimer = Timer.periodic(Duration(seconds: 1), (_) => setCountUp());
        break;
      case TimerType.DOWN:
        countTimer =
            Timer.periodic(Duration(seconds: 1), (_) => setCountDown());
        break;
    }
  }

  void stopTimer() {
    setState(() => countTimer!.cancel());
  }

  void resetTimer(int min, int sec) {
    stopTimer();
    setState(() => myDuration = Duration(minutes: min, seconds: sec));
  }

  void setCountDown() {
    final reduceSecondsBy = 1;
    setState(() {
      final seconds = myDuration.inSeconds - reduceSecondsBy;
      if (seconds < 0) {
        countTimer!.cancel();
        setAppStatus(APP_STATUS.IN_BREAK);
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

  void addWeight(int targetWeight) {
    setState(() {
      this.targetWeight += targetWeight;
    });
  }

  void reduceWeight(int targetWeight) {
    setState(() {
      this.targetWeight -= targetWeight;
    });
  }

  void addReps(int number) {
    setState(() {
      this.targetReps += number;
    });
  }

  void reduceReps(int number) {
    setState(() {
      this.targetReps -= number;
    });
  }

  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }
}
