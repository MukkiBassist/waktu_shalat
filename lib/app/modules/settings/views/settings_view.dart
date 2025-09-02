// lib/app/modules/settings/views/settings_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/theme_controller.dart';
import '../../prayer_times/controllers/prayer_times_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import '../../../services/prayer_cache_service.dart';

class SettingsView extends StatelessWidget {
  // Use Get.find() consistently for all dependencies
  final ThemeController themeController = Get.find();
  final SettingsController controller = Get.find();
  final PrayerCacheService prayerCacheService = Get.find();
  final PrayerTimesController prayerTimesController =
      Get.find<PrayerTimesController>();

  SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                final textController = TextEditingController(
                  text: controller.cacheDays.value.toString(),
                );
                Get.defaultDialog(
                  title: "Ubah Cache Hari",

                  content: TextField(
                    controller: textController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "Masukkan jumlah hari (Maks 30)",
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () async {
                        final days = int.tryParse(textController.text);
                        if (days != null && days > 0 && days <= 30) {
                          // Tutup dialog setelah berhasil
                          controller.setCacheDays(days.toInt());
                          Get.back();
                        } else {
                          Get.snackbar(
                            "Error",
                            "Masukkan angka yang valid (1-30)",
                          );
                        }
                      },
                      child: const Text('Simpan'),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
