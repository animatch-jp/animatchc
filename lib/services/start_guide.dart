import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 「はじめてのこと」の進みぐあい（本人しか読めない users/{uid}/private/onboarding）
// orgSeen: 団体のページを1つ見た / dismissed: 案内を閉じた
class StartGuide {
  static bool _orgSeenSaved = false;

  static DocumentReference<Map<String, dynamic>>? _ref() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('private')
        .doc('onboarding');
  }

  static Future<Map<String, dynamic>> load() async {
    final r = _ref();
    if (r == null) return {};
    final d = await r.get();
    return d.data() ?? {};
  }

  // 団体のページを開いたとき（1回だけ書く）
  static Future<void> markOrgSeen() async {
    if (_orgSeenSaved) return;
    _orgSeenSaved = true;
    try {
      await _ref()?.set({'orgSeen': true}, SetOptions(merge: true));
    } catch (_) {}
  }

  static Future<void> dismiss() async {
    try {
      await _ref()?.set({'dismissed': true}, SetOptions(merge: true));
    } catch (_) {}
  }
}
