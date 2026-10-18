import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 通知の設定の1項目。
/// key は、通知を送る側の shouldSendNotification(uid, key) と、同じ文字列にすること。
class _SettingItem {
  final String key;
  final IconData icon;
  final String description;
  const _SettingItem(this.key, this.icon, this.description);
}

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  // 実際に通知を送るコードがある項目だけを並べる。
  //  ・コメント・メッセージ … chat_page.dart / event_chat_page.dart / pet_brag_page.dart(コメント)
  //  ・リアクション … pet_brag_page.dart(リアクション)
  //  ・ランキング・バッジ … pet_brag_page.dart(バッジ獲得)
  //  ・イベント関連 … event_page.dart
  // 「AniMatchからのお知らせ」は、送る仕組みがまだ無いので、出していない。
  static const _communityItems = [
    _SettingItem('コメント・メッセージ', Icons.chat_bubble_rounded,
        'チャット、グループチャット、ペット自慢へのコメント'),
    _SettingItem('リアクション', Icons.favorite_rounded,
        'ペット自慢への「かわいい」などの反応'),
    _SettingItem('ランキング・バッジ', Icons.emoji_events_rounded,
        'バッジを獲得したとき'),
  ];

  static const _otherItems = [
    _SettingItem('イベント関連', Icons.event_rounded,
        'イベントの参加・内容の変更・キャンセル・削除・追放'),
  ];

  late final Map<String, bool> _settings = {
    for (final item in [..._communityItems, ..._otherItems]) item.key: true,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final saved =
      doc.data()?['notificationSettings'] as Map<String, dynamic>?;
      if (saved != null && mounted) {
        setState(() {
          saved.forEach((key, value) {
            if (_settings.containsKey(key) && value is bool) {
              _settings[key] = value;
            }
          });
        });
      }
    } catch (e) {
      debugPrint('通知設定の読み込みエラー: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  // 保存に失敗したら false を返す
  Future<bool> _saveSettings(Map<String, bool> values) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'notificationSettings': values},
        SetOptions(merge: true),
      );
      return true;
    } catch (e) {
      debugPrint('通知設定の保存エラー: $e');
      return false;
    }
  }

  Future<void> _onToggle(String key, bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _settings[key] = value);
    final ok = await _saveSettings({key: value});
    if (!ok && mounted) {
      // 保存できなかったので、スイッチを元に戻す
      setState(() => _settings[key] = !value);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('設定を保存できませんでした。もう一度お試しください'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _allOn() async {
    final messenger = ScaffoldMessenger.of(context);
    final before = Map<String, bool>.from(_settings);
    setState(() => _settings.updateAll((key, value) => true));
    final ok = await _saveSettings({for (final k in _settings.keys) k: true});
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('全ての通知をオンにしました🔔'),
          backgroundColor: Color(0xFFE8845A),
        ),
      );
    } else {
      setState(() {
        before.forEach((k, v) => _settings[k] = v);
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('設定を保存できませんでした。もう一度お試しください'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8F5),
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFFE8845A))),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('通知設定 🔔',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _allOn,
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
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            _buildSection(_communityItems),
            const SizedBox(height: 20),
            const Text('その他',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            _buildSection(_otherItems),
            const SizedBox(height: 16),
            Text(
              'オフにしても、チャット画面の未読の数は表示されます。\n'
                  '団体・病院の登録の結果など、大事なお知らせは、オフにしても届きます。',
              style:
              TextStyle(fontSize: 11, color: Colors.grey[600], height: 1.6),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(List<_SettingItem> items) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8845A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(item.icon,
                          color: const Color(0xFFE8845A), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.key,
                              style: const TextStyle(
                                  fontSize: 14, color: Color(0xFF3D2B1F))),
                          const SizedBox(height: 2),
                          Text(item.description,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  height: 1.4)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _settings[item.key] ?? true,
                      onChanged: (val) => _onToggle(item.key, val),
                      activeThumbColor: const Color(0xFFE8845A),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1) const Divider(height: 1, indent: 64),
            ],
          );
        }).toList(),
      ),
    );
  }
}