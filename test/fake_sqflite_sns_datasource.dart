import 'package:flutter/cupertino.dart';
import 'package:prjectcm/data/sqflite_sns_datasource.dart';
import 'package:prjectcm/models/evaluation_report.dart';
import 'package:prjectcm/models/hospital.dart';
import 'package:prjectcm/models/waiting_time.dart';

class FakeSqfliteSnsDataSource extends SqfliteSnsDataSource {

  final List<Hospital> hospitals = [];

  @override
  Future<bool> init() async {
    return true;
  }

  @override
  Future<List<Hospital>> getAllHospitals() async {
    return hospitals;
  }

  @override
  Future<void> attachEvaluation(int hospitalId, EvaluationReport report) async {
    final hospital = hospitals.firstWhere((element) => element.id == hospitalId);
    hospital.reports.add(report);
  }

  @override
  Future<void> insertHospital(Hospital hospital) async {
    debugPrint('inserting hospital ${hospital.name}');
    final index = hospitals.indexWhere((h) => h.id == hospital.id);

    if (index != -1) {  // caso já exista, substitui o hospital
      final reports = hospitals[index].reports;
      hospitals[index] = hospital;
      hospital.reports = reports;
    } else {
      hospitals.add(hospital);
    }
  }

  @override
  Future<Hospital> getHospitalDetailById(int hospitalId) async {
    return hospitals.firstWhere((element) => element.id == hospitalId);
  }

  @override
  Future<List<Hospital>> getHospitalsByName(String name) async {
    return hospitals.where((element) => element.name.toLowerCase().contains(name.toLowerCase())).toList();
  }

  @override
  Future<List<WaitingTime>> getHospitalWaitingTimes(int hospitalId) async {
    return [];
  }

  @override
  Future<void> insertWaitingTime(int hospitalId, dynamic waitingTime) async {}
}
