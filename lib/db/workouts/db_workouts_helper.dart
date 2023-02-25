import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sisyphus/db/workouts/workouts.dart';
import 'package:sqflite/sqflite.dart';

class DBWorkoutsHelper {
  DBWorkoutsHelper._privateConstructor();

  static final DBWorkoutsHelper instance = DBWorkoutsHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'workouts.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE workouts(
      id INTEGER PRIMARY KEY,
      name TEXT,
      created_at TEXT,
      updated_at TEXT
    )
    ''');
  }

  Future<int> insert(Workouts workout) async {
    Database db = await instance.database;
    return await db.insert('workouts', workout.toMap());
  }

  Future<List<Workouts>> getWorkouts() async {
    Database db = await instance.database;
    var workouts = await db.query('workouts', orderBy: 'created_at');
    List<Workouts> workoutList = workouts.isNotEmpty
      ? workouts.map((c) => Workouts.fromMap(c)).toList()
        : [];
    return workoutList;
  }

}