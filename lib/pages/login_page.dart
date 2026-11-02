import 'package:flutter/material.dart';
import '../services/private_account.dart';
import '../widgets/animaru.dart';
import '../widgets/animaru_guide.dart';
import '../widgets/signup_decor.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart';
import 'root_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_setup_page.dart';
import 'organization_login_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'hospital_login_page.dart';



class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
final _emailCtrl = TextEditingController();
final _passCtrl = TextEditingController();
bool _obscurePassword = true;
bool _isLoading = false;

// あにまるの案内（パスワードを入れるときは、目をかくす）
final _passFocus = FocusNode();
String _guideMsg = 'おかえり！\nログインして、うちの子に会いに行こう';
AnimaruMood _guideMood = AnimaruMood.normal;

@override
void initState() {
super.initState();
_passFocus.addListener(() {
if (!mounted) return;
setState(() {
if (_passFocus.hasFocus) {
_guideMsg = 'パスワードは見ないようにしてるよ…！';
_guideMood = AnimaruMood.shy;
} else {
_guideMsg = 'おかえり！\nログインして、うちの子に会いに行こう';
_guideMood = AnimaruMood.normal;
}
});
});
}

@override
void dispose() {
_emailCtrl.dispose();
_passCtrl.dispose();
_passFocus.dispose();
super.dispose();
}

void _showPasswordReset() {
final emailCtrl = TextEditingController();
showDialog(
context: context,
builder: (_) => AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Text('パスワードをリセット'),
content: Column(
mainAxisSize: MainAxisSize.min,
children: [
const Text('登録したメールアドレスを入力してください',
style: TextStyle(fontSize: 13, color: Colors.grey)),
const SizedBox(height: 16),
TextField(
controller: emailCtrl,
keyboardType: TextInputType.emailAddress,
decoration: InputDecoration(
labelText: 'メールアドレス',
border: OutlineInputBorder(
borderRadius: BorderRadius.circular(12)),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.circular(12),
borderSide: const BorderSide(color: Color(0xFFE8845A))),
),
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: const Text('キャンセル',
style: TextStyle(color: Colors.grey)),
),
ElevatedButton(
onPressed: () async {
if (emailCtrl.text.isEmpty) return;
try {
await FirebaseAuth.instance.sendPasswordResetEmail(
email: emailCtrl.text.trim());
if (mounted) {
Navigator.pop(context);
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('パスワードリセットメールを送信しました📧'),
backgroundColor: Color(0xFF2D6A4F),
),
);
}
} on FirebaseAuthException catch (e) {
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text(e.code == 'user-not-found'
? 'このメールアドレスは登録されていません'
: 'エラーが発生しました'),
backgroundColor: Colors.red,
),
);
}
}
},
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFFE8845A),
foregroundColor: Colors.white,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12))),
child: const Text('送信'),
),
],
),
);
}

void _login() async {
if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('メールアドレスとパスワードを入力してください'),
backgroundColor: Colors.red,
),
);
return;
}

setState(() => _isLoading = true);

try {
final userCredential = await FirebaseAuth.instance
.signInWithEmailAndPassword(
email: _emailCtrl.text.trim(),
password: _passCtrl.text.trim(),
);

final uid = userCredential.user?.uid;

final orgDoc = await FirebaseFirestore.instance
    .collection('organizations')
    .doc(uid)
    .get();

if (orgDoc.exists) {
  await FirebaseAuth.instance.signOut();
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('団体・保護主アカウントです。専用のログイン画面からログインしてください'),
        backgroundColor: Colors.orange,
      ),
    );
  }
  return;
}

final hospitalDoc = await FirebaseFirestore.instance
    .collection('hospitals')
    .doc(uid)
    .get();

if (hospitalDoc.exists) {
  await FirebaseAuth.instance.signOut();
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('病院アカウントです。専用のログイン画面からログインしてください'),
        backgroundColor: Colors.orange,
      ),
    );
  }
  return;
}

final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .get();


if (!userDoc.exists) {
if (mounted) {
Navigator.pushReplacement(
context,
MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
);
}
return;
}


// FCMトークン取得
String? fcmToken;
if (!kIsWeb) {
fcmToken = await FirebaseMessaging.instance.getToken();
}

await FirebaseFirestore.instance
.collection('users')
.doc(uid)
.update({
'lastSeen': FieldValue.serverTimestamp(),
});
// 通知の鍵は、本人しか読めない場所に保存する
if (fcmToken != null) await PrivateAccount.saveFcmToken(uid, fcmToken);


if (mounted) {
Navigator.pushAndRemoveUntil(
context,
MaterialPageRoute(builder: (_) => const RootPage()),
(route) => false,
);
}

} on FirebaseAuthException catch (e) {
  String message = 'ログインに失敗しました';
  if (e.code == 'user-not-found') message = 'アカウントが見つかりません';
  if (e.code == 'wrong-password') message = 'パスワードが間違っています';
  if (e.code == 'invalid-email') message = 'メールアドレスの形式が正しくありません';
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
} catch (e) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('エラーが発生しました。もう一度お試しください'),
        backgroundColor: Colors.red,
      ),
    );
  }
} finally {
  if (mounted) setState(() => _isLoading = false);
}
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFFFFFF5F3),
    body: SingleChildScrollView(
      child: Column(
        children: [
          SignupHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('🐾', style: TextStyle(fontSize: 48)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('AniMatch',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white)),
                const Text('Find Your Wild Connection',
                    style: TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 18),
                AnimaruGuide(step: null, message: _guideMsg, mood: _guideMood),
              ],
            ),
          ),


          Padding(
            padding: const EdgeInsets.all(24),
            child: StaggerColumn(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ログイン',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('アカウントにログインしてください',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'メールアドレス',
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: Color(0xFFE8A598)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                      const BorderSide(color: Color(0xFFE8A598)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  focusNode: _passFocus,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'パスワード',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: Color(0xFFE8A598)),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey),
                      onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                      const BorderSide(color: Color(0xFFE8A598)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showPasswordReset(),
                    child: const Text('パスワードを忘れた方',
                        style: TextStyle(color: Color(0xFFE8A598))),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8845A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding:
                      const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : const Text('ログイン',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterPage())),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE8845A),
                      side: const BorderSide(color: Color(0xFFE8845A)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding:
                      const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('新規登録はこちら',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const OrganizationLoginPage())),
                    child: const Text('団体・保護主の方はこちら 🏢',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            decoration: TextDecoration.underline)),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const HospitalLoginPage())),
                    child: const Text('病院・獣医師の方はこちら 🏥',
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            decoration: TextDecoration.underline)),
                  ),
                ),

                const SizedBox(height: 32),

              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
