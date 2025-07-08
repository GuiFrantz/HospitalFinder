import 'package:flutter/material.dart';
import 'package:prjectcm/data/http_sns_datasource.dart';
import 'package:provider/provider.dart';
import 'package:prjectcm/models/hospital.dart';
import 'package:prjectcm/main.dart';

import '../connectivity_module.dart';
import '../data/sns_repository.dart';
import '../data/sqflite_sns_datasource.dart';
import '../location_module.dart';

class HospitalDetail extends StatelessWidget {
  final int hospitalId;



  const HospitalDetail({Key? key, required this.hospitalId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final httpDataSource = Provider.of<HttpSnsDataSource>(context);
    final sqfliteDataSource = Provider.of<SqfliteSnsDataSource>(context);
    final connectivityModule = Provider.of<ConnectivityModule>(context);
    final locationModule = Provider.of<LocationModule>(context);
    final repository = SnsRepository(httpDataSource, sqfliteDataSource, connectivityModule, locationModule);

    return Scaffold(
        appBar: _buildAppBar(),
        body: Center(
          child: FutureBuilder(
            future: repository.getHospitalDetailById(hospitalId),
            builder: (_, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return CircularProgressIndicator();
              } else {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.data == null) {
                  return Text('Hospital não encontrado');
                } else {
                  return _buildHospitalDetailScreen(snapshot.data!);
                }
              }
            },
          ),
        ));
  }

  Widget _buildHospitalDetailScreen(Hospital hospital) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderImage(),
            _buildHospitalInfoCard(hospital),
            _buildEvaluationsSection(hospital),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // AppBar Builder
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.mainAppColor,
      centerTitle: true,
      title: Text(
        'Detalhes do Hospital',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  // Header Image Builder
  Widget _buildHeaderImage() {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppColors.mainAppColor.withAlpha(_opacityToAlpha(0.2)),
      child: const Center(
        child: Icon(
          Icons.local_hospital,
          size: 80,
          color: AppColors.mainAppColor,
        ),
      ),
    );
  }

  // Hospital Info Card Builder
  Widget _buildHospitalInfoCard(Hospital hospital) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHospitalNameAndEmergencyStatus(hospital),
            const SizedBox(height: 16),
            _buildLocationAndRatingRow(hospital),
            const SizedBox(height: 8),
            _buildAddressSection(hospital),
            const SizedBox(height: 16),
            _buildContactSection(hospital),
            const SizedBox(height: 16),
            _buildCoordinatesSection(hospital),
          ],
        ),
      ),
    );
  }

  // Hospital Name and Emergency Status
  Widget _buildHospitalNameAndEmergencyStatus(Hospital hospital) {
    return Row(
      children: [
        Expanded(
          child: Text(
            hospital.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildEmergencyStatusBadge(hospital),
      ],
    );
  }

  Widget _buildEmergencyStatusBadge(Hospital hospital) {
    final bool hasEmergency = hospital.hasEmergency;
    final Color color = hasEmergency ? Colors.green : Colors.red;
    final IconData icon =
        hasEmergency ? Icons.medical_services : Icons.do_not_disturb;

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(_opacityToAlpha(0.2)),
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

  // Location and Rating Row
  Widget _buildLocationAndRatingRow(Hospital hospital) {
    final String averageRating = _calculateAverageRating(hospital);

    return Row(
      children: [
        _buildLocationInfo(hospital.district),
        const SizedBox(width: 16),
        _buildRatingInfo(averageRating),
        const SizedBox(width: 16),
        _buildDistanceInfo(hospital.distance),
      ],
    );
  }

  Widget _buildLocationInfo(String district) {
    return Row(
      children: [
        const Icon(Icons.location_on, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          district,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildRatingInfo(String averageRating) {
    return Row(
      children: [
        const Icon(Icons.star, size: 16, color: Colors.amber),
        const SizedBox(width: 4),
        Text(
          averageRating,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDistanceInfo(double? distance) {
    return Row(
      children: [
        const Icon(Icons.route, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          distanceToString(distance),
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  // Contact Information Sections
  Widget _buildAddressSection(Hospital hospital) {
    return _buildInfoSection(
      title: 'Endereço',
      content: Text(hospital.address, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildContactSection(Hospital hospital) {
    return _buildInfoSection(
      title: 'Contacto',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContactRow(Icons.phone, hospital.phoneNumber.toString()),
          const SizedBox(height: 8),
          _buildContactRow(Icons.email, hospital.email),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildCoordinatesSection(Hospital hospital) {
    return _buildInfoSection(
      title: 'Coordenadas',
      content: Row(
        children: [
          const Icon(Icons.gps_fixed, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            '${hospital.latitude}, ${hospital.longitude}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({required String title, required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        content,
      ],
    );
  }

  // Evaluations Section
  Widget _buildEvaluationsSection(Hospital hospital) {
    return Column(
      children: [
        _buildEvaluationsHeader(hospital),
        _buildEvaluationsList(hospital),
      ],
    );
  }

  Widget _buildEvaluationsHeader(Hospital hospital) {
    final String averageRating = _calculateAverageRating(hospital);
    final double ratingValue = averageRating != 'Sem avaliações'
        ? double.tryParse(averageRating.split('/').first) ?? 0.0
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Avaliações (${hospital.reports.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (ratingValue > 0) Row(children: _buildRatingStars(ratingValue)),
        ],
      ),
    );
  }

  Widget _buildEvaluationsList(Hospital hospital) {
    if (hospital.reports.isEmpty) {
      return _buildNoEvaluationsMessage();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: hospital.reports.length,
      itemBuilder: (context, index) =>
          _buildEvaluationCard(hospital.reports[index]),
    );
  }

  Widget _buildEvaluationCard(evaluation) {
    final int ratingNum = evaluation.rating;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildEvaluationHeader(evaluation.dateTime, ratingNum),
            if (evaluation.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Text(evaluation.comment, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationHeader(String dateTime, int rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          dateTime,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        Row(
          children: List.generate(
            5,
            (i) => Icon(
              i < rating ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoEvaluationsMessage() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text(
          'Este hospital ainda não tem avaliações.',
          style: TextStyle(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  // Utility Methods
  String _calculateAverageRating(Hospital hospital) {
    if (hospital.reports.isEmpty) {
      return 'Sem avaliações';
    }

    double totalRating = 0;
    int validRatingsCount = 0;

    for (var evaluation in hospital.reports) {
      final ratingValue = evaluation.rating;
      totalRating += ratingValue;
      validRatingsCount++;
        }

    if (validRatingsCount == 0) {
      return 'Sem avaliações';
    }

    double average = totalRating / validRatingsCount;
    return '${average.toStringAsFixed(1)}/5';
  }

  List<Widget> _buildRatingStars(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = rating - fullStars >= 0.5;

    // Add full stars
    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, color: Colors.amber, size: 18));
    }

    // Add half star if needed
    if (hasHalfStar) {
      stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 18));
    }

    // Add empty stars
    int emptyStars = 5 - stars.length;
    for (int i = 0; i < emptyStars; i++) {
      stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 18));
    }

    return stars;
  }

  int _opacityToAlpha(double opacity) {
    return (opacity * 255).round();
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
