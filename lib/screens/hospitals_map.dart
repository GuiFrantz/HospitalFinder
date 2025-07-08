import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:prjectcm/data/http_sns_datasource.dart';
import 'package:prjectcm/models/hospital.dart';
import 'package:provider/provider.dart';
import '../location_module.dart';
import 'hospital_detail.dart';

class HospitalsMap extends StatefulWidget {
  const HospitalsMap({Key? key}) : super(key: key);

  @override
  State<HospitalsMap> createState() => _HospitalsMapState();
}

class _HospitalsMapState extends State<HospitalsMap> {
  GoogleMapController? _mapController;
  final LocationModule _locationService = LocationModule();
  LocationData? _currentLocation;
  StreamSubscription<LocationData>? _locationSubscription;

  Set<Marker> _hospitalMarkers = {};
  List<Hospital> _hospitals = [];
  bool _isLoading = true;

  static const CameraPosition _defaultInitialPosition = CameraPosition(
    target: LatLng(38.7223, -9.1393),
    zoom: 8.0,
  );

  @override
  void initState() {
    super.initState();
    _initializeMapData();
  }

  Future<void> _initializeMapData() async {
    _getUserLocation();
    await _loadHospitals();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
    _listenToLocationChanges();
  }

  Future<void> _getUserLocation() async {
    try {
      _currentLocation = await _locationService.getCurrentLocation();
      if (_currentLocation != null && mounted) {
        _animateToUserLocation();
      }
    } catch (e) {
      print("Error getting current location: $e");
    }
  }

  void _listenToLocationChanges() {
    _locationSubscription = _locationService.onLocationChanged().listen((LocationData newLocation) {
      if (mounted) {
        setState(() {
          _currentLocation = newLocation;
        });
      }
    });
  }

  Future<void> _loadHospitals() async {
    try {
      final repository = context.read<HttpSnsDataSource>();
      _hospitals = await repository.getAllHospitals();
      _updateMarkers();
    } catch (e) {
      print("Error loading hospitals: $e");
    }
  }

  void _updateMarkers() {
    if (_hospitals.isEmpty) return;

    final Set<Marker> markers = {};
    for (final hospital in _hospitals) {
      markers.add(
        Marker(
          markerId: MarkerId(hospital.id.toString()),
          position: LatLng(hospital.latitude, hospital.longitude),
          infoWindow: InfoWindow(
            title: hospital.name,
            snippet: 'Clique para ver detalhes',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HospitalDetail(
                    hospitalId: hospital.id,
                  ),
                ),
              );
            },
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
    if (mounted) {
      setState(() {
        _hospitalMarkers = markers;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_currentLocation != null) {
      _animateToUserLocation();
    }
  }

  void _animateToUserLocation() {
    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
            zoom: 14.0,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: _currentLocation != null
            ? CameraPosition(
          target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          zoom: 14.0,
        )
            : _defaultInitialPosition,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _hospitalMarkers,
        mapType: MapType.normal,
        zoomControlsEnabled: true,
      ),
    );
  }
}