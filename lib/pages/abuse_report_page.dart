import 'package:flutter/material.dart';

class AbuseReportPage extends StatefulWidget {
  const AbuseReportPage({super.key});

  @override
  State<AbuseReportPage> createState() => _AbuseReportPageState();
}

class _AbuseReportPageState extends State<AbuseReportPage> {
  int _step = 0;
  String _selectedType = '';
  String _selectedUrgency = '';
  final _locationCtrl = TextEditingController();
  final _detailCtrl = TextEditingController();
  bool _submitted = false;

  final _abuseTypes = [
    {'emoji': '🥊', 'label': '身体的虐待', 'desc': '暴力・傷つける行為'},
    {'emoji': '🏚️', 'label': '放置・ネグレクト', 'desc': '食事・水を与えない'},
    {'emoji': '🔒', 'label': '劣悪な飼育環境', 'desc': '狭いケージ・不衛生'},
    {'emoji': '🚫', 'label': '遺棄', 'desc': '動物を捨てる行為'},
    {'emoji': '🍖', 'label': '食用目的', 'desc': '食用での飼育・取引'},
    {'emoji': '❓', 'label': 'その他', 'desc': 'その他の虐待'},
  ];

  final _urgencyLevels = [
    {'emoji': '🆘', 'label': '今すぐ助けが必要', 'color': Colors.red},
    {'emoji': '⚠️', 'label': '早急に対応が必要', 'color': Colors.orange},
    {'emoji': '📋', 'label': '調査が必要', 'color': Colors.blue},
  ];

  final _contacts = [
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

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8F5),
        appBar: AppBar(
          title: const Text('虐待通報',
              style: TextStyle(fontWeight: FontWeight.w900,
                  color: Color(0xFF3D2B1F))),
          backgroundColor: const Color(0xFFFFF8F5),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🙏', style: TextStyle(fontSize: 72)),
                const SizedBox(height: 20),
                const Text('通報を受け付けました',
                    style: TextStyle(fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF3D2B1F))),
                const SizedBox(height: 12),
                Text('内容を確認後\n関係機関と連携して対応します',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14,
                        color: Colors.grey[600], height: 1.6)),
                const SizedBox(height: 32),
                const Text('緊急の場合は直接ご連絡ください',
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3D2B1F))),
                const SizedBox(height: 16),
                ...(_contacts.map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Text(c['emoji'] as String,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name'] as String,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF3D2B1F))),
                            Text(c['phone'] as String,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFE8845A),
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ))),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8845A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14)),
                  child: const Text('戻る',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }
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
            // 緊急連絡先バナー
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
                  const Text('🆘 緊急の場合はすぐに連絡してください',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.red)),
                  const SizedBox(height: 8),
                  ..._contacts.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text(c['emoji'] as String),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(c['name'] as String,
                                style: TextStyle(fontSize: 12,
                                    color: Colors.grey[700]))),
                        Text(c['phone'] as String,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // STEP 1
            const Text('STEP 1: 虐待の種類を選んでください',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.5,
              children: _abuseTypes.map((type) {
                final sel = _selectedType == type['label'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type['label'] as String),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: sel ? Colors.red[50] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: sel ? Colors.red : Colors.grey[300]!)),
                    child: Row(
                      children: [
                        Text(type['emoji'] as String,
                            style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(type['label'] as String,
                                style: TextStyle(fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: sel ? Colors.red : const Color(0xFF3D2B1F)))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            // STEP 2
            const Text('STEP 2: 緊急度を選んでください',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 12),
            ..._urgencyLevels.map((level) {
              final sel = _selectedUrgency == level['label'];
              return GestureDetector(
                onTap: () => setState(
                        () => _selectedUrgency = level['label'] as String),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: sel ? (level['color'] as Color).withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: sel ? (level['color'] as Color) : Colors.grey[300]!)),
                  child: Row(
                    children: [
                      Text(level['emoji'] as String,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Text(level['label'] as String,
                          style: TextStyle(fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: sel ? (level['color'] as Color) : const Color(0xFF3D2B1F))),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            // STEP 3
            const Text('STEP 3: 場所を教えてください',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 8),
            TextField(
              controller: _locationCtrl,
              decoration: InputDecoration(
                hintText: '例：東京都渋谷区〇〇',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // STEP 4
            const Text('STEP 4: 詳細を教えてください',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 8),
            TextField(
              controller: _detailCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '見た状況・動物の様子などを詳しく教えてください',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Colors.red)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedType.isEmpty || _selectedUrgency.isEmpty
                    ? null
                    : () => setState(() => _submitted = true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('通報する🆘',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
