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
                  SizedBox(height: 6),
                  Text('最終更新日：2026年4月1日',
                      style: TextStyle(fontSize: 12,
                          color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _Section('1. はじめに',
                'AniMatch（以下「本アプリ」）は、動物好きの方々が安心して利用できるマッチングサービスです。本プライバシーポリシーは、本アプリが収集する個人情報の取り扱いについて説明します。'),
            _Section('2. 収集する情報',
                '本アプリは以下の情報を収集することがあります：\n\n・氏名・ニックネーム\n・メールアドレス\n・プロフィール画像\n・ペットの情報\n・位置情報（任意）\n・利用履歴・行動履歴'),
            _Section('3. 情報の利用目的',
                '収集した情報は以下の目的で利用します：\n\n・マッチングサービスの提供\n・本人確認\n・サービスの改善\n・不正利用の防止\n・お問い合わせへの対応'),
            _Section('4. 情報の共有',
                '以下の場合を除き、第三者への個人情報の提供は行いません：\n\n・ユーザーの同意がある場合\n・法令に基づく場合\n・生命・身体の安全に関わる場合'),
            _Section('5. 情報の保護',
                '個人情報の漏洩・紛失・改ざんを防ぐため、適切なセキュリティ対策を講じています。'),
            _Section('6. Cookieの使用',
                'より良いサービス提供のため、Cookieを使用することがあります。ブラウザの設定でCookieを無効にすることができます。'),
            _Section('7. 未成年者の利用',
                '本アプリは18歳以上の方を対象としています。18歳未満の方の利用はお断りしています。'),
            _Section('8. プライバシーポリシーの変更',
                '本ポリシーは予告なく変更される場合があります。変更後はアプリ内でお知らせします。'),
            _Section('9. お問い合わせ',
                'プライバシーに関するお問い合わせは、アプリ内のお問い合わせフォームよりご連絡ください。'),
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
