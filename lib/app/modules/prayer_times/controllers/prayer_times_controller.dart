// lib/app/modules/prayer_times/controllers/prayer_times_controller.dart

// ignore_for_file: avoid_print

import 'dart:async';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sholat/app/services/location_service.dart';
import '../../../services/prayer_times_service.dart';
//import '../../../utils/permission_helper.dart';

class PrayerTimesController extends GetxController {
  final PrayerTimesService _prayerTimeService = PrayerTimesService();
  final LocationService _locationService = LocationService();

  var isLoading = false.obs;
  var errorMessage = ''.obs;

  var prayerTimes = <String, String>{}.obs; // { "Fajr": "05:01", ... }
  var currentActivePrayer = ''.obs;
  var nextPrayerName = ''.obs;
  var currentAddress = ''.obs;
  var timeToNextPrayer = ''.obs; // countdown string

  Timer? _countdownTimer;

  @override
  void onInit() {
    super.onInit();
    loadPrayerTimes();
  }

  Future<void> loadPrayerTimes() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Ambil lokasi saat ini
      Position? position = await _locationService.getCurrentLocation();
      if (position == null) {
        errorMessage.value = 'Gagal mendapatkan lokasi saat ini.';
        return;
      }

      // Simpan koordinat yang baru didapat ke SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_lat', position.latitude);
      await prefs.setDouble('last_lon', position.longitude);

      // Ambil nama lokasi dari koordinat
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Tentukan alamat yang lebih lengkap
        currentAddress.value =
            '${place.locality ?? ''}, ${place.country ?? ''}';
      } else {
        // Jika nama lokasi tidak ditemukan, gunakan koordinat
        currentAddress.value =
            'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
      }

      // Gunakan koordinat dari objek position untuk menghitung jadwal sholat
      // Tidak perlu lagi mengambil dari SharedPreferences karena sudah ada
      List<Map<String, dynamic>> timesList = await _prayerTimeService
          .getPrayerTimesByCoordinates(position.latitude, position.longitude);

      // Konversi List menjadi Map<String, String>
      Map<String, String> timesMap = {};
      for (var item in timesList) {
        timesMap[item['name']] = item['time'];
      }
      prayerTimes.assignAll(timesMap);

      _updateCurrentAndNextPrayer();
      _startCountdown();
    } catch (e) {
      errorMessage.value = 'Gagal memuat waktu sholat: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void _updateCurrentAndNextPrayer() {
    if (prayerTimes.isEmpty) return;

    DateTime now = DateTime.now();
    String? active;
    String? next;

    List<MapEntry<String, String>> sortedTimes = prayerTimes.entries.toList()
      ..sort(
        (a, b) =>
            _parsePrayerTime(a.value).compareTo(_parsePrayerTime(b.value)),
      );

    for (int i = 0; i < sortedTimes.length; i++) {
      DateTime prayerTime = _parsePrayerTime(sortedTimes[i].value);
      DateTime? nextTime = (i + 1 < sortedTimes.length)
          ? _parsePrayerTime(sortedTimes[i + 1].value)
          : null;

      if (now.isAfter(prayerTime) &&
          (nextTime == null || now.isBefore(nextTime))) {
        active = sortedTimes[i].key;
        next = (i + 1 < sortedTimes.length)
            ? sortedTimes[i + 1].key
            : sortedTimes.first.key;
        break;
      }
    }

    // Jika belum ada waktu sholat yang berlalu, sholat pertama adalah yang berikutnya
    currentActivePrayer.value = active ?? sortedTimes.first.key;
    nextPrayerName.value = next ?? sortedTimes.first.key;
  }

  // Pindahkan fungsi _startCountdown() ke sini
  void _startCountdown() {
    _countdownTimer?.cancel();

    if (nextPrayerName.value.isEmpty) return;

    final nextTimeData = prayerTimes[nextPrayerName.value];

    if (nextTimeData == null) return;

    DateTime nextTime = _parsePrayerTime(nextTimeData);
    if (nextTime.isBefore(DateTime.now())) {
      nextTime = nextTime.add(const Duration(days: 1));
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      Duration diff = nextTime.difference(DateTime.now());

      if (diff.isNegative) {
        _updateCurrentAndNextPrayer();
        _startCountdown();
        timer.cancel();
        return;
      }

      timeToNextPrayer.value = _formatDuration(diff);
    });
  }

  DateTime _parsePrayerTime(String time) {
    final now = DateTime.now();
    final parts = time.split(':');
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }
}
