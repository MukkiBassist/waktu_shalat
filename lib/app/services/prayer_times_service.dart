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
