import 'package:flutter/material.dart';

const _lostPets = [
  {
    'name': 'ポチ',
    'type': '犬',
    'emoji': '🐕',
    'location': '東京都世田谷区',
    'date': '2026年3月28日',
    'description': '茶色の柴犬、首輪あり（赤色）。人懐こい性格です。',
    'contact': '090-1234-5678',
    'status': '迷子',
    'urgent': true,
    'reward': true,
  },
  {
    'name': 'モモ',
    'type': '猫',
    'emoji': '🐱',
    'location': '大阪府大阪市北区',
    'date': '2026年3月27日',
    'description': '白と茶色のミックス猫。首輪なし。臆病な性格です。',
    'contact': '080-1234-5678',
    'status': '迷子',
    'urgent': false,
    'reward': false,
  },
  {
    'name': 'ピーチ',
    'type': 'うさぎ',
    'emoji': '🐰',
    'location': '神奈川県横浜市',
    'date': '2026年3月26日',
    'description': '白いうさぎ、耳に黒い模様あり。おとなしい性格です。',
    'contact': '070-1234-5678',
    'status': '保護',
    'urgent': false,
    'reward': false,
  },
  {
    'name': 'レオ',
    'type': '犬',
    'emoji': '🦮',
    'location': '福岡県福岡市',
    'date': '2026年3月25日',
    'description': '大型犬（ゴールデンレトリバー）。首輪あり（青色）。',
    'contact': '090-9876-5432',
    'status': '迷子',
    'urgent': true,
    'reward': true,
  },
];

class LostPetPage extends StatefulWidget {
  const LostPetPage({super.key});

  @override
  State<LostPetPage> createState() => _LostPetPageState();
}

class _LostPetPageState extends State<LostPetPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _selectedType = '全て';
  final _types = ['全て', '犬', '猫', 'うさぎ', '鳥', 'その他'];

  List get _filtered => _lostPets.where((p) =>
  _selectedType == '全て' || p['type'] == _selectedType).toList();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('迷子・保護情報 🔍',
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
            Tab(text: '迷子・保護情報'),
            Tab(text: '情報を投稿'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildList(),
          _buildPost(),
        ],
      ),
    );
  }
  Widget _buildList() {
    return Column(
      children: [
        // 緊急バナー
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red[200]!)),
          child: const Row(
            children: [
              Text('🆘', style: TextStyle(fontSize: 24)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('迷子の情報を見かけたら',
                        style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.bold, color: Colors.red)),
                    Text('すぐに投稿・連絡してください！\n一刻も早い発見が命を救います',
                        style: TextStyle(fontSize: 12,
                            color: Colors.red, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
        // フィルター
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: _types.map((type) {
              final selected = _selectedType == type;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFFE8845A) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: selected
                              ? const Color(0xFFE8845A) : Colors.grey[300]!)),
                  child: Text(type,
                      style: TextStyle(
                          fontSize: 13,
                          color: selected ? Colors.white : Colors.grey[700],
                          fontWeight: selected
                              ? FontWeight.bold : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
        ),
        // リスト
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _filtered.length,
            itemBuilder: (_, i) {
              final pet = _filtered[i];
              final isLost = pet['status'] == '迷子';
              final isUrgent = pet['urgent'] == true;
              final color = isLost ? Colors.red : const Color(0xFF2D6A4F);

              return GestureDetector(
                onTap: () => _showDetail(context, pet),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: isUrgent
                        ? Border.all(color: Colors.red, width: 2) : null,
                    boxShadow: [BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10, offset: const Offset(0, 3))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16)),
                          child: Center(
                              child: Text(pet['emoji'] as String,
                                  style: const TextStyle(fontSize: 32))),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                        color: color,
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text(pet['status'] as String,
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(pet['name'] as String,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF3D2B1F))),
                                  if (pet['reward'] == true) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: Colors.amber,
                                          borderRadius: BorderRadius.circular(6)),
                                      child: const Text('謝礼あり',
                                          style: TextStyle(fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('${pet['type']} ・ ${pet['location']}',
                                  style: TextStyle(fontSize: 12,
                                      color: Colors.grey[600])),
                              Text(pet['date'] as String,
                                  style: TextStyle(fontSize: 11,
                                      color: Colors.grey[400])),
                              const SizedBox(height: 4),
                              Text(pet['description'] as String,
                                  style: TextStyle(fontSize: 12,
                                      color: Colors.grey[600]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  void _showDetail(BuildContext context, Map pet) {
    final isLost = pet['status'] == '迷子';
    final color = isLost ? Colors.red : const Color(0xFF2D6A4F);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(pet['emoji'] as String,
                            style: const TextStyle(fontSize: 48)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text(pet['status'] as String,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(height: 6),
                            Text(pet['name'] as String,
                                style: const TextStyle(fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF3D2B1F))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _LostDetailRow(Icons.pets_rounded, pet['type'] as String),
                    const SizedBox(height: 8),
                    _LostDetailRow(Icons.location_on_rounded,
                        pet['location'] as String),
                    const SizedBox(height: 8),
                    _LostDetailRow(Icons.calendar_today_rounded,
                        pet['date'] as String),
                    const Divider(height: 32),
                    const Text('詳細情報',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(height: 8),
                    Text(pet['description'] as String,
                        style: TextStyle(fontSize: 14,
                            color: Colors.grey[600], height: 1.7)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  isLost
                                      ? '飼い主に連絡しました！🙏'
                                      : '保護者に連絡しました！🙏'),
                              backgroundColor: color,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        icon: const Icon(Icons.phone_rounded),
                        label: Text(isLost ? '飼い主に連絡する' : '保護者に連絡する'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16)),
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

  Widget _buildPost() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFE8845A), Color(0xFFF4A261)]),
                borderRadius: BorderRadius.circular(20)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('迷子・保護情報を投稿🔍',
                    style: TextStyle(fontSize: 20,
                        fontWeight: FontWeight.w900, color: Colors.white)),
                SizedBox(height: 6),
                Text('迷子の情報や保護した動物の\n情報を投稿できます',
                    style: TextStyle(fontSize: 13,
                        color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('この機能はリリース後に使えます！\n迷子情報をみんなで共有できるようになります🐾',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.6)),
        ],
      ),
    );
  }
}

class _LostDetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _LostDetailRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFE8845A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ),
      ],
    );
  }
}
