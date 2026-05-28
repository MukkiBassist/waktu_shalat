import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quran_controller.dart';
import 'surah_detail_view.dart';

class QuranView extends StatelessWidget {
  QuranView({super.key});

  final QuranController controller = Get.put(QuranController());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔍 Bilah Pencarian
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                color: isDark ? Colors.grey[900] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: TextField(
                    onChanged: controller.filterSurah,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: "Cari Surat (contoh: Yasin, Al-Kahfi)...",
                      hintStyle: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: isDark ? Colors.green[400] : Colors.green[700],
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 📜 Daftar Surat
              Expanded(
                child: Obx(() {
                  if (controller.isLoadingSurahs.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.filteredSurahList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 60,
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Surat tidak ditemukan.",
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.fetchSurahs,
                    color: Colors.green[700],
                    child: ListView.separated(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: controller.filteredSurahList.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final surah = controller.filteredSurahList[index];
                        return Card(
                          elevation: 1.5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          color: isDark ? Colors.grey[900]?.withOpacity(0.85) : Colors.white.withOpacity(0.9),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              controller.loadSurahDetail(surah);
                              Get.to(() => SurahDetailView());
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                              child: Row(
                                children: [
                                  // 🔢 Badge Nomor Surat
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.green[700]?.withOpacity(0.1),
                                      border: Border.all(
                                        color: Colors.green[700]!,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${surah.nomor}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isDark ? Colors.green[300] : Colors.green[800],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // 📝 Info Surat
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          surah.namaLatin,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Text(
                                              surah.arti,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "•",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "${surah.jumlahAyat} Ayat",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "•",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              surah.tempatTurun.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 🕌 Teks Arab Surat
                                  Text(
                                    surah.nama,
                                    style: const TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
