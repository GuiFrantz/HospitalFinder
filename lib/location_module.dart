import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';
import 'package:flutter/foundation.dart';

class LocationModule {
  final Location _location = Location();

  Future<bool> _checkAndRequestPermission() async {
    if (kDebugMode) {
      try {
        bool serviceEnabled = await _location.serviceEnabled()
            .timeout(Duration(milliseconds: 500), onTimeout: () {
          return true;
        });

        if (!serviceEnabled) {
          serviceEnabled = await _location.requestService()
              .timeout(Duration(milliseconds: 500), onTimeout: () {
            return true;
          });

          if (!serviceEnabled) {
            return true;
          }
        }
        PermissionStatus permissionGranted = await _location.hasPermission()
            .timeout(Duration(milliseconds: 100), onTimeout: () {
          return PermissionStatus.granted;
        });


        if (permissionGranted == PermissionStatus.denied) {
          permissionGranted = await _location.requestPermission()
              .timeout(Duration(milliseconds: 100), onTimeout: () {
            return PermissionStatus.granted;
          });

          if (permissionGranted != PermissionStatus.granted) {
            return true;
          }
        }

        return true;

      } catch (e) {
        return true;
      }
    } else {
      try {
        bool serviceEnabled = await _location.serviceEnabled();

        if (!serviceEnabled) {
          serviceEnabled = await _location.requestService();
          if (!serviceEnabled) {
            return false;
          }
        }

        PermissionStatus permissionGranted = await _location.hasPermission();

        if (permissionGranted == PermissionStatus.denied) {
          permissionGranted = await _location.requestPermission();
          if (permissionGranted != PermissionStatus.granted) {
            return false;
          }
        }
        return true;
      } catch (e) {
        return false;
      }
    }
  }

  Future<LocationData?> getCurrentLocation() async {
    final hasPermission = await _checkAndRequestPermission();
    if (!hasPermission) {
      return null;
    }

    try {
      if (kDebugMode) {
        return LocationData.fromMap({
          'latitude': 38.7580,
          'longitude': -9.1531,
          'accuracy': 1.0
        });
      }

      final locationData = await _location.getLocation()
          .timeout(Duration(milliseconds: 100), onTimeout: () {
        return LocationData.fromMap({
          'latitude': 38.7580,
          'longitude': -9.1531,
          'accuracy': 1.0
        });
      });

      return locationData;
    } catch (e) {
      return null;
    }
  }

  Stream<LocationData> onLocationChanged() {
    return Stream.fromFuture(_checkAndRequestPermission()).asyncExpand((hasPermission) {
      if (!hasPermission) {
        return Stream.empty();
      } else {
        return _location.onLocationChanged.handleError((error) {
        });
      }
    });
  }

  double calculateDistance(double startLatitude, double startLongitude,
      double endLatitude, double endLongitude) {

    final distance = Geolocator.distanceBetween(
        startLatitude, startLongitude, endLatitude, endLongitude);
    return distance;
  }
}