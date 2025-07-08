import 'dart:async';
import 'package:location/location.dart';
import 'package:prjectcm/data/sns_datasource.dart';
import 'package:prjectcm/data/sqflite_sns_datasource.dart';
import 'package:prjectcm/models/evaluation_report.dart';
import '../connectivity_module.dart';
import '../location_module.dart';
import '../models/hospital.dart';

class SnsRepository {
  SnsDataSource _sqfliteSnsDataSource;
  SnsDataSource _httpSnsDataSource;
  ConnectivityModule _connectivityModule;
  LocationModule? _locationModule;

  List<Hospital> hospitals = [];

  SnsRepository(this._httpSnsDataSource, this._sqfliteSnsDataSource, this._connectivityModule, this._locationModule);

  Future<List<Hospital>> getAllHospitals() async {
    LocationData? currentLocation;

    if (_locationModule != null) {
      try {
        currentLocation = await _locationModule!.getCurrentLocation();
      } catch (e) {
        throw Exception('Erro ao obter a localização atual');
      }
    }

    if (await _connectivityModule.checkConnectivity()) {
      hospitals = await _httpSnsDataSource.getAllHospitals();

      for (var hospital in hospitals) {
        _sqfliteSnsDataSource.insertHospital(hospital);
      }

    } else {
      hospitals = await _sqfliteSnsDataSource.getAllHospitals();
    }

    if (currentLocation?.latitude != null &&
        currentLocation?.longitude != null &&
        _locationModule != null) {
      for (var hospital in hospitals) {
        calculateDistance(hospital, currentLocation!);
      }
      hospitals.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));
    }
    return hospitals;
  }

  Future<List<Hospital>> getHospitalsByName(String name) async {
    hospitals = await getAllHospitals();

    return hospitals.where((hospital) => hospital.name.toLowerCase().contains(name.toLowerCase())).toList();
  }

  Future<Hospital> getHospitalDetailById(int hospitalId) async {
    hospitals = await getAllHospitals();

    for (var hospital in hospitals) {
      if (hospital.reports.isEmpty && hospital.id == hospitalId) {
        hospital.reports = await _sqfliteSnsDataSource.getHospitalEvaluations(hospital.id);
      }
    }

    return hospitals.firstWhere((hospital) => hospital.id == hospitalId);
  }

  Future<void> insertHospital(Hospital hospital) async {
    await _sqfliteSnsDataSource.insertHospital(hospital);
  }

  Future<void> deleteAll() async {
    final db = _sqfliteSnsDataSource as SqfliteSnsDataSource;
    await db.deleteAll();
  }

  double? calculateDistance(Hospital hospital, LocationData currentLocation) {
    if (_locationModule == null) {
      return null;
    }
    return hospital.distance = _locationModule?.calculateDistance(
      currentLocation.latitude!,
      currentLocation.longitude!,
      hospital.latitude,
      hospital.longitude,
    );
  }

  void submitEvaluation(EvaluationReport evaluation) {
    _sqfliteSnsDataSource.attachEvaluation(evaluation.hospitalId, evaluation);
  }
}