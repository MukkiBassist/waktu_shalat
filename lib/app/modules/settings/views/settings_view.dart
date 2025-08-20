import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sholat/app/utils/logger.dart';
import '../../../theme/theme_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../../services/prayer_cache_service.dart';

class SettingsView extends StatelessWidget {
  final ThemeController themeController = Get.find();
  final SettingsController controller = Get.find();
  final PrayerCacheService prayerCacheService = Get.find();

  SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Pengaturan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 30),
          Obx(
            () => SwitchListTile(
              title: const Text("Mode Gelap (Dark Mode)"),
              value: themeController.isDarkMode.value,
              onChanged: (value) => themeController.toggleTheme(),
            ),
          ),

          ListTile(
            title: const Text("Cache Hari Sholat"),
            subtitle: Obx(
              () => Text("Jumlah hari cache: ${controller.cacheDays.value}"),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Get.defaultDialog(
                  title: "Ubah Cache Hari",
                  content: TextField(
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "Masukkan jumlah hari (Maks 30)",
                    ),
                    onSubmitted: (value) async {
                      final days = int.tryParse(value);

                      if (days != null && days > 0) {
                        if (days > 30) {
                          Get.snackbar(
                            "Error",
                            "Jumlah hari tidak boleh lebih dari 30",
                          );
                          return;
                        }
                        // Update cache days in SettingsController
                        controller.updateCacheDays(days);
                        await prayerCacheService.fetchAndCachePrayerTimes();
                        logSuccess('Cache days updated to $days');
                        Get.snackbar(
                          "Berhasil",
                          "Jumlah hari cache diubah menjadi $days",
                        );
                        Get.back();
                      } else {
                        Get.snackbar("Error", "Masukkan angka yang valid");
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
