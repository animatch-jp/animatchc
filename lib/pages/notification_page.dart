import 'package:flutter/material.dart';

const _notifications = [
  {
    'type': 'like',
    'emoji': '❤️',
    'title': 'いいねが来ました！',
    'desc': 'さくらさんがマイクにいいねしました',
    'time': '5分前',
    'read': false,
  },
  {
    'type': 'match',
    'emoji': '🎉',
    'title': 'マッチしました！',
    'desc': 'ゆいさんとマッチしました！チャットしてみましょう',
    'time': '30分前',
    'read': false,
  },
  {
    'type': 'chat',
    'emoji': '💬',
    'title': 'メッセージが来ました！',
    'desc': 'けんたさん：「はじめまして！」',
    'time': '1時間前',
    'read': false,
  },
  {
    'type': 'event',
    'emoji': '📅',
    'title': 'イベントのお知らせ',
    'desc': 'ドッグランイベントまで3日です！',
    'time': '2時間前',
    'read': true,
  },
  {
    'type': 'support',
    'emoji': '🌱',
    'title': '支援のお礼',
    'desc': '里親申請が受理されました！担当者から連絡があります',
    'time': '1日前',
    'read': true,
  },
  {
    'type': 'stamp',
    'emoji': '🎊',
    'title': 'スタンプ解放！',
    'desc': 'わんこセットが解放されました！チャットで使えます',
    'time': '2日前',
    'read': true,
  },
  {
    'type': 'urgent',
    'emoji': '🆘',
    'title': '緊急支援のお知らせ',
    'desc': '多頭崩壊緊急支援のボランティアを募集しています',
    'time': '3日前',
    'read': true,
  },
];

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map> _notifs = List.from(_notifications);

  Color _typeColor(String type) {
    switch (type) {
      case 'like': return const Color(0xFFE8845A);
      case 'match': return Colors.pink;
      case 'chat': return Colors.blue;
      case 'event': return Colors.purple;
      case 'support': return const Color(0xFF2D6A4F);
      case 'stamp': return Colors.amber;
      case 'urgent': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifs.where((n) => n['read'] == false).length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: Text(unread > 0 ? '通知 ($unread)' : '通知',
            style: const TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => setState(() {
              _notifs = _notifs.map((n) =>
              {...n, 'read': true}).toList();
            }),
            child: const Text('全て既読',
                style: TextStyle(color: Color(0xFFE8845A),
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifs.length,
        itemBuilder: (_, i) {
          final notif = _notifs[i];
          final isRead = notif['read'] as bool;
          final color = _typeColor(notif['type'] as String);

          return GestureDetector(
            onTap: () => setState(() {
              _notifs[i] = {...notif, 'read': true};
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isRead ? Colors.white : color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(18),
                border: isRead ? null : Border.all(
                    color: color.withOpacity(0.2)),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14)),
                    child: Center(
                        child: Text(notif['emoji'] as String,
                            style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(notif['title'] as String,
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isRead
                                          ? FontWeight.normal : FontWeight.bold,
                                      color: const Color(0xFF3D2B1F))),
                            ),
                            if (!isRead)
                              Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(notif['desc'] as String,
                            style: TextStyle(fontSize: 12,
                                color: Colors.grey[600]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(notif['time'] as String,
                            style: TextStyle(fontSize: 11,
                                color: Colors.grey[400])),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
