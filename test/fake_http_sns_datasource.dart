import 'package:prjectcm/data/http_sns_datasource.dart';
import 'package:prjectcm/models/evaluation_report.dart';
import 'package:prjectcm/models/hospital.dart';
import 'package:prjectcm/models/waiting_time.dart';

class FakeHttpSnsDataSource extends HttpSnsDataSource {

  final List<Hospital> hospitals = [
    Hospital(
      id: 1,
      name: 'hospital 1',
      latitude: 38.756301,
      longitude: -9.147035,
      address: 'address1',
      phoneNumber: 123,
      email: 'hospital1@sns.pt',
      district: 'Lisboa',
      hasEmergency: true,
    ),
    Hospital(
      id: 2,
      name: 'hospital 2',
      latitude: 0.0,
      longitude: 0.0,
      address: 'address2',
      phoneNumber: 456,
      email: 'hospital2@sns.pt',
      district: 'Porto',
      hasEmergency: false,
    ),
  ];

  final int? delay;

  FakeHttpSnsDataSource({this.delay});

  @override
  Future<void> insertHospital(Hospital hospital) async {}

  @override
  Future<List<Hospital>> getAllHospitals() async {
    if (delay != null) {
      await Future.delayed(Duration(seconds: delay!));
    }

    return hospitals;
  }

  @override
  Future<void> attachEvaluation(int hospitalId, EvaluationReport report) {
    // TODO: implement attachEvaluation
    throw UnimplementedError();
  }

  @override
  Future<Hospital> getHospitalDetailById(int hospitalId) async {
    return hospitals.firstWhere((element) => element.id == hospitalId);
  }

  @override
  Future<List<Hospital>> getHospitalsByName(String name) {
    // TODO: implement getHospitalsByName
    throw UnimplementedError();
  }

  @override
  Future<List<WaitingTime>> getHospitalWaitingTimes(int hospitalId) async {
    return [];
  }

}