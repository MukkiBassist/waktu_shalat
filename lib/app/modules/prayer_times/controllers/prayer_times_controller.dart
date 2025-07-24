// ignore_for_file: avoid_print

import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

import '../../../services/location_service.dart';
import '../../../utils/notification_helper.dart';

// =====================
// Class Model PrayerTime
// =====================
class PrayerTime {
  final String name;
  final String time; // String dalam format HH:mm
  final DateTime dateTime;

  PrayerTime({required this.name, required this.dateTime})
    : time = DateFormat('HH:mm').format(dateTime); // format otomatis
}

// ===========================
// Fungsi simpan ke cache lokal
// ===========================
Future<void> _cachePrayerData(List<PrayerTime> times, String address) async {
  final prefs = await SharedPreferences.getInstance();

  List<Map<String, dynamic>> data = times
      .map((e) => {'name': e.name, 'dateTime': e.dateTime.toIso8601String()})
      .toList();

  await prefs.setString('cachedPrayerTimes', jsonEncode(data));
  await prefs.setString('cachedAddress', address);
  await prefs.setString('cachedDate', DateTime.now().toIso8601String());
}

// =============================
// Controller Utama: PrayerTimes
// =============================
class PrayerTimesController extends GetxController {
  final LocationService _locationService = LocationService();

  final notificationPrefs = <String, bool>{}.obs;
  var prayerTimes = <PrayerTime>[].obs;
  var currentAddress = ''.obs;
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  var currentActivePrayer = ''.obs;
  var nextPrayerName = ''.obs;
  var timeToNextPrayer = ''.obs;

  late Timer _timer;

  // ========================
  // Load preferensi notifikasi
  // ========================
  Future<void> loadNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('prayerNotifPrefs');
    if (stored != null) {
      notificationPrefs.assignAll(Map<String, bool>.from(jsonDecode(stored)));
    } else {
      // default semua aktif kecuali Terbit
      notificationPrefs.assignAll({
        'Subuh': true,
        'Terbit Matahari': false,
        'Dzuhur': true,
        'Ashar': true,
        'Maghrib': true,
        'Isya': true,
      });
    }
  }

  // ========================
  // Simpan preferensi
  // ========================
  Future<void> saveNotificationPref() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('prayerNotifPrefs', jsonEncode(notificationPrefs));
  }

  // ========================
  // Format durasi waktu tersisa
  // ========================
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  // ========================
  // Lifecycle INIT
  // ========================
  @override
  void onInit() {
    super.onInit();
    loadNotificationPrefs();

    // Coba load cache terlebih dahulu
    loadCachedPrayerTimes().then((cached) {
      if (!cached) {
        print('Cache gagal. Fetch ulang...');
        fetchPrayerTimes(); // jika cache gagal
      } else {
        print('Cache sukses di-load');
        isLoading(false);
        handleRescheduleIfNeeded(); // ✅ Pastikan jadwal hari ini ter-set
      }
    });

    // Timer 1 detik untuk update status
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isLoading.value) {
        _checkActivePrayer();
      }
    });
  }

  @override
  void onClose() {
    _timer.cancel();
    super.onClose();
  }

  // ========================
  // Load dari Cache
  // ========================
  Future<bool> loadCachedPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('cachedPrayerTimes');
    final cachedAddress = prefs.getString('cachedAddress');
    final cachedDateStr = prefs.getString('cachedDate');

    if (cachedData != null && cachedAddress != null && cachedDateStr != null) {
      final cachedDate = DateTime.parse(cachedDateStr);
      final today = DateTime.now();

      if (cachedDate.year == today.year &&
          cachedDate.month == today.month &&
          cachedDate.day == today.day) {
        final decoded = jsonDecode(cachedData) as List;
        final times = decoded.map((e) {
          return PrayerTime(
            name: e['name'],
            dateTime: DateTime.parse(e['dateTime']),
          );
        }).toList();

        prayerTimes.assignAll(times);
        currentAddress.value = cachedAddress;
        _checkActivePrayer();
        return true;
      }
    }
    return false;
  }

  // ========================
  // Ambil lokasi & hitung jadwal
  // ========================
  Future<void> fetchPrayerTimes() async {
    isLoading(true);
    errorMessage('');
    print('Memulai fetch jadwal sholat...');

    try {
      Position? position = await _locationService.getCurrentLocation();

      if (position != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          currentAddress.value = place.locality ?? 'Lokasi Tidak Dikenal';
        } else {
          currentAddress.value =
              'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
        }

        final params = CalculationMethod.muslim_world_league.getParameters();
        params.madhab = Madhab.shafi;

        final prayerTimesResult = PrayerTimes(
          Coordinates(position.latitude, position.longitude),
          DateComponents.from(DateTime.now()),
          params,
        );

        List<PrayerTime> fetchedTimes = [
          PrayerTime(name: 'Subuh', dateTime: prayerTimesResult.fajr.toLocal()),
          PrayerTime(
            name: 'Terbit Matahari',
            dateTime: prayerTimesResult.sunrise.toLocal(),
          ),
          PrayerTime(
            name: 'Dzuhur',
            dateTime: prayerTimesResult.dhuhr.toLocal(),
          ),
          PrayerTime(name: 'Ashar', dateTime: prayerTimesResult.asr.toLocal()),
          PrayerTime(
            name: 'Maghrib',
            dateTime: prayerTimesResult.maghrib.toLocal(),
          ),
          PrayerTime(name: 'Isya', dateTime: prayerTimesResult.isha.toLocal()),
        ];

        prayerTimes.assignAll(fetchedTimes);

        await _cachePrayerData(fetchedTimes, currentAddress.value);
        _checkActivePrayer();

        await schedulePrayerNotifications(fetchedTimes, notificationPrefs);
        print('Jadwal berhasil diambil & notifikasi dijadwalkan ulang.');
      } else {
        errorMessage('Tidak bisa mendapatkan lokasi. Coba lagi.');
      }
    } catch (e) {
      String displayMessage;
      if (e.toString().contains('disabled')) {
        displayMessage = 'GPS dinonaktifkan. Aktifkan GPS Anda.';
      } else if (e.toString().contains('denied')) {
        displayMessage = 'Izin lokasi ditolak. Berikan izin di pengaturan.';
      } else {
        displayMessage = 'Terjadi kesalahan: $e';
      }
      errorMessage(displayMessage);
    } finally {
      isLoading(false);
    }
  }

  // ========================
  // Cek status sholat saat ini
  // ========================
  void _checkActivePrayer() {
    if (prayerTimes.isEmpty || isLoading.value) {
      currentActivePrayer.value = '';
      nextPrayerName.value = '';
      timeToNextPrayer.value = '';
      return;
    }

    final now = DateTime.now().toLocal();
    String active = '';
    String next = '';
    DateTime? nextPrayerTime;

    for (int i = 0; i < prayerTimes.length; i++) {
      if (now.isAfter(prayerTimes[i].dateTime)) {
        active = prayerTimes[i].name;
      } else {
        next = prayerTimes[i].name;
        nextPrayerTime = prayerTimes[i].dateTime;
        break;
      }
    }

    if (active == 'Isya' && now.isAfter(prayerTimes[5].dateTime)) {
      next = 'Subuh';
      nextPrayerTime = prayerTimes[0].dateTime.add(Duration(days: 1));
    } else if (active == '' && now.isBefore(prayerTimes[0].dateTime)) {
      active = 'Isya';
      next = 'Subuh';
      nextPrayerTime = prayerTimes[0].dateTime;
    }

    currentActivePrayer.value = active;
    nextPrayerName.value = next;

    if (nextPrayerTime != null && nextPrayerName.value.isNotEmpty) {
      final timeRemaining = nextPrayerTime.difference(now);
      if (timeRemaining.isNegative) {
        _checkActivePrayer(); // ulang jika salah waktu
        return;
      }
      timeToNextPrayer.value = _formatDuration(timeRemaining);
    } else {
      timeToNextPrayer.value = 'N/A';
    }
  }
}
