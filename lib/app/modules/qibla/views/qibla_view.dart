import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/qibla_controller.dart';
import 'dart:math';
import 'package:flutter_svg/flutter_svg.dart';

class QiblaView extends GetView<QiblaController> {
  const QiblaView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arah Kiblat'), centerTitle: true),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    controller.errorMessage.value,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => controller.initQiblaSensor(),
                    child: Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Arah Kiblat: ${controller.qiblaDirection.value.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              'Arah Hadap Perangkat ${controller.heading.value.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    'assets/images/compas_base.png',
                    width: 300,
                    height: 300,
                  ),
                  Transform.rotate(
                    angle: (-controller.heading.value * (pi / 180)),
                    child: Image.asset(
                      'assets/images/compas_needle.png',
                      width: 250,
                      height: 250,
                    ),
                  ),
                  Transform.rotate(
                    angle: controller.qiblaRotation,
                    child: SvgPicture.asset(
                      'assets/icons/qibla_arrow.svg',
                      width: 150,
                      height: 150,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Pastikan Perangkat rata dan jauh dari interferensi magnetik',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        );
      }),
    );
  }
}
