import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ログインを忘れないための、みんなで使う部品（ふつうの人・団体・病院のどの画面でも同じものを使う）

/// 「メールアドレスを忘れた方」を押したときの案内
void showEmailHelp(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('メールアドレスを忘れたとき'),
      content: const Text(
          '・スマホにパスワードを保存していれば、メールアドレスの欄を押すと候補が出ます。\n'
          '・よく使うメールアドレスを、1つずつ「パスワードを忘れた方」に入れてみてください。登録したアドレスなら、作り直しのメールが届きます。\n\n'
          'それでもわからないときは、animatch.jp@gmail.com へ、アプリで使っていた名前（団体・病院は団体名・病院名）を書いて送ってください。'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('とじる')),
      ],
    ),
  );
}

/// ログアウトの確かめる画面に出す文（ログインに使うメールアドレスを見せる）
Widget logoutNoteText() {
  final email = FirebaseAuth.instance.currentUser?.email ?? '';
  return Text('もう一度ログインするときは、このメールアドレスとパスワードを使います。\n'
      '$email\n\n'
      'パスワードを忘れたときは、ログイン画面の「パスワードを忘れた方」から作り直せます。');
}
