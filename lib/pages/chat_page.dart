import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import 'report_page.dart';

class ChatPage extends StatefulWidget {
  final String userName;
  final String userEmoji;

  const ChatPage({
    super.key,
    required this.userName,
    required this.userEmoji,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _showStamps = false;
  bool _isFriend = false;
  bool _isBlocked = false;
  bool _isMuted = false;
  bool _isTyping = false;

  final _messages = [
    {'text': 'はじめまして！', 'isMe': false, 'time': '14:00', 'read': true, 'type': 'text'},
    {'text': 'こんにちは！よろしくお願いします🐾', 'isMe': true, 'time': '14:01', 'read': true, 'type': 'text'},
    {'text': 'ワンちゃん飼ってるんですね！', 'isMe': false, 'time': '14:02', 'read': true, 'type': 'text'},
    {'text': 'はい！柴犬です🐕', 'isMe': true, 'time': '14:03', 'read': true, 'type': 'text'},
    {'text': 'かわいいですね！一緒に散歩しましょう', 'isMe': false, 'time': '14:04', 'read': false, 'type': 'text'},
  ];

  final _stampSets = [
    {
      'name': 'わんこセット',
      'emojis': ['🐕', '🐶', '🦮', '🐩', '🐾', '🦴'],
    },
    {
      'name': 'にゃんこセット',
      'emojis': ['🐱', '🐈', '😺', '😸', '😻', '🐾'],
    },
    {
      'name': 'うさぎセット',
      'emojis': ['🐰', '🐇', '🌿', '🥕', '💕', '✨'],
    },
  ];

  final _userInfo = {
    'age': '25歳',
    'city': '大阪',
    'purpose': '🐾 動物好き友達探し',
    'relation': '🏠 飼ってる',
    'bio': '犬と一緒に色んな場所に行くのが好きです！',
    'petName': 'マイク',
    'petType': '犬',
    'petAge': '2歳',
    'petBio': '甘えん坊で人懐こい男の子🐶',
  };

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'text': text,
        'isMe': true,
        'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'read': false,
        'type': 'text',
      });
      _msgCtrl.clear();
      _showStamps = false;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _sendLocation() {
    setState(() {
      _messages.add({
        'text': '📍 現在地を共有しました',
        'isMe': true,
        'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'read': false,
        'type': 'location',
      });
      _showStamps = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('位置情報を共有しました📍'),
        backgroundColor: Color(0xFF2D6A4F),
      ),
    );
  }

  void _sendPhoto() {
    setState(() {
      _messages.add({
        'text': '📷 写真を送信しました（リリース後に使えます）',
        'isMe': true,
        'time': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
        'read': false,
        'type': 'photo',
      });
      _showStamps = false;
    });
  }
  void _showUserProfile() {
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
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8845A).withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: Center(
                          child: Text(widget.userEmoji,
                              style: const TextStyle(fontSize: 44))),
                    ),
                    const SizedBox(height: 12),
                    Text(widget.userName,
                        style: const TextStyle(fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3D2B1F))),
                    const SizedBox(height: 4),
                    Text('${_userInfo['age']} ・ ${_userInfo['city']}',
                        style: TextStyle(fontSize: 13,
                            color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8845A).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(_userInfo['purpose']!,
                          style: const TextStyle(fontSize: 12,
                              color: Color(0xFFE8845A),
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('自己紹介',
                              style: TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3D2B1F))),
                          const SizedBox(height: 8),
                          Text(_userInfo['bio']!,
                              style: TextStyle(fontSize: 13,
                                  color: Colors.grey[600], height: 1.6)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ペット情報',
                              style: TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3D2B1F))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                    color: const Color(0xFFE8845A).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Center(
                                    child: Text('🐾',
                                        style: TextStyle(fontSize: 24))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${_userInfo['petName']}（${_userInfo['petType']}・${_userInfo['petAge']}）',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3D2B1F))),
                                    const SizedBox(height: 4),
                                    Text(_userInfo['petBio']!,
                                        style: TextStyle(fontSize: 12,
                                            color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded,
              color: Color(0xFF3D2B1F)),
        ),
        title: GestureDetector(
          onTap: _showUserProfile,
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: const Color(0xFFE8845A).withOpacity(0.1),
                    shape: BoxShape.circle),
                child: Center(
                    child: Text(widget.userEmoji,
                        style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.userName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3D2B1F))),
                      if (_isFriend) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFFE8845A),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Text('フレンド',
                              style: TextStyle(fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ],
                  ),
                  const Text('タップでプロフィールを見る',
                      style: TextStyle(fontSize: 10,
                          color: Colors.grey)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert_rounded,
                color: Colors.grey),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            itemBuilder: (_) => [
              PopupMenuItem(
                child: Row(children: [
                  Icon(_isFriend
                      ? Icons.person_remove_rounded
                      : Icons.person_add_rounded,
                      color: const Color(0xFFE8845A)),
                  PopupMenuItem(
                    child: Row(children: [
                      Icon(_isMuted
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                          color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(_isMuted ? 'ミュート解除' : 'ミュートする'),
                    ]),
                    onTap: () {
                      Future.delayed(
                          const Duration(milliseconds: 100), () {
                        setState(() => _isMuted = !_isMuted);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_isMuted
                                ? 'ミュートしました🔇'
                                : 'ミュートを解除しました🔊'),
                            backgroundColor: Colors.grey,
                          ),
                        );
                      });
                    },
                  ),

                  const SizedBox(width: 8),
                  Text(_isFriend ? 'フレンド解除' : 'フレンドに追加'),
                ]),
                onTap: () {
                  Future.delayed(
                      const Duration(milliseconds: 100), () {
                    setState(() => _isFriend = !_isFriend);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isFriend
                            ? 'フレンドに追加しました！🐾'
                            : 'フレンドを解除しました'),
                        backgroundColor: const Color(0xFFE8845A),
                      ),
                    );
                  });
                },
              ),
              PopupMenuItem(
                child: const Row(children: [
                  Icon(Icons.block_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('ブロックする'),
                ]),
                onTap: () {
                  Future.delayed(
                      const Duration(milliseconds: 100), () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('ブロックしました'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  });
                },
              ),
              PopupMenuItem(
                child: const Row(children: [
                  Icon(Icons.flag_rounded, color: Colors.red),
                  SizedBox(width: 8),
                  Text('通報する',
                      style: TextStyle(color: Colors.red)),
                ]),
                onTap: () {
                  Future.delayed(
                      const Duration(milliseconds: 100), () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) =>
                            ReportPage(userName: widget.userName)));
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
      Expanded(
      child: ListView.builder(
      controller: _scrollCtrl,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        itemBuilder: (_, i) {
          final msg = _messages[i];
          final isMe = msg['isMe'] as bool;
          final isRead = msg['read'] as bool;
          final type = msg['type'] as String;

          // 日付区切り
          final showDate = i == 0;

          return Column(
            children: [
              if (showDate)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12)),
                  child: const Text('今日',
                      style: TextStyle(fontSize: 11,
                          color: Colors.grey)),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: isMe
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!isMe) ...[
                      Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                            color: const Color(0xFFE8845A).withOpacity(0.1),
                            shape: BoxShape.circle),
                        child: Center(
                            child: Text(widget.userEmoji,
                                style: const TextStyle(fontSize: 16))),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onLongPress: () {
                            showModalBottomSheet(
                              context: context,
                              shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20))),
                              builder: (_) => Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                      leading: const Icon(Icons.copy_rounded),
                                      title: const Text('コピー'),
                                      onTap: () => Navigator.pop(context)),
                                  if (isMe)
                                    ListTile(
                                        leading: const Icon(
                                            Icons.delete_rounded,
                                            color: Colors.red),
                                        title: const Text('削除',
                                            style: TextStyle(color: Colors.red)),
                                        onTap: () {
                                          setState(() => _messages.removeAt(i));
                                          Navigator.pop(context);
                                        }),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            constraints: BoxConstraints(
                                maxWidth:
                                MediaQuery.of(context).size.width * 0.65),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: type == 'location'
                                  ? const Color(0xFF2D6A4F)
                                  : type == 'photo'
                                  ? Colors.blue
                                  : isMe
                                  ? const Color(0xFFE8845A)
                                  : Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(18),
                                topRight: const Radius.circular(18),
                                bottomLeft: Radius.circular(isMe ? 18 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 18),
                              ),
                              boxShadow: [BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2))],
                            ),
                            child: Text(msg['text'] as String,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: isMe || type == 'location' || type == 'photo'
                                        ? Colors.white
                                        : const Color(0xFF3D2B1F),
                                    height: 1.4)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(msg['time'] as String,
                                style: TextStyle(fontSize: 10,
                                    color: Colors.grey[400])),
                            if (isMe) ...[
                              const SizedBox(width: 4),
                              Icon(
                                  isRead
                                      ? Icons.done_all_rounded
                                      : Icons.done_rounded,
                                  size: 14,
                                  color: isRead
                                      ? const Color(0xFFE8845A)
                                      : Colors.grey[400]),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
          if (_isTyping)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                        color: const Color(0xFFE8845A).withOpacity(0.1),
                        shape: BoxShape.circle),
                    child: Center(
                        child: Text(widget.userEmoji,
                            style: const TextStyle(fontSize: 16))),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        _TypingDot(delay: 0),
                        const SizedBox(width: 4),
                        _TypingDot(delay: 200),
                        const SizedBox(width: 4),
                        _TypingDot(delay: 400),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (_showStamps)
    Container(
    height: 200,
    color: Colors.white,
    child: Column(
    children: [
    SizedBox(
    height: 40,
    child: ListView.builder(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    itemCount: _stampSets.length,
    itemBuilder: (_, i) {
    final set = _stampSets[i];
    return Padding(
    padding: const EdgeInsets.only(right: 16),
    child: Center(
    child: Text(set['name'] as String,
    style: const TextStyle(fontSize: 12,
    color: Color(0xFFE8845A),
    fontWeight: FontWeight.bold)),
    ),
    );
    },
    ),
    ),
    Expanded(
    child: GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate:
    const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 6,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    ),
    itemCount: _stampSets
        .expand((s) => s['emojis'] as List)
        .length,
    itemBuilder: (_, i) {
    final allEmojis = _stampSets
        .expand((s) => s['emojis'] as List)
        .toList();
    return GestureDetector(
    onTap: () => _sendMessage(allEmojis[i] as String),
    child: Container(
    decoration: BoxDecoration(
    color: const Color(0xFFFFF8F5),
    borderRadius: BorderRadius.circular(10)),
    child: Center(
    child: Text(allEmojis[i] as String,
    style: const TextStyle(fontSize: 28))),
    ),
    );
    },
    ),
    ),
    ],
    ),
    ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _sendPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.photo_rounded,
                        color: Colors.grey, size: 24),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendLocation,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.location_on_rounded,
                        color: Color(0xFF2D6A4F), size: 24),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _showStamps = !_showStamps),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: _showStamps
                            ? const Color(0xFFE8845A).withOpacity(0.1)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.emoji_emotions_rounded,
                        color: _showStamps
                            ? const Color(0xFFE8845A) : Colors.grey,
                        size: 24),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    decoration: InputDecoration(
                      hintText: 'メッセージを入力...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_msgCtrl.text),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8845A),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(
                          color: const Color(0xFFE8845A).withOpacity(0.3),
                          blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: const Icon(Icons.send_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('⚠️ プライバシー保護'),
            content: const Text(
                'このチャットのスクリーンショットは\n相手のプライバシーを侵害する可能性があります。\n\n個人情報の取り扱いには十分ご注意ください。'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8845A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('理解しました'),
              ),
            ],
          ),
        );
      }
    });

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle),
        ),
      ),
    );
  }
}
