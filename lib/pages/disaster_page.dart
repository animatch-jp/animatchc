import 'package:flutter/material.dart';

class DisasterPage extends StatefulWidget {
  const DisasterPage({super.key});

  @override
  State<DisasterPage> createState() => _DisasterPageState();
}

class _DisasterPageState extends State<DisasterPage> {
  String _myStatus = '';
  bool _statusSent = false;

  final _nearbyStatuses = [
    {'name': 'さくら', 'emoji': '🐕', 'status': '無事です', 'time': '5分前', 'safe': true},
    {'name': 'ゆい', 'emoji': '🐱', 'status': '無事です', 'time': '10分前', 'safe': true},
    {'name': 'けんた', 'emoji': '🐶', 'status': '助けが必要です', 'time': '15分前', 'safe': false},
    {'name': 'みか', 'emoji': '🐰', 'status': '無事です', 'time': '20分前', 'safe': true},
    {'name': 'たろう', 'emoji': '🐹', 'status': '助けが必要です', 'time': '30分前', 'safe': false},
  ];

  final _shelters = [
    {
      'name': '代々木公園避難所',
      'address': '東京都渋谷区代々木神園町',
      'petOk': true,
      'distance': '0.5km',
    },
    {
      'name': '新宿中央公園',
      'address': '東京都新宿区西新宿',
      'petOk': true,
      'distance': '1.2km',
    },
    {
      'name': '渋谷区立スポーツセンター',
      'address': '東京都渋谷区渋谷',
      'petOk': false,
      'distance': '1.8km',
    },
  ];

  final _emergencyContacts = [
    {'name': '動物愛護センター（東京）', 'phone': '03-3302-3507', 'emoji': '🐾'},
    {'name': '警察（緊急）', 'phone': '110', 'emoji': '🚔'},
    {'name': '消防（緊急）', 'phone': '119', 'emoji': '🚒'},
    {'name': '動物病院救急', 'phone': '0120-xxx-xxx', 'emoji': '🏥'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: const Color(0xFFFFF8F5),
        appBar: AppBar(
          title: const Text('災害時安否確認 🆘',
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
            // 緊急バナー
            Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red[300]!)),
            child: const Row(
              children: [
                Text('🆘', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('緊急時はすぐに安否を報告',
                          style: TextStyle(fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red)),
                      Text('あなたの安否をフレンドに知らせましょう',
                          style: TextStyle(fontSize: 12,
                              color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 安否報告ボタン
          const Text('あなたの安否を報告',
              style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2B1F))),
          const SizedBox(height: 12),
          _statusSent
              ? Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: _myStatus == '無事です'
                    ? const Color(0xFF2D6A4F).withOpacity(0.1)
                    : Colors.red[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _myStatus == '無事です'
                        ? const Color(0xFF2D6A4F) : Colors.red)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_myStatus == '無事です' ? '✅' : '🆘',
                    style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(_myStatus,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _myStatus == '無事です'
                                ? const Color(0xFF2D6A4F) : Colors.red)),
                    const Text('と報告しました',
                        style: TextStyle(fontSize: 12,
                            color: Colors.grey)),
                  ],
                ),
              ],
            ),
          )
              : Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    _myStatus = '無事です';
                    _statusSent = true;
                  }),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D6A4F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('✅ 無事です',
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setState(() {
                    _myStatus = '助けが必要です';
                    _statusSent = true;
                  }),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('🆘 助けが必要',
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
            const SizedBox(height: 24),
            // 近くの安否情報
            const Text('近くの安否情報',
                style: TextStyle(fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 12),
            ..._nearbyStatuses.map((status) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
    color: (status['safe'] as bool)
    ? const Color(0xFF2D6A4F).withOpacity(0.3)
        : Colors.red.withOpacity(0.3)),
    boxShadow: [BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: Row(
    children: [
    Container(
    width: 44, height: 44,
    decoration: BoxDecoration(
    color: (status['safe'] as bool)
    ? const Color(0xFF2D6A4F).withOpacity(0.1)
        : Colors.red.withOpacity(0.1),
    shape: BoxShape.circle),
    child: Center(
    child: Text(status['emoji'] as String,
    style: const TextStyle(fontSize: 24))),
    ),
    const SizedBox(width: 12),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(status['name'] as String,
    style: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3D2B1F))),
    Text(status['time'] as String,
    style: TextStyle(fontSize: 11,
    color: Colors.grey[500])),
    ],
    ),
    ),
    Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
    color: (status['safe'] as bool)
    ? const Color(0xFF2D6A4F)
        : Colors.red,
    borderRadius: BorderRadius.circular(12)),
    child: Text(status['status'] as String,
    style: const TextStyle(fontSize: 12,
    color: Colors.white,
    fontWeight: FontWeight.bold)),
    ),
    ],
    ),
    )),
    const SizedBox(height: 24),
    // ペットOKな避難所
    const Text('近くのペットOK避難所',
    style: TextStyle(fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3D2B1F))),
    const SizedBox(height: 12),
    ..._shelters.map((shelter) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: (shelter['petOk'] as bool)
    ? Border.all(
    color: const Color(0xFF2D6A4F).withOpacity(0.3))
        : null,
    boxShadow: [BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: Row(
    children: [
    Text((shelter['petOk'] as bool) ? '🐾' : '🏠',
    style: const TextStyle(fontSize: 28)),
    const SizedBox(width: 12),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(shelter['name'] as String,
    style: const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Color(0xFF3D2B1F))),
    Text(shelter['address'] as String,
    style: TextStyle(fontSize: 11,
    color: Colors.grey[600])),
    ],
    ),
    ),
    Column(
    children: [
    Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
    color: (shelter['petOk'] as bool)
    ? const Color(0xFF2D6A4F)
        : Colors.grey,
    borderRadius: BorderRadius.circular(8)),
    child: Text(
    (shelter['petOk'] as bool) ? 'ペットOK' : 'ペット不可',
    style: const TextStyle(fontSize: 10,
    color: Colors.white,
    fontWeight: FontWeight.bold)),
    ),
    const SizedBox(height: 4),
    Text(shelter['distance'] as String,
    style: TextStyle(fontSize: 11,
    color: Colors.grey[500])),
    ],
    ),
    ],
    ),
    )),
              const SizedBox(height: 24),
              // 緊急連絡先
              const Text('緊急連絡先',
                  style: TextStyle(fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D2B1F))),
              const SizedBox(height: 12),
              ..._emergencyContacts.map((contact) => Container(
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
                    Text(contact['emoji'] as String,
                        style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(contact['name'] as String,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3D2B1F))),
                          Text(contact['phone'] as String,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFE8845A),
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${contact['phone']}に電話します📞'),
                            backgroundColor: const Color(0xFFE8845A),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8845A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8)),
                      child: const Text('電話',
                          style: TextStyle(fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 24),
            ],
          ),
        ),
    );
  }
}
