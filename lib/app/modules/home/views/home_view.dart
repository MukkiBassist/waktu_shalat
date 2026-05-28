// home_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';
import '../controllers/home_controller.dart';
import 'package:sholat/app/theme/theme_controller.dart'; // Impor ThemeController

class HomeView extends GetView<HomeController> {
  HomeView({super.key});

  final PrayerTimesController prayerTimesController = Get.find();
  final ThemeController themeController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final auraColor = prayerTimesController.auraColor.value;
      final appBarAuraColor = prayerTimesController.appBarAuraColor.value;
      final isDarkMode = themeController.isDarkMode.value;

      return Scaffold(
        backgroundColor: isDarkMode ? Colors.black : Colors.white,
        appBar: AppBar(
          backgroundColor: appBarAuraColor,
          elevation: 5,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Waktu Sholat & Tasbih',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                'By Mukki Natapradja Project',
                style: TextStyle(
                  fontSize: 11,
                  color:
                      Theme.of(context).textTheme.bodySmall?.color ??
                      Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.color, //Color.fromARGB(179, 79, 79, 79),
                ),
              ),
            ],
          ),
          actions: [
            Obx(
              () => controller.selectedIndex == 0
                  ? IconButton(
                      onPressed: () => prayerTimesController
                          .fetchAndSetPrayerTimes(forceRefresh: true),
                      icon: const Icon(Icons.refresh),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
        body: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 380),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,

                  colors: [auraColor, isDarkMode ? Colors.black : Colors.white],

                  stops: const [0.0, 1.0],
                  /* radius: MediaQuery.of(context).size.aspectRatio > 0.5
                      ? 1.5
                      : 2.0,
                  colors: [auraColor, isDarkMode ? Colors.black : Colors.white], */
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              transitionBuilder: (Widget child, Animation<double> animation) {
                final offsetAnimation =
                    Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    );
                final fadeTween = Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                );
                return FadeTransition(
                  opacity: fadeTween,
                  child: SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(controller.selectedIndex),
                child: controller.pages[controller.selectedIndex],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Obx(
          () => SalomonBottomBar(
            currentIndex: controller.selectedIndex,
            onTap: controller.onItemTapped,
            items: [
              SalomonBottomBarItem(
                icon: const Icon(Icons.access_time),
                title: const Text('Sholat'),
                selectedColor: Colors.deepPurple,
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.menu_book),
                title: const Text('Al-Quran'),
                selectedColor: Colors.green,
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.auto_awesome),
                title: const Text('Dzikir'),
                selectedColor: Colors.orange,
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.explore),
                title: const Text('Qibla'),
                selectedColor: Colors.teal,
              ),
              SalomonBottomBarItem(
                icon: const Icon(Icons.settings),
                title: const Text('Pengaturan'),
                selectedColor: Colors.blueGrey,
              ),
            ],
          ),
        ),
      );
    });
  }
}
