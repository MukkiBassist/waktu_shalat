// lib/app/modules/prayer_times/controllers/prayer_times_controller.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sholat/app/services/prayer_cache_service.dart';
import 'package:sholat/app/services/prayer_times_service.dart';
import 'package:sholat/app/utils/logger.dart';
import 'package:intl/intl.dart';
import 'package:sholat/app/data/models/prayer_time.dart';
import 'package:sholat/app/services/location_service.dart';
import 'package:sholat/app/utils/notification_controller.dart';
import 'package:sholat/app/modules/settings/controllers/settings_controller.dart';

class PrayerTimesController extends GetxController {
  final settingsController = Get.find<SettingsController>();
  final auraColor = const Color(0xffEEEEEE).obs;
  final appBarAuraColor = const Color(0xffEEEEEE).obs;
  final _isLoading = false.obs;
  bool get isLoading => _isLoading.value;

  final _prayerTimes = <PrayerTime>[].obs;
  List<PrayerTime> get prayerTimes => _prayerTimes;

  List<PrayerTime> get todayPrayerTimes {
    final now = DateTime.now();
    return _prayerTimes.where((prayer) {
      final prayerDate = prayer.dateTime.toLocal();
      return prayerDate.year == now.year &&
          prayerDate.month == now.month &&
          prayerDate.day == now.day;
    }).toList();
  }

  var currentActivePrayer = ''.obs;
  var nextPrayerName = ''.obs;
  var currentAddress = 'Memuat lokasi...'.obs;
  var timeToNextPrayer = ''.obs;

  final PrayerCacheService _cacheService = PrayerCacheService();
  final PrayerTimesService _prayerService = PrayerTimesService();
  final LocationService _locationService = LocationService();

  Timer? _countdownTimer;

  @override
  void onInit() {
    super.onInit();
    loadLastColors();
    loadLastAddress();
    fetchAndSetPrayerTimes();
  }

  Future<void> loadLastAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString('last_address');
    if (savedAddress != null) {
      currentAddress.value = savedAddress;
    }
  }

  Future<void> saveColors(Color aura, Color appBarAura) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auraColor', aura.hashCode);
    await prefs.setInt('appBarAuraColor', appBarAura.hashCode);
  }

  Future<void> loadLastColors() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAuraColorValue = prefs.getInt('auraColor');
    final savedAppBarAuraColorValue = prefs.getInt('appBarAuraColor');

    if (savedAuraColorValue != null) {
      auraColor.value = Color(savedAuraColorValue);
    }
    if (savedAppBarAuraColorValue != null) {
      appBarAuraColor.value = Color(savedAppBarAuraColorValue);
    }
  }

  // ✅ Perbaikan: Menggunakan logika warna dari HomeView yang Anda sukai
  void updateAuraColor(String prayerName) {
    Color baseColor;
    switch (prayerName.toLowerCase()) {
      case 'terbit matahari':
        baseColor = const Color(0xFFFFF9C4);
        break;
      case 'subuh':
        baseColor = const Color(0xFFB3E5FC);
        break;
      case 'dzuhur':
        baseColor = Color.lerp(
          const Color(0xFFFFF9C4),
          const Color(0xFFFFE0B2),
          0.3,
        )!;
        break;
      case 'ashar':
        baseColor = const Color(0xFFFFCC80);
        break;
      case 'maghrib':
        baseColor = Color.lerp(
          const Color(0xFFFFAB91), // pastel coral
          const Color(0xFFD1C4E9), // pastel lavender
          0.5,
        )!;
        break;
      case 'isya':
        baseColor = const Color(0xFFB39DDB);
        break;
      default:
        baseColor = const Color(0xFFCFD8DC);
    }

    auraColor.value = baseColor.withAlpha(89);
    appBarAuraColor.value = baseColor.withAlpha(200);
    saveColors(auraColor.value, appBarAuraColor.value);
  }

  Future<void> fetchAndSetPrayerTimes({bool forceRefresh = false}) async {
    try {
      _isLoading(true);
      final isCacheExpired = await _cacheService.isCacheExpired();

      List<PrayerTime> dataToProcess = [];

      if (forceRefresh || isCacheExpired) {
        logInfo('Cache expired or empty. Fetching new data from network...');
        final position = await _locationService.getCurrentLocation();

        if (position != null) {
          final days = settingsController.cacheDays.value;

          //simpan alamat
          String address;
          try {
            address = await _locationService.getAddressFromCoordinates(
              position.latitude,
              position.longitude,
            );
          } catch (e) {
            logError('Failed to get address from coordinates: $e');
            final prefs = await SharedPreferences.getInstance();
            address =
                prefs.getString('last_address') ?? 'Alamat tidak tersedia';
          }
          currentAddress.value = address;
          // Simpan ke prefs
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('last_address', address);
          await prefs.setDouble('last_lat', position.latitude);
          await prefs.setDouble('last_lon', position.longitude);

          dataToProcess = await _prayerService.fetchPrayerTimesForDays(
            days,
            latitude: position.latitude,
            longitude: position.longitude,
          );

          if (dataToProcess.isNotEmpty) {
            await _cacheService.savePrayerTimes(dataToProcess);
            await NotificationController().performReschedule();
            logSuccess('Prayer times fetched and saved to cache.');
          } else {
            await _loadFromCache();
            dataToProcess = _prayerTimes.toList();
            logWarning('Failed to fetch new prayer times.');
          }
        } else {
          logError('Failed to get current location. Cannot fetch new data.');

          // Coba muat dari cache jika lokasi tidak tersedia
          final prefs = await SharedPreferences.getInstance();
          final savedLat = prefs.getDouble('last_lat');
          final savedLon = prefs.getDouble('last_lon');
          final savedAddress = prefs.getString('last_address');
          if (savedLat != null && savedLon != null) {
            currentAddress.value = savedAddress ?? 'Alamat tidak tersedia';
            dataToProcess = await _prayerService.fetchPrayerTimesForDays(
              settingsController.cacheDays.value,
              latitude: savedLat,
              longitude: savedLon,
            );
          } else {
            await _loadFromCache();
            dataToProcess = _prayerTimes.toList();
          }
        }
      } else {
        logInfo('Using cached data.');
        await _loadFromCache();
        dataToProcess = _prayerTimes.toList();
      }

      _prayerTimes.value = dataToProcess;

      if (_prayerTimes.isNotEmpty) {
        _updatePrayerState();
        _startCountdown();
      }
    } finally {
      _isLoading(false);
    }
  }

  Future<void> _loadFromCache() async {
    final cachedData = await _cacheService.getPrayerTimes();
    if (cachedData.isNotEmpty) {
      _prayerTimes.value = cachedData;
      logSuccess('Prayer times loaded from cache.');
    } else {
      logWarning('No prayer times found in cache.');
    }
  }

  void _updatePrayerState() {
    if (_prayerTimes.isEmpty) return;
    final now = DateTime.now();
    final sortedTimes = List<PrayerTime>.from(_prayerTimes)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    PrayerTime? active;
    PrayerTime? next;

    for (int i = 0; i < sortedTimes.length; i++) {
      if (now.isAfter(sortedTimes[i].dateTime.toLocal())) {
        active = sortedTimes[i];
      }
      if (now.isBefore(sortedTimes[i].dateTime.toLocal())) {
        next = sortedTimes[i];
        break;
      }
    }

    currentActivePrayer.value = active?.name ?? '';
    nextPrayerName.value = next?.name ?? sortedTimes.first.name;

    final colorSource = currentActivePrayer.value.isNotEmpty
        ? currentActivePrayer.value
        : nextPrayerName.value;
    updateAuraColor(colorSource);
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (nextPrayerName.value.isEmpty) return;

    final nextPrayer = _prayerTimes.firstWhereOrNull(
      (p) => p.name == nextPrayerName.value,
    );
    if (nextPrayer == null) return;

    DateTime nextTime = nextPrayer.dateTime.toLocal();
    if (nextTime.isBefore(DateTime.now())) {
      nextTime = nextTime.add(const Duration(days: 1));
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final diff = nextTime.difference(DateTime.now());
      if (diff.isNegative) {
        _updatePrayerState();
        _startCountdown();
        timer.cancel();
        return;
      }
      timeToNextPrayer.value = _formatDuration(diff);
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  String formatTimeForDisplay(DateTime dateTime) {
    return DateFormat('HH:mm').format(dateTime.toLocal());
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    super.onClose();
  }
}
