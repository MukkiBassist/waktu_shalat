// lib/app/services/prayer_times_service.dart
// ignore_for_file: avoid_print

import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:sholat/app/services/location_service.dart';

class PrayerTimeItem {
  final String name;
  final String time; // format HH:mm untuk view
  final DateTime dateTime;

  PrayerTimeItem({required this.name, required this.dateTime})
    : time = DateFormat('HH:mm').format(dateTime);
}

class PrayerTimesService {
  final LocationService _locationService = LocationService();
  //final PrayerCacheService _cacheService = PrayerCacheService();

  /* /// Ambil jadwal sholat dari lokasi user, simpan ke cache, lalu jadwalkan notifikasi
  Future<void> fetchAndCachePrayerTimes() async {
    try {
      // 1️⃣ Ambil lokasi dari LocationService
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        throw Exception("Gagal mendapatkan lokasi pengguna");
      }

      final myCoordinates = Coordinates(position.latitude, position.longitude);

      // 2️⃣ Tentukan parameter perhitungan (contoh: Muslim World League)
      final params = CalculationMethod.muslim_world_league.getParameters();
      params.madhab = Madhab.shafi;

      // 3️⃣ Hitung jadwal sholat
      final prayerTimes = PrayerTimes.today(myCoordinates, params);

      // 4️⃣ Konversi ke List Map untuk disimpan
      final prayerTimesList = [
        {"name": "Subuh", "time": prayerTimes.fajr.toLocal()},
        {"name": "Matahari Terbit", "time": prayerTimes.sunrise.toLocal()},
        {"name": "Dzuhur", "time": prayerTimes.dhuhr.toLocal()},
        {"name": "Ashar", "time": prayerTimes.asr.toLocal()},
        {"name": "Maghrib", "time": prayerTimes.maghrib.toLocal()},
        {"name": "Isya", "time": prayerTimes.isha.toLocal()},
      ];

      // 5️⃣ Ambil lama cache (default 3 hari jika belum di-set user)
      final cacheDays = await _cacheService.getCacheDays();

      // 6️⃣ Simpan ke cache
      await _cacheService.savePrayerTimesToCache(prayerTimesList, cacheDays);

      // 7️⃣ Jadwalkan notifikasi untuk setiap waktu sholat
      for (var prayer in prayerTimesList) {
        final prayerName = prayer['name']!;
        final time = prayer['time']! as DateTime;

        await NotificationService().schedulePrayerNotification(
          id: prayerName.hashCode, // unik per nama
          title: 'Waktu Sholat',
          body: 'Sekarang waktunya sholat $prayerName',
          dateTime: time,
          payload: 'prayer_$prayerName',
        );
      }

      print("✅ Jadwal sholat berhasil diambil dan disimpan.");
    } catch (e) {
      print("❌ Gagal mengambil jadwal sholat: $e");
    }
  } */

  Future<List<PrayerTimeItem>> fetchPrayerTimesForDays(int days) async {
    final position = await _locationService.getCurrentLocation();
    if (position == null) {
      throw Exception("Gagal mendapatkan lokasi pengguna");
    }

    final myCoordinates = Coordinates(position.latitude, position.longitude);
    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;

    final today = DateTime.now();
    final List<PrayerTimeItem> allTimes = [];

    for (int i = 0; i < days; i++) {
      final date = today.add(Duration(days: i));
      final prayerTimes = PrayerTimes(
        myCoordinates,
        DateComponents.from(date),
        params,
      );

      allTimes.addAll([
        PrayerTimeItem(
          name: "Subuh",
          dateTime: _mergeDateTime(date, prayerTimes.fajr.toLocal()),
        ),
        PrayerTimeItem(
          name: 'Dzuhur',
          dateTime: _mergeDateTime(date, prayerTimes.dhuhr.toLocal()),
        ),
        PrayerTimeItem(
          name: 'Ashar',
          dateTime: _mergeDateTime(date, prayerTimes.asr.toLocal()),
        ),
        PrayerTimeItem(
          name: 'Maghrib',
          dateTime: _mergeDateTime(date, prayerTimes.maghrib.toLocal()),
        ),
        PrayerTimeItem(
          name: 'Isya',
          dateTime: _mergeDateTime(date, prayerTimes.isha.toLocal()),
        ),
      ]);
    }

    return allTimes;
  }

  DateTime _mergeDateTime(DateTime date, DateTime prayerTime) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      prayerTime.hour,
      prayerTime.minute,
    );
  }

  Future<List<Map<String, dynamic>>> getPrayerTimesByCoordinates(
    double lat,
    double lon,
  ) async {
    final coordinates = Coordinates(lat, lon);

    final params = CalculationMethod.muslim_world_league.getParameters();
    params.madhab = Madhab.shafi;

    //Hitung jadwal sholat untuk hari ini
    final prayerTimes = PrayerTimes.today(coordinates, params);
    final format = DateFormat('HH:mm');

    return [
      {"name": "Subuh", "time": format.format(prayerTimes.fajr.toLocal())},
      {
        "name": "Terbit Matahari",
        "time": format.format(prayerTimes.sunrise.toLocal()),
      },
      {"name": "Dzuhur", "time": format.format(prayerTimes.dhuhr.toLocal())},
      {"name": "Ashar", "time": format.format(prayerTimes.asr.toLocal())},
      {"name": "Maghrib", "time": format.format(prayerTimes.maghrib.toLocal())},
      {"name": "Isya", "time": format.format(prayerTimes.isha.toLocal())},
    ];
  }
}
