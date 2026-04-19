import 'package:flutter/material.dart';
import 'premium_page.dart';

class FootprintPage extends StatefulWidget {
  const FootprintPage({super.key});

  @override
  State<FootprintPage> createState() => _FootprintPageState();
}

class _FootprintPageState extends State<FootprintPage> {
  bool _isPremium = false;

  final _footprints = [
    {'name': 'さくら', 'emoji': '🐕', 'city': '大阪', 'time': '5分前', 'pet': '犬'},
    {'name': '???', 'emoji': '🐱', 'city': '???', 'time': '12分前', 'pet': '???'},
    {'name': '???', 'emoji': '🐰', 'city': '???', 'time': '30分前', 'pet': '???'},
    {'name': 'けんた', 'emoji': '🐶', 'city': '福岡', 'time': '1時間前', 'pet': '犬'},
    {'name': '???', 'emoji': '🐹', 'city': '???', 'time': '2時間前', 'pet': '???'},
    {'name': '???', 'emoji': '🐈', 'city': '???', 'time': '3時間前', 'pet': '???'},
    {'name': 'みか', 'emoji': '🐰', 'city': '東京', 'time': '5時間前', 'pet': 'うさぎ'},
    {'name': '???', 'emoji': '🐦', 'city': '???', 'time': '昨日', 'pet': '???'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('足あと 👣',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: Column(
        children: [
          if (!_isPremium)
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const PremiumPage())),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFE8845A), Color(0xFFFFCC80)]),
                    borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Text('👑', style: TextStyle(fontSize: 28)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('誰が見たかわかる！',
                              style: TextStyle(fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text('プレミアムにアップグレードする',
                              style: TextStyle(fontSize: 12,
                                  color: Colors.white70)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.white),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${_footprints.length}人が見ました',
                    style: const TextStyle(fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D2B1F))),
                const Spacer(),
                if (!_isPremium)
                  GestureDetector(
                    onTap: () => setState(() => _isPremium = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8845A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: const Text('プレミアムで全員見る👑',
                          style: TextStyle(fontSize: 11,
                              color: Color(0xFFE8845A),
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _footprints.length,
              itemBuilder: (_, i) {
                final fp = _footprints[i];
                final isHidden = fp['name'] == '???' && !_isPremium;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                            color: isHidden
                                ? Colors.grey[200]
                                : const Color(0xFFE8845A).withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: Center(
                            child: Text(
                                isHidden ? '👣' : fp['emoji'] as String,
                                style: const TextStyle(fontSize: 24))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                isHidden ? 'プレミアムで見る👑' : fp['name'] as String,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isHidden
                                        ? Colors.grey : const Color(0xFF3D2B1F))),
                            Text(
                                isHidden ? '???' : '${fp['pet']} ・ ${fp['city']}',
                                style: TextStyle(fontSize: 12,
                                    color: Colors.grey[500])),
                          ],
                        ),
                      ),
                      Text(fp['time'] as String,
                          style: TextStyle(fontSize: 11,
                              color: Colors.grey[400])),
                    ],
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
