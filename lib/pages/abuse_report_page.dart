import 'package:flutter/material.dart';

class AbuseReportPage extends StatelessWidget {
  const AbuseReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = [
      {
        'name': '動物愛護センター（東京）',
        'phone': '03-3302-3507',
        'desc': '虐待通報の専門窓口',
        'emoji': '🐾',
      },
      {
        'name': '警察',
        'phone': '110',
        'desc': '緊急の場合',
        'emoji': '🚔',
      },
      {
        'name': '動物愛護管理相談センター',
        'phone': '0570-078-999',
        'desc': '全国共通相談窓口',
        'emoji': '📞',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('虐待通報 🆘',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red[300]!)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🆘 動物の虐待を見かけたら',
                      style: TextStyle(fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.red)),
                  const SizedBox(height: 8),
                  Text('AniMatch内では調査・対応ができないため、下記の専門機関に直接ご連絡ください。緊急の場合はすぐに110番へ。',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.6)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ...contacts.map((c) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
              child: Row(
                children: [
                  Text(c['emoji'] as String, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['name'] as String,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3D2B1F))),
                        Text(c['desc'] as String,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text(c['phone'] as String,
                            style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFFE8845A),
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
