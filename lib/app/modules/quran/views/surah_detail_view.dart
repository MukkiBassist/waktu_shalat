import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quran_controller.dart';

class SurahDetailView extends StatelessWidget {
  SurahDetailView({super.key});

  final QuranController controller = Get.find<QuranController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final surah = controller.selectedSurah.value;
      if (surah == null) {
        return const Scaffold(
          body: Center(child: Text("Tidak ada surat terpilih.")),
        );
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(
            surah.namaLatin,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: isDark ? Colors.grey[950] : Colors.green[700],
          elevation: 4,
          actions: [
            // ℹ️ Tombol Deskripsi Surat
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                _showSurahInfoDialog(context, surah.namaLatin, surah.deskripsi);
              },
            ),
            // ⏹️ Tombol Stop Audio Global
            Obx(() => controller.currentlyPlayingAyah.value != null
                ? IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: controller.stopAudio,
                    tooltip: 'Hentikan Audio',
                  )
                : const SizedBox.shrink()),
          ],
        ),
        body: Obx(() {
          if (controller.isLoadingDetail.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.ayahList.isEmpty) {
            return const Center(child: Text("Gagal memuat ayat."));
          }

          return Column(
            children: [
              // 🎛️ Panel Kontrol (Qari, Kecepatan, Unduh Masal)
              _buildControlPanel(context, isDark),

              // 📜 List Ayat
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: controller.ayahList.length + 1, // +1 untuk header Bismillah
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // Tampilkan Bismillah di awal surat (kecuali At-Tawbah nomor 9 & Al-Fatihah nomor 1)
                      if (surah.nomor != 1 && surah.nomor != 9) {
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              "بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ",
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.green[300] : Colors.green[800],
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }

                    final ayah = controller.ayahList[index - 1];
                    return _buildAyahCard(context, ayah, isDark);
                  },
                ),
              ),
            ],
          );
        }),
      );
    });
  }

  /// Membangun kontrol panel atas untuk Qari, Kecepatan, & Download Massal
  Widget _buildControlPanel(BuildContext context, bool isDark) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 3,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      color: isDark ? Colors.grey[900] : Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            Row(
              children: [
                // 🗣️ Dropdown Pilihan Qari
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pilih Suara Qari",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[400] : Colors.green[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.grey[700]! : Colors.green[200]!,
                              ),
                              color: isDark ? Colors.black38 : Colors.white,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: controller.selectedQari.value,
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down, color: Colors.green[700]),
                                items: controller.qariList.entries.map((entry) {
                                  return DropdownMenuItem<String>(
                                    value: entry.key,
                                    child: Text(
                                      entry.value,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    controller.setQari(val);
                                  }
                                },
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // ⚡ Kecepatan Suara
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Kecepatan Pemutaran",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[400] : Colors.green[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark ? Colors.grey[700]! : Colors.green[200]!,
                              ),
                              color: isDark ? Colors.black38 : Colors.white,
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<double>(
                                value: controller.playbackSpeed.value,
                                isExpanded: true,
                                icon: Icon(Icons.speed, color: Colors.green[700]),
                                items: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                                  return DropdownMenuItem<double>(
                                    value: speed,
                                    child: Text(
                                      speed == 1.0 ? 'Normal (1.0x)' : '${speed}x',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    controller.setPlaybackSpeed(val);
                                  }
                                },
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 📥 Tombol Download Satu Surat Offline
            Obx(() {
              if (controller.isDownloadingMassive.value) {
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Mengunduh surat ke memori offline...",
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.green[300] : Colors.green[800],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "${(controller.massiveDownloadProgress.value * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.green[300] : Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: controller.massiveDownloadProgress.value,
                        backgroundColor: isDark ? Colors.grey[800] : Colors.green[100],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                        minHeight: 8,
                      ),
                    ),
                  ],
                );
              }

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.downloadEntireSurahAudio,
                  icon: const Icon(Icons.download_for_offline_outlined, size: 18),
                  label: const Text(
                    "Unduh Audio Satu Surat Offline",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Membangun kartu individual untuk masing-masing Ayat Al-Quran
  Widget _buildAyahCard(BuildContext context, dynamic ayah, bool isDark) {
    return Obx(() {
      final isCurrentlyPlaying = (controller.currentlyPlayingAyah.value == ayah.nomorAyat);
      final isAudioActive = isCurrentlyPlaying && controller.isPlaying.value;

      final downloadProgress = controller.audioDownloadProgress[ayah.nomorAyat] ?? 0.0;
      final isDownloaded = (downloadProgress == 1.0);
      final isDownloading = (downloadProgress > 0.0 && downloadProgress < 1.0);

      return Card(
        margin: const EdgeInsets.only(bottom: 16.0),
        elevation: isCurrentlyPlaying ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: isCurrentlyPlaying
                ? (isDark ? Colors.green[400]! : Colors.green[700]!)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        color: isCurrentlyPlaying
            ? (isDark ? Colors.green[950]?.withOpacity(0.4) : Colors.green[50])
            : (isDark ? Colors.grey[900]?.withOpacity(0.9) : Colors.white),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🏷️ Baris Atas: Nomor Ayat & Kontrol Audio
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nomor Ayat Circular Badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrentlyPlaying
                          ? Colors.green[700]
                          : (isDark ? Colors.grey[800] : Colors.grey[200]),
                    ),
                    child: Center(
                      child: Text(
                        '${ayah.nomorAyat}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isCurrentlyPlaying
                              ? Colors.white
                              : (isDark ? Colors.grey[300] : Colors.grey[800]),
                        ),
                      ),
                    ),
                  ),

                  // Kontrol Audio Ayat (Play/Pause/Offline status)
                  Row(
                    children: [
                      // Offline Cache Status Icon
                      if (isDownloaded)
                        Icon(
                          Icons.offline_pin,
                          color: isDark ? Colors.green[300] : Colors.green[700],
                          size: 18,
                        ),
                      const SizedBox(width: 8),

                      // Tombol Play / Pause Ayat
                      GestureDetector(
                        onTap: () => controller.togglePlayAyah(ayah),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isAudioActive
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green[700]?.withOpacity(0.1),
                          ),
                          child: Icon(
                            isAudioActive
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            color: isAudioActive ? Colors.red : Colors.green[700],
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Indikator Progress Unduhan jika sedang mengunduh
              if (isDownloading) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: downloadProgress,
                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${(downloadProgress * 100).toStringAsFixed(0)}%",
                      style: TextStyle(fontSize: 10, color: Colors.green[700], fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // 🕌 Arab Text (Besar, Tebal, Rapat Kanan)
              Text(
                ayah.teksArab,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  height: 1.8,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 14),

              // 📝 Latin Transliteration (Italicized, Pastel color)
              Text(
                ayah.teksLatin,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.amber[100] : Colors.brown[700],
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),

              // 🇮🇩 Indonesian Translation
              Text(
                ayah.teksIndonesia,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  /// Menampilkan dialog popup deskripsi/sejarah surat
  void _showSurahInfoDialog(BuildContext context, String title, String content) {
    // Menghapus tag HTML jika ada pada deskripsi API
    final cleanContent = content.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');

    Get.defaultDialog(
      title: "Tentang Surat $title",
      titleStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      content: Expanded(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              cleanContent,
              textAlign: TextAlign.justify,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ),
      ),
      textConfirm: "Tutup",
      confirmTextColor: Colors.white,
      buttonColor: Colors.green[700],
      onConfirm: () => Get.back(),
    );
  }
}
