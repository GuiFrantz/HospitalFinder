import 'package:path/path.dart';
import 'package:prjectcm/data/sns_datasource.dart';
import 'package:prjectcm/models/evaluation_report.dart';
import 'package:prjectcm/models/hospital.dart';
import 'package:prjectcm/models/waiting_time.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteSnsDataSource extends SnsDataSource {

  Database ? _database;
  List<Hospital> hospitals = [];

  Future<void> init() async {
    if (_database != null) {
      return;
    }

    _database = await openDatabase(
      join(await getDatabasesPath(), 'sns.db'),
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE hospital('
              'id INTEGER PRIMARY KEY, '
              'name TEXT NOT NULL, '
              'description TEXT NULL, '
              'longitude REAL, '
              'latitude REAL, '
              'address TEXT, '
              'phone INTEGER, '
              'email TEXT, '
              'district TEXT, '
              'hasEmergency INTEGER'
              ')',
        );

        await db.execute(
          'CREATE TABLE evaluation('
              'id INTEGER PRIMARY KEY, '
              'hospitalId INTEGER NOT NULL, '
              'rating INTEGER NOT NULL, '
              'dateTime TEXT NOT NULL, '
              'comment TEXT NULL'
              ')',
        );
      },
      version: 1,
    );
  }

  @override
  Future<void> attachEvaluation(int hospitalId, EvaluationReport report) {
    if (_database == null) {
      return Future.value();
    }
    return _database!.insert('evaluation', report.toDB());
  }

  @override
  Future<List<Hospital>> getAllHospitals() async {
    if (_database == null) {
      return[];
    }
    List result = await _database!.rawQuery('SELECT * FROM hospital');
    return result.map((hospital) => Hospital.fromDB(hospital)).toList();
  }

  @override
  Future<Hospital> getHospitalDetailById(int hospitalId) async {
   throw Exception('Implemented on SnsRepository (called getHospitalDetailById)');
  }

  @override
  Future<List<WaitingTime>> getHospitalWaitingTimes(int hospitalId) {
    throw Exception('Not implemented');
  }

  @override
  Future<List<Hospital>> getHospitalsByName(String name) async {
    throw Exception('Implemented on SnsRepository (called getHospitalsByName)');
  }

  @override
  Future<void> insertHospital(Hospital hospital) async {
    if (_database == null) {
      return;
    }
    await _database!.insert('hospital', hospital.toDB(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteAll() async {
    if (_database == null) {
      return;
    }

    await _database!.rawDelete('DELETE FROM hospital');
  }

  @override
  Future<List<EvaluationReport>> getHospitalEvaluations(int hospitalId) async {
    if (_database == null) {
      return [];
    }
    List result = await _database!.rawQuery(
        'SELECT * FROM evaluation WHERE hospitalId = ?',
        [hospitalId]
    );
    return result.map((evaluation) => EvaluationReport.fromDB(evaluation)).toList();
  }

  @override
  Future<void> insertWaitingTime(int hospitalId, waitingTime) {
    throw UnimplementedError();
  }
}