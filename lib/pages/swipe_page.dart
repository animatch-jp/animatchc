import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import 'chat_page.dart';
import 'profile_page.dart';
import 'user_profile_page.dart';


class SwipePage extends StatefulWidget {
  const SwipePage({super.key});

  @override
  State<SwipePage> createState() => _SwipePageState();
}

class _SwipePageState extends State<SwipePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  bool _liked = false;
  bool _disliked = false;
  bool _showMatch = false;
  int _swipeCount = 0;
  final _provider = globalProvider;
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _myValuesType = '';
  Map<String, dynamic>? _petBragCard;
  String? _petBragCardId;
  bool _showingPetBragCard = false;


  String _matchedUserName = '';
  String _matchedUserUid = '';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.5, 0),
    ).animate(CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOut,
    ));
    _loadUsers();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;

      // ブロックリストを取得
      final blocksSnapshot = await FirebaseFirestore.instance
          .collection('blocks')
          .doc(currentUid)
          .collection('blocked')
          .get();
      final blockedUids = blocksSnapshot.docs.map((d) => d.id).toSet();
      // いいね済みリストを取得
      final likesSnapshot = await FirebaseFirestore.instance
          .collection('likes')
          .doc(currentUid)
          .collection('liked')
          .get();
      final likedUids = likesSnapshot.docs.map((d) => d.id).toSet();
      final myDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .get();
      final myShowing = myDoc.data()?['showing'] ?? '全員';
      _myValuesType = myDoc.data()?['valuesType'] ?? '';


      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('isVisible', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();


      final users = snapshot.docs
          .where((doc) => doc.id != currentUid)
          .where((doc) => !blockedUids.contains(doc.id))
          .where((doc) => !likedUids.contains(doc.id))
          .where((doc) {
        final data = doc.data();
        final name = data['name'] as String? ?? '';
        final imageUrl = data['profileImageUrl'] as String? ?? '';
        final age = data['age'] as int? ?? 0;
        if (name.isEmpty || imageUrl.isEmpty || age == 0) return false;
        return true;
      })

          .where((doc) {
        if (myShowing == '全員') return true;
        final gender = doc.data()['gender'] as String? ?? '';
        return gender == myShowing;
      })

          .map((doc) => {'uid': doc.id, ...doc.data()})
          .toList();


      if (mounted) {
        users.shuffle();
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }

    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRandomPetBrag() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('petBrags')
          .limit(20)
          .get();
      if (snapshot.docs.isEmpty) return;
      final randomDoc = (snapshot.docs..shuffle()).first;
      _petBragCard = randomDoc.data();
      _petBragCardId = randomDoc.id;
    } catch (e) {
      // 取得できなくても通常のスワイプは継続させる
    }
  }


  Future<void> _saveLike(String targetUid) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    print('🔥 _saveLike 開始: targetUid=$targetUid'); // ←ここに追加
    final myDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .get();
    final myName = myDoc.data()?['name'] ?? '';
    print('🔥 myName: $myName');
    final existingLike = await FirebaseFirestore.instance
        .collection('likes')
        .doc(myUid)
        .collection('liked')
        .doc(targetUid)
        .get();

    if (existingLike.exists) return;

    await FirebaseFirestore.instance
        .collection('likes')
        .doc(myUid)
        .collection('liked')
        .doc(targetUid)
        .set({'createdAt': FieldValue.serverTimestamp()});
    // ブロックされているか確認
    final blockedByDoc = await FirebaseFirestore.instance
        .collection('blocks')
        .doc(targetUid)
        .collection('blocked')
        .doc(myUid)
        .get();

    if (!blockedByDoc.exists) {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(targetUid)
          .collection('items')
          .add({
        'type': 'like',
        'emoji': '❤️',
        'title': 'いいねが来ました！',
        'desc': '$myName さんがいいねしました',
        'fromUid': myUid,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }


    await FirebaseFirestore.instance
        .collection('users')
        .doc(targetUid)
        .update({
      'receivedLikeCount': FieldValue.increment(1),
    });

    final doc = await FirebaseFirestore.instance
        .collection('likes')
        .doc(targetUid)
        .collection('liked')
        .doc(myUid)
        .get();

    if (doc.exists) {
      final matchId = ([myUid, targetUid]..sort()).join('_');
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .set({
        'users': [myUid, targetUid],
        'createdAt': FieldValue.serverTimestamp(),
      });
      for (final uid in [myUid, targetUid]) {
        final targetDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetUid)
            .get();
        final targetName = targetDoc.data()?['name'] ?? '';

        // ブロックされているか確認
        final blockedByDoc = await FirebaseFirestore.instance
            .collection('blocks')
            .doc(uid)
            .collection('blocked')
            .doc(uid == myUid ? targetUid : myUid)
            .get();

        if (!blockedByDoc.exists) {
          await FirebaseFirestore.instance
              .collection('notifications')
              .doc(uid)
              .collection('items')
              .add({
            'type': 'match',
            'emoji': '🎉',
            'title': 'マッチしました！',
            'desc': uid == myUid ? '$targetName とマッチしました！' : '$myName とマッチしました！',
            'fromUid': uid == myUid ? targetUid : myUid,
            'read': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (mounted) {
        setState(() => _showMatch = true);
      }

    }
  }

  Map<String, dynamic> get _currentUser => _users[_currentIndex];



  void _nextPet({bool liked = false}) {
    if (liked && _users.isNotEmpty) {
      _matchedUserName = _currentUser['name'] ?? '';
      _matchedUserUid = _currentUser['uid'] ?? '';
      print('🔥 _nextPet liked: $liked users: ${_users.length}');
      _saveLike(_currentUser['uid']);
      _users.removeWhere((u) => u['uid'] == _matchedUserUid);
    }


    setState(() {
      _liked = liked;
      _disliked = !liked;
      _swipeCount++;
    });

    if (_swipeCount % 5 == 0) {
      _petBragCard = null;
      _loadRandomPetBrag();
    }




    _animCtrl.forward().then((_) {
      setState(() {
        _liked = false;
        _disliked = false;
        if (_swipeCount % 5 == 0 && _petBragCard != null) {
          _showingPetBragCard = true;
        } else {
          if (_currentIndex < _users.length - 1) {
            _currentIndex++;
          } else {
            _currentIndex = 0;
          }
        }
      });
      _animCtrl.reset();
    });
  }

  void _dismissPetBragCard() {
    setState(() {
      _showingPetBragCard = false;
      _petBragCard = null;
      _petBragCardId = null;
      if (_currentIndex < _users.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0;
      }
    });
  }

  Future<void> _voteOnPetBrag(String voteType) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null || _petBragCardId == null) return;

    final voterDoc = await FirebaseFirestore.instance
        .collection('petBrags')
        .doc(_petBragCardId)
        .collection('voters')
        .doc(myUid)
        .get();

    if (!voterDoc.exists) {
      await FirebaseFirestore.instance
          .collection('petBrags')
          .doc(_petBragCardId)
          .collection('voters')
          .doc(myUid)
          .set({'voteType': voteType, 'createdAt': FieldValue.serverTimestamp()});

      await FirebaseFirestore.instance
          .collection('petBrags')
          .doc(_petBragCardId)
          .update({
        'votes.$voteType': FieldValue.increment(1),
        'voteCount': FieldValue.increment(1),
      });
    }

    _dismissPetBragCard();
  }

  int _calculateCompatibility(String myType, String otherType) {
    if (myType.isEmpty || otherType.isEmpty) return 70;

    const matrix = {
      'しっかり派': {
        'しっかり派': 85, 'バランス派': 80, 'のんびり派': 60, '自由派': 55,
      },
      'バランス派': {
        'しっかり派': 80, 'バランス派': 90, 'のんびり派': 80, '自由派': 75,
      },
      'のんびり派': {
        'しっかり派': 60, 'バランス派': 80, 'のんびり派': 85, '自由派': 70,
      },
      '自由派': {
        'しっかり派': 55, 'バランス派': 75, 'のんびり派': 70, '自由派': 80,
      },
    };

    return matrix[myType]?[otherType] ?? 70;
  }

  Color _compatibilityColor(int value) {

    if (value >= 80) return const Color(0xFF2D6A4F);
    if (value >= 60) return const Color(0xFFE8845A);
    return Colors.red;
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8F5),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFE8845A)),
        ),
      );
    }

    if (_users.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8F5),
        appBar: AppBar(
          title: const Text('今日のおすすめ 🐾',
              style: TextStyle(
                  fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
          backgroundColor: const Color(0xFFFFF8F5),
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🐾', style: TextStyle(fontSize: 64)),
              SizedBox(height: 16),
              Text('今日のおすすめはいません',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D2B1F))),
              SizedBox(height: 8),
              Text('また後で確認してみてください',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      );
    }



    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('ペットを探す 🐾',
            style: TextStyle(
                fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfilePage())),
            icon: const Icon(Icons.person_rounded, color: Color(0xFFE8845A)),
          ),
        ],
      ),
      body: _showingPetBragCard && _petBragCard != null
          ? _buildPetBragCard()
          : Stack(
        children: [
          Column(
            children: [

              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_currentIndex < _users.length - 1)
                      Positioned(
                        top: 16,
                        child: _buildCard(
                            _users[_currentIndex + 1],
                            isBackground: true),
                      ),

                    SlideTransition(
    position: _slideAnim,
    child: GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                UserProfilePage(uid: _currentUser['uid']),
          ),
        );
        _loadUsers();
      },
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! < -300) {
          _nextPet(liked: true);
        } else if (details.primaryVelocity! > 300) {
          _nextPet(liked: false);
        }
      },
    child: Stack(
    children: [
    _buildCard(_currentUser),
    if (_liked)
    Positioned(
    top: 40, left: 20,
    child: Transform.rotate(
    angle: -0.3,
    child: Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
    border: Border.all(
    color: const Color(0xFF2D6A4F),
    width: 3),
    borderRadius:
    BorderRadius.circular(8)),
    child: const Text('LIKE 💚',
    style: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: Color(0xFF2D6A4F))),
    ),
    ),
    ),
    if (_disliked)
    Positioned(
    top: 40, right: 20,
    child: Transform.rotate(
    angle: 0.3,
    child: Container(
    padding: const EdgeInsets.symmetric(
    horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
    border: Border.all(
    color: Colors.red, width: 3),
    borderRadius:
    BorderRadius.circular(8)),
    child: const Text('NOPE ✕',
    style: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: Colors.red)),
    ),
    ),
    ),
    ],
    ),
    ),
    ),
    ],
    ),
    ),
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 40, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.close_rounded,
                color: Colors.red,
                size: 56,
                onTap: () => _nextPet(liked: false),
              ),
              _ActionButton(
                icon: Icons.star_rounded,
                color: Colors.amber,
                size: 44,
                onTap: () async {
                  final myUid = FirebaseAuth.instance.currentUser?.uid;
                  if (myUid == null) return;
                  final targetUid = _currentUser['uid'] as String;
                  await FirebaseFirestore.instance
                      .collection('favorites')
                      .doc(myUid)
                      .collection('favorited')
                      .doc(targetUid)
                      .set({'createdAt': FieldValue.serverTimestamp()});
                  final myDocForFav = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(myUid)
                      .get();
                  final myName = myDocForFav.data()?['name'] ?? '';
                  await FirebaseFirestore.instance
                      .collection('notifications')
                      .doc(targetUid)
                      .collection('items')
                      .add({
                    'type': 'favorite',
                    'emoji': '⭐',
                    'title': 'お気に入りに追加されました！',
                    'desc': '$myName さんがお気に入りに追加しました',
                    'fromUid': myUid,
                    'read': false,
                    'createdAt': FieldValue.serverTimestamp(),
                  });


                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(targetUid)
                      .update({
                    'receivedFavCount': FieldValue.increment(1),
                  });
                  _nextPet(liked: false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('お気に入りに追加しました！⭐'),
                      backgroundColor: Colors.amber,
                    ),
                  );
                },

              ),
              _ActionButton(
                icon: Icons.favorite_rounded,
                color: const Color(0xFF2D6A4F),
                size: 56,
                onTap: () => _nextPet(liked: true),
              ),
            ],
          ),
        ),
      ],
      ),
            if (_showMatch)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        const Text('マッチしました！',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF3D2B1F))),
                        const SizedBox(height: 8),
                        Text('チャットを始めましょう🐾',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600])),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            setState(() => _showMatch = false);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => ChatPage(
                                        userName: _matchedUserName,
                                        userEmoji: '🐾',
                                        uid: _matchedUserUid)));
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8845A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 14)),
                          child: const Text('チャットする🐾',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              setState(() => _showMatch = false),
                          child: const Text('続けてスワイプする',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
      ),
    );
  }
  void _showPets(Map<String, dynamic> user) async {
    final uid = user['uid'] as String;
    final petsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pets')
        .get();

    final pets = petsSnapshot.docs.map((d) => d.data()).toList();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${user['name']}さんのペット🐾',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (pets.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('ペット情報がありません',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: pets.length,
                  itemBuilder: (_, i) {
                    final pet = pets[i];
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16)),
                            child: pet['imageUrl'] != null &&
                                (pet['imageUrl'] as String).isNotEmpty
                                ? Image.network(
                                pet['imageUrl'] as String,
                                width: 150, height: 120,
                                fit: BoxFit.cover)
                                : Container(
                                width: 150, height: 120,
                                color: Colors.orange[100],
                                child: const Center(
                                    child: Text('🐾',
                                        style: TextStyle(
                                            fontSize: 48)))),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                Text(
                                  '${pet['name']}（${pet['type']}）',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text((pet['age'] ?? '').toString(),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600])),
                                if (pet['tags'] != null &&
                                    (pet['tags'] as List).isNotEmpty)
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: (pet['tags'] as List)
                                        .map((tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFE8845A)
                                              .withOpacity(0.1),
                                          borderRadius:
                                          BorderRadius.circular(8)),
                                      child: Text(tag.toString(),
                                          style: const TextStyle(
                                              fontSize: 9,
                                              color: Color(0xFFE8845A))),
                                    ))
                                        .toList(),
                                  ),

                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetBragCard() {
    final data = _petBragCard!;
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width - 32,
        height: MediaQuery.of(context).size.height * 0.58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              data['imageUrl'] != null &&
                  (data['imageUrl'] as String).isNotEmpty
                  ? Image.network(data['imageUrl'] as String,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover)
                  : Container(
                color: Colors.orange[50],
                child: const Center(
                    child: Text('🐾', style: TextStyle(fontSize: 80))),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Text('🐾 今日のペット自慢',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _dismissPetBragCard,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xDD000000), Colors.transparent])),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['petName'] ?? '',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(data['theme'] ?? '',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _bragVoteButton(
                              '😍', 'かわいい', () => _voteOnPetBrag('kawaii')),
                          _bragVoteButton('🤣', 'おもしろい',
                                  () => _voteOnPetBrag('omoshiroi')),
                          _bragVoteButton(
                              '🥹', '癒される', () => _voteOnPetBrag('iyashi')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bragVoteButton(String emoji, String label, VoidCallback onTap) {
    return _AnimatedVoteButton(emoji: emoji, label: label, onTap: onTap);
  }


  Widget _buildCard(Map<String, dynamic> user, {bool isBackground = false}) {

    final otherValuesType = user['valuesType'] as String? ?? '';
    final hasValuesData = _myValuesType.isNotEmpty && otherValuesType.isNotEmpty;
    final compatibility = _calculateCompatibility(_myValuesType, otherValuesType);


    return Container(
      width: MediaQuery.of(context).size.width - 32,
      height: MediaQuery.of(context).size.height * 0.58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            user['profileImageUrl'] != null &&
                (user['profileImageUrl'] as String).isNotEmpty
                ? Image.network(
              user['profileImageUrl'] as String,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  color: Colors.orange[50],
                  child: const Center(
                      child: Text('🐾',
                          style: TextStyle(fontSize: 80)))),
            )
                : Container(
              color: Colors.orange[50],
              child: const Center(
                  child: Text('🐾',
                      style: TextStyle(fontSize: 80))),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Color(0xDD000000), Colors.transparent])),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text(
                                '${user['name'] ?? ''}・${user['age'] ?? ''}歳',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900))),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color: hasValuesData
                                    ? _compatibilityColor(compatibility)
                                    : Colors.grey,
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(
                                hasValuesData ? '相性 $compatibility%' : '診断待ち',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold))),

                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(user['prefecture'] ?? '',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                        const SizedBox(width: 12),
                        const Icon(Icons.pets_rounded,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(user['animal'] ?? '',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(user['bio'] ?? '',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
            if (!isBackground)
              Positioned(
                top: 12, right: 12,
                child: GestureDetector(
                  onTap: () => _showPets(user),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🐾', style: TextStyle(fontSize: 12)),
                        SizedBox(width: 4),
                        Text('ペットを見る',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3D2B1F))),
                      ],
                    ),
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }
}

class _AnimatedVoteButton extends StatefulWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _AnimatedVoteButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  State<_AnimatedVoteButton> createState() => _AnimatedVoteButtonState();
}

class _AnimatedVoteButtonState extends State<_AnimatedVoteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.3)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Center(
                  child: Text(widget.emoji,
                      style: const TextStyle(fontSize: 26))),
            ),
          ),
          const SizedBox(height: 4),
          Text(widget.label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4))
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}

