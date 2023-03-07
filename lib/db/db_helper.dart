import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sisyphus/db/workouts.dart';
import 'package:sqflite/sqflite.dart';
import 'evaluations.dart';
import 'sets.dart';

class DBHelper {
  DBHelper._privateConstructor();

  static final DBHelper instance = DBHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'database.db');
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

    await db.execute(
    '''
    CREATE TABLE sets(
      id INTEGER PRIMARY KEY,
      workout INTEGER,
      target_num_time INTEGER,
      weight INTEGER,
      created_at TEXT,
      updated_at TEXT
    )
    ''');

    await db.execute(
    '''
    CREATE TABLE evaluations(
      id INTEGER PRIMARY KEY,
      set_id INTEGER,
      type TEXT,
      result_num_time INTEGER,
      created_at TEXT,
      updated_at TEXT
    )
    '''
    );

  }

  Future<int> insertWorkouts(Workouts workout) async {
    Database db = await instance.database;
    return await db.insert('workouts', workout.toMap());
  }

  Future<int> insertSets(Sets set) async {
    Database db = await instance.database;
    return await db.insert('sets', set.toMap());
  }

  Future<int> insertEvaluations(Evaluations evaluation) async {
    Database db = await instance.database;
    return await db.insert('evaluations', evaluation.toMap());
  }

  Future<List<Workouts>> getWorkouts() async {
    Database db = await instance.database;
    var workouts = await db.query('workouts', orderBy: 'created_at');
    List<Workouts> workoutList = workouts.isNotEmpty
      ? workouts.map((c) => Workouts.fromMap(c)).toList()
        : [];
    return workoutList;
  }

  Future<List<Sets>> getSets() async {
    Database db = await instance.database;
    var sets = await db.query('sets', orderBy: 'created_at');
    List<Sets> setList = sets.isNotEmpty
        ? sets.map((c) => Sets.fromMap(c)).toList()
        : [];
    return setList;
  }

  Future<List<Evaluations>> getEvaluations() async {
    Database db = await instance.database;
    var evaluations = await db.query('evaluations', orderBy: 'created_at');
    List<Evaluations> evaluationList = evaluations.isNotEmpty
        ? evaluations.map((c) => Evaluations.fromMap(c)).toList()
        : [];
    return evaluationList;
  }

  Future<List<Item>> getTodaySet(int workoutID) async {
    DateFormat formatter = DateFormat('yyyy-MM-dd');
    String today = formatter.format(DateTime.now());
    List<Item> list = <Item>[];
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.rawQuery('SELECT * FROM sets WHERE date = ? AND workout = ?', [today, workoutID]);
    result.forEach((element) {
      list.add(Item.fromMap(element));
    });
    return list;
  }

  Future<List<Sets>> recentSet(int workoutID) async {
    String today = DateTime.now().toIso8601String();

    List<Sets> list = <Sets>[];
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.rawQuery('SELECT * FROM sets WHERE date < ? AND workout = ? LIMIT 10', [today, workoutID]);

    result.forEach((element) {
      list.add(Sets.fromMap(element));
    });
    return list;
  }

  Future<int?> recentSetNumber(String date, int workoutID) async {
    Database db = await instance.database;
    var result = await db.rawQuery('SELECT COUNT(id) FROM sets WHERE date = ? AND workout = ? LIMIT 10', [date, workoutID]);
    final count = Sqflite.firstIntValue(result);
    print('result is');
    print(result);
    return count;
  }


  Future<List<Item>> getTodayEvaluation(int setID) async {
    List<Item> list = <Item> [];
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.rawQuery('SELECT * FROM evaluations WHERE evaluations.set_id = ?', [setID]);
    result.forEach((element) {
      list.add(Item.fromMap(element));
    });
    return list;
    }

}

class Item {
  int? id;
  int? weight;
  int? target_num_time;
  int? result_num_time;
  String? type;
  final String? createdAt;

  Item({ this.id, this.weight, this.target_num_time, this.result_num_time, this.type, this.createdAt});


  factory Item.fromMap(Map<String, dynamic> json) => Item(
    id: json['id'],
    weight: json['weight'],
    type: json['type'],
    target_num_time: json['target_num_time'],
    result_num_time: json['result_num_time'],
    createdAt: json['created_at']
  );

}