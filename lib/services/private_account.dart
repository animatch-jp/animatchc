import 'package:cloud_firestore/cloud_firestore.dart';

/// メールアドレスや通知の鍵（FCMトークン）など、本人と運営しか見てはいけないものを置く場所。
/// 利用者：users/{uid}/private/account
/// 団体・病院：organizations/{id}/private/contact ・ hospitals/{id}/private/contact
/// （みんなが読める場所に置かないため。データを守るルールでも止めている）
class PrivateAccount {
  static DocumentReference<Map<String, dynamic>> userRef(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('private').doc('account');

  static DocumentReference<Map<String, dynamic>> contactRef(String collection, String id) =>
      FirebaseFirestore.instance.collection(collection).doc(id).collection('private').doc('contact');

  /// 通知の鍵を、本人だけが読める場所に保存する
  static Future<void> saveFcmToken(String uid, String token) async {
    if (token.isEmpty) return;
    try {
      await userRef(uid).set({'fcmToken': token, 'updatedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true));
    } catch (_) {}
  }

  /// 前の版で、みんなが読めるプロフィールに入っていたメールと通知の鍵を、本人だけの場所へ移す
  static Future<void> moveOldFields(String uid) async {
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(uid);
      final snap = await ref.get();
      final d = snap.data();
      if (d == null) return;
      final hasEmail = d.containsKey('email');
      final hasToken = d.containsKey('fcmToken');
      if (!hasEmail && !hasToken) return;
      final keep = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
      if (hasEmail && d['email'] is String) keep['email'] = d['email'];
      if (hasToken && d['fcmToken'] is String && (d['fcmToken'] as String).isNotEmpty) {
        keep['fcmToken'] = d['fcmToken'];
      }
      await userRef(uid).set(keep, SetOptions(merge: true));
      await ref.update({
        if (hasEmail) 'email': FieldValue.delete(),
        if (hasToken) 'fcmToken': FieldValue.delete(),
      });
    } catch (_) {}
  }

  /// 運営の画面で、団体・病院のメールを読む（前の版のデータは、本体の email を使う）
  static Future<String> contactEmail(String collection, String id, Map<String, dynamic> data) async {
    try {
      final s = await contactRef(collection, id).get();
      final e = s.data()?['email'];
      if (e is String && e.isNotEmpty) return e;
    } catch (_) {}
    final old = data['email'];
    return old is String ? old : '';
  }
}
