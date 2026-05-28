import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sholat/app/data/models/surah.dart';
import 'package:sholat/app/data/models/ayah.dart';
import 'package:sholat/app/services/quran_service.dart';
import 'package:sholat/app/utils/logger.dart';

class QuranController extends GetxController {
  final QuranService _quranService = QuranService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // State Daftar Surat
  final surahList = <Surah>[].obs;
  final filteredSurahList = <Surah>[].obs;
  final isLoadingSurahs = false.obs;
  final searchQuery = ''.obs;

  // State Detail Surat & Ayat
  final selectedSurah = Rxn<Surah>();
  final ayahList = <Ayah>[].obs;
  final isLoadingDetail = false.obs;

  // State Pengaturan Audio
  final selectedQari = '01'.obs; // Default: Abdullah Al-Juhany
  final playbackSpeed = 1.0.obs; // Default: 1.0x

  // State Pemutaran Audio Ayat
  final currentlyPlayingAyah = Rxn<int>(); // Nomor ayat yang diputar
  final isPlaying = false.obs;

  // State Download Progress per Ayat
  final audioDownloadProgress = <int, double>{}.obs;

  // State Download Massal (Satu Surat)
  final isDownloadingMassive = false.obs;
  final massiveDownloadProgress = 0.0.obs;

  // Daftar Nama Qari pendamping kode API
  final Map<String, String> qariList = {
    '01': 'Abdullah Al-Juhany',
    '02': 'Abdul Muhsin Al-Qasim',
    '03': 'Abdurrahman As-Sudais',
    '04': 'Ibrahim Al-Dossari',
    '05': 'Misyari Rasyid Al-Afasy',
    '06': 'Yasser Al-Dosari',
  };

  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
    fetchSurahs();

    // Listener saat pemutaran audio selesai
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      logSuccess('Audio finished playing.');
      _playNextAyahAutomatically();
    });

    // Listener perubahan status audio player
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      state,
    ) {
      isPlaying.value = (state == PlayerState.playing);
    });
  }

  @override
  void onClose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _playerCompleteSubscription?.cancel();
    _playerStateSubscription?.cancel();
    super.onClose();
  }

  /// Memuat pilihan preferensi Qari & Kecepatan Audio dari SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      selectedQari.value = prefs.getString('quran_selected_qari') ?? '01';
      playbackSpeed.value = prefs.getDouble('quran_playback_speed') ?? 1.0;
      _audioPlayer.setPlaybackRate(playbackSpeed.value);
    } catch (e) {
      logError('Error loadPreferences: $e');
    }
  }

  /// Menyimpan pilihan Qari
  Future<void> setQari(String qariKey) async {
    selectedQari.value = qariKey;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('quran_selected_qari', qariKey);
    logSuccess('Qari updated to $qariKey - ${qariList[qariKey]}');

    // Stop audio jika sedang memutar ketika Qari diganti
    if (isPlaying.value) {
      stopAudio();
    }
  }

  /// Menyimpan & mengubah kecepatan pemutaran audio
  Future<void> setPlaybackSpeed(double speed) async {
    playbackSpeed.value = speed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('quran_playback_speed', speed);
    await _audioPlayer.setPlaybackRate(speed);
    logSuccess('Playback speed updated to $speed x');
  }

  /// Mengunduh daftar 114 Surah
  Future<void> fetchSurahs() async {
    try {
      isLoadingSurahs(true);
      final list = await _quranService.fetchSurahList();
      surahList.value = list;
      filteredSurahList.value = list;
    } finally {
      isLoadingSurahs(false);
    }
  }

  /// Melakukan pencarian / pemfilteran Surat
  void filterSurah(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      filteredSurahList.value = surahList;
    } else {
      filteredSurahList.value = surahList.where((surah) {
        final nameLatin = surah.namaLatin.toLowerCase();
        final arti = surah.arti.toLowerCase();
        final num = surah.nomor.toString();
        final q = query.toLowerCase();
        return nameLatin.contains(q) || arti.contains(q) || num == q;
      }).toList();
    }
  }

  /// Mengunduh detail Surah dan daftar Ayat
  Future<void> loadSurahDetail(Surah surah) async {
    try {
      isLoadingDetail(true);
      selectedSurah.value = surah;
      ayahList.clear();
      audioDownloadProgress.clear();
      stopAudio();

      final list = await _quranService.fetchSurahDetail(surah.nomor);
      ayahList.value = list;

      // Membaca status ketersediaan cache audio lokal untuk setiap ayat
      for (final ayah in ayahList) {
        final isCached = await _quranService.isAudioDownloaded(
          surah.nomor,
          ayah.nomorAyat,
          selectedQari.value,
        );
        audioDownloadProgress[ayah.nomorAyat] = isCached ? 1.0 : 0.0;
      }
    } finally {
      isLoadingDetail(false);
    }
  }

  /// Memutar atau menjeda audio untuk ayat tertentu
  Future<void> togglePlayAyah(Ayah ayah) async {
    final surahNum = selectedSurah.value?.nomor;
    if (surahNum == null) return;

    final ayahNum = ayah.nomorAyat;

    // Jika menekan ayat yang sama saat sedang memutar, maka jeda (pause)
    if (currentlyPlayingAyah.value == ayahNum && isPlaying.value) {
      await _audioPlayer.pause();
      logInfo('Paused ayah $ayahNum');
      return;
    }

    // Jika menekan ayat yang sama saat sedang dijeda, maka lanjut (resume)
    if (currentlyPlayingAyah.value == ayahNum && !isPlaying.value) {
      await _audioPlayer.resume();
      logInfo('Resumed ayah $ayahNum');
      return;
    }

    // Menghentikan pemutaran sebelumnya jika ada
    await _audioPlayer.stop();
    currentlyPlayingAyah.value = ayahNum;

    final qariKey = selectedQari.value;
    final audioUrl = ayah.audio[qariKey] ?? ayah.audio['01'] ?? '';

    if (audioUrl.isEmpty) {
      Get.snackbar('Error', 'Audio tidak tersedia untuk Qari ini.');
      return;
    }

    // Cek apakah file sudah terunduh secara lokal
    final isCached = await _quranService.isAudioDownloaded(
      surahNum,
      ayahNum,
      qariKey,
    );
    final localPath = await _quranService.getAudioLocalPath(
      surahNum,
      ayahNum,
      qariKey,
    );

    if (isCached) {
      logInfo('Playing offline audio for ayah $ayahNum from: $localPath');
      audioDownloadProgress[ayahNum] = 1.0;
      await _audioPlayer.play(DeviceFileSource(localPath));
    } else {
      // Belum ada lokal, lakukan pengunduhan terlebih dahulu
      logInfo('Audio cache not found. Starting download before playing...');

      // Tampilkan progress pengunduhan instan
      audioDownloadProgress[ayahNum] = 0.05; // Mulai indikator tipis
      final success = await _quranService.downloadAudio(
        surahNum,
        ayahNum,
        qariKey,
        audioUrl,
        onProgress: (progress) {
          audioDownloadProgress[ayahNum] = progress;
        },
      );

      if (success) {
        audioDownloadProgress[ayahNum] = 1.0;
        await _audioPlayer.play(DeviceFileSource(localPath));
      } else {
        audioDownloadProgress[ayahNum] = 0.0;
        currentlyPlayingAyah.value = null;
        Get.snackbar(
          'Gagal Mengunduh',
          'Pastikan perangkat Anda terhubung ke internet untuk memutar & mengunduh audio.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  /// Menghentikan pemutaran audio
  Future<void> stopAudio() async {
    await _audioPlayer.stop();
    currentlyPlayingAyah.value = null;
    isPlaying.value = false;
  }

  /// Memutar ayat selanjutnya secara otomatis (Continuous Play)
  Future<void> _playNextAyahAutomatically() async {
    final currentAyah = currentlyPlayingAyah.value;
    if (currentAyah == null) return;

    final nextIndex =
        ayahList.indexWhere((a) => a.nomorAyat == currentAyah) + 1;
    if (nextIndex < ayahList.length) {
      final nextAyah = ayahList[nextIndex];
      logInfo('Auto-playing next ayah: ${nextAyah.nomorAyat}');
      await togglePlayAyah(nextAyah);
    } else {
      logInfo('Finished surah. Stopping auto-play.');
      currentlyPlayingAyah.value = null;
      isPlaying.value = false;
    }
  }

  /// Mengunduh seluruh audio ayat dalam surat secara bersamaan (Massive Download)
  Future<void> downloadEntireSurahAudio() async {
    final surah = selectedSurah.value;
    if (surah == null || ayahList.isEmpty) return;

    if (isDownloadingMassive.value) {
      Get.snackbar(
        'Informasi',
        'Proses pengunduhan audio surat sedang berlangsung.',
      );
      return;
    }

    try {
      isDownloadingMassive(true);
      massiveDownloadProgress(0.0);
      int totalAyah = ayahList.length;
      int completedAyah = 0;
      final qariKey = selectedQari.value;

      logInfo(
        'Starting massive audio download for Surah ${surah.namaLatin} ...',
      );

      for (final ayah in ayahList) {
        final audioUrl = ayah.audio[qariKey] ?? ayah.audio['01'] ?? '';

        if (audioUrl.isNotEmpty) {
          // Lakukan pengunduhan secara linear (satu per satu agar stabil)
          final success = await _quranService.downloadAudio(
            surah.nomor,
            ayah.nomorAyat,
            qariKey,
            audioUrl,
            onProgress: (progress) {
              // Hitung progress parsial
              final partialProgress = (completedAyah + progress) / totalAyah;
              massiveDownloadProgress(partialProgress);

              // Update status progress per ayat individual
              audioDownloadProgress[ayah.nomorAyat] = progress;
            },
          );

          if (success) {
            audioDownloadProgress[ayah.nomorAyat] = 1.0;
          } else {
            audioDownloadProgress[ayah.nomorAyat] = 0.0;
          }
        }

        completedAyah++;
        massiveDownloadProgress(completedAyah / totalAyah);
      }

      Get.snackbar(
        'Sukses Mengunduh',
        'Semua audio Surat ${surah.namaLatin} untuk Qari ${_qariName(qariKey)} berhasil disimpan offline.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      logError('Error massive download: $e');
      Get.snackbar(
        'Error',
        'Terjadi kesalahan saat mengunduh audio massal: $e',
      );
    } finally {
      isDownloadingMassive(false);
      massiveDownloadProgress(0.0);
    }
  }

  String _qariName(String key) {
    return qariList[key] ?? 'Unknown Qari';
  }
}
