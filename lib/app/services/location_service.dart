// lib/app/services/location_service.dart
// ignore_for_file: avoid_print

import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentLocation() async {
    print('LocationService: Starting getCurrentLocation...'); // Tambah ini
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('LocationService: Location services are disabled.'); // Tambah ini
      return Future.error('Location services are disabled.');
    }
    print('LocationService: Location service is enabled.'); // Tambah ini

    permission = await Geolocator.checkPermission();
    print(
      'LocationService: Initial permission status: $permission',
    ); // Tambah ini

    if (permission == LocationPermission.denied) {
      print('LocationService: Permissions denied, requesting...'); // Tambah ini
      permission = await Geolocator.requestPermission(); // Meminta izin lokasi
      print(
        'LocationService: Permission after request: $permission',
      ); // Tambah ini
      if (permission == LocationPermission.denied) {
        print(
          'LocationService: Location permissions are denied again.',
        ); // Tambah ini
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print(
        'LocationService: Location permissions are permanently denied.',
      ); // Tambah ini
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );
      print(
        'LocationService: Location successfully obtained: ${position.latitude}, ${position.longitude}',
      ); // Tambah ini
      return position;
    } catch (e) {
      print('LocationService: Error getting position: $e'); // Tambah ini
      return Future.error(
        'Failed to get current position: $e',
      ); // Pastikan ini juga mengembalikan error
    }
  }
}


//=====================================================
/* import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // documented code can be found)
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,

        // engaturan khusus platform di sini:
        // androidSettings: AndroidSettings(
        //   accuracy: LocationAccuracy.high,
        //   forceLocationManager: true, // Untuk menggunakan LocationManager API pada Android
        //   intervalDuration: const Duration(seconds: 10),
        //   distanceFilter: 0,
        // ),
        // appleSettings: AppleSettings(
        //   accuracy: LocationAccuracy.high,
        //   activityType: ActivityType.fitness,
        //   distanceFilter: 0,
        //   pauseLocationUpdatesAutomatically: true,
        //   showBackgroundLocationIndicator: false,
        // ),
      ),

      //desiredAccuracy: LocationAccuracy.high,
    );
  }
} */

