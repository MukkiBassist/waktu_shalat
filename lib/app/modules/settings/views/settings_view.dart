import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../theme/theme_controller.dart'; // pastikan file ini ada

class SettingsView extends StatelessWidget {
  final ThemeController themeController = Get.find();

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
        ],
      ),
    );
  }
}
