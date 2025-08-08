// lib/app/modules/prayer_times/controllers/prayer_times_controller.dart
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
import '../../../helpers/notification_scheduler.dart';
import '../../../utils/notification_helper.dart';

/// =====================
/// Class Model PrayerTime
/// =====================
class PrayerTime {
  final int id;
  final String name;
  final String time;
  final DateTime dateTime;

  PrayerTime({required this.id, required this.name, required this.dateTime})
    : time = DateFormat('HH:mm').format(dateTime.toLocal());
}

/// ===========================
/// Fungsi simpan ke cache lokal
/// ===========================
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

/// =============================
/// Controller Utama: PrayerTimes
/// =============================
class PrayerTimesController extends GetxController {
  final LocationService _locationService = LocationService();

  // Rx store (dipakai di UI)
  final notificationPrefs = <String, bool>{}.obs;
  final prayerTimes = <PrayerTime>[].obs;
  final currentAddress = ''.obs;
  final isLoading = true.obs;
  final errorMessage = ''.obs;

  final currentActivePrayer = ''.obs;
  final nextPrayerName = ''.obs;
  final timeToNextPrayer = ''.obs;

  late Timer _timer;

  static late PrayerTimesController instance;

  @override
  void onInit() {
    super.onInit();
    instance = this;
    loadNotificationPrefs();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isLoading.value) _checkActivePrayer();
    });
  }

  @override
  void onClose() {
    _timer.cancel();
    super.onClose();
  }

  // -------------------------
  // PUBLIC API untuk scheduler
  // -------------------------

  /// Mengembalikan list waktu sholat untuk **hari ini** (non-Rx)
  List<PrayerTime> get prayerTimesForToday {
    final now = DateTime.now();
    return prayerTimes.where((p) {
      final d = p.dateTime.toLocal();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  /// Mengembalikan preferensi notifikasi sebagai Map biasa (untuk scheduling)
  Map<String, bool> get notificationPrefsMap =>
      Map<String, bool>.from(notificationPrefs);

  /// Muat preferensi & data cached. Jika cache tidak valid maka ambil fresh.
  /// Default: tidak langsung menjadwalkan (schedule=false)
  Future<void> refreshPrayerTimesAndPrefs({bool schedule = false}) async {
    await loadNotificationPrefs();
    final loadedFromCache = await loadCachedPrayerData();
    if (!loadedFromCache) {
      await fetchPrayerTimes(schedule: schedule);
    }
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
  /// Jika [schedule] == true --> fungsi juga akan memanggil scheduler (jadwalkan notifikasi).
  /// Jika false, hanya ambil waktu & cache.
  Future<void> fetchPrayerTimes({bool schedule = true}) async {
    print('✅ Memulai fetch jadwal sholat...');
    isLoading(true);
    errorMessage('');

    try {
      Position? position = await _locationService.getCurrentLocation();
      if (position == null) {
        errorMessage('Tidak bisa mendapatkan lokasi. Coba lagi.');
        return;
      }

      // geocoding optional (jika gagal, lanjutkan)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          currentAddress.value =
              '${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
        } else {
          currentAddress.value =
              'Lat: ${position.latitude.toStringAsFixed(4)}, Lon: ${position.longitude.toStringAsFixed(4)}';
        }
      } catch (e) {
        print('⚠️ Gagal mendapatkan nama lokasi (geocoding): $e');
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

      final fetchedTimes = <PrayerTime>[
        PrayerTime(id: 1, name: 'Subuh', dateTime: prayerTimesResult.fajr),
        PrayerTime(
          id: 0,
          name: 'Terbit Matahari',
          dateTime: prayerTimesResult.sunrise,
        ),
        PrayerTime(id: 2, name: 'Dzuhur', dateTime: prayerTimesResult.dhuhr),
        PrayerTime(id: 3, name: 'Ashar', dateTime: prayerTimesResult.asr),
        PrayerTime(id: 4, name: 'Maghrib', dateTime: prayerTimesResult.maghrib),
        PrayerTime(id: 5, name: 'Isya', dateTime: prayerTimesResult.isha),
      ];

      prayerTimes.assignAll(fetchedTimes);
      await _cachePrayerData(fetchedTimes, currentAddress.value);
      _checkActivePrayer();

      // Hanya jadwalkan jika diminta (untuk menghindari double-scheduling dari background logic)
      if (schedule) {
        // Pakai entrypoint background-safe (notification_scheduler)
        await schedulePrayerNotificationsWithCatchup(
          fetchedTimes,
          notificationPrefsMap,
        );
        await markTodayAsScheduled();
      }

      print(
        '✅ Jadwal berhasil diambil${schedule ? ' & notifikasi dijadwalkan ulang.' : '.'}',
      );
    } catch (e, st) {
      print('❌ Error pada fetchPrayerTimes: $e');
      print(st);
      errorMessage('Terjadi kesalahan: ${e.toString()}');
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

    // Temukan sholat aktif (sholat terakhir yang sudah lewat)
    for (int i = prayerTimes.length - 1; i >= 0; i--) {
      if (now.isAfter(prayerTimes[i].dateTime)) {
        active = prayerTimes[i].name;
        break;
      }
    }

    // Temukan sholat berikutnya (sholat pertama yang belum terlewat)
    for (int i = 0; i < prayerTimes.length; i++) {
      if (now.isBefore(prayerTimes[i].dateTime)) {
        next = prayerTimes[i].name;
        nextPrayerTime = prayerTimes[i].dateTime;
        break;
      }
    }

    // Logika khusus untuk periode setelah Isya sampai Subuh
    if (next.isEmpty) {
      active = 'Isya';
      nextPrayerTime = prayerTimes
          .firstWhere((p) => p.name == 'Subuh')
          .dateTime
          .add(const Duration(days: 1));
      next = 'Subuh';
    }

    currentActivePrayer.value = active;
    nextPrayerName.value = next;

    if (nextPrayerTime != null && nextPrayerName.value.isNotEmpty) {
      final timeRemaining = nextPrayerTime.difference(now);
      if (!timeRemaining.isNegative) {
        timeToNextPrayer.value = _formatDuration(timeRemaining);
      } else {
        timeToNextPrayer.value = 'N/A';
      }
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
