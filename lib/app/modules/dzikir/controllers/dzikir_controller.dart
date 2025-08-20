// ignore_for_file: avoid_print

import 'package:audioplayers/audioplayers.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sholat/app/utils/logger.dart';

class DzikirController extends GetxController {
  var selectedDzikir = 'Sholallahu ala Muhammad'.obs;
  var count = 0.obs;
  final AudioPlayer _player = AudioPlayer();

  @override
  void onInit() {
    super.onInit();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _player.setSource(AssetSource('sounds/click.wav'));
    await _player.setReleaseMode(ReleaseMode.stop); // agar tidak auto ulang
  }

  var scale = 1.0.obs;

  void playClickAnimation() {
    scale.value = 1.2; // scale up
    Future.delayed(const Duration(milliseconds: 50), () {
      scale.value = 1.0; // back to normal
    });
  }

  void playClickSound() async {
    try {
      await _player.stop();
      await _player.seek(Duration.zero);
      await _player.resume();
      //await cache.load('click.wav'); // ini otomatis cache dan main cepat
      logSuccess("Berhasil play suara");
    } catch (e) {
      logError("Gagal play suara: $e");
    }
  }

  void increment() {
    count.value++;
    saveCounter();
    playClickSound();
    playClickAnimation();
  }

  void reset() {
    count.value = 0;
    saveCounter();
  }

  void setDzikir(String newDzikir) async {
    await saveCounter();
    selectedDzikir.value = newDzikir;
    await loadCounter(); // Reset hitungan setiap ganti dzikir
  }

  Future<void> saveCounter() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt(selectedDzikir.value, count.value);
  }

  Future<void> loadCounter() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(selectedDzikir.value) ?? 0;
    count.value = saved;
  }

  // ignore: unused_element
  String _getStorageKey() {
    return 'count_${selectedDzikir.value}';
  }
}
