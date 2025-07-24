// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:math';
import 'package:sholat/app/services/location_service.dart';

class QiblaController extends GetxController {
  final LocationService _locationService = LocationService();

  var heading = 0.0.obs;
  var qiblaDirection = 0.0.obs;
  var errorMessage = ''.obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    // TODO: implement onInit
    super.onInit();
    initQiblaSensor();
  }

  void initQiblaSensor() async {
    isLoading(true);
    errorMessage('');
    try {
      // dapatkan lokasi pengguna
      Position? position = await _locationService.getCurrentLocation();
      if (position != null) {
        //hitung azimuth kiblat dari lokasi pengguna
        final coordinates = Coordinates(position.latitude, position.longitude);
        final qibla = Qibla(coordinates);
        qiblaDirection.value = qibla.direction;

        //mulai membaca sensor kompas
        FlutterCompass.events?.listen((CompassEvent event) {
          if (event.heading != null) {
            // event.heading adalah arah hadap perangkat dari utara magnetik (0-360 derajat)
            // Kita perlu adjust dengan deklinasi magnetik jika ingin akurat ke utara geografis
            // Namun, untuk kompas sederhana, heading langsung cukup.
            heading.value = event.heading!;
          }
        });
      } else {
        errorMessage(
          'Tidak dapat mengambil lokasi, Pastikan aplikasi mendapat izin lokasi',
        );
      }
    } catch (e) {
      errorMessage(
        'Terjadi Kesalahan saat menginisialisasi Qibla: ${e.toString()}',
      );
      print('Error Qibla Controller : $e');
    } finally {
      isLoading(false);
    }
  }

  double get qiblaRotation {
    return ((qiblaDirection.value - heading.value) * (pi / 180));
  }
}
