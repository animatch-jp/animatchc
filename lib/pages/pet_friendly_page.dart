import 'package:flutter/material.dart';

class PetFriendlyPage extends StatefulWidget {
  const PetFriendlyPage({super.key});

  @override
  State<PetFriendlyPage> createState() => _PetFriendlyPageState();
}

class _PetFriendlyPageState extends State<PetFriendlyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedPref = '全国';

  final _prefs = ['全国', '東京', '大阪', '京都', '福岡', '神奈川', '愛知'];

  final _cafes = [
    {
      'name': 'ドッグカフェ ポチの家',
      'type': '☕ カフェ',
      'pets': '🐕 犬OK',
      'address': '東京都渋谷区',
      'hours': '10:00〜20:00',
      'price': '入店料500円',
      'features': ['🐕 犬同伴OK', '🪑 テラス席あり', '🍰 ペットメニューあり'],
      'rating': 4.5,
      'reviews': 128,
    },
    {
      'name': 'ネコと珈琲 みゃあ',
      'type': '☕ カフェ',
      'pets': '🐱 猫OK',
      'address': '大阪府大阪市',
      'hours': '11:00〜21:00',
      'price': '入店料600円',
      'features': ['🐱 猫同伴OK', '🛋️ ソファ席あり', '🍵 猫用おやつあり'],
      'rating': 4.3,
      'reviews': 95,
    },
    {
      'name': 'アニマルカフェ ぽかぽか',
      'type': '☕ カフェ',
      'pets': '🐾 全動物OK',
      'address': '東京都新宿区',
      'hours': '10:00〜19:00',
      'price': '入店料800円',
      'features': ['🐾 全動物OK', '🌿 広いスペース', '📸 撮影スポットあり'],
      'rating': 4.7,
      'reviews': 210,
    },
    {
      'name': 'うさぎカフェ もふもふ',
      'type': '☕ カフェ',
      'pets': '🐰 うさぎOK',
      'address': '京都府京都市',
      'hours': '11:00〜18:00',
      'price': '入店料700円',
      'features': ['🐰 うさぎ同伴OK', '🌸 和風インテリア', '🥕 うさぎメニューあり'],
      'rating': 4.4,
      'reviews': 76,
    },
  ];

  final _parks = [
    {
      'name': '代々木公園',
      'type': '🌳 公園',
      'pets': '🐕 犬OK',
      'address': '東京都渋谷区',
      'hours': '24時間',
      'price': '無料',
      'features': ['🐕 ドッグラン', '🚿 水飲み場あり', '🅿️ 駐車場あり'],
      'rating': 4.6,
      'reviews': 520,
    },
    {
      'name': '万博記念公園',
      'type': '🌳 公園',
      'pets': '🐾 全動物OK',
      'address': '大阪府吹田市',
      'hours': '9:30〜17:00',
      'price': '入園料260円',
      'features': ['🐾 ペット同伴OK', '🌿 広大な芝生', '🏃 散歩コースあり'],
      'rating': 4.4,
      'reviews': 380,
    },
    {
      'name': '舎人公園',
      'type': '🌳 公園',
      'pets': '🐕 犬OK',
      'address': '東京都足立区',
      'hours': '24時間',
      'price': '無料',
      'features': ['🐕 ドッグラン', '🏞️ 池あり', '🚴 サイクリングコース'],
      'rating': 4.2,
      'reviews': 245,
    },
    {
      'name': '鶴舞公園',
      'type': '🌳 公園',
      'pets': '🐾 全動物OK',
      'address': '愛知県名古屋市',
      'hours': '24時間',
      'price': '無料',
      'features': ['🌸 桜の名所', '🐾 ペット同伴OK', '🛶 ボート池あり'],
      'rating': 4.3,
      'reviews': 189,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('ペット同伴スポット🐾',
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
            Tab(text: '☕ カフェ'),
            Tab(text: '🌳 公園'),
          ],
        ),
      ),
      body: Column(
        children: [
          // 都道府県フィルター
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _prefs.length,
              itemBuilder: (_, i) {
                final pref = _prefs[i];
                final selected = _selectedPref == pref;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPref = pref),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFE8845A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected
                                ? const Color(0xFFE8845A)
                                : Colors.grey[300]!)),
                    child: Text(pref,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: selected ? Colors.white : Colors.grey[600])),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(_cafes),
                _buildList(_parks),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Map> items) {
    final filtered = _selectedPref == '全国'
        ? items
        : items.where((item) =>
        (item['address'] as String).contains(_selectedPref)).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🐾', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('$_selectedPrefの情報は\nまだ登録されていません',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final item = filtered[i];
        return GestureDetector(
          onTap: () => _showDetail(context, item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8, offset: const Offset(0, 2))]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(item['name'] as String,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3D2B1F)))),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFF2D6A4F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(item['pets'] as String,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF2D6A4F),
                                fontWeight: FontWeight.bold))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        color: Color(0xFFE8845A), size: 14),
                    const SizedBox(width: 4),
                    Text(item['address'] as String,
                        style: TextStyle(fontSize: 12,
                            color: Colors.grey[600])),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time_rounded,
                        color: Color(0xFFE8845A), size: 14),
                    const SizedBox(width: 4),
                    Text(item['hours'] as String,
                        style: TextStyle(fontSize: 12,
                            color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text('${item['rating']}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(width: 4),
                    Text('(${item['reviews']}件)',
                        style: TextStyle(fontSize: 12,
                            color: Colors.grey[500])),
                    const Spacer(),
                    Text(item['price'] as String,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE8845A),
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  void _showDetail(BuildContext context, Map item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
            color: Color(0xFFFFF8F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(item['name'] as String,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF3D2B1F)))),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFF2D6A4F).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(item['pets'] as String,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF2D6A4F),
                                    fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _detailRow(Icons.location_on_rounded,
                        item['address'] as String),
                    const SizedBox(height: 8),
                    _detailRow(Icons.access_time_rounded,
                        item['hours'] as String),
                    const SizedBox(height: 8),
                    _detailRow(Icons.payments_rounded,
                        item['price'] as String),
                    const SizedBox(height: 16),
                    const Text('特徴',
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: (item['features'] as List).map((f) =>
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: const Color(0xFFE8845A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(f as String,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFE8845A))),
                          )).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text('${item['rating']}',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3D2B1F))),
                        const SizedBox(width: 8),
                        Text('${item['reviews']}件のレビュー',
                            style: TextStyle(fontSize: 13,
                                color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('マップ機能はリリース後に使えます🗺️'),
                              backgroundColor: Color(0xFFE8845A),
                            ),
                          );
                        },
                        icon: const Icon(Icons.map_rounded),
                        label: const Text('マップで見る'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8845A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE8845A), size: 16),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      ],
    );
  }
}
