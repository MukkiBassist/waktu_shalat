// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/location_service.dart';
import '../../../utils/notification_helper.dart';

// =====================
// Class Model PrayerTime
// =====================
class PrayerTime {
  final int id;
  final String name;
  final String time;
  final DateTime dateTime;

  PrayerTime({required this.id, required this.name, required this.dateTime})
    : time = DateFormat('HH:mm').format(dateTime.toLocal());
}

// ===========================
// Fungsi simpan ke cache lokal
// ===========================
Future<void> _cachePrayerData(List<PrayerTime> times, String address) async {
  final prefs = await SharedPreferences.getInstance();

  List<Map<String, dynamic>> data = times
      .map(
        (e) => {
          'id': e.id,
          'name': e.name,
          'dateTime': e.dateTime.toIso8601String(),
        },
      )
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

  static late PrayerTimesController instance;

  @override
  void onInit() {
    super.onInit();
    instance = this;
    loadNotificationPrefs();
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

  // ==================================
  // FUNGSI BARU: Meminta izin lokasi
  // ==================================
  Future<void> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ Lokasi tidak diaktifkan.');
      await Geolocator.openLocationSettings();
      throw Exception('Layanan lokasi tidak diaktifkan.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ Izin lokasi ditolak.');
        throw Exception('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Izin lokasi ditolak secara permanen.');
      throw Exception(
        'Izin lokasi ditolak secara permanen, tidak bisa meminta lagi.',
      );
    }

    print('✅ Izin lokasi diberikan.');
  }

  // ========================
  // Ambil lokasi & hitung jadwal
  // ========================
  Future<void> fetchPrayerTimes() async {
    print('✅ Memulai fetch jadwal sholat...');
    isLoading(true);
    errorMessage('');

    try {
      Position? position = await _locationService.getCurrentLocation();
      if (position != null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          currentAddress.value =
              '${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
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
          PrayerTime(id: 1, name: 'Subuh', dateTime: prayerTimesResult.fajr),
          PrayerTime(
            id: 0,
            name: 'Terbit Matahari',
            dateTime: prayerTimesResult.sunrise,
          ),
          PrayerTime(id: 2, name: 'Dzuhur', dateTime: prayerTimesResult.dhuhr),
          PrayerTime(id: 3, name: 'Ashar', dateTime: prayerTimesResult.asr),
          PrayerTime(
            id: 4,
            name: 'Maghrib',
            dateTime: prayerTimesResult.maghrib,
          ),
          PrayerTime(id: 5, name: 'Isya', dateTime: prayerTimesResult.isha),
        ];

        prayerTimes.assignAll(fetchedTimes);
        await _cachePrayerData(fetchedTimes, currentAddress.value);
        _checkActivePrayer();
        await schedulePrayerNotifications(fetchedTimes, notificationPrefs);
        await markTodayAsScheduled();

        print('✅ Jadwal berhasil diambil & notifikasi dijadwalkan ulang.');
      } else {
        errorMessage('Tidak bisa mendapatkan lokasi. Coba lagi.');
      }
    } catch (e, stackTrace) {
      print('❌ Error pada fetchPrayerTimes: $e');
      print('❌ StackTrace: $stackTrace');
      String displayMessage = 'Terjadi kesalahan: ${e.toString()}';
      errorMessage(displayMessage);
    } finally {
      isLoading(false);
    }
  }

  // ========================
  // Load dari Cache
  // ========================
  Future<bool> loadCachedPrayerData() async {
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
            id: e['id'],
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
      if (now.isAfter(prayerTimes[i].dateTime.toLocal())) {
        active = prayerTimes[i].name;
      } else {
        next = prayerTimes[i].name;
        nextPrayerTime = prayerTimes[i].dateTime;
        break;
      }
    }

    if (active == 'Isya' && now.isAfter(prayerTimes[5].dateTime.toLocal())) {
      next = 'Subuh';
      nextPrayerTime = prayerTimes[0].dateTime.toLocal().add(
        const Duration(days: 1),
      );
    } else if (active.isEmpty &&
        now.isBefore(prayerTimes[0].dateTime.toLocal())) {
      active = 'Isya';
      next = 'Subuh';
      nextPrayerTime = prayerTimes[0].dateTime.toLocal();
    }

    currentActivePrayer.value = active;
    nextPrayerName.value = next;

    if (nextPrayerTime != null && nextPrayerName.value.isNotEmpty) {
      final timeRemaining = nextPrayerTime.difference(now);
      if (timeRemaining.isNegative) {
        _checkActivePrayer();
        return;
      }
      timeToNextPrayer.value = _formatDuration(timeRemaining);
    } else {
      timeToNextPrayer.value = 'N/A';
    }
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
  // Load preferensi notifikasi
  // ========================
  Future<void> loadNotificationPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('prayerNotifPrefs');
    if (stored != null) {
      notificationPrefs.assignAll(Map<String, bool>.from(jsonDecode(stored)));
    } else {
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
}
