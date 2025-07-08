import 'package:flutter/material.dart';
import 'package:prjectcm/main.dart';
import 'package:provider/provider.dart';
import '../connectivity_module.dart';
import '../data/http_sns_datasource.dart';
import '../data/sns_repository.dart';
import '../data/sqflite_sns_datasource.dart';
import '../location_module.dart';
import '../models/hospital.dart';
import 'hospital_detail.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isEmergency = false;
  static const int lowOpacityAlpha = 51;

  @override
  Widget build(BuildContext context) {
    final httpDataSource = Provider.of<HttpSnsDataSource>(context);
    final sqfliteDataSource = Provider.of<SqfliteSnsDataSource>(context);
    final connectivityModule = Provider.of<ConnectivityModule>(context);
    final locationModule = Provider.of<LocationModule>(context);
    final repository = SnsRepository(httpDataSource, sqfliteDataSource, connectivityModule, locationModule);

    return FutureBuilder<List<Hospital>>(
        future: repository.getAllHospitals(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final List<Hospital> allHospitals = snapshot.data!;
            final nearestHospital = _getNearestHospital(allHospitals, _isEmergency);

            return Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildGreetingCard(),
                      const SizedBox(height: 16),
                      _buildClosestHospitalSection(nearestHospital),
                      const SizedBox(height: 24),
                      _buildAdditionalInfoSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return const Center(child: Text('No hospitals found.'));
          }
        }
    );
  }

  // Data logic methods
  Hospital? _getNearestHospital(
      List<Hospital> hospitals, bool emergency) {
    try {
      return hospitals.firstWhere(
              (Hospital hosp) => hosp.hasEmergency == emergency);
    } catch (e) {
      return null;
    }
  }

  String _getGreetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bom dia!';
    } else if (hour < 18) {
      return 'Boa tarde!';
    } else {
      return 'Boa noite!';
    }
  }

  // UI Widget building methods
  Widget _buildGreetingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mainAppColor.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getGreetingByTime(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Este é um projeto académico por Bruno Ramos e Guilherme Frantz.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildClosestHospitalSection(Hospital? nearestHospital) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hospital Mais Próximo',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildHospitalCard(nearestHospital),
      ],
    );
  }

  Widget _buildHospitalCard(Hospital? nearestHospital) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmergencySwitch(),
            const Divider(),
            if (nearestHospital != null) ...[
              _buildHospitalInfo(nearestHospital),
              const SizedBox(height: 16),
              _buildHospitalActionButton(nearestHospital),
            ] else
              _buildNoHospitalFound(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySwitch() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Flexible(
          child: Text(
            'Precisa de Urgência?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Switch(
          value: _isEmergency,
          activeColor: AppColors.mainAppColor,
          onChanged: (value) {
            setState(() {
              _isEmergency = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildHospitalInfo(Hospital hospital) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHospitalHeader(hospital),
        const SizedBox(height: 12),
        _buildHospitalMetrics(hospital),
        const SizedBox(height: 8),
        _buildHospitalAddress(hospital),
      ],
    );
  }

  Widget _buildHospitalHeader(Hospital hospital) {
    return Row(
      children: [
        Expanded(
          child: Text(
            hospital.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildEmergencyBadge(hospital.hasEmergency),
      ],
    );
  }

  Widget _buildEmergencyBadge(bool hasEmergency) {
    final color = hasEmergency ? Colors.green : Colors.red;
    final icon = hasEmergency ? Icons.medical_services : Icons.do_not_disturb;

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(lowOpacityAlpha),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            'Urgência',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalMetrics(Hospital hospital) {
    return Row(
      children: [
        _buildMetricItem(Icons.location_on, hospital.district),
        const SizedBox(width: 16),
        _buildMetricItem(Icons.route, distanceToString(hospital.distance)),
      ],
    );
  }

  Widget _buildMetricItem(IconData icon, String text, [Color? iconColor]) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor ?? Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildHospitalAddress(Hospital hospital) {
    return Text(
      hospital.address,
      style: const TextStyle(fontSize: 14, color: Colors.grey),
    );
  }

  Widget _buildHospitalActionButton(Hospital hospital) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            key: const Key('dashboard-ver-detalhes-button'),
            onPressed: () => _navigateToHospitalDetail(hospital.id),
            icon: const Icon(Icons.info_outline, size: 18),
            label: const Text('Ver Detalhes'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoHospitalFound() {
    return const Column(
      children: [
        SizedBox(height: 12),
        Center(
          child: Text(
            'Nenhum hospital encontrado com o critério selecionado.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informações Adicionais',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildEmergencyNumbersCard(),
      ],
    );
  }

  Widget _buildEmergencyNumbersCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEmergencyNumbersHeader(),
            const SizedBox(height: 12),
            ..._buildEmergencyNumbersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyNumbersHeader() {
    return Row(
      children: const [
        Icon(Icons.emergency, color: Colors.red),
        SizedBox(width: 8),
        Text(
          'Números de Emergência',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  List<Widget> _buildEmergencyNumbersList() {
    final emergencyNumbers = [
      ('Emergência Nacional', '112'),
      ('INEM', '112'),
      ('SNS 24', '808 24 24 24'),
      ('Centro Anti-Venenos', '808 250 143'),
    ];

    return emergencyNumbers
        .map((entry) => _buildEmergencyNumberRow(entry.$1, entry.$2))
        .expand((widget) => [widget, const SizedBox(height: 8)])
        .take(emergencyNumbers.length * 2 - 1)
        .toList();
  }

  Widget _buildEmergencyNumberRow(String label, String number) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14)),
        Text(
          number,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Navigation methods
  void _navigateToHospitalDetail(int hospitalId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospitalDetail(hospitalId: hospitalId,),
      ),
    );
  }

  String distanceToString(double? distance) {
    if (distance == null) {
      return '---';
    }

    if (distance < 1000) {
      return '${distance.toStringAsFixed(0)} m';
    } else {
      double kilometers = distance / 1000;
      return '${kilometers.toStringAsFixed(1)} km';
    }
  }
}