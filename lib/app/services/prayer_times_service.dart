// lib/app/services/prayer_times_service.dart
// ignore_for_file: avoid_print

import 'package:adhan/adhan.dart';
import 'package:sholat/app/data/models/prayer_time.dart';
import 'package:sholat/app/services/location_service.dart';
import 'package:sholat/app/utils/logger.dart';

class PrayerTimesService {
  final LocationService _locationService = LocationService();

  Future<List<PrayerTime>> fetchPrayerTimesForDays(
    int days, {
    double? latitude,
    double? longitude,
  }) async {
    try {
      Coordinates myCoordinates;

      // Gunakan koordinat yang diberikan jika ada
      if (latitude != null && longitude != null) {
        myCoordinates = Coordinates(latitude, longitude);
      } else {
        // Jika tidak, ambil lokasi dari service
        final position = await _locationService.getCurrentLocation();
        if (position == null) {
          throw Exception("Gagal mendapatkan lokasi pengguna");
        }
        myCoordinates = Coordinates(position.latitude, position.longitude);
      }

      final params = CalculationMethod.muslim_world_league.getParameters();
      params.madhab = Madhab.shafi;

      final prayerTimeList = <PrayerTime>[];

      for (int i = 0; i < days; i++) {
        final date = DateComponents.from(DateTime.now().add(Duration(days: i)));
        final prayerTimes = PrayerTimes(myCoordinates, date, params);

        prayerTimeList.add(
          PrayerTime(id: i * 6 + 1, name: 'Subuh', dateTime: prayerTimes.fajr),
        );
        prayerTimeList.add(
          PrayerTime(
            id: i * 6 + 2,
            name: 'Terbit Matahari',
            dateTime: prayerTimes.sunrise,
          ),
        );
        prayerTimeList.add(
          PrayerTime(
            id: i * 6 + 3,
            name: 'Dzuhur',
            dateTime: prayerTimes.dhuhr,
          ),
        );
        prayerTimeList.add(
          PrayerTime(id: i * 6 + 4, name: 'Ashar', dateTime: prayerTimes.asr),
        );
        prayerTimeList.add(
          PrayerTime(
            id: i * 6 + 5,
            name: 'Maghrib',
            dateTime: prayerTimes.maghrib,
          ),
        );
        prayerTimeList.add(
          PrayerTime(id: i * 6 + 6, name: 'Isya', dateTime: prayerTimes.isha),
        );
      }

      logSuccess('Prayer times fetched successfully for $days days.');
      return prayerTimeList;
    } catch (e) {
      logError('Failed to fetch prayer times: $e');
      return [];
    }
  }
}
