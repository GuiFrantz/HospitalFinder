import 'evaluation_report.dart';

class Hospital {
  int id = 0;
  String name = '';
  String? description = '';
  double longitude = 0;
  double latitude = 0;
  String address = '';
  int phoneNumber = 0;
  String email = '';
  String district = '';
  bool hasEmergency = false;
  List<EvaluationReport> reports = [];
  double? distance = 0;

  Hospital({
    required this.id,
    required this.name,
    this.description,
    required this.longitude,
    required this.latitude,
    required this.address,
    required this.phoneNumber,
    required this.email,
    required this.district,
    required this.hasEmergency,
    this.distance,
  });

  factory Hospital.fromJSON(Map<String, dynamic> json) {
    return Hospital(
      id: json['Id'] ?? 0,
      name: json['Name'] ?? 'Sem nome',
      description: json['Description'],
      longitude: json['Longitude'] ?? 0.0,
      latitude: json['Latitude'] ?? 0.0,
      address: json['Address'] ?? 'Sem morada',
      phoneNumber: json['Phone'] ?? 0,
      email: json['Email'] ?? 'sememail@example.com',
      district: json['District'] ?? 'Desconhecido',
      hasEmergency: json['HasEmergency'] ?? false,
    );
  }

  factory Hospital.fromDB(Map<String, dynamic> db) {
    return Hospital(
      id: db['id'] ?? 0,
      name: db['name'] ?? 'Sem nome',
      description: db['description'],
      longitude: db['longitude'] ?? 0.0,
      latitude: db['latitude'] ?? 0.0,
      address: db['address'] ?? 'Sem morada',
      phoneNumber: db['phone'] ?? 0,
      email: db['email'] ?? 'sememail@example.com',
      district: db['district'] ?? 'Desconhecido',
      hasEmergency: (db['hasEmergency'] == 1),
    );
  }

  Map<String, dynamic> toDB() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'longitude': longitude,
      'latitude': latitude,
      'address': address,
      'phone': phoneNumber,
      'email': email,
      'district': district,
      'hasEmergency': hasEmergency ? 1 : 0,
    };
  }
}
