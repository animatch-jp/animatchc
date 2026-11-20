// はじめての5分（11/20 社長「アプリを始めた時から、またやりたい要素を」）
//
// 1. 入口：登録の前に、好きな動物をえらんで、いまのイベントやできることを見られる
// 2. 最初の1枚：登録したら、うちの子の写真をすぐみんなに見せられる（firstPost: true）
// 3. はじめましての列：ホームのいちばん上に、はじめて投稿した子が並ぶ。みんなが最初の反応を送れる
// 4. 明日の約束：反応が届いたらお知らせしていいかを聞き、明日のお題を見せて終わる
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../widgets/event_board.dart';
import '../widgets/signup_decor.dart' show signupRoute;
import '../services/cloudinary_service.dart';
import '../services/content_filter.dart';
import '../services/blocked_users.dart';
import 'hiroba_data.dart' show liveOnlineEvents, upcomingOnlineEvents, OnlineEvent;
import 'pet_themes.dart';
import 'pet_brag_page.dart' show petBragFreeSlot, showPostDetail;
import 'register_page.dart';
import 'login_page.dart';
import 'welcome_page.dart';

const _orange = Color(0xFFE8845A);
const _brown = Color(0xFF3D2B1F);
const _cream = Color(0xFFFFF8F5);

/// 入口でえらんだ好きな動物（登録の画面で、最初からえらばれた状態にする）
class FirstSteps {
  static List<String> pickedAnimals = [];
}

/// 登録の画面の「好きな動物」と同じ名前
const _animalChoices = [
  ('犬', '🐶'),
  ('猫', '🐱'),
  ('うさぎ', '🐰'),
  ('鳥', '🐦'),
  ('ハムスター', '🐹'),
  ('モルモット', '🐾'),
  ('シマリス', '🐿️'),
  ('爬虫類', '🦎'),
  ('その他', '🐟'),
];

// ============================================================
// 1. 入口（ログインしていない人が最初に見る）
// ============================================================

class FirstLookPage extends StatefulWidget {
  const FirstLookPage({super.key});

  @override
  State<FirstLookPage> createState() => _FirstLookPageState();
}

class _FirstLookPageState extends State<FirstLookPage> {
  final Set<String> _picked = {};
  bool _showPreview = false;

  void _start() {
    FirstSteps.pickedAnimals = _picked.toList();
    Navigator.push(context, signupRoute(const RegisterPage()));
  }

  void _login() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _showPreview ? _preview() : _pick(),
        ),
      ),
    );
  }

  Widget _pick() {
    return ListView(
      key: const ValueKey('pick'),
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
      children: [
        const Text('好きな動物は？',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: _brown)),
        const SizedBox(height: 8),
        Text('いくつでもえらべます。いっしょに暮らしていなくても大丈夫です',
            style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final a in _animalChoices)
              _AnimalChip(
                emoji: a.$2,
                label: a.$1,
                selected: _picked.contains(a.$1),
                onTap: () => setState(() {
                  _picked.contains(a.$1) ? _picked.remove(a.$1) : _picked.add(a.$1);
                }),
              ),
          ],
        ),
        const SizedBox(height: 32),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _picked.isEmpty ? null : () => setState(() => _showPreview = true),
          child: const Text('のぞいてみる', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _login,
          child: const Text('アカウントがある人は、ログイン', style: TextStyle(color: _brown)),
        ),
      ],
    );
  }

  Widget _preview() {
    final now = DateTime.now();
    final events = <OnlineEvent>[
      ...liveOnlineEvents(now),
      ...upcomingOnlineEvents(now),
    ].take(3).toList();
    final names = _picked.join('・');
    return CorkBoard(
      key: const ValueKey('preview'),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 32),
        children: [
          Row(children: [
            IconButton(
              onPressed: () => setState(() => _showPreview = false),
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            ),
            const Expanded(
              child: Text('いまのAniMatch',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 12),
          for (var i = 0; i < events.length; i++) ...[
            PaperFlyer(
              angle: i.isEven ? -1.2 : 1.0,
              color: [kPaperYellow, kPaperWhite, kPaperBlue][i % 3],
              child: Row(children: [
                Text(events[i].emoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(events[i].isLive(now) ? 'いま開催中' : 'このあと',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: events[i].isLive(now) ? kPinRed : Colors.grey[700])),
                    Text(events[i].title,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: kInk)),
                    Text(events[i].howTo, style: const TextStyle(fontSize: 12, color: kInk, height: 1.4)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 18),
          ],
          PaperFlyer(
            attach: FlyerAttach.tape,
            angle: 0.6,
            color: kPaperPink,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$names好きの人と、こんなことができます',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: kInk)),
              const SizedBox(height: 10),
              for (final t in const [
                ('📸', 'うちの子の写真に「かわいい」「癒される」が届く'),
                ('🐾', '同じ動物の部屋で、スタンプ1つから話に入れる'),
                ('🎪', '写真大会や話しあい会に、スタンプ1つで参加できる'),
                ('🏠', '近くの里親募集・迷子・譲渡会をすぐ知れる'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(t.$1, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(t.$2,
                            style: const TextStyle(fontSize: 14, color: kInk, height: 1.4))),
                  ]),
                ),
            ]),
          ),
          const SizedBox(height: 26),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _orange,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _start,
            child: const Text('1分ではじめる', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _login,
            child: const Text('アカウントがある人は、ログイン', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _AnimalChip extends StatelessWidget {
  const _AnimalChip(
      {required this.emoji, required this.label, required this.selected, required this.onTap});
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _orange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _orange : const Color(0xFFEADBD2), width: 2),
        ),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : _brown)),
        ]),
      ),
    );
  }
}

// ============================================================
// 2. 最初の1枚（登録が終わったあと）
// ============================================================

/// うちの子の種類を、ランキングの動物の種類に合わせる
String? _rankAnimal(String type) {
  if (type.contains('犬')) return '犬';
  if (type.contains('猫')) return '猫';
  if (type.contains('うさぎ')) return 'うさぎ';
  if (type.contains('鳥') || type.contains('インコ')) return '小鳥';
  if (type.contains('ハムスター') || type.contains('モルモット') || type.contains('リス')) {
    return 'ハムスター・小動物';
  }
  if (type.contains('フェレット')) return 'フェレット';
  if (type.contains('爬虫') || type.contains('トカゲ') || type.contains('ヘビ') || type.contains('カメ')) {
    return '爬虫類';
  }
  return null;
}

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 明日のお題（getTodayThemes と同じ決め方で、1日先）
String tomorrowTheme() {
  final days = DateTime.now().add(const Duration(days: 1)).difference(DateTime(2026, 1, 1)).inDays;
  return petBragThemes[days % petBragThemes.length];
}

class FirstPhotoPage extends StatefulWidget {
  const FirstPhotoPage({super.key, this.petCount = 0});
  final int petCount;

  @override
  State<FirstPhotoPage> createState() => _FirstPhotoPageState();
}

class _FirstPhotoPageState extends State<FirstPhotoPage> {
  Map<String, dynamic>? _pet;
  String? _petId;
  String? _imageUrl;
  bool _loading = true;
  bool _uploading = false;
  bool _posting = false;
  bool _posted = false;
  final _commentCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPet();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPet() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('pets')
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        _pet = snap.docs.first.data();
        _petId = snap.docs.first.id;
        final img = (_pet!['imageUrl'] as String?) ?? '';
        if (img.isNotEmpty) _imageUrl = img;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pick() async {
    setState(() => _uploading = true);
    final url = await CloudinaryService.pickAndUploadImage();
    if (!mounted) return;
    setState(() {
      if (url != null) _imageUrl = url;
      _uploading = false;
    });
  }

  Future<void> _post() async {
    if (ContentFilter.blocked(context, [_commentCtrl.text])) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _imageUrl == null || _pet == null) return;
    setState(() => _posting = true);
    try {
      final dateKey = _dateKey(DateTime.now());
      final id = await petBragFreeSlot('${uid}_d_${dateKey}_', 3);
      if (id == null) throw StateError('limit');
      await FirebaseFirestore.instance.collection('petBrags').doc(id).set({
        'uid': uid,
        'petId': _petId,
        'petName': ((_pet!['name'] as String?) ?? '').trim(),
        'imageUrl': _imageUrl,
        'comment': _commentCtrl.text.trim(),
        'theme': getTodayThemes().first,
        'animalType': _rankAnimal((_pet!['type'] as String?) ?? ''),
        'dateKey': dateKey,
        'createdAt': FieldValue.serverTimestamp(),
        'votes': {'kawaii': 0, 'omoshiroi': 0, 'iyashi': 0},
        'voteCount': 0,
        'commentCount': 0,
        'firstPost': true, // ホームの「はじめまして」の列に出す
      });
      if (mounted) setState(() => _posted = true);
    } catch (e) {
      debugPrint('最初の1枚の投稿エラー: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('投稿できませんでした。あとでホームから出せます')));
    }
    if (mounted) setState(() => _posting = false);
  }

  void _finish() {
    Navigator.pushAndRemoveUntil(
      context,
      signupRoute(WelcomePage(petCount: widget.petCount)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _orange))
            : _posted
                ? _AfterFirstPost(onDone: _finish)
                : (_pet == null ? _noPet() : _withPet()),
      ),
    );
  }

  Widget _withPet() {
    final name = (_pet!['name'] as String?) ?? 'うちの子';
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      children: [
        Text('$nameを、みんなに見せよう',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _brown)),
        const SizedBox(height: 6),
        Text('はじめての1枚は、ホームの「はじめまして」の列に出ます。みんなから最初の反応が届きます',
            style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: _uploading ? null : _pick,
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFEADBD2), width: 2),
                image: _imageUrl == null
                    ? null
                    : DecorationImage(image: NetworkImage(_imageUrl!), fit: BoxFit.cover),
              ),
              child: _uploading
                  ? const Center(child: CircularProgressIndicator(color: _orange))
                  : _imageUrl == null
                      ? const Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('📷', style: TextStyle(fontSize: 44)),
                          SizedBox(height: 6),
                          Text('写真をえらぶ', style: TextStyle(color: _brown, fontWeight: FontWeight.bold)),
                        ]))
                      : null,
            ),
          ),
        ),
        if (_imageUrl != null)
          TextButton(
            onPressed: _uploading ? null : _pick,
            child: const Text('ほかの写真にする', style: TextStyle(color: _brown)),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _commentCtrl,
          maxLength: 100,
          decoration: InputDecoration(
            hintText: 'ひとこと（なくてもOK）',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: (_imageUrl == null || _posting) ? null : _post,
          child: _posting
              ? const SizedBox(
                  width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('みんなに見せる', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ),
        TextButton(
          onPressed: _finish,
          child: Text('あとで', style: TextStyle(color: Colors.grey[600])),
        ),
      ],
    );
  }

  Widget _noPet() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      children: [
        const Text('はじめましての子に、🐾を送ってみよう',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: _brown)),
        const SizedBox(height: 6),
        Text('写真を押すと、「かわいい」「おもしろい」「癒される」を送れます。送られた人は、とてもうれしいです',
            style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5)),
        const SizedBox(height: 16),
        const NewFacesGrid(),
        const SizedBox(height: 18),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () async {
            await askNotifyPermission();
            _finish();
          },
          child: const Text('ホームへ', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

/// お知らせの許可をたずねる（Webなどでできないときは、何もしない）
Future<void> askNotifyPermission() async {
  try {
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
  } catch (_) {}
}

class _AfterFirstPost extends StatelessWidget {
  const _AfterFirstPost({required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      children: [
        const Center(child: Text('🎉', style: TextStyle(fontSize: 64))),
        const SizedBox(height: 10),
        const Center(
          child: Text('みんなに見せました！',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: _brown)),
        ),
        const SizedBox(height: 8),
        Text('「はじめまして」の列に出ています。反応が届いたら、お知らせしてもいいですか？',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5)),
        const SizedBox(height: 22),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _orange,
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () async {
            await askNotifyPermission();
            onDone();
          },
          child: const Text('お知らせを受けとる', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ),
        TextButton(
          onPressed: onDone,
          child: Text('あとで', style: TextStyle(color: Colors.grey[600])),
        ),
        const SizedBox(height: 24),
        PaperFlyer(
          attach: FlyerAttach.tape,
          color: kPaperYellow,
          angle: -0.8,
          child: Column(children: [
            const Text('明日のお題', style: TextStyle(fontSize: 12, color: kInk, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(tomorrowTheme(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kInk)),
            const SizedBox(height: 4),
            const Text('明日、1枚とってみてね', style: TextStyle(fontSize: 12, color: kInk)),
          ]),
        ),
      ],
    );
  }
}

// ============================================================
// 3. はじめましての列（ホームのいちばん上）
// ============================================================

Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _newFaces() {
  // 新しい投稿60件から、はじめての1枚だけをえらぶ（新しい組み合わせの索引を作らずにすむ）
  final since = DateTime.now().subtract(const Duration(days: 7));
  return FirebaseFirestore.instance
      .collection('petBrags')
      .orderBy('createdAt', descending: true)
      .limit(60)
      .snapshots()
      .map((s) => s.docs.where((d) {
            final data = d.data();
            if (data['firstPost'] != true) return false;
            if (BlockedUsers.instance.isBlocked(data['uid'])) return false;
            final t = data['createdAt'];
            return t is! Timestamp || t.toDate().isAfter(since);
          }).take(12).toList());
}

class NewFacesRow extends StatelessWidget {
  const NewFacesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: _newFaces(),
      builder: (context, snap) {
        final docs = snap.data ?? const [];
        if (docs.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('👋 はじめましての子',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _brown)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: Text('最初の反応を送ってあげよう',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _FaceTile(doc: docs[i], size: 96),
              ),
            ),
          ]),
        );
      },
    );
  }
}

class NewFacesGrid extends StatelessWidget {
  const NewFacesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
      stream: _newFaces(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(color: _orange)),
          );
        }
        final docs = snap.data!;
        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Text('いまは、はじめましての子がいません。ホームで、みんなの写真に反応してみてください',
                style: TextStyle(color: _brown, height: 1.5)),
          );
        }
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final d in docs.take(9)) _FaceTile(doc: d, size: 100)],
        );
      },
    );
  }
}

class _FaceTile extends StatelessWidget {
  const _FaceTile({required this.doc, required this.size});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final double size;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final img = (data['imageUrl'] as String?) ?? '';
    final votes = (data['voteCount'] as num?)?.toInt() ?? 0;
    return GestureDetector(
      onTap: () => showPostDetail(context, doc.id),
      child: SizedBox(
        width: size,
        child: Column(children: [
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: img.isEmpty
                  ? Container(width: size, height: size, color: Colors.white,
                      child: const Center(child: Text('🐾', style: TextStyle(fontSize: 30))))
                  : Image.network(img, width: size, height: size, fit: BoxFit.cover),
            ),
            if (votes == 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(8)),
                  child: const Text('はじめて', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
          ]),
          const SizedBox(height: 4),
          Text((data['petName'] as String?) ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _brown)),
        ]),
      ),
    );
  }
}
