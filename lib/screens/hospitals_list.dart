import 'package:flutter/material.dart';
import 'package:prjectcm/data/http_sns_datasource.dart';
import 'package:prjectcm/models/hospital.dart';
import 'package:provider/provider.dart';
import '../connectivity_module.dart';
import '../data/sns_repository.dart';
import '../data/sqflite_sns_datasource.dart';
import '../location_module.dart';
import '../main.dart';
import 'hospital_detail.dart';

class HospitalsList extends StatefulWidget {
  const HospitalsList({Key? key}) : super(key: key);

  @override
  State<HospitalsList> createState() => _HospitalsListState();
}

class _HospitalsListState extends State<HospitalsList> {
  String _searchQuery = '';
  bool _showOnlyWithEmergency = false;
  List<Hospital> _allHospitals = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchHospitals();
  }

  Future<void> _fetchHospitals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final httpDataSource = Provider.of<HttpSnsDataSource>(context, listen: false);
      final sqfliteDataSource = Provider.of<SqfliteSnsDataSource>(context, listen: false);
      final connectivityModule = Provider.of<ConnectivityModule>(context, listen: false);
      final locationModule = Provider.of<LocationModule>(context, listen: false);
      final repository = SnsRepository(httpDataSource, sqfliteDataSource, connectivityModule, locationModule);

      _allHospitals = await repository.getAllHospitals();
    } catch (e) {
      _errorMessage = 'Error: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _opacityToAlpha(double opacity) {
    return (opacity * 255).round();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    } else {
      return Scaffold(
        body: _buildList(_allHospitals),
      );
    }
  }

  Widget _buildList(List<Hospital> hospitals) {
    final filteredHospitals = _getFilteredHospitals(hospitals);

    return Column(
      children: [
        _buildSearchSection(),
        _buildResultsCounter(filteredHospitals),
        _buildHospitalsList(filteredHospitals),
      ],
    );
  }

  List<Hospital> _getFilteredHospitals(List<Hospital> allHospitals) {
    if (allHospitals.isEmpty) return [];
    return allHospitals.where((hospital) {
      final hospitalName = hospital.name.toLowerCase();
      final hospitalDistrict = hospital.district.toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesSearch =
          hospitalName.contains(query) || hospitalDistrict.contains(query);
      final matchesEmergencyFilter =
          !_showOnlyWithEmergency || hospital.hasEmergency;
      return matchesSearch && matchesEmergencyFilter;
    }).toList();
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildSearchField(),
          const SizedBox(width: 8),
          _buildEmergencyFilter(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Expanded(
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Pesquisar hospitais...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildEmergencyFilter() {
    final mainAppColorAlpha20 = _opacityToAlpha(0.2);
    final greyAlpha10 = _opacityToAlpha(0.1);

    return InkWell(
      onTap: () {
        setState(() {
          _showOnlyWithEmergency = !_showOnlyWithEmergency;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _showOnlyWithEmergency
              ? AppColors.mainAppColor.withAlpha(mainAppColorAlpha20)
              : Colors.grey.withAlpha(greyAlpha10),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _showOnlyWithEmergency
                ? AppColors.mainAppColor
                : Colors.grey.withAlpha(100),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medical_services,
              size: 20,
              color:
              _showOnlyWithEmergency ? AppColors.mainAppColor : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              'Urgência',
              style: TextStyle(
                fontSize: 14,
                fontWeight: _showOnlyWithEmergency
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: _showOnlyWithEmergency
                    ? AppColors.mainAppColor
                    : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCounter(List<Hospital> filteredHospitals) {
    final count = filteredHospitals.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '$count ${count == 1 ? "hospital encontrado" : "hospitais encontrados"}',
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalsList(List<Hospital> filteredHospitals) {
    return Expanded(
      child: filteredHospitals.isEmpty
          ? _buildEmptyState("Não foi possível obter os hospitais. Verifique a conectividade e volte a tentar")
          : _buildHospitalsListView(filteredHospitals),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildHospitalsListView(List<Hospital> filteredHospitals) {
    return ListView.builder(
      key: const Key('list-view'),
      padding: const EdgeInsets.only(bottom: 16.0),
      itemCount: filteredHospitals.length,
      itemBuilder: (context, index) {
        final hospital = filteredHospitals[index];
        return _buildHospitalCard(hospital);
      },
    );
  }

  Widget _buildHospitalCard(Hospital hospital) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToHospitalDetail(hospital.id),
        child: Semantics(
          label: 'Hospital ${hospital.name}, Distrito ${hospital.district}, '
              '${hospital.hasEmergency ? 'Com' : 'Sem'} serviço de urgência',
          child: _buildHospitalListTile(hospital),
        ),
      ),
    );
  }

  Widget _buildHospitalListTile(Hospital hospital) {
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      isThreeLine: true,
      title: _buildHospitalTitle(hospital),
      subtitle: _buildHospitalSubtitle(hospital),
      trailing:
      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }

  Widget _buildHospitalTitle(Hospital hospital) {
    return Row(
      children: [
        Expanded(
          child: Text(
            hospital.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _buildEmergencyBadge(hospital.hasEmergency),
      ],
    );
  }

  Widget _buildEmergencyBadge(bool hasEmergency) {
    final greenAlpha20 = _opacityToAlpha(0.2);
    final redAlpha20 = _opacityToAlpha(0.2);

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasEmergency
            ? Colors.green.withAlpha(greenAlpha20)
            : Colors.red.withAlpha(redAlpha20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasEmergency ? Icons.check_circle_outline : Icons.highlight_off,
            size: 14,
            color: hasEmergency ? Colors.green.shade700 : Colors.red.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            'Urgência',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: hasEmergency ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalSubtitle(Hospital hospital) {
    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildLocationInfo(hospital.district),
              const SizedBox(width: 16),
              _buildDistanceInfo(hospital),
              const SizedBox(width: 16),
              _buildRatingInfo(hospital),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo(String district) {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              district,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceInfo(Hospital hospital) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.route, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          distanceToString(hospital.distance),
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildRatingInfo(Hospital hospital) {
    final ratingText = _calculateRatingText(hospital);
    if (ratingText == 'Sem avaliações') return const SizedBox.shrink();

    return Flexible(
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_border_outlined,
                size: 14, color: Colors.amber),
            const SizedBox(width: 4),
            Text(
              ratingText,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateRatingText(Hospital hospital) {
    if (hospital.reports.isEmpty) {
      return 'Sem avaliações';
    }

    double totalRating = 0;
    int validRatingsCount = 0;

    for (var evaluation in hospital.reports) {
      final ratingValue = int.tryParse(evaluation.rating.toString());

      if (ratingValue != null) {
        totalRating += ratingValue;
        validRatingsCount++;
      }
    }

    if (validRatingsCount > 0) {
      double average = totalRating / validRatingsCount;
      return '${average.toStringAsFixed(1)}/5';
    }

    return 'Sem avaliações';
  }

  void _navigateToHospitalDetail(int hospitalId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HospitalDetail(
          hospitalId: hospitalId,
        ),
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