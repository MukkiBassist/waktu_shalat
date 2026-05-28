import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sholat/app/data/models/surah.dart';
import 'package:sholat/app/data/models/ayah.dart';
import 'package:sholat/app/utils/logger.dart';

class QuranService {
  static const String _baseUrl = 'https://equran.id/api/v2';

  /// Mengambil daftar semua surat dari API EQuran.id
  Future<List<Surah>> fetchSurahList() async {
    try {
      logLoading('Fetching surah list from equran.id...');
      final response = await http.get(Uri.parse('$_baseUrl/surat'));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['code'] == 200) {
          final List<dynamic> data = decoded['data'];
          final list = data.map((json) => Surah.fromJson(json)).toList();
          logSuccess('Successfully fetched ${list.length} surahs.');
          return list;
        }
      }
      logError('Failed to fetch surahs. Code status not 200.');
      return [];
    } catch (e) {
      logError('Error fetchSurahList: $e');
      return [];
    }
  }

  /// Mengambil detail surat beserta daftar ayat dari API EQuran.id
  Future<List<Ayah>> fetchSurahDetail(int nomor) async {
    try {
      logLoading('Fetching surah $nomor detail from equran.id...');
      final response = await http.get(Uri.parse('$_baseUrl/surat/$nomor'));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['code'] == 200) {
          final List<dynamic> data = decoded['data']['ayat'];
          final list = data.map((json) => Ayah.fromJson(json)).toList();
          logSuccess('Successfully fetched ${list.length} ayahs for surah $nomor.');
          return list;
        }
      }
      logError('Failed to fetch surah $nomor details.');
      return [];
    } catch (e) {
      logError('Error fetchSurahDetail: $e');
      return [];
    }
  }

  /// Mendapatkan path direktori lokal untuk menyimpan audio
  Future<String> _getAudioDirectoryPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final directory = Directory('${appDir.path}/audio_quran');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory.path;
  }

  /// Mendapatkan file path absolut untuk file audio lokal tertentu
  Future<String> getAudioLocalPath(int surahNomor, int nomorAyat, String qariKey) async {
    final dirPath = await _getAudioDirectoryPath();
    // Format: /audio_quran/surah_1/qari_01_ayah_1.mp3
    final surahDir = Directory('$dirPath/surah_$surahNomor');
    if (!await surahDir.exists()) {
      await surahDir.create(recursive: true);
    }
    return '${surahDir.path}/qari_${qariKey}_ayah_$nomorAyat.mp3';
  }

  /// Memeriksa apakah audio ayat tertentu sudah terunduh secara lokal
  Future<bool> isAudioDownloaded(int surahNomor, int nomorAyat, String qariKey) async {
    final filePath = await getAudioLocalPath(surahNomor, nomorAyat, qariKey);
    final file = File(filePath);
    return file.existsSync();
  }

  /// Mengunduh audio ayat secara streaming untuk memantau progress pengunduhan
  Future<bool> downloadAudio(
    int surahNomor,
    int nomorAyat,
    String qariKey,
    String audioUrl, {
    Function(double progress)? onProgress,
  }) async {
    try {
      final localPath = await getAudioLocalPath(surahNomor, nomorAyat, qariKey);
      final file = File(localPath);

      if (file.existsSync()) {
        logInfo('Audio already exists locally. Skipping download.');
        if (onProgress != null) onProgress(1.0);
        return true;
      }

      logLoading('Downloading audio: $audioUrl');
      final request = http.Request('GET', Uri.parse(audioUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        logError('Failed to download audio. HTTP Status: ${response.statusCode}');
        return false;
      }

      final contentLength = response.contentLength ?? 0;
      final fileSink = file.openWrite();

      int bytesDownloaded = 0;
      await response.stream.listen(
        (chunk) {
          fileSink.add(chunk);
          bytesDownloaded += chunk.length;
          if (contentLength > 0 && onProgress != null) {
            final progress = bytesDownloaded / contentLength;
            onProgress(progress);
          }
        },
        onError: (err) {
          logError('Error stream audio download: $err');
          fileSink.close();
          if (file.existsSync()) file.deleteSync();
        },
        cancelOnError: true,
      ).asFuture();

      await fileSink.close();
      logSuccess('Audio successfully downloaded and saved to: $localPath');
      return true;
    } catch (e) {
      logError('Error downloading audio: $e');
      return false;
    }
  }

  /// Menghapus semua cache audio Al-Quran lokal untuk menghemat memori
  Future<void> clearAudioCache() async {
    try {
      final dirPath = await _getAudioDirectoryPath();
      final directory = Directory(dirPath);
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
        logSuccess('Successfully cleared Quran audio cache.');
      }
    } catch (e) {
      logError('Failed to clear Quran audio cache: $e');
    }
  }
}
