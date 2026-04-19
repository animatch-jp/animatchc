import 'package:flutter/material.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'support_page.dart';
import 'chat_list_page.dart';
import 'profile_page.dart';
import 'event_page.dart';
import 'hospital_page.dart';

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  int _idx = 0;

  final _pages = const [
    HomePage(),
    SearchPage(),
    EventPage(),
    SupportPage(),
    ChatListPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_idx],
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
                _NavItem(icon: Icons.home_rounded, label: 'ホーム',
                    selected: _idx == 0, onTap: () => setState(() => _idx = 0)),
                _NavItem(icon: Icons.search_rounded, label: '検索',
                    selected: _idx == 1, onTap: () => setState(() => _idx = 1)),
                _NavItem(icon: Icons.event_rounded, label: 'イベント',
                    selected: _idx == 2, onTap: () => setState(() => _idx = 2)),
                _NavItem(icon: Icons.volunteer_activism_rounded, label: '支援',
                    selected: _idx == 3, onTap: () => setState(() => _idx = 3)),
                _NavItem(icon: Icons.chat_bubble_rounded, label: 'チャット',
                    selected: _idx == 4, onTap: () => setState(() => _idx = 4)),
                _NavItem(icon: Icons.person_rounded, label: 'マイページ',
                    selected: _idx == 5, onTap: () => setState(() => _idx = 5)),
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

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
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
            Icon(icon,
                color: selected
                    ? const Color(0xFFE8845A)
                    : const Color(0xFFBDB5B0),
                size: 24),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: selected
                        ? const Color(0xFFE8845A)
                        : const Color(0xFFBDB5B0),
                    fontWeight: selected
                        ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
