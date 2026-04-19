import 'package:flutter/material.dart';

const _hotels = [
  {
    'name': 'アニマルホテル東京',
    'address': '東京都渋谷区',
    'phone': '03-2345-6789',
    'animals': ['犬', '猫', 'うさぎ', 'ハムスター'],
    'price': '3,000円〜/泊',
    'rating': 4.8,
    'reviewCount': 156,
    'exotic': true,
    'camera': true,
    'outdoor': true,
    'description': '24時間スタッフが常駐。カメラで様子を確認できます。',
    'badge': '人気No.1',
  },
  {
    'name': 'ペットリゾート大阪',
    'address': '大阪府大阪市',
    'phone': '06-2345-6789',
    'animals': ['犬', '猫'],
    'price': '2,500円〜/泊',
    'rating': 4.5,
    'reviewCount': 98,
    'exotic': false,
    'camera': true,
    'outdoor': false,
    'description': '広々とした個室でリラックス。散歩サービスあり。',
    'badge': '新規オープン',
  },
  {
    'name': 'エキゾチックペットホテル',
    'address': '神奈川県横浜市',
    'phone': '045-2345-6789',
    'animals': ['うさぎ', 'ハムスター', 'フェレット', 'チンチラ', '鳥'],
    'price': '2,000円〜/泊',
    'rating': 4.9,
    'reviewCount': 67,
    'exotic': true,
    'camera': false,
    'outdoor': false,
    'description': 'エキゾチックアニマル専門。経験豊富なスタッフが対応。',
    'badge': 'エキゾチック専門',
  },
  {
    'name': 'ペットホテル福岡',
    'address': '福岡県福岡市',
    'phone': '092-2345-6789',
    'animals': ['犬', '猫', 'うさぎ'],
    'price': '1,800円〜/泊',
    'rating': 4.3,
    'reviewCount': 201,
    'exotic': false,
    'camera': true,
    'outdoor': true,
    'description': '広い庭でのびのびと過ごせます。',
    'badge': '地域No.1',
  },
];

const _hotelAnimalTypes = [
  '全て', '犬', '猫', 'うさぎ', 'ハムスター',
  'フェレット', 'チンチラ', '鳥', 'その他',
];

class HotelPage extends StatefulWidget {
  const HotelPage({super.key});

  @override
  State<HotelPage> createState() => _HotelPageState();
}

class _HotelPageState extends State<HotelPage> {
  String _selectedAnimal = '全て';
  bool _exoticOnly = false;
  bool _cameraOnly = false;
  bool _outdoorOnly = false;
  final _searchCtrl = TextEditingController();

  List get _filtered => _hotels.where((h) {
    final animals = h['animals'] as List;
    final matchAnimal = _selectedAnimal == '全て' ||
        animals.contains(_selectedAnimal);
    final matchExotic = !_exoticOnly || h['exotic'] == true;
    final matchCamera = !_cameraOnly || h['camera'] == true;
    final matchOutdoor = !_outdoorOnly || h['outdoor'] == true;
    return matchAnimal && matchExotic && matchCamera && matchOutdoor;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('ペットホテル 🏨',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: Column(
          children: [
      Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'ホテル名・地域で検索',
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFFE8845A)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    ),
    SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Row(
    children: _hotelAnimalTypes.map((animal) {
    final selected = _selectedAnimal == animal;
    return GestureDetector(
    onTap: () => setState(() => _selectedAnimal = animal),
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
    child: Text(animal,
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
    SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Row(
    children: [
    _FilterChip(
    label: '🦎 エキゾチック対応',
    selected: _exoticOnly,
    onTap: () => setState(
    () => _exoticOnly = !_exoticOnly)),
    _FilterChip(
    label: '📷 カメラあり',
    selected: _cameraOnly,
    onTap: () => setState(
    () => _cameraOnly = !_cameraOnly)),
    _FilterChip(
    label: '🌳 屋外スペースあり',
    selected: _outdoorOnly,
    onTap: () => setState(
    () => _outdoorOnly = !_outdoorOnly)),
    ],
    ),
    ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final h = _filtered[i];
                  return GestureDetector(
                    onTap: () => _showDetail(context, h),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 10, offset: const Offset(0, 3))],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: const Color(0xFFE8845A).withOpacity(0.05),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20))),
                            child: Row(
                              children: [
                                Container(
                                  width: 52, height: 52,
                                  decoration: BoxDecoration(
                                      color: const Color(0xFFE8845A).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(14)),
                                  child: const Center(
                                      child: Text('🏨',
                                          style: TextStyle(fontSize: 28))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(h['name'] as String,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF3D2B1F))),
                                      const SizedBox(height: 2),
                                      Text(h['address'] as String,
                                          style: TextStyle(fontSize: 12,
                                              color: Colors.grey[600])),
                                      const SizedBox(height: 4),
                                      Text(h['price'] as String,
                                          style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFFE8845A),
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFE8845A),
                                          borderRadius: BorderRadius.circular(8)),
                                      child: Text(h['badge'] as String,
                                          style: const TextStyle(fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded,
                                            color: Colors.amber, size: 14),
                                        Text('${h['rating']}',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Text(h['description'] as String,
                                    style: TextStyle(fontSize: 12,
                                        color: Colors.grey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (h['camera'] == true)
                                      _Badge('📷 カメラあり'),
                                    if (h['camera'] == true)
                                      const SizedBox(width: 8),
                                    if (h['outdoor'] == true)
                                      _Badge('🌳 屋外あり'),
                                    if (h['exotic'] == true) ...[
                                      const SizedBox(width: 8),
                                      _Badge('🦎 エキゾ対応'),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
      ),
    );
  }
  void _showDetail(BuildContext context, Map h) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
                        const Text('🏨', style: TextStyle(fontSize: 40)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(h['name'] as String,
                                  style: const TextStyle(fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF3D2B1F))),
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFE8845A).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(h['badge'] as String,
                                    style: const TextStyle(fontSize: 12,
                                        color: Color(0xFFE8845A),
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _HotelRow(Icons.location_on_rounded,
                        h['address'] as String),
                    const SizedBox(height: 8),
                    _HotelRow(Icons.phone_rounded, h['phone'] as String),
                    const SizedBox(height: 8),
                    _HotelRow(Icons.payments_rounded, h['price'] as String),
                    const Divider(height: 32),
                    const Text('設備・サービス',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        _Badge(h['camera'] == true
                            ? '✅ カメラあり' : '❌ カメラなし'),
                        _Badge(h['outdoor'] == true
                            ? '✅ 屋外スペースあり' : '❌ 屋外なし'),
                        _Badge(h['exotic'] == true
                            ? '✅ エキゾチック対応' : '❌ エキゾチック不可'),
                      ],
                    ),
                    const Divider(height: 32),
                    const Text('対応動物',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: (h['animals'] as List).map((a) =>
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: const Color(0xFFE8845A).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(a as String,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFE8845A),
                                    fontWeight: FontWeight.bold)),
                          )).toList(),
                    ),
                    const Divider(height: 32),
                    Text(h['description'] as String,
                        style: TextStyle(fontSize: 14,
                            color: Colors.grey[600], height: 1.7)),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 20),
                        Text(' ${h['rating']}',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(' (${h['reviewCount']}件)',
                            style: TextStyle(fontSize: 12,
                                color: Colors.grey[600])),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('予約リクエストを送りました！🏨'),
                              backgroundColor: Color(0xFFE8845A),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8845A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16)),
                        child: const Text('予約する🏨',
                            style: TextStyle(fontSize: 16,
                                fontWeight: FontWeight.bold)),
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
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected,
    required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
            color: selected ? const Color(0xFFE8845A) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected
                    ? const Color(0xFFE8845A) : Colors.grey[300]!)),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white : Colors.grey[700],
                fontWeight: selected
                    ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10)),
      child: Text(text,
          style: const TextStyle(fontSize: 12)),
    );
  }
}

class _HotelRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HotelRow(this.icon, this.text);

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
