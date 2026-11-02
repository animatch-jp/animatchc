import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/blocked_users.dart';
import '../services/cloudinary_service.dart';
import '../services/content_filter.dart';
import '../widgets/verified_org_mark.dart';
import '../widgets/share_card.dart';
import 'organization_profile_page.dart';
import 'report_page.dart';

// 団体の自由投稿（お知らせ・活動報告など）
// 場所：orgPosts/{id}
// { orgId, orgName, kind, text, imageUrl, createdAt, updatedAt }
// 出せるのは、運営が確認した団体だけ（データを守るルールで止めている）
class OrgPosts {
  static const kinds = <String, String>{
    'news': 'お知らせ',
    'report': '活動報告',
    'event': 'イベントの告知',
    'help': 'おねがい',
  };
  static const kindEmoji = <String, String>{
    'news': '📢',
    'report': '🐾',
    'event': '📅',
    'help': '🙏',
  };
  static const maxText = 500;

  static CollectionReference<Map<String, dynamic>> get col =>
      FirebaseFirestore.instance.collection('orgPosts');

  // 並べかえはアプリの中でする（データベースに「索引」を足さなくても動くように）
  static Query<Map<String, dynamic>> ofOrg(String orgId) =>
      col.where('orgId', isEqualTo: orgId);

  static int _ms(dynamic t) =>
      t is Timestamp ? t.millisecondsSinceEpoch : 9999999999999; // 保存した直後は、いちばん新しい扱い

  static List<QueryDocumentSnapshot<Map<String, dynamic>>> newestFirst(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final l = [...docs];
    l.sort((a, b) => _ms(b.data()['createdAt']).compareTo(_ms(a.data()['createdAt'])));
    return l;
  }

  static Query<Map<String, dynamic>> latest() =>
      col.orderBy('createdAt', descending: true);

  static String timeLabel(dynamic ts) {
    if (ts is! Timestamp) return '';
    final d = ts.toDate();
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'いま';
    if (diff.inHours < 1) return '${diff.inMinutes}分前';
    if (diff.inDays < 1) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';
    return '${d.year}/${d.month}/${d.day}';
  }

  // 投稿・直す画面を開く。保存できたら true
  static Future<bool> openSheet(BuildContext context,
      {required String orgId,
      required String orgName,
      String? docId,
      Map<String, dynamic>? initial}) async {
    final r = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: OrgPostSheet(orgId: orgId, orgName: orgName, docId: docId, initial: initial),
      ),
    );
    return r == true;
  }

  static Future<void> confirmDelete(BuildContext context, String docId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('この投稿を消しますか？'),
        content: const Text('消すと、もとに戻せません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('やめる')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('消す', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await col.doc(docId).delete();
    } catch (e) {
      debugPrint('団体の投稿の削除エラー: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('消せませんでした。もう一度ためしてください')));
      }
    }
  }
}

class OrgPostSheet extends StatefulWidget {
  final String orgId;
  final String orgName;
  final String? docId;
  final Map<String, dynamic>? initial;

  const OrgPostSheet(
      {super.key, required this.orgId, required this.orgName, this.docId, this.initial});

  @override
  State<OrgPostSheet> createState() => _OrgPostSheetState();
}

class _OrgPostSheetState extends State<OrgPostSheet> {
  final _textCtrl = TextEditingController();
  String _kind = 'news';
  String? _imageUrl;
  bool _uploading = false;
  bool _saving = false;

  bool get _isEdit => widget.docId != null;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    if (d != null) {
      _textCtrl.text = (d['text'] ?? '').toString();
      final k = (d['kind'] ?? '').toString();
      if (OrgPosts.kinds.containsKey(k)) _kind = k;
      final img = (d['imageUrl'] ?? '').toString();
      _imageUrl = img.isEmpty ? null : img;
    }
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _uploading = true);
    final url = await CloudinaryService.pickAndUploadImage();
    if (!mounted) return;
    setState(() {
      if (url != null) _imageUrl = url;
      _uploading = false;
    });
  }

  Future<void> _save() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('本文を書いてください')));
      return;
    }
    if (ContentFilter.blocked(context, [text], allowContact: true)) return;
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'kind': _kind,
      'text': text,
      'imageUrl': _imageUrl ?? '',
    };
    try {
      if (_isEdit) {
        await OrgPosts.col
            .doc(widget.docId)
            .update({...body, 'updatedAt': FieldValue.serverTimestamp()});
      } else {
        await OrgPosts.col.add({
          ...body,
          'orgId': widget.orgId,
          'orgName': widget.orgName,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('団体の投稿の保存エラー: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('保存できませんでした。運営の確認が終わっているか、文字が長すぎないかを確かめてください')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_isEdit ? '投稿を直す' : 'お知らせ・活動報告を書く',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('団体のページと、どうぶつマップに出ます',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: OrgPosts.kinds.entries.map((e) {
              final sel = _kind == e.key;
              return ChoiceChip(
                label: Text('${OrgPosts.kindEmoji[e.key]} ${e.value}'),
                selected: sel,
                onSelected: (_) => setState(() => _kind = e.key),
                selectedColor: const Color(0xFF2D6A4F),
                labelStyle: TextStyle(color: sel ? Colors.white : const Color(0xFF3D2B1F)),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _textCtrl,
            maxLines: 6,
            maxLength: OrgPosts.maxText,
            decoration: InputDecoration(
              labelText: '本文 *',
              hintText: '例：今週末、譲渡会をひらきます。／ごはんの寄付をありがとうございました。',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _uploading ? null : _pickImage,
            child: Container(
              width: double.infinity,
              height: _imageUrl == null ? 70 : 180,
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F4), borderRadius: BorderRadius.circular(14)),
              child: _uploading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D6A4F)))
                  : _imageUrl != null
                      ? Stack(children: [
                          Positioned.fill(
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(_imageUrl!, fit: BoxFit.cover)),
                          ),
                          Positioned(
                            top: 6,
                            right: 6,
                            child: IconButton.filledTonal(
                              tooltip: '写真を外す',
                              onPressed: () => setState(() => _imageUrl = null),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ),
                        ])
                      : const Center(
                          child: Text('📸 写真をつける（なくてもOK）',
                              style: TextStyle(color: Colors.grey))),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving || _uploading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(_isEdit ? '保存する' : '投稿する',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// 1つの投稿のカード
class OrgPostCard extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  // 団体の名前を押したら、団体のページを開く（団体のページの中では false）
  final bool showOrgLink;

  const OrgPostCard(
      {super.key, required this.docId, required this.data, this.showOrgLink = true});

  @override
  Widget build(BuildContext context) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final orgId = (data['orgId'] ?? '').toString();
    final orgName = (data['orgName'] ?? '').toString();
    final kind = (data['kind'] ?? 'news').toString();
    final text = (data['text'] ?? '').toString();
    final img = (data['imageUrl'] ?? '').toString();
    final mine = me != null && me == orgId;
    final edited = data['updatedAt'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EFE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 4, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(10)),
                  child: Text('${OrgPosts.kindEmoji[kind] ?? '📢'} ${OrgPosts.kinds[kind] ?? 'お知らせ'}',
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB4642E))),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      '${OrgPosts.timeLabel(data['createdAt'])}${edited ? '（直しました）' : ''}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded, color: Colors.grey[600]),
                  onSelected: (v) async {
                    if (v == 'edit') {
                      await OrgPosts.openSheet(context,
                          orgId: orgId, orgName: orgName, docId: docId, initial: data);
                    } else if (v == 'delete') {
                      await OrgPosts.confirmDelete(context, docId);
                    } else if (v == 'share') {
                      await ShareCard.open(context,
                          imageUrl: img,
                          title: orgName,
                          subtitle: text,
                          label: '${OrgPosts.kindEmoji[kind] ?? ''} ${OrgPosts.kinds[kind] ?? 'お知らせ'}',
                          color: const Color(0xFF2D6A4F));
                    } else if (v == 'report') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReportPage(
                            userName: orgName,
                            targetUid: orgId,
                            contentLabel: '団体のお知らせ・活動報告',
                            contentRef: 'orgPosts/$docId',
                            contentText: text.length > 100 ? text.substring(0, 100) : text,
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => mine
                      ? [
                          const PopupMenuItem(value: 'edit', child: Text('内容を直す')),
                          if (img.isNotEmpty)
                            const PopupMenuItem(value: 'share', child: Text('画像にしてシェア')),
                          const PopupMenuItem(value: 'delete', child: Text('消す')),
                        ]
                      : const [PopupMenuItem(value: 'report', child: Text('この投稿を通報する'))],
                ),
              ],
            ),
          ),
          if (showOrgLink)
            InkWell(
              onTap: orgId.isEmpty
                  ? null
                  : () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => OrganizationProfilePage(orgId: orgId))),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: Row(
                  children: [
                    const Text('🏢 ', style: TextStyle(fontSize: 13)),
                    Flexible(
                      child: Text(orgName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D6A4F))),
                    ),
                    const SizedBox(width: 6),
                    const VerifiedOrgMark(small: true),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Text(text, style: const TextStyle(fontSize: 14, height: 1.6)),
          ),
          if (img.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Image.network(img,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink()),
            ),
        ],
      ),
    );
  }
}

// 1つの団体の投稿の一覧（団体のページ・団体マイページで使う）
class OrgPostList extends StatelessWidget {
  final String orgId;
  final int limit;
  final String emptyText;

  const OrgPostList(
      {super.key,
      required this.orgId,
      this.limit = 10,
      this.emptyText = 'まだお知らせはありません'});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: OrgPosts.ofOrg(orgId).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint('団体の投稿の読みこみエラー: ${snap.error}');
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('お知らせを読みこめませんでした',
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          );
        }
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
                child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2D6A4F)))),
          );
        }
        final docs = OrgPosts.newestFirst(snap.data!.docs).take(limit).toList();
        if (docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(emptyText, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          );
        }
        return Column(
          children: docs
              .map((d) => OrgPostCard(docId: d.id, data: d.data(), showOrgLink: false))
              .toList(),
        );
      },
    );
  }
}

// いろいろな団体の、新しい投稿（どうぶつマップで使う）
class LatestOrgPosts extends StatefulWidget {
  final int limit;
  const LatestOrgPosts({super.key, this.limit = 5});

  @override
  State<LatestOrgPosts> createState() => _LatestOrgPostsState();
}

class _LatestOrgPostsState extends State<LatestOrgPosts> {
  // 1回だけ読む（いつも新しく読み続けると、読みこみ回数がふえるため）
  late Future<QuerySnapshot<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = OrgPosts.latest().limit(widget.limit).get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snap) {
        if (snap.hasError) {
          debugPrint('団体の新しい投稿の読みこみエラー: ${snap.error}');
          return const SizedBox.shrink();
        }
        if (!snap.hasData) return const SizedBox.shrink();
        final docs = snap.data!.docs
            .where((d) => !BlockedUsers.instance.isBlocked(d.data()['orgId']))
            .toList();
        if (docs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text('📢 団体のお知らせ・活動報告',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
            ),
            ...docs.map((d) => OrgPostCard(docId: d.id, data: d.data())),
          ],
        );
      },
    );
  }
}
