import 'package:flutter/material.dart';
import 'chat_page.dart';
import '../models/pet.dart';

class ChatRequest {
  final Pet pet;
  final String message;
  bool isAccepted;
  bool isRejected;

  ChatRequest({
    required this.pet,
    required this.message,
    this.isAccepted = false,
    this.isRejected = false,
  });
}

final _dummyRequests = [
  ChatRequest(
    pet: const Pet(
      id: '2', name: 'マイク', type: '犬', age: 2,
      bio: '甘えん坊で人懐こい男の子🐶',
      avatarPath: 'assets/images/mike.jpg',
      photos: [], owner: 'さくら', ownerCity: '大阪',
    ),
    message: 'マイクと仲良くしてください！',
  ),
  ChatRequest(
    pet: const Pet(
      id: '3', name: 'モナ', type: '猫', age: 4,
      bio: 'おっとりした女の子🌞',
      avatarPath: 'assets/images/mona.jpg',
      photos: [], owner: 'ゆい', ownerCity: '京都',
    ),
    message: 'モナのことよろしくお願いします！',
    isAccepted: true,
  ),
];

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final received = _dummyRequests
        .where((r) => !r.isAccepted && !r.isRejected).toList();
    final accepted = _dummyRequests
        .where((r) => r.isAccepted).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F3),
      appBar: AppBar(
        title: const Text('チャット 💬',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: const Color(0xFFFFF5F3),
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: const Color(0xFFE8A598),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFE8A598),
          tabs: [
            Tab(text: 'リクエスト（${received.length}）'),
            Tab(text: 'チャット中（${accepted.length}）'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
      received.isEmpty
      ? const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('💬', style: TextStyle(fontSize: 52)),
          SizedBox(height: 12),
          Text('リクエストはありません',
              style: TextStyle(color: Colors.grey, fontSize: 15)),
          SizedBox(height: 6),
          Text('ペットを探してチャットしよう！',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    )
        : ListView.builder(
    itemCount: received.length,
    itemBuilder: (_, i) {
    final req = received[i];
    return Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Row(
    children: [
    ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.asset(req.pet.avatarPath,
    width: 52, height: 52, fit: BoxFit.cover,
    errorBuilder: (_,__,___) => Container(
    width: 52, height: 52,
    color: Colors.orange[50],
    child: const Center(
    child: Text('🐾')))),
    ),
    const SizedBox(width: 12),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    Text(req.pet.name,
    style: const TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 15)),
    Text('${req.pet.owner}さん・${req.pet.ownerCity}',
    style: TextStyle(fontSize: 12,
    color: Colors.grey[600])),
    Text(req.message,
    style: TextStyle(fontSize: 12,
    color: Colors.grey[500])),
    ],
    ),
    ),
    ],
    ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() =>
              req.isRejected = true),
              style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey,
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('拒否'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => setState(() =>
              req.isAccepted = true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8A598),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('許可する'),
            ),
          ),
        ],
      ),
    ],
    ),
    );
    },
      ),
          accepted.isEmpty
              ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('💕', style: TextStyle(fontSize: 52)),
                SizedBox(height: 12),
                Text('チャット中の相手はいません',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
              ],
            ),
          )
              : ListView.builder(
            itemCount: accepted.length,
            itemBuilder: (_, i) {
              final req = accepted[i];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(req.pet.avatarPath,
                      width: 52, height: 52, fit: BoxFit.cover,
                      errorBuilder: (_,__,___) => Container(
                          width: 52, height: 52, color: Colors.orange[50],
                          child: const Center(child: Text('🐾')))),
                ),
                title: Text(req.pet.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    '${req.pet.owner}さん・${req.pet.ownerCity}'),
                trailing: const Icon(Icons.chat_bubble_outline,
                    color: Color(0xFFE8A598)),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => ChatPage(
                    userName: req.pet.name,
                    userEmoji: '🐾',
                  ),

                )),
              );
            },
          ),
        ],
      ),
    );
  }
}
