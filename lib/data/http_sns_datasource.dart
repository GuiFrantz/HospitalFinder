import 'dart:convert';
import 'package:prjectcm/data/sns_datasource.dart';
import '../http/http_client.dart';
import '../models/evaluation_report.dart';
import '../models/hospital.dart';
import '../models/waiting_time.dart';

class HttpSnsDataSource extends SnsDataSource {

  List<Hospital> hospitalsList = [];

  @override
  Future<void> insertHospital(Hospital hospital) {
    throw Exception('Not implemented');
  }

  @override
  Future<List<Hospital>> getAllHospitals() async {

    final response = await HttpClient().get(
      url: 'https://servicos.min-saude.pt/pds/api/tems/institution',
    );

    if (response.statusCode == 200) {
      final responseJSON = jsonDecode(response.body);
      List hospitalsJSON = responseJSON['Result'];

      hospitalsList = hospitalsJSON.map((hospitalJSON) => Hospital.fromJSON(hospitalJSON)).toList();
    } else {
      throw Exception('Failed to load hospitals, status code: ${response.statusCode}');
    }

    return hospitalsList;
  }

  @override
  Future<List<Hospital>> getHospitalsByName(String name) async {
    throw Exception('Implemented on SnsRepository (called getHospitalsByName)');
  }

  @override
  Future<Hospital> getHospitalDetailById(int hospitalId) async {
    throw Exception('Implemented on SnsRepository (called getHospitalDetailById)');
  }

  @override
  Future<void> attachEvaluation(int hospitalId, EvaluationReport report) {
    throw Exception('Not implemented');
  }

  @override
  Future<List<WaitingTime>> getHospitalWaitingTimes(int hospitalId) {
    throw Exception('Not implemented');
  }

  @override
  Future<void> insertWaitingTime(int hospitalId, waitingTime) {
    // TODO: implement insertWaitingTime
    throw UnimplementedError();
  }

}