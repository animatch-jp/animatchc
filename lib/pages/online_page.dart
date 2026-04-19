import 'package:flutter/material.dart';

const _onlineUsers = [
  {'name': 'さくら', 'emoji': '🐕', 'city': '大阪', 'pet': '犬', 'online': true},
  {'name': 'ゆい', 'emoji': '🐱', 'city': '京都', 'pet': '猫', 'online': true},
  {'name': 'けんた', 'emoji': '🐶', 'city': '福岡', 'pet': '犬', 'online': false},
  {'name': 'みか', 'emoji': '🐰', 'city': '東京', 'pet': 'うさぎ', 'online': true},
  {'name': 'たろう', 'emoji': '🐹', 'city': '名古屋', 'pet': 'ハムスター', 'online': false},
  {'name': 'あい', 'emoji': '🐈', 'city': '札幌', 'pet': '猫', 'online': true},
];

class OnlinePage extends StatelessWidget {
  const OnlinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('オンライン中 🟢',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF3D2B1F)),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _onlineUsers.length,
        itemBuilder: (_, i) {
          final user = _onlineUsers[i];
          final isOnline = user['online'] as bool;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8845A).withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: Center(
                          child: Text(user['emoji'] as String,
                              style: const TextStyle(fontSize: 28))),
                    ),
                    Positioned(
                      right: 0, bottom: 0,
                      child: Container(
                        width: 14, height: 14,
                        decoration: BoxDecoration(
                            color: isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user['name'] as String,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D2B1F))),
                      Text('${user['pet']} ・ ${user['city']}',
                          style: TextStyle(fontSize: 12,
                              color: Colors.grey[600])),
                      Text(isOnline ? 'オンライン中' : '最近オンライン',
                          style: TextStyle(
                              fontSize: 11,
                              color: isOnline ? Colors.green : Colors.grey)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8845A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8)),
                  child: const Text('チャット',
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
