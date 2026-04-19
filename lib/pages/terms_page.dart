import 'package:flutter/material.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('利用規約',
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
                      colors: [Color(0xFF2D6A4F), Color(0xFF52B788)]),
                  borderRadius: BorderRadius.circular(20)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('利用規約📋',
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.w900, color: Colors.white)),
                  SizedBox(height: 6),
                  Text('最終更新日：2026年4月1日',
                      style: TextStyle(fontSize: 12,
                          color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _Section('第1条（適用）',
                'この利用規約は、AniMatch（以下「本サービス」）の利用条件を定めるものです。ユーザーは本規約に同意した上で本サービスをご利用ください。'),
            _Section('第2条（利用資格）',
                '本サービスは以下の方を対象としています：\n\n・18歳以上の方\n・動物を愛する方\n・本規約に同意された方\n\n18歳未満の方の利用はお断りしています。'),
            _Section('第3条（禁止事項）',
                '以下の行為を禁止します：\n\n・動物への虐待・暴力目的での利用\n・食用目的での動物の取引\n・詐欺・金銭目的の行為\n・他のユーザーへのハラスメント\n・虚偽情報の投稿\n・なりすまし行為\n・本サービスの不正利用'),
            _Section('第4条（動物の取り扱い）',
                '本サービスを通じた動物の譲渡・里親募集においては、以下を遵守してください：\n\n・動物愛護管理法を遵守すること\n・動物の福祉を最優先にすること\n・適切な飼育環境を提供できること\n・無責任な飼育放棄をしないこと'),
            _Section('第5条（免責事項）',
                '本サービスは以下について責任を負いません：\n\n・ユーザー間のトラブル\n・サービスの中断・終了\n・情報の正確性\n・第三者サービスの利用'),
            _Section('第6条（アカウントの停止）',
                '以下の場合、予告なくアカウントを停止することがあります：\n\n・本規約違反\n・不正利用\n・他のユーザーへの迷惑行為\n・虚偽情報の登録'),
            _Section('第7条（規約の変更）',
                '本規約は予告なく変更される場合があります。変更後はアプリ内でお知らせします。'),
            _Section('第8条（準拠法）',
                '本規約は日本法に準拠し、日本の裁判所を管轄とします。'),
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
