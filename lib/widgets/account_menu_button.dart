import 'package:flutter/material.dart';

import '../pages/contact_page.dart';
import '../pages/delete_account_page.dart';
import '../pages/privacy_page.dart';
import '../pages/terms_page.dart';

/// 団体・病院のマイページの右上に出す「…」のメニュー。
/// 利用規約・プライバシーポリシー・お問い合わせ・アカウントの削除を開ける
/// （ふつうの利用者はプロフィールの画面から開ける）
class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({super.key, this.color = const Color(0xFF3D2B1F)});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'メニュー',
      icon: Icon(Icons.more_vert_rounded, color: color),
      onSelected: (v) {
        final Widget page = switch (v) {
          'terms' => const TermsPage(),
          'privacy' => const PrivacyPage(),
          'contact' => const ContactPage(),
          _ => const DeleteAccountPage(),
        };
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'terms', child: Text('利用規約')),
        PopupMenuItem(value: 'privacy', child: Text('プライバシーポリシー')),
        PopupMenuItem(value: 'contact', child: Text('お問い合わせ')),
        PopupMenuDivider(),
        PopupMenuItem(
            value: 'delete',
            child: Text('アカウントを削除', style: TextStyle(color: Colors.red))),
      ],
    );
  }
}
