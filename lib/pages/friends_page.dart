import 'package:flutter/material.dart';
import 'chat_page.dart';

const _friends = [
  {
    'name': 'さくら',
    'emoji': '🐕',
    'pet': '犬',
    'city': '大阪',
    'online': true,
    'lastMessage': '今日も散歩楽しかったです！',
    'lastTime': '5分前',
  },
  {
    'name': 'ゆい',
    'emoji': '🐱',
    'pet': '猫',
    'city': '京都',
    'online': true,
    'lastMessage': 'うちの猫もそれ好きです🐱',
    'lastTime': '30分前',
  },
  {
    'name': 'みか',
    'emoji': '🐰',
    'pet': 'うさぎ',
    'city': '東京',
    'online': false,
    'lastMessage': 'うさぎって本当にかわいいですよね',
    'lastTime': '2時間前',
  },
  {
    'name': 'けんた',
    'emoji': '🐶',
    'pet': '犬',
    'city': '福岡',
    'online': false,
    'lastMessage': 'また一緒に散歩しましょう！',
    'lastTime': '1日前',
  },
  {
    'name': 'あい',
    'emoji': '🐈',
    'pet': '猫',
    'city': '札幌',
    'online': true,
    'lastMessage': 'ありがとうございます🙏',
    'lastTime': '2日前',
  },
];

class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final onlineFriends = _friends.where((f) => f['online'] == true).toList();
    final offlineFriends = _friends.where((f) => f['online'] == false).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('フレンド 🐾',
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
            // オンライン中
            const Text('オンライン中 🟢',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 12),
            ...onlineFriends.map((f) => _buildFriendCard(context, f)),
            const SizedBox(height: 16),
            // オフライン
            const Text('最近オンライン',
                style: TextStyle(fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 12),
            ...offlineFriends.map((f) => _buildFriendCard(context, f)),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendCard(BuildContext context, Map friend) {
    final isOnline = friend['online'] as bool;
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ChatPage(
            userName: friend['name'] as String,
            userEmoji: friend['emoji'] as String,
          ))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                      color: const Color(0xFFE8845A).withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: isOnline ? Colors.green : Colors.grey,
                          width: 2)),
                  child: Center(
                      child: Text(friend['emoji'] as String,
                          style: const TextStyle(fontSize: 26))),
                ),
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 14, height: 14,
                    decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white, width: 2)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(friend['name'] as String,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D2B1F))),
                      Text(friend['lastTime'] as String,
                          style: TextStyle(fontSize: 11,
                              color: Colors.grey[400])),
                    ],
                  ),
                  Text('${friend['pet']} ・ ${friend['city']}',
                      style: TextStyle(fontSize: 12,
                          color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(friend['lastMessage'] as String,
                      style: TextStyle(fontSize: 12,
                          color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
