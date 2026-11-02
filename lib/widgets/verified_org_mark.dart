import 'package:flutter/material.dart';

/// 「運営が確認した団体」の印。里親募集・ボランティア募集は、運営が承認した団体しか出せない
/// （データを守るルールで止めている）ので、その投稿にはいつもこの印をつける。
class VerifiedOrgMark extends StatelessWidget {
  const VerifiedOrgMark({super.key, this.small = false});
  final bool small;

  @override
  Widget build(BuildContext context) {
    final fs = small ? 10.0 : 11.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2D6A4F).withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: fs + 3, color: const Color(0xFF2D6A4F)),
          const SizedBox(width: 3),
          Text('確認ずみ団体',
              style: TextStyle(fontSize: fs, fontWeight: FontWeight.bold, color: const Color(0xFF2D6A4F))),
        ],
      ),
    );
  }
}
