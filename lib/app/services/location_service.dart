// lib/app/services/location_service.dart
// ignore_for_file: avoid_print
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sholat/app/utils/logger.dart';

class LocationService {
  Future<Position?> getCurrentLocation({bool saveToPrefs = true}) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      logWarning('LocationService: disabled');
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        logWarning('LocationService: permission denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      logWarning('LocationService: permission denied forever');
      return null;
    }

    try {
      final position =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 0,
            ),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              logWarning(
                'LocationService: timeout obtaining position, falling back to cache',
              );
              throw Exception('Timeout obtaining position');
            },
          );

      if (saveToPrefs) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('last_lat', position.latitude);
        await prefs.setDouble('last_lon', position.longitude);
      }

      return position;
    } catch (e) {
      logError('LocationService: error obtaining position -> $e');
      return null;
    }
  }

  Future<String> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.locality}, ${place.administrativeArea}, ${place.country}";
      }
      return "Alamat tidak ditemukan";
    } catch (e) {
      logError("Error getAddressFromCoordinates: $e");
      return "Gagal mendapatkan alamat";
    }
  }
}
