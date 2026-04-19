import 'package:flutter/material.dart';

const _rankings = [
  {
    'rank': 1,
    'name': 'マイク',
    'type': '犬',
    'emoji': '🐕',
    'owner': 'さくら',
    'city': '大阪',
    'likes': 342,
    'badge': '👑 今週の1位',
  },
  {
    'rank': 2,
    'name': 'モナ',
    'type': '猫',
    'emoji': '🐱',
    'owner': 'ゆい',
    'city': '京都',
    'likes': 287,
    'badge': '🥈 2位',
  },
  {
    'rank': 3,
    'name': 'チョコ',
    'type': '犬',
    'emoji': '🐶',
    'owner': 'けんた',
    'city': '福岡',
    'likes': 251,
    'badge': '🥉 3位',
  },
  {
    'rank': 4,
    'name': 'ピーチ',
    'type': 'うさぎ',
    'emoji': '🐰',
    'owner': 'みか',
    'city': '東京',
    'likes': 198,
    'badge': '4位',
  },
  {
    'rank': 5,
    'name': 'レオ',
    'type': '犬',
    'emoji': '🦮',
    'owner': 'たろう',
    'city': '名古屋',
    'likes': 176,
    'badge': '5位',
  },
  {
    'rank': 6,
    'name': 'ユキ',
    'type': '猫',
    'emoji': '🐈',
    'owner': 'あい',
    'city': '札幌',
    'likes': 154,
    'badge': '6位',
  },
  {
    'rank': 7,
    'name': 'ハナ',
    'type': 'ハムスター',
    'emoji': '🐹',
    'owner': 'りか',
    'city': '横浜',
    'likes': 132,
    'badge': '7位',
  },
  {
    'rank': 8,
    'name': 'ソラ',
    'type': '犬',
    'emoji': '🐕‍🦺',
    'owner': 'ひろ',
    'city': '仙台',
    'likes': 121,
    'badge': '8位',
  },
  {
    'rank': 9,
    'name': 'ポポ',
    'type': '鳥',
    'emoji': '🐦',
    'owner': 'なな',
    'city': '広島',
    'likes': 98,
    'badge': '9位',
  },
  {
    'rank': 10,
    'name': 'クロ',
    'type': '猫',
    'emoji': '🐈‍⬛',
    'owner': 'けい',
    'city': '福岡',
    'likes': 87,
    'badge': '10位',
  },
];

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('ランキング 🏆',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xFFE8845A),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE8845A),
          tabs: const [
            Tab(text: '今週'),
            Tab(text: '今月'),
            Tab(text: '全期間'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildRanking(),
          _buildRanking(),
          _buildRanking(),
        ],
      ),
    );
  }
  Widget _buildRanking() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // トップ3
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFE8845A), Color(0xFFFFCC80)]),
                borderRadius: BorderRadius.circular(24)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 2位
                _TopCard(_rankings[1], height: 100),
                // 1位
                _TopCard(_rankings[0], height: 130),
                // 3位
                _TopCard(_rankings[2], height: 80),
              ],
            ),
          ),
          // 4位以降
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _rankings.length - 3,
            itemBuilder: (_, i) {
              final pet = _rankings[i + 3];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8845A).withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: Center(
                          child: Text('${pet['rank']}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE8845A)))),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8845A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Center(
                          child: Text(pet['emoji'] as String,
                              style: const TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pet['name'] as String,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3D2B1F))),
                          Text('${pet['type']} ・ ${pet['owner']}さん ・ ${pet['city']}',
                              style: TextStyle(fontSize: 12,
                                  color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.favorite_rounded,
                            color: Color(0xFFE8845A), size: 16),
                        const SizedBox(width: 4),
                        Text('${pet['likes']}',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE8845A))),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TopCard extends StatelessWidget {
  final Map pet;
  final double height;
  const _TopCard(this.pet, {required this.height});

  @override
  Widget build(BuildContext context) {
    final isFirst = pet['rank'] == 1;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (isFirst)
          const Text('👑', style: TextStyle(fontSize: 28)),
        Container(
          width: isFirst ? 80 : 64,
          height: isFirst ? 80 : 64,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle),
          child: Center(
              child: Text(pet['emoji'] as String,
                  style: TextStyle(fontSize: isFirst ? 40 : 32))),
        ),
        const SizedBox(height: 8),
        Text(pet['name'] as String,
            style: TextStyle(
                fontSize: isFirst ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text(pet['owner'] as String,
            style: const TextStyle(fontSize: 11,
                color: Colors.white70)),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text('${pet['likes']}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: height,
          width: isFirst ? 80 : 64,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12))),
          child: Center(
              child: Text(pet['badge'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold))),
        ),
      ],
    );
  }
}
