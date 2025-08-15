// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:sholat/app/modules/prayer_times/controllers/prayer_times_controller.dart';
import 'package:sholat/app/utils/logger.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  HomeView({super.key});

  final PrayerTimesController prayerTimesController = Get.find();

  //warna tema sesuai waktu
  Color getAuraColor(String prayerName, double opacity) {
    Color baseColor;
    switch (prayerName.toLowerCase()) {
      case 'terbit matahari':
        baseColor = const Color(0xFFFFEB3B); // contoh kuning cerah
        break;

      case 'subuh':
        baseColor = const Color(0xFF03A9F4);
        break;
      case 'dzuhur':
        baseColor = Color.lerp(
          const Color(0xFF9C27B0),
          const Color(0xFFFFC107),
          0.3,
        )!;
        break;
      case 'ashar':
        baseColor = const Color(0xFFFF9800);
        break;
      case 'maghrib':
        baseColor = Color.lerp(
          const Color(0xFFFF5722),
          const Color(0xFF673AB7),
          0.5,
        )!;
        break;
      case 'isya':
        baseColor = const Color(0xFF673AB7);
        break;
      default:
        baseColor = const Color(0xFF607D8B);
    }

    return baseColor.withAlpha((opacity * 255).round());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /* floatingActionButton: FloatingActionButton( // <== ini untuk test
        onPressed: () {
          showInstantPrayerNotification(
            "Uji Notifikasi",
            "Ini adalah notifikasi uji coba.",
          );
        },
        tooltip: 'Tes Notifikasi',
        child: Icon(Icons.notifications),
      ), */
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /* ElevatedButton(    // <==========  untuk test notifikasi (works) 
              onPressed: () {
                showNotification(
                  title: 'Tes Manual',
                  body: 'Ini notifikasi muncul!',
                );
              },
              child: Text("Tes Notifikasi"),
            ), */
            Text(
              'Waktu Sholat & Tasbih',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'By Mukki Natapradja Project',
              style: TextStyle(
                fontSize: 11,
                color: Color.fromARGB(179, 79, 79, 79),
              ),
            ),
          ],
        ),
        actions: [
          Obx(
            () => controller.selectedIndex == 0
                ? IconButton(
                    onPressed: () => prayerTimesController.loadPrayerTimes(),
                    icon: const Icon(Icons.refresh),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),

      body: Obx(() {
        final auraColor = getAuraColor(
          prayerTimesController.currentActivePrayer.value,
          0.35,
        );
        logSuccess(
          ' Prayer Name Value : ${prayerTimesController.currentActivePrayer.value}',
        );

        return AnimatedSwitcher(
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
              child: SlideTransition(position: offsetAnimation, child: child),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<int>(controller.selectedIndex),
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: MediaQuery.of(context).size.aspectRatio > 0.5
                      ? 1.5
                      : 2.0,

                  colors: [auraColor, Colors.transparent],
                ),
              ),
              child: controller.pages[controller.selectedIndex],
            ),
          ),
        );
      }),

      //Obx(() => controller.pages[controller.selectedIndex]),
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
              icon: const Icon(Icons.auto_awesome),
              title: Text('Dzikir'),
              selectedColor: Colors.orange,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.explore),
              title: Text('Qibla'),
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
  }
}
