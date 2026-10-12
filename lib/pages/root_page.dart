import 'package:flutter/material.dart';
import 'home_page.dart';
import 'chat_list_page.dart';
import 'profile_page.dart';
import 'event_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'animal_map_page.dart';
import '../services/unread_service.dart';
import '../services/age_utils.dart';

class RootPage extends StatefulWidget {
  final int initialIndex;
  const RootPage({super.key, this.initialIndex = 0});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  late int _idx;
  final ScrollController _homeScrollController = ScrollController();
  final Set<int> _visitedIndices = {};

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
    _visitedIndices.add(_idx);
    UnreadService.instance.init(); // 下タブ「チャット」のバッジ用に、未読を数え始める
    _initFCM();
    _syncAge(); // 誕生日が来ていたら、年齢を更新する
  }

  @override
  void dispose() {
    _homeScrollController.dispose();
    super.dispose();
  }

  // 生年月日から年齢を計算し直して、変わっていたら age を更新する。
  // （イベントの18歳判定は users の age を見ているため）
  Future<void> _syncAge() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final userRef =
      FirebaseFirestore.instance.collection('users').doc(user.uid);
      final birthDoc = await userRef.collection('private').doc('birth').get();
      final birth = AgeUtils.parse(birthDoc.data()?['birthDate'] as String?);
      if (birth == null) return; // 生年月日が未登録の人は、そのまま
      final age = AgeUtils.calculate(birth);
      final userDoc = await userRef.get();
      if (!userDoc.exists) return;
      if (userDoc.data()?['age'] != age) {
        await userRef.update({'age': age});
      }
    } catch (e) {
      debugPrint('年齢の更新エラー: $e');
    }
  }

  Future<void> _initFCM() async {
    if (kIsWeb) return;
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    final user = FirebaseAuth.instance.currentUser;

    if (token != null && user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
    }
  }

  List<Widget> get _pages => [
    HomePage(scrollController: _homeScrollController),
    const AnimalMapPage(),
    const EventPage(),
    const ChatListPage(),
    const ProfilePage(),
  ];

  void _selectTab(int index) {
    // チャットタブを開くときに、参加中のイベントを最新にする
    if (index == 3) UnreadService.instance.refreshMembership();
    setState(() {
      _idx = index;
      _visitedIndices.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    return Scaffold(
      body: IndexedStack(
        index: _idx,
        children: List.generate(pages.length, (i) {
          return _visitedIndices.contains(i) ? pages[i] : const SizedBox.shrink();
        }),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: const Color(0xFFE8845A).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                    icon: Icons.home_rounded,
                    label: 'ホーム',
                    selected: _idx == 0,
                    onTap: () {
                      if (_idx == 0) {
                        _homeScrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                        );
                      } else {
                        _selectTab(0);
                      }
                    }),
                _NavItem(
                    icon: Icons.pets_rounded,
                    label: 'どうぶつマップ',
                    selected: _idx == 1,
                    onTap: () => _selectTab(1)),
                _NavItem(
                    icon: Icons.event_rounded,
                    label: 'イベント',
                    selected: _idx == 2,
                    onTap: () => _selectTab(2)),
                ValueListenableBuilder<int>(
                  valueListenable: UnreadService.instance.totalUnread,
                  builder: (_, unread, __) => _NavItem(
                      icon: Icons.chat_bubble_rounded,
                      label: 'チャット',
                      badge: unread,
                      selected: _idx == 3,
                      onTap: () => _selectTab(3)),
                ),
                _NavItem(
                    icon: Icons.person_rounded,
                    label: 'マイページ',
                    selected: _idx == 4,
                    onTap: () => _selectTab(4)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFE8845A).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon,
                    color: selected
                        ? const Color(0xFFE8845A)
                        : const Color(0xFFBDB5B0),
                    size: 24),
                if (badge > 0)
                  Positioned(
                    right: -9,
                    top: -5,
                    child: Container(
                      constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Center(
                        child: Text(badge > 99 ? '99+' : '$badge',
                            style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: selected
                        ? const Color(0xFFE8845A)
                        : const Color(0xFFBDB5B0),
                    fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}