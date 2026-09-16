import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  static const _features = [
    {
      'emoji': '📸',
      'title': 'ペット自慢',
      'desc': 'うちの子の写真を投稿して、リアクションやコメントをもらえます。動物の種類で絞り込むこともできます。毎月のお題や、週間ランキングもあります。',
    },
    {
      'emoji': '❓',
      'title': '質問掲示板',
      'desc': 'ちょっとした困りごとを投稿して、動物好きのみんなに聞くことができます。',
    },
    {
      'emoji': '🐾',
      'title': 'どうぶつマップ',
      'desc': '保護団体・迷子情報・里親募集・ボランティア・動物病院を、まとめて地図感覚で探せます。',
    },
    {
      'emoji': '🔍',
      'title': '迷子情報',
      'desc': '迷子になったペットの情報を投稿できます。都道府県で絞り込んで、みんなで探すのを手伝えます。',
    },
    {
      'emoji': '🏠',
      'title': '里親募集',
      'desc': '保護団体が投稿する、里親を探している子たちに出会えます。',
    },
    {
      'emoji': '🤝',
      'title': 'ボランティア',
      'desc': '保護団体が募集するボランティア活動に「興味あります」を伝えられます。',
    },
    {
      'emoji': '🏥',
      'title': '動物病院マップ',
      'desc': '対応動物や診療体制で病院を探せます。実際に利用した人がタグを付けて、評判を共有できます。',
    },
    {
      'emoji': '📅',
      'title': 'イベント',
      'desc': '散歩仲間募集など、動物好き同士が集まるイベントに参加・投稿できます。',
    },
    {
      'emoji': '💬',
      'title': 'チャット',
      'desc': '団体や他のユーザーと直接やり取りできます。',
    },
    {
      'emoji': '🔔',
      'title': '通知設定',
      'desc': 'コメントやイベントなど、受け取りたい通知の種類を選べます。',
    },
    {
      'emoji': '🐕',
      'title': 'お世話タスク',
      'desc': '登録したペットごとに、毎日のお世話タスクを記録できます。ホーム画面やペット詳細ページで進み具合が見られます。',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('使い方ガイド 📖',
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFE8845A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: const Text(
                  'AniMatchでできることを、ひとつずつ紹介します🐾',
                  style: TextStyle(fontSize: 13, color: Color(0xFFE8845A))),
            ),
            const SizedBox(height: 16),
            ..._features.map((f) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(f['emoji']!, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(f['title']!,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3D2B1F))),
                        const SizedBox(height: 4),
                        Text(f['desc']!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
