import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import '../models/match.dart';
import 'chat_page.dart';

class MatchListPage extends StatefulWidget {
  const MatchListPage({super.key});

  @override
  State<MatchListPage> createState() => _MatchListPageState();
}

class _MatchListPageState extends State<MatchListPage> {
  List<Match> _matches = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = AppProvider();
    _matches = provider.matches;
  }

  @override
  Widget build(BuildContext context) {
    final provider = AppProvider();
    final matches = provider.matches;

    return Scaffold(
      appBar: AppBar(
        title: Text('マッチ一覧（${matches.length}件）'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: matches.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('💕', style: TextStyle(fontSize: 52)),
            SizedBox(height: 12),
            Text('まだマッチがいません',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            SizedBox(height: 6),
            Text('スワイプしていいねしよう！',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      )
          : ListView.builder(
        itemCount: matches.length,
        itemBuilder: (_, i) {
          final m = matches[i];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(m.pet.avatarPath,
                  width: 52, height: 52, fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => Container(
                      width: 52, height: 52, color: Colors.orange[50],
                      child: const Center(child: Text('🐾')))),
            ),
            title: Text(m.pet.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
                'オーナー: ${m.pet.owner}さん・${m.pet.ownerCity}'),
            trailing: const Icon(Icons.chat_bubble_outline,
                color: Color(0xFFE8A598)),
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ChatPage(
                userName: m.pet.name,
                userEmoji: '🐾',
              ),

            )),
          );
        },
      ),
    );
  }
}
