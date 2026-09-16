import 'package:flutter/material.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('プライバシーポリシー',
            style: TextStyle(fontWeight: FontWeight.w900,
                color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFE8845A), Color(0xFFF4A261)]),
                  borderRadius: BorderRadius.circular(20)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('プライバシーポリシー🔐',
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w900, color: Colors.white)),
                  SizedBox(height: 8),
                  Text('あなたの情報を、どう扱うか説明します',
                      style: TextStyle(fontSize: 13, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('最終更新日：2026年7月31日',
                      style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _Section('1. このアプリについて',
                'かんたんに言うと：AniMatchは、動物が好きな人たちが、ペットの写真をシェアしたり、里親募集やボランティア、迷子の子を探すお手伝いをしたりできる場所です。\n\nこのページでは、AniMatchがあなたのどんな情報を集めて、どう使うのかを、できるだけわかりやすく説明します。'),
            _Section('2. どんな情報を集めるの？',
                'かんたんに言うと：登録するときに入力してもらう情報や、アプリを使う中で自然に生まれる情報です。\n\n・名前やニックネーム\n・メールアドレス\n・プロフィール写真\n・登録したペットの情報\n・投稿した写真やコメント\n・都道府県などの地域情報（迷子情報や病院を探しやすくするため）\n・アプリの使い方の記録（不具合を直したり、使いやすくするため）'),
            _Section('3. 何のために使うの？',
                'かんたんに言うと：アプリをちゃんと動かすため、そしてもっと使いやすくするためです。\n\n・投稿や里親募集、迷子情報などの機能を提供するため\n・本当に本人かどうか確認するため\n・アプリの不具合を直したり、新しい機能を作るため\n・悪意のある行動（なりすまし、迷惑行為など）を防ぐため\n・お問い合わせに答えるため'),
            _Section('4. 他の人や会社に渡すことはある？',
                'かんたんに言うと：基本的には渡しません。ただし、例外が3つだけあります。\n\n・あなた自身が「渡していいよ」と了承した場合\n・法律で決められている場合（裁判所からの命令など）\n・誰かの命や安全に関わる、緊急の場合'),
            _Section('5. 情報はちゃんと守られているの？',
                'かんたんに言うと：はい、大事に扱っています。\n\n情報が漏れたり、勝手に書き換えられたりしないよう、できる限りの対策をしています。'),
            _Section('6. Cookie（クッキー）について',
                'かんたんに言うと：アプリを使いやすくするための、小さな記録です。\n\nブラウザの設定で、オフにすることもできます。'),
            _Section('7. 何歳から使えるの？',
                '・13歳未満の方は、残念ながらご利用いただけません。\n・13歳以上18歳未満の方は、保護者の方と相談したうえで使ってください。\n・18歳以上の方は、自由にご利用いただけます。\n\nAniMatchには、恋愛や出会いを目的とした機能、知らない人同士を直接つなげる機能はありません。安心して、動物の話を楽しんでください。'),
            _Section('8. このページの内容が変わることはある？',
                'かんたんに言うと：あります。\n\n法律が変わったり、新しい機能が増えたりしたら、この内容を見直すことがあります。変わったときは、アプリ内でお知らせします。'),
            _Section('9. 他のサービスも使っています',
                'AniMatchは、次のサービスを使って作られています：\n\n・Firebase（Google社）- データの保存・ログイン機能\n・Cloudinary - 写真の保存\n\nこれらのサービスにも、それぞれのプライバシーポリシーがあります。'),
            _Section('10. 何か聞きたいことがあったら',
                'わからないことや、心配なことがあれば、いつでも連絡してください。\n\nAniMatch運営事務局\nanimatch.jp@gmail.com'),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16)),
              child: const Text(
                  'AniMatch運営事務局\n© 2026 AniMatch All Rights Reserved.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
class _Section extends StatelessWidget {
  final String title;
  final String content;
  const _Section(this.title, this.content);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2B1F))),
          const SizedBox(height: 8),
          Text(content,
              style: TextStyle(fontSize: 13,
                  color: Colors.grey[600], height: 1.7)),
        ],
      ),
    );
  }
}
