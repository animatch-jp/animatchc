import 'dart:async';
import '../widgets/animaru_loading.dart';
import '../services/content_filter.dart';
import 'package:flutter/material.dart';
import '../widgets/login_help.dart';
import '../services/private_account.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import '../services/cloudinary_service.dart';
import 'organization_chat_list_page.dart';
import 'prefectures.dart';
import 'notification_page.dart';
import 'lost_pet_page.dart';
import 'volunteer_page.dart';
import 'adoption_page.dart';
import 'org_posts.dart';
import '../widgets/account_menu_button.dart';
import '../widgets/share_card.dart';

class OrganizationHomePage extends StatefulWidget {
  const OrganizationHomePage({super.key});

  @override
  State<OrganizationHomePage> createState() => _OrganizationHomePageState();
}

class _OrganizationHomePageState extends State<OrganizationHomePage> {
  Map<String, dynamic>? _orgData;
  bool _isLoading = true;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatSub;
  Timer? _ticker;
  int _unreadTotal = 0;
  int _waitingCount = 0;
  int _overdueCount = 0;

  @override
  void initState() {
    super.initState();
    _loadOrgData();
    _listenChats();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _loadOrgData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(uid)
        .get();
    PrivateAccount.moveContactEmail('organizations', uid, doc.data());
    if (mounted) {
      setState(() {
        _orgData = doc.data();
        _isLoading = false;
      });
    }
  }

  void _listenChats() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    _chatSub = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: myUid)
        .snapshots()
        .listen((snap) {
      var unread = 0;
      var waiting = 0;
      var overdue = 0;
      final now = DateTime.now();
      for (final doc in snap.docs) {
        final data = doc.data();

        final unreadMap = data['unread'];
        if (unreadMap is Map) {
          final v = unreadMap[myUid];
          if (v is num) unread += v.toInt();
        }

        if (data['status'] == 'done') continue;
        final lastSender = data['lastSenderId'] as String?;
        // 古いチャット（lastSenderIdなし）は数えない
        if (lastSender == null || lastSender == myUid) continue;
        waiting++;
        final at = data['lastMessageAt'];
        if (at is Timestamp && now.difference(at.toDate()).inHours >= 24) {
          overdue++;
        }
      }
      if (!mounted) return;
      setState(() {
        _unreadTotal = unread;
        _waitingCount = waiting;
        _overdueCount = overdue;
      });
    }, onError: (_) {});
  }

  void _showAdoptionPostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _AdoptionPostSheet(
          orgId: FirebaseAuth.instance.currentUser?.uid ?? '',
          orgName: _orgData?['name'] ?? '',
          onPosted: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showEditOrgSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _EditOrgSheet(
          orgId: FirebaseAuth.instance.currentUser?.uid ?? '',
          currentData: _orgData ?? {},
          onSaved: () {
            Navigator.pop(context);
            _loadOrgData();
          },
        ),
      ),
    );
  }

  void _showVolunteerPostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding:
        EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: _VolunteerPostSheet(
          orgId: FirebaseAuth.instance.currentUser?.uid ?? '',
          orgName: _orgData?['name'] ?? '',
          onPosted: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _editPost({required bool adoption, required String docId, required Map<String, dynamic> data}) {
    final orgId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final orgName = _orgData?['name'] ?? '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: adoption
            ? _AdoptionPostSheet(orgId: orgId, orgName: orgName, docId: docId, initial: data,
                onPosted: () => Navigator.pop(sheetCtx))
            : _VolunteerPostSheet(orgId: orgId, orgName: orgName, docId: docId, initial: data,
                onPosted: () => Navigator.pop(sheetCtx)),
      ),
    );
  }

  // 掲載をやめる（消す）。消す前に確かめる
  Future<void> _deletePost({required String collection, required String docId, required String label}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('掲載をやめますか？'),
        content: Text('「$label」を消します。消すと、元に戻せません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx, false),
              child: const Text('やめる', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(dctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('消す'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final ref = FirebaseFirestore.instance.collection(collection).doc(docId);
      // ボランティア募集は、「興味あります」を押した人の記録（名前）も消す
      if (collection == 'volunteers') {
        try {
          final its = await ref.collection('interested').get();
          for (final d in its.docs) {
            await d.reference.delete();
          }
        } catch (_) {}
      }
      await ref.delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('掲載をやめました'), backgroundColor: Colors.grey));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('消せませんでした')));
      }
    }
  }

  Widget _editRow(VoidCallback onEdit, VoidCallback onDelete) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: const Text('内容を直す', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF3D2B1F),
                padding: const EdgeInsets.symmetric(vertical: 8)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('掲載をやめる', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 8)),
          ),
        ),
      ],
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    }
  }

  void _openChatList() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const OrganizationChatListPage()));
  }

  Widget _chatIconWithBadge() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: _openChatList,
          icon: const Icon(Icons.chat_bubble_outline_rounded,
              color: Color(0xFFE8845A)),
        ),
        if (_unreadTotal > 0)
          Positioned(
            right: 4,
            top: 4,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFFFFF8F5), width: 1.5),
                ),
                child: Center(
                  child: Text(_unreadTotal > 99 ? '99+' : '$_unreadTotal',
                      style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _todayCard() {
    final hasWork = _waitingCount > 0;
    final Color color = _overdueCount > 0
        ? Colors.red
        : hasWork
        ? const Color(0xFFE8845A)
        : const Color(0xFF2D6A4F);
    final String title = hasWork ? '今日やること' : '今日は対応待ちなし';
    final String body = hasWork
        ? '未返信の問い合わせが $_waitingCount 件あります'
        : 'すべての問い合わせに返信できています 🎉';

    return GestureDetector(
      onTap: _openChatList,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(hasWork ? '📬' : '✅',
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  const SizedBox(height: 2),
                  Text(body,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3D2B1F))),
                  if (_overdueCount > 0) ...[
                    const SizedBox(height: 2),
                    Text('うち $_overdueCount 件は24時間以上たっています',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
            child: CircularProgressIndicator(color: Color(0xFFE8845A))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        title: const Text('団体マイページ 🏢',
            style:
            TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
        backgroundColor: const Color(0xFFFFF8F5),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          const NotificationBellButton(),
          _chatIconWithBadge(),
          const AccountMenuButton(),
          IconButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  title: const Text('ログアウトしますか？'),
                  content: logoutNoteText(),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('キャンセル',
                          style: TextStyle(color: Colors.grey)),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE8845A),
                          foregroundColor: Colors.white),
                      child: const Text('ログアウト'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                _logout();
              }
            },
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFE8845A)),
          ),
        ],
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
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(_orgData?['name'] ?? '',
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ),
                      IconButton(
                        onPressed: _showEditOrgSheet,
                        icon: const Icon(Icons.edit_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                  if ((_orgData?['nameUpdatePending'] ?? '')
                      .toString()
                      .isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('団体名の変更を確認中です',
                          style: TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  const SizedBox(height: 8),
                  Text(_orgData?['activityDescription'] ?? '',
                      style: const TextStyle(
                          fontSize: 13, color: Colors.white70, height: 1.5)),
                  if ((_orgData?['activityUpdatePending'] ?? '')
                      .toString()
                      .isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Text('活動内容の変更を確認中です',
                          style: TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _todayCard(),
            const Text('投稿管理',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3D2B1F))),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showAdoptionPostSheet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF2D6A4F), Color(0xFF52B788)]),
                    borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Text('🐾', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('里親募集を投稿する',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _showVolunteerPostSheet,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFE8845A), Color(0xFFF4A261)]),
                    borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Text('🤝', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('ボランティア募集を投稿する',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LostPetPage())),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF3498DB),
                    borderRadius: BorderRadius.circular(16)),
                child: const Row(
                  children: [
                    Text('🔍', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('迷子情報を見る・投稿する',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: _SectionHeader(
                      title: 'お知らせ・活動報告',
                      hint: '団体のページと、どうぶつマップに出ます。譲渡会の告知やお礼などに'),
                ),
                TextButton.icon(
                  onPressed: () => OrgPosts.openSheet(context,
                      orgId: FirebaseAuth.instance.currentUser?.uid ?? '',
                      orgName: (_orgData?['name'] ?? '').toString()),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('書く'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D6A4F)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OrgPostList(
              orgId: FirebaseAuth.instance.currentUser?.uid ?? '',
              limit: 5,
              emptyText: 'まだ投稿はありません。「書く」から、最初のお知らせを出してみましょう',
            ),
            const SizedBox(height: 24),
            const _SectionHeader(
                title: '投稿した里親募集',
                hint: '押すと、利用者から見える画面を確認できます'),
            const SizedBox(height: 12),
            Container(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('adoptions')
                    .where('orgId',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const AnimaruLoading();
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('まだ投稿がありません🐾',
                          style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final docId = docs[i].id;
                      final isAdopted = data['status'] == 'adopted';
                      return GestureDetector(
                          onTap: () => showAdoptionDetail(context, data),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: data['imageUrl'] != null &&
                                          (data['imageUrl'] as String)
                                              .isNotEmpty
                                          ? Image.network(data['imageUrl'],
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover)
                                          : Container(
                                        width: 56,
                                        height: 56,
                                        color: Colors.orange[50],
                                        child: const Center(child: Text('🐾')),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(data['petName'] ?? '',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                        FontWeight.bold)),
                                              ),
                                              if (isAdopted)
                                                Container(
                                                  padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                      color:
                                                      const Color(0xFF2D6A4F),
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          6)),
                                                  child: const Text('里親決定',
                                                      style: TextStyle(
                                                          fontSize: 9,
                                                          color: Colors.white,
                                                          fontWeight:
                                                          FontWeight.bold)),
                                                ),
                                            ],
                                          ),
                                          Text(data['type'] ?? '',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600])),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const _TapHint(text: 'タップして、利用者から見える画面を確認'),
                                const SizedBox(height: 8),
                                _editRow(
                                  () => _editPost(adoption: true, docId: docId, data: data),
                                  () => _deletePost(collection: 'adoptions', docId: docId,
                                      label: (data['petName'] ?? '').toString()),
                                ),
                                if ((data['imageUrl'] ?? '').toString().isNotEmpty && !isAdopted)
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () => ShareCard.open(
                                        context,
                                        imageUrl: data['imageUrl'] as String,
                                        title: '${data['petName'] ?? ''}（${data['type'] ?? ''}）',
                                        subtitle: (data['personality'] ?? '').toString(),
                                        label: '🐾 里親さん募集中',
                                        footer: (_orgData?['name'] ?? '').toString(),
                                        color: const Color(0xFF2D6A4F),
                                      ),
                                      icon: const Icon(Icons.ios_share_rounded, size: 16),
                                      label: const Text('画像にして団体のSNSでシェア', style: TextStyle(fontSize: 12)),
                                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D6A4F)),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('adoptions')
                                          .doc(docId)
                                          .update({
                                        'status':
                                        isAdopted ? 'available' : 'adopted'
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isAdopted
                                          ? Colors.grey[700]
                                          : const Color(0xFF2D6A4F),
                                      side: BorderSide(
                                          color: isAdopted
                                              ? Colors.grey[400]!
                                              : const Color(0xFF2D6A4F)),
                                      padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: Text(
                                        isAdopted ? '募集中に戻す' : '里親が決まりました',
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ));
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const _SectionHeader(
                title: '投稿したボランティア募集',
                hint: '押すと、「興味あります」の人を確認して、チャットを始められます'),
            const SizedBox(height: 12),
            Container(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('volunteers')
                    .where('orgId',
                    isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const AnimaruLoading();
                  }
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(
                      child: Text('まだ投稿がありません🤝',
                          style: TextStyle(color: Colors.grey)),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final docId = docs[i].id;
                      final isClosed = data['status'] == 'closed';
                      return GestureDetector(
                          onTap: () => VolunteerPage.showDetail(context, docId, data),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: data['imageUrl'] != null &&
                                          (data['imageUrl'] as String)
                                              .isNotEmpty
                                          ? Image.network(data['imageUrl'],
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover)
                                          : Container(
                                        width: 56,
                                        height: 56,
                                        color: const Color(0xFFE8845A)
                                            .withOpacity(0.1),
                                        child: const Center(child: Text('🤝')),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(data['title'] ?? '',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                        FontWeight.bold)),
                                              ),
                                              if (isClosed)
                                                Container(
                                                  padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                                  decoration: BoxDecoration(
                                                      color: Colors.grey,
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          6)),
                                                  child: const Text('締切',
                                                      style: TextStyle(
                                                          fontSize: 9,
                                                          color: Colors.white,
                                                          fontWeight:
                                                          FontWeight.bold)),
                                                ),
                                            ],
                                          ),
                                          Text(data['location'] ?? '',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600])),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _VolunteerHint(volunteerId: docId),
                                const SizedBox(height: 8),
                                _editRow(
                                  () => _editPost(adoption: false, docId: docId, data: data),
                                  () => _deletePost(collection: 'volunteers', docId: docId,
                                      label: (data['title'] ?? '').toString()),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection('volunteers')
                                          .doc(docId)
                                          .update({
                                        'status': isClosed ? 'open' : 'closed'
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isClosed
                                          ? const Color(0xFF2D6A4F)
                                          : Colors.grey[700],
                                      side: BorderSide(
                                          color: isClosed
                                              ? const Color(0xFF2D6A4F)
                                              : Colors.grey[400]!),
                                      padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    child: Text(
                                        isClosed ? '募集を再開する' : '募集を締め切る',
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ));
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const _SectionHeader(
                title: '投稿した迷子情報',
                hint: '押すと、内容の確認と「見つかりました」への切り替えができます'),
            const SizedBox(height: 12),
            const _PostedLostList(),
          ],
        ),
      ),
    );
  }
}

class _AdoptionPostSheet extends StatefulWidget {
  final String orgId;
  final String orgName;
  final VoidCallback onPosted;
  // docId と initial があるときは、投稿した内容を直す
  final String? docId;
  final Map<String, dynamic>? initial;

  const _AdoptionPostSheet({
    required this.orgId,
    required this.orgName,
    required this.onPosted,
    this.docId,
    this.initial,
  });

  @override
  State<_AdoptionPostSheet> createState() => _AdoptionPostSheetState();
}

class _AdoptionPostSheetState extends State<_AdoptionPostSheet> {
  String? _imageUrl;
  bool _isUploading = false;
  bool _isPosting = false;
  final _petNameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  String _gender = 'オス';
  final _personalityCtrl = TextEditingController();
  final _backgroundCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();

  bool get _isEdit => widget.docId != null;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    if (d != null) {
      String t(String k) => (d[k] ?? '').toString();
      _petNameCtrl.text = t('petName');
      _typeCtrl.text = t('type');
      _ageCtrl.text = t('age');
      if (['オス', 'メス', '不明'].contains(t('gender'))) _gender = t('gender');
      _personalityCtrl.text = t('personality');
      _backgroundCtrl.text = t('background');
      _conditionsCtrl.text = t('conditions');
      final img = t('imageUrl');
      _imageUrl = img.isEmpty ? null : img;
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isUploading = true);
    final url = await CloudinaryService.pickAndUploadImage();
    setState(() {
      if (url != null) _imageUrl = url;
      _isUploading = false;
    });
  }

  Future<void> _submit() async {
    if (ContentFilter.blocked(context, [_petNameCtrl.text, _personalityCtrl.text, _backgroundCtrl.text, _conditionsCtrl.text], allowContact: true)) return;
    if (_imageUrl == null ||
        _petNameCtrl.text.trim().isEmpty ||
        _typeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('写真・名前・種類は必須です')),
      );
      return;
    }

    setState(() => _isPosting = true);

    final body = <String, dynamic>{
      'petName': _petNameCtrl.text.trim(),
      'type': _typeCtrl.text.trim(),
      'age': _ageCtrl.text.trim(),
      'gender': _gender,
      'personality': _personalityCtrl.text.trim(),
      'imageUrl': _imageUrl,
      'background': _backgroundCtrl.text.trim(),
      'conditions': _conditionsCtrl.text.trim(),
    };
    try {
      final col = FirebaseFirestore.instance.collection('adoptions');
      if (_isEdit) {
        await col.doc(widget.docId).update({...body, 'updatedAt': FieldValue.serverTimestamp()});
      } else {
        await col.add({
          ...body,
          'orgId': widget.orgId,
          'orgName': widget.orgName,
          'status': 'available',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('保存できませんでした。運営の確認が終わっているか、文字が長すぎないかを確かめてください')));
      }
      return;
    }

    widget.onPosted();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_isEdit ? '里親募集を直す' : '里親募集を投稿',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isUploading ? null : _pickImage,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(16)),
              child: _isUploading
                  ? const Center(
                  child:
                  CircularProgressIndicator(color: Color(0xFFE8845A)))
                  : _imageUrl != null
                  ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(_imageUrl!,
                      width: double.infinity, fit: BoxFit.cover))
                  : const Center(
                  child: Text('📸 写真を選ぶ',
                      style: TextStyle(color: Colors.grey))),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _petNameCtrl,
            maxLength: 20,
            decoration: InputDecoration(
              labelText: '名前 *',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _typeCtrl,
            maxLength: 30,
            decoration: InputDecoration(
              labelText: '種類（犬・猫など） *',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ageCtrl,
            maxLength: 15,
            decoration: InputDecoration(
              labelText: '年齢',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('性別', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['オス', 'メス', '不明'].map((g) {
              final sel = _gender == g;
              return GestureDetector(
                onTap: () => setState(() => _gender = g),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                      color: sel ? const Color(0xFF2D6A4F) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(g,
                      style: TextStyle(
                          color: sel ? Colors.white : Colors.grey[700])),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _personalityCtrl,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: '性格・特徴',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _backgroundCtrl,
            maxLines: 4,
            maxLength: 800,
            decoration: InputDecoration(
              labelText: '保護に至った経緯',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _conditionsCtrl,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: '希望する里親の条件',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPosting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A4F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isPosting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isEdit ? '保存する' : '投稿する',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _VolunteerPostSheet extends StatefulWidget {
  final String orgId;
  final String orgName;
  final VoidCallback onPosted;
  // docId と initial があるときは、投稿した内容を直す
  final String? docId;
  final Map<String, dynamic>? initial;

  const _VolunteerPostSheet({
    required this.orgId,
    required this.orgName,
    required this.onPosted,
    this.docId,
    this.initial,
  });

  @override
  State<_VolunteerPostSheet> createState() => _VolunteerPostSheetState();
}

class _VolunteerPostSheetState extends State<_VolunteerPostSheet> {
  String? _imageUrl;
  bool _isUploading = false;
  bool _isPosting = false;
  final _titleCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _scheduleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String? _selectedArea;

  bool get _isEdit => widget.docId != null;

  @override
  void initState() {
    super.initState();
    final d = widget.initial;
    if (d != null) {
      String t(String k) => (d[k] ?? '').toString();
      _titleCtrl.text = t('title');
      _locationCtrl.text = t('location');
      _scheduleCtrl.text = t('schedule');
      _descriptionCtrl.text = t('description');
      final a = t('area');
      _selectedArea = a.isEmpty ? null : a;
      final img = t('imageUrl');
      _imageUrl = img.isEmpty ? null : img;
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isUploading = true);
    final url = await CloudinaryService.pickAndUploadImage();
    setState(() {
      if (url != null) _imageUrl = url;
      _isUploading = false;
    });
  }

  Future<void> _submit() async {
    if (ContentFilter.blocked(context, [_titleCtrl.text, _descriptionCtrl.text], allowContact: true)) return;
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルは必須です')),
      );
      return;
    }

    setState(() => _isPosting = true);

    final body = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'location': _locationCtrl.text.trim(),
      'area': _selectedArea ?? '',
      'schedule': _scheduleCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
      'imageUrl': _imageUrl ?? '',
    };
    try {
      final col = FirebaseFirestore.instance.collection('volunteers');
      if (_isEdit) {
        await col.doc(widget.docId).update({...body, 'updatedAt': FieldValue.serverTimestamp()});
      } else {
        await col.add({
          ...body,
          'orgId': widget.orgId,
          'orgName': widget.orgName,
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isPosting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('保存できませんでした。運営の確認が終わっているか、文字が長すぎないかを確かめてください')));
      }
      return;
    }

    widget.onPosted();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_isEdit ? 'ボランティア募集を直す' : 'ボランティア募集を投稿',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isUploading ? null : _pickImage,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                  color: const Color(0xFFE8845A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: _isUploading
                  ? const Center(
                  child:
                  CircularProgressIndicator(color: Color(0xFFE8845A)))
                  : _imageUrl != null
                  ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(_imageUrl!,
                      width: double.infinity, fit: BoxFit.cover))
                  : const Center(
                  child: Text('📸 写真を選ぶ（任意）',
                      style: TextStyle(color: Colors.grey))),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            maxLength: 40,
            decoration: InputDecoration(
              labelText: 'タイトル *',
              hintText: '例：週末の保護犬お散歩ボランティア募集',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationCtrl,
            maxLength: 50,
            decoration: InputDecoration(
              labelText: '活動場所',
              hintText: '例：京都市内 保護施設',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('都道府県（どうぶつマップに表示されます）',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prefectures.map((pref) {
              final sel = _selectedArea == pref;
              return GestureDetector(
                onTap: () => setState(() => _selectedArea = pref),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color:
                      sel ? const Color(0xFFE8845A) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(pref,
                      style: TextStyle(
                          fontSize: 12,
                          color: sel ? Colors.white : Colors.grey[700])),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _scheduleCtrl,
            maxLength: 50,
            decoration: InputDecoration(
              labelText: '活動日時・頻度',
              hintText: '例：毎週土曜 10:00〜12:00',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionCtrl,
            maxLines: 5,
            maxLength: 800,
            decoration: InputDecoration(
              labelText: '活動内容',
              hintText: '具体的な活動内容や、参加条件などを書いてください',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPosting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8845A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isPosting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_isEdit ? '保存する' : '投稿する',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditOrgSheet extends StatefulWidget {
  final String orgId;
  final Map<String, dynamic> currentData;
  final VoidCallback onSaved;

  const _EditOrgSheet({
    required this.orgId,
    required this.currentData,
    required this.onSaved,
  });

  @override
  State<_EditOrgSheet> createState() => _EditOrgSheetState();
}

class _EditOrgSheetState extends State<_EditOrgSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _activityCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _websiteCtrl;
  String? _selectedArea;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.currentData['name'] ?? '');
    _activityCtrl = TextEditingController(
        text: widget.currentData['activityDescription'] ?? '');
    _contactCtrl =
        TextEditingController(text: widget.currentData['contactInfo'] ?? '');
    _websiteCtrl =
        TextEditingController(text: widget.currentData['websiteUrl'] ?? '');
    _selectedArea = widget.currentData['area'] ?? '';
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final updates = <String, dynamic>{
      'contactInfo': _contactCtrl.text.trim(),
      'websiteUrl': _websiteCtrl.text.trim(),
      'area': _selectedArea ?? '',
    };

    final nameChanged =
        _nameCtrl.text.trim() != (widget.currentData['name'] ?? '');
    final activityChanged = _activityCtrl.text.trim() !=
        (widget.currentData['activityDescription'] ?? '');

    if (nameChanged) {
      updates['nameUpdatePending'] = _nameCtrl.text.trim();
    }
    if (activityChanged) {
      updates['activityUpdatePending'] = _activityCtrl.text.trim();
    }

    await FirebaseFirestore.instance
        .collection('organizations')
        .doc(widget.orgId)
        .update(updates);

    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('団体情報を編集',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10)),
            child: const Text(
                '団体名・活動内容は、変更後すぐには反映されません。運営が確認してから反映されます。連絡先・サイト・都道府県は、すぐに反映されます。',
                style: TextStyle(fontSize: 11, color: Colors.orange)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              labelText: '団体名 または お名前',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _activityCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: '活動内容・実績',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _contactCtrl,
            decoration: InputDecoration(
              labelText: '連絡先（電話番号など）',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _websiteCtrl,
            decoration: InputDecoration(
              labelText: '公式サイト・SNS',
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('都道府県',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: prefectures.map((pref) {
              final sel = _selectedArea == pref;
              return GestureDetector(
                onTap: () => setState(() => _selectedArea = pref),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: sel ? const Color(0xFF2D6A4F) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(pref,
                      style: TextStyle(
                          fontSize: 12,
                          color: sel ? Colors.white : Colors.grey[700])),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8845A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('保存する',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String hint;
  const _SectionHeader({required this.title, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D2B1F))),
          const SizedBox(height: 2),
          Text(hint, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _TapHint extends StatelessWidget {
  final String text;
  const _TapHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.touch_app_rounded, size: 14, color: Color(0xFFE8845A)),
        const SizedBox(width: 4),
        Expanded(
          child: Text(text,
              style: const TextStyle(fontSize: 11, color: Color(0xFFE8845A))),
        ),
        const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
      ],
    );
  }
}

class _VolunteerHint extends StatelessWidget {
  final String volunteerId;
  const _VolunteerHint({required this.volunteerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteers')
          .doc(volunteerId)
          .collection('interested')
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: count > 0
                    ? const Color(0xFFE8845A)
                    : Colors.grey.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count > 0 ? '🙋 興味あります $count人' : '🙋 興味ありの人はまだいません',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: count > 0 ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('タップして確認・チャット',
                  style: TextStyle(fontSize: 11, color: Color(0xFFE8845A))),
            ),
            const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
          ],
        );
      },
    );
  }
}

class _PostedLostList extends StatelessWidget {
  const _PostedLostList();

  static int _ms(dynamic t) =>
      t is Timestamp ? t.millisecondsSinceEpoch : 9999999999999;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lostPets')
          .where('uid', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
                child: CircularProgressIndicator(color: Color(0xFF3498DB))),
          );
        }
        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) => _ms((b.data() as Map<String, dynamic>)['createdAt'])
            .compareTo(_ms((a.data() as Map<String, dynamic>)['createdAt'])));
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text('まだ投稿がありません🔍',
                  style: TextStyle(color: Colors.grey)),
            ),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final resolved = data['status'] == 'resolved';
            final image = (data['imageUrl'] ?? '').toString();
            return GestureDetector(
              onTap: () => showLostPetDetail(context, data, doc.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: image.isNotEmpty
                              ? Image.network(image,
                              width: 56, height: 56, fit: BoxFit.cover)
                              : Container(
                            width: 56,
                            height: 56,
                            color:
                            const Color(0xFF3498DB).withOpacity(0.1),
                            child: const Center(child: Text('🐾')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text((data['petName'] ?? '').toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: resolved
                                            ? const Color(0xFF2D6A4F)
                                            : const Color(0xFF3498DB),
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Text(resolved ? '見つかりました' : '迷子中',
                                        style: const TextStyle(
                                            fontSize: 9,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              Text((data['location'] ?? '').toString(),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const _TapHint(text: 'タップして、内容の確認・「見つかりました」に切り替え'),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}