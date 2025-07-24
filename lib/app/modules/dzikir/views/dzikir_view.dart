import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dzikir_controller.dart';

class DzikirView extends GetView<DzikirController> {
  DzikirView({super.key});
  final DzikirController dzikirController = Get.find();

  // 🔽 Daftar dzikir yang bisa dipilih
  final List<String> dzikirList = [
    "Al Fatihah",
    "Al Ikhlas",
    "Ya Latif",
    "Sholallahu ala Muhammad",
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 🔺 Judul
            const Text(
              "Dzikir Harian",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // 🔄 Dropdown Pemilihan Dzikir
            Obx(
              () => DropdownButtonFormField<String>(
                value: dzikirController.selectedDzikir.value,
                decoration: const InputDecoration(
                  labelText: "Pilih Dzikir Utama",
                  border: OutlineInputBorder(),
                ),
                items: dzikirList.map((dzikir) {
                  return DropdownMenuItem(value: dzikir, child: Text(dzikir));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    dzikirController.setDzikir(value);
                  }
                },
              ),
            ),
            const SizedBox(height: 20),

            // 🔘 Counter Card
            Card(
              elevation: 5,
              color: isDark ? Colors.grey[900] : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // 📝 Nama Dzikir Terpilih
                    Obx(
                      () => Text(
                        dzikirController.selectedDzikir.value,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // 🔢 Counter
                    Obx(
                      () => AnimatedScale(
                        scale: dzikirController.scale.value,
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeInOut,
                        child: Text(
                          '${dzikirController.count.value}',
                          style: TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 🔘 Tombol Tambah dan Reset
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: dzikirController.increment,
                            icon: const Icon(Icons.add_circle),
                            label: const Text("Tambah"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: dzikirController.reset,
                            icon: const Icon(Icons.refresh),
                            label: const Text("Reset"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 📋 List Dzikir Lain (Optional)
            const Text(
              "Dzikir Lainnya:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ...dzikirList.map(
              (dzikir) => ListTile(
                title: Text(dzikir),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => dzikirController.setDzikir(dzikir),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
