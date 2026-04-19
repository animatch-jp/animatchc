import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends State<NotificationSettingsPage> {

  final _settings = {
    'いいねが来た': true,
    'マッチした': true,
    'メッセージが来た': true,
    'フレンドリクエスト': true,
    '足あと': false,
    '保護活動の緊急情報': true,
    '迷子情報（近くで）': true,
    'イベントのお知らせ': false,
    '病院マップの新情報': false,
    'AniMatchからのお知らせ': true,
  };

  final _icons = {
    'いいねが来た': Icons.favorite_rounded,
    'マッチした': Icons.celebration_rounded,
    'メッセージが来た': Icons.chat_bubble_rounded,
    'フレンドリクエスト': Icons.people_rounded,
    '足あと': Icons.remove_red_eye_rounded,
    '保護活動の緊急情報': Icons.warning_rounded,
    '迷子情報（近くで）': Icons.search_rounded,
    'イベントのお知らせ': Icons.event_rounded,
    '病院マップの新情報': Icons.local_hospital_rounded,
    'AniMatchからのお知らせ': Icons.notifications_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('通知設定 🔔',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _settings.updateAll((key, value) => true);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('全ての通知をオンにしました🔔'),
                  backgroundColor: Color(0xFFE8845A),
                ),
              );
            },
            child: const Text('全てオン',
                style: TextStyle(color: Color(0xFFE8845A))),
          ),
        ],
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
                  color: const Color(0xFFE8845A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: const Row(
                children: [
                  Text('🔔', style: TextStyle(fontSize: 28)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        '通知をオフにしても\n緊急情報は赤いバッジで表示されます',
                        style: TextStyle(fontSize: 12,
                            color: Color(0xFF3D2B1F), height: 1.5)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('マッチング',
                style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            _buildSection(['いいねが来た', 'マッチした',
              'メッセージが来た', 'フレンドリクエスト', '足あと']),
            const SizedBox(height: 20),
            const Text('保護活動・緊急',
                style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            _buildSection(['保護活動の緊急情報', '迷子情報（近くで）']),
            const SizedBox(height: 20),
            const Text('その他',
                style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            _buildSection(['イベントのお知らせ',
              '病院マップの新情報', 'AniMatchからのお知らせ']),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
  Widget _buildSection(List<String> keys) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: keys.asMap().entries.map((entry) {
          final i = entry.key;
          final key = entry.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8845A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(_icons[key],
                          color: const Color(0xFFE8845A), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(key,
                            style: const TextStyle(fontSize: 14,
                                color: Color(0xFF3D2B1F)))),
                    Switch(
                      value: _settings[key]!,
                      onChanged: (val) => setState(() => _settings[key] = val),
                      activeColor: const Color(0xFFE8845A),
                    ),
                  ],
                ),
              ),
              if (i < keys.length - 1)
                const Divider(height: 1, indent: 64),
            ],
          );
        }).toList(),
      ),
    );
  }
}
