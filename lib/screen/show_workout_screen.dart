import 'package:flutter/material.dart';
import '../db/workouts/db_workouts_helper.dart';
import '../db/workouts/workouts.dart';

class ShowWorkoutScreen extends StatelessWidget {
  const ShowWorkoutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {Navigator.pop(context);},
        ),
      ),
      body: WorkoutList()
    );
  }


  Widget WorkoutList() {
    return FutureBuilder<List<Workouts>> (
        future: DBWorkoutsHelper.instance.getWorkouts(),
        builder: (BuildContext context, AsyncSnapshot<List<Workouts>> snapshot) {
          if (snapshot.hasData) {
            return Container(
              child: ListView.builder(
                  itemCount: snapshot.data!.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      leading:Text(snapshot.data![index].id.toString()),
                      title: Text(snapshot.data![index].name),
                    );
                  }
              ),
            );
          } else {
            return Center(child: Text('데이터가 없습니다.'));
          }
        }
    );

  }


}
