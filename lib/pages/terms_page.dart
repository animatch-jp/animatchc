import 'package:flutter/material.dart';
import '../services/legal_info.dart';

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
                  SizedBox(height: 8),
                  Text('みんなが気持ちよく使うための、大事な約束です',
                      style: TextStyle(fontSize: 13, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('最終更新日：${LegalInfo.displayDate}',
                      style: TextStyle(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _Section('第1条　この規約について',
                'この利用規約は、AniMatch（以下「本サービス」）を使うときの、みんなで守るルールです。\n\nAniMatchを使い始めたら、この規約に同意したものとします。'),
            _Section('第2条　誰が使えるの？',
                '・13歳未満の方は、ご利用いただけません。\n・13歳以上18歳未満の方は、必ず保護者の方の同意を得たうえで、ご利用ください。\n・イベントの主催・参加は、18歳以上の方に限ります。\n・登録するときは、正しい生年月日を入力してください。いつわって登録することは禁止です。\n・動物が好きで、この規約を守れる方が対象です。'),
            _Section('第3条　やってはいけないこと',
                'AniMatchを、みんなが安心して使える場所にするために、次のことは禁止します：\n\n・動物を傷つけたり、いじめたりする目的での利用\n・動物を食用として売買すること\n・お金をだまし取ろうとする行為\n・他の人を傷つける言葉や、いじめ\n・うそや、事実と違う情報を投稿すること\n・他の人になりすますこと\n・恋愛や出会いを目的とした利用\n・他の人の住所・電話番号・顔写真などを、本人の許可なく書き込むこと\n・営業や勧誘を目的とした投稿（運営が認めたものを除く）\n・アプリの仕組みを悪用すること'),
            _Section('第4条　里親募集・保護活動について',
                'AniMatchを通じて、動物の里親を探したり、保護活動をしたりするときは、次のことを守ってください：\n\n・動物愛護管理法という法律を守ること\n・動物にとって、一番いい環境を考えること\n・きちんと最後まで育てられる状況で、里親になること\n・無責任に飼うのをやめたりしないこと'),
            _Section('第5条　イベントについて',
                'AniMatchのイベントは、ユーザー同士が、動物をきっかけに集まるためのものです。\n\n・イベントの主催・参加は、18歳以上の方に限ります。\n・イベントを開くのは、運営ではなく、ユーザー（主催者）です。運営は、イベントの内容や安全を保証しません。\n・はじめて会う人との集まりです。不安を感じたときは、無理に参加しないでください。住所などの個人情報は、むやみに教えないでください。\n・参加をキャンセルするときは、できるだけ早く、アプリから手続きしてください。キャンセルをくり返すと、イベントへの参加を制限することがあります。\n・主催者は、ルールを守らない参加者を、イベントから外すことができます。'),
            _Section('第6条　運営が責任を持てないこと',
                '申し訳ありませんが、AniMatch運営は、次のことについて責任を持つことができません：\n\n・ユーザー同士のトラブル\n・イベントの当日に起きた事故やトラブル\n・アプリが一時的に止まったり、終了したりすること\n・投稿された情報が、100％正しいこと\n・AniMatchが使っている他社サービスに関すること\n\nただし、運営に故意または重大な過失があった場合は、この限りではありません。'),
            _Section('第7条　アカウントの停止・投稿の削除',
                'もし次のようなことがあった場合、事前に連絡せず、アカウントの利用を止めたり、投稿やイベントを削除したりすることがあります：\n\n・この規約を守っていないとき\n・不正な使い方をしているとき\n・他の人に迷惑をかけているとき\n・うその情報や、いつわった生年月日を登録しているとき'),
            _Section('第8条　規約が変わることについて',
                'この規約は、必要に応じて変わることがあります。変わったときは、アプリの中でお知らせします。'),
            _Section('第9条　法律について',
                'この規約は、日本の法律にもとづいています。何かトラブルがあったときは、日本の裁判所で解決します。'),
            _Section('第10条　著作権について',
                'アプリの中のデザイン・ロゴ・文章などは、AniMatch運営のものです。許可なく、コピーしたり、他の場所で使ったりしないでください。\n\nユーザーが投稿した写真や文章の権利は、投稿した人にあります。ただし、AniMatchの中で表示したり、紹介したりするために必要な範囲で使うことを、許可していただきます。'),
            _Section('第11条　お金について',
                '現在、AniMatchは無料でご利用いただけます。\n\n将来、新しい機能やサービスを追加する場合は、その内容や条件を、あらためてこの規約でお知らせします。'),
            _Section('第12条　何か聞きたいことがあったら',
                'わからないことがあれば、いつでも連絡してください。\n\nAniMatch運営事務局\nanimatch.jp@gmail.com'),
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