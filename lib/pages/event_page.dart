import 'package:flutter/material.dart';

const _events = [
  {
    'title': '保護犬譲渡会@代々木公園',
    'category': '保護活動',
    'date': '4月10日 10:00〜16:00',
    'location': '東京都渋谷区',
    'participants': 24,
    'emoji': '🐕',
    'description': '保護犬たちの里親を募集しています。気軽に来てください！',
    'organizer': '東京保護犬の会',
    'isOfficial': true,
  },
  {
    'title': '猫カフェボランティア募集',
    'category': 'ボランティア',
    'date': '4月15日 13:00〜17:00',
    'location': '大阪府大阪市',
    'participants': 8,
    'emoji': '🐱',
    'description': '猫のお世話を手伝ってくれるボランティアを募集しています。',
    'organizer': '大阪猫の会',
    'isOfficial': true,
  },
  {
    'title': 'ペットフード寄付キャンペーン',
    'category': 'フード支援',
    'date': '4月20日〜30日',
    'location': '全国',
    'participants': 156,
    'emoji': '🍖',
    'description': '保護施設へのペットフード寄付を募集しています。',
    'organizer': 'AniMatch運営',
    'isOfficial': true,
  },
  {
    'title': '多摩川沿い朝の散歩仲間募集',
    'category': '散歩仲間募集',
    'date': '毎朝7:00〜8:00',
    'location': '東京都世田谷区',
    'participants': 5,
    'emoji': '🐕',
    'description': '多摩川沿いを毎朝散歩しています。一緒に歩きませんか？',
    'organizer': 'たかし',
    'isOfficial': false,
  },
  {
    'title': '代々木公園週末散歩会',
    'category': '散歩仲間募集',
    'date': '毎週土曜 9:00〜11:00',
    'location': '東京都渋谷区',
    'participants': 12,
    'emoji': '🌳',
    'description': '代々木公園で週末に犬の散歩をしています。犬種問わず歓迎！',
    'organizer': 'さくら',
    'isOfficial': false,
  },
  {
    'title': '緊急！多頭崩壊の支援を',
    'category': '緊急支援',
    'date': '緊急',
    'location': '埼玉県',
    'participants': 43,
    'emoji': '🆘',
    'description': '多頭崩壊が発生しました。緊急の支援をお願いします。',
    'organizer': '埼玉動物愛護団体',
    'isOfficial': true,
  },
];

const _categories = ['全て', '保護活動', 'ボランティア', 'フード支援', '緊急支援', '散歩仲間募集'];

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  String _selectedCategory = '全て';

  List get _filtered => _events.where((e) =>
  _selectedCategory == '全て' || e['category'] == _selectedCategory).toList();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('イベント掲示板 📋',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showPostEvent(context),
            icon: const Icon(Icons.add_circle_rounded,
                color: Color(0xFFE8845A), size: 28),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: _categories.map((cat) {
                final sel = _selectedCategory == cat;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: sel
                            ? const Color(0xFFE8845A) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel
                                ? const Color(0xFFE8845A) : Colors.grey[300]!)),
                    child: Text(cat,
                        style: TextStyle(fontSize: 13,
                            color: sel ? Colors.white : Colors.grey[700],
                            fontWeight: sel
                                ? FontWeight.bold : FontWeight.normal)),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final event = _filtered[i];
                final isEmergency = event['category'] == '緊急支援';
                final isWalk = event['category'] == '散歩仲間募集';
                return GestureDetector(
                  onTap: () => _showEventDetail(context, event),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: isEmergency
                          ? Border.all(color: Colors.red[300]!)
                          : isWalk
                          ? Border.all(
                          color: const Color(0xFF2D6A4F).withOpacity(0.3))
                          : null,
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10, offset: const Offset(0, 3))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(event['emoji'] as String,
                                  style: const TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (event['isOfficial'] as bool) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFF2D6A4F),
                                                borderRadius: BorderRadius.circular(6)),
                                            child: const Text('公式',
                                                style: TextStyle(fontSize: 9,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        if (isEmergency) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius: BorderRadius.circular(6)),
                                            child: const Text('緊急',
                                                style: TextStyle(fontSize: 9,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Expanded(
                                          child: Text(event['title'] as String,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF3D2B1F))),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(event['organizer'] as String,
                                        style: TextStyle(fontSize: 12,
                                            color: Colors.grey[500])),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(event['description'] as String,
                              style: TextStyle(fontSize: 13,
                                  color: Colors.grey[600]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(event['date'] as String,
                                  style: TextStyle(fontSize: 12,
                                      color: Colors.grey[600])),
                              const SizedBox(width: 12),
                              const Icon(Icons.location_on_rounded,
                                  size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(event['location'] as String,
                                  style: TextStyle(fontSize: 12,
                                      color: Colors.grey[600])),
                              const Spacer(),
                              const Icon(Icons.people_rounded,
                                  size: 14, color: Color(0xFFE8845A)),
                              const SizedBox(width: 4),
                              Text('${event['participants']}人',
                                  style: const TextStyle(fontSize: 12,
                                      color: Color(0xFFE8845A),
                                      fontWeight: FontWeight.bold)),
                            ],
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
      ),
    );
  }
  void _showEventDetail(BuildContext context, Map event) {
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
                        Text(event['emoji'] as String,
                            style: const TextStyle(fontSize: 40)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(event['title'] as String,
                                  style: const TextStyle(fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF3D2B1F))),
                              Text(event['organizer'] as String,
                                  style: TextStyle(fontSize: 13,
                                      color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _EventRow(Icons.calendar_today_rounded,
                        event['date'] as String),
                    const SizedBox(height: 8),
                    _EventRow(Icons.location_on_rounded,
                        event['location'] as String),
                    const SizedBox(height: 8),
                    _EventRow(Icons.people_rounded,
                        '${event['participants']}人が参加'),
                    const Divider(height: 32),
                    const Text('詳細',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(height: 8),
                    Text(event['description'] as String,
                        style: TextStyle(fontSize: 14,
                            color: Colors.grey[600], height: 1.7)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('参加申請を送りました！🐾'),
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
                        child: const Text('参加する🐾',
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
  void _showPostEvent(BuildContext context) {
    final _titleCtrl = TextEditingController();
    final _descCtrl = TextEditingController();
    String _selectedCat = '散歩仲間募集';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
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
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('イベントを投稿',
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF3D2B1F))),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('カテゴリ',
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3D2B1F))),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _categories
                              .where((c) => c != '全て')
                              .map((cat) {
                            final sel = _selectedCat == cat;
                            return GestureDetector(
                              onTap: () => setModalState(
                                      () => _selectedCat = cat),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                    color: sel
                                        ? const Color(0xFFE8845A) : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: sel
                                            ? const Color(0xFFE8845A)
                                            : Colors.grey[300]!)),
                                child: Text(cat,
                                    style: TextStyle(fontSize: 13,
                                        color: sel
                                            ? Colors.white : Colors.grey[700])),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        const Text('タイトル',
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3D2B1F))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleCtrl,
                          decoration: InputDecoration(
                            hintText: '例：代々木公園で散歩仲間募集！',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey[300]!)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE8845A))),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text('詳細',
                            style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3D2B1F))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descCtrl,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: '場所・時間・参加条件などを書いてください',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey[300]!)),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFFE8845A))),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('投稿しました！🐾'),
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
                            child: const Text('投稿する',
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
        ),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EventRow(this.icon, this.text);

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
