import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sisyphus/db/sets/sets.dart';
import 'package:sqflite/sqflite.dart';

class DBSetsHelper {
  DBSetsHelper._privateConstructor();

  static final DBSetsHelper instance = DBSetsHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'sets.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE sets(
      id INTEGER PRIMARY KEY,
      set INTEGER,
      target_num_time INTEGER,
      weight INTEGER,
      created_at TEXT,
      updated_at TEXT
    )
    ''');
  }

  Future<int> insert(Sets set) async {
    Database db = await instance.database;
    return await db.insert('sets', set.toMap());
  }

  Future<List<Sets>> getWorkouts() async {
    Database db = await instance.database;
    var sets = await db.query('sets', orderBy: 'created_at');
    List<Sets> setList = sets.isNotEmpty
        ? sets.map((c) => Sets.fromMap(c)).toList()
        : [];
    return setList;
  }

}