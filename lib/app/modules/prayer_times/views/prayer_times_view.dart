//lib\app\modules\prayer_times\views\prayer_times_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../controllers/prayer_times_controller.dart';

class PrayerTimesView extends GetView<PrayerTimesController> {
  // Tambahkan properti untuk menerima warna dari HomeView
  final Color activePrayerColor;
  const PrayerTimesView({super.key, required this.activePrayerColor});

  // Menentukan animasi Lottie berdasarkan nama sholat
  String getLottieAsset(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'subuh':
        return 'assets/lottie/matahari.json';
      case 'dzuhur':
      case 'ashar':
        return 'assets/lottie/matahari.json';
      case 'maghrib':
      case 'isya':
        return 'assets/lottie/bulan.json';
      default:
        return 'assets/lottie/matahari.json';
    }
  }

  String getBackgroundLottieAsset(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'subuh':
        return 'assets/lottie/background_siang.json';
      case 'dzuhur':
      case 'ashar':
        return 'assets/lottie/background_siang.json';
      case 'maghrib':
        return 'assets/lottie/background_sore.json';
      case 'isya':
        return 'assets/lottie/background_malam.json';
      default:
        return 'assets/lottie/background_siang.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final RxBool isExpanded = true.obs;

    return Scaffold(
      backgroundColor: Colors.transparent,

      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.errorMessage.isNotEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      controller.errorMessage.value,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => controller.refreshPrayerTimes(),
                      child: const Text('Silahkan coba lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Stack(
            children: [
              // Background Lottie gabungan (latar + objek animasi)
              Obx(
                () => AnimatedOpacity(
                  duration: const Duration(milliseconds: 500),
                  opacity: isExpanded.value ? 0 : 1,
                  child: Stack(
                    children: [
                      // Background waktu
                      Lottie.asset(
                        getBackgroundLottieAsset(
                          controller.currentActivePrayer.value,
                        ),
                        fit: BoxFit.cover,
                        repeat: true,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      // Matahari / Bulan
                      // Objek utama: bulan / matahari (diangkat ke atas)
                      Positioned(
                        top: 50,
                        left: 0,
                        right: 0,
                        child: Lottie.asset(
                          getLottieAsset(controller.currentActivePrayer.value),
                          fit: BoxFit.contain,
                          repeat: true,
                          height: 300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Konten utama
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    '🕌 Jadwal Shalat Hari Ini',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lokasi: ${controller.currentAddress.value}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Tanggal: ${DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now())}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Box Sholat Berikutnya + Tombol Gulung
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.blueGrey.shade700
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? const Color(0x4D000000)
                                  : const Color(0x33000000),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sholat Berikutnya',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              controller.nextPrayerName.value,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.color,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dalam ${controller.timeToNextPrayer.value}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tombol toggle gulung
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Obx(
                          () => GestureDetector(
                            onTap: () => isExpanded.value = !isExpanded.value,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                isExpanded.value
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Jadwal Sholat: Foldable List
                  Obx(
                    () => ClipRect(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: isExpanded.value ? 500 : 0,
                        child: ListView.separated(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,

                          itemCount: controller.prayerTimes.length,
                          itemBuilder: (_, index) {
                            // Akses entri Map menggunakan index
                            final prayerEntry = controller.prayerTimes.entries
                                .elementAt(index);
                            final prayerName = prayerEntry.key;
                            final prayerTime = prayerEntry.value;

                            final isCurrent =
                                controller.currentActivePrayer.value ==
                                prayerName;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isCurrent
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.shade300,
                                  width: isCurrent ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    /* prayer.name, */
                                    // <-- Perbaikan di sini -->
                                    prayerName,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isCurrent
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer
                                          : Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  Text(
                                    // Perbaikan di sini: gunakan DateTime.parse untuk mengonversi string ke DateTime
                                    prayerTime,
                                    // end of Perbaikan
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: isCurrent
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer
                                          : Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}
