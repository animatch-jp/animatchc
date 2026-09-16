import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends State<NotificationSettingsPage> {

  final _settings = {
    'コメント・メッセージ': true,
    'リアクション': true,
    'ランキング・バッジ': true,
    'イベント関連': true,
    'AniMatchからのお知らせ': true,
  };

  final _icons = {
    'コメント・メッセージ': Icons.chat_bubble_rounded,
    'リアクション': Icons.favorite_rounded,
    'ランキング・バッジ': Icons.emoji_events_rounded,
    'イベント関連': Icons.event_rounded,
    'AniMatchからのお知らせ': Icons.notifications_rounded,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final saved = doc.data()?['notificationSettings'] as Map<String, dynamic>?;
    if (saved != null) {
      setState(() {
        saved.forEach((key, value) {
          if (_settings.containsKey(key)) {
            _settings[key] = value as bool;
          }
        });
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSetting(String key, bool value) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'notificationSettings.$key': value});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
      );
    }
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
            onPressed: () async {
              setState(() {
                _settings.updateAll((key, value) => true);
              });
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                final allOn = {for (var k in _settings.keys) 'notificationSettings.$k': true};
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update(allOn);
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('全ての通知をオンにしました🔔'),
                    backgroundColor: Color(0xFFE8845A),
                  ),
                );
              }
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
            const Text('コミュニティ',
                style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            _buildSection(['コメント・メッセージ', 'リアクション', 'ランキング・バッジ']),
            const SizedBox(height: 20),
            const Text('その他',
                style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            _buildSection(['イベント関連', 'AniMatchからのお知らせ']),
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
                      onChanged: (val) {
                        setState(() => _settings[key] = val);
                        _saveSetting(key, val);
                      },
                      activeThumbColor: const Color(0xFFE8845A),
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
