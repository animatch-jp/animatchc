// 下のタブ「ひろば」：話したり動いたりするのが少しにがてな人でも、気軽に入れる場所
// ・期間限定のお祭り（みんなで目標の数を集める）
// ・今日のお題（毎日かわる、ひとことで答えられる問い）
// ・いつでも開いている部屋（見るだけでもよい・スタンプだけでもよい）
// ・みんなで集まる（いままでのイベント。18歳以上）
// ・友達をさそう
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/tab_reselect.dart';
import '../widgets/festive_backdrop.dart';
import '../widgets/motion.dart';
import 'event_page.dart';
import 'hiroba_data.dart';
import 'hiroba_room_page.dart';

const _brown = Color(0xFF3D2B1F);

class HirobaPage extends StatefulWidget {
  const HirobaPage({super.key});

  @override
  State<HirobaPage> createState() => _HirobaPageState();
}

class _HirobaPageState extends State<HirobaPage> {
  final _scroll = ScrollController();
  void _toTop() => TabReselect.toTop([_scroll]);

  // 部屋ごとの「今日の投稿の数」（開いたときと、下に引っぱったときだけ数える）
  final Map<String, int> _todayCount = {};
  int? _festivalCount;

  @override
  void initState() {
    super.initState();
    TabReselect.tabs[2].addListener(_toTop);
    _loadCounts();
  }

  @override
  void dispose() {
    TabReselect.tabs[2].removeListener(_toTop);
    _scroll.dispose();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>> _col(String roomId) =>
      FirebaseFirestore.instance.collection('hiroba').doc(roomId).collection('hirobaPosts');

  Future<void> _loadCounts() async {
    final now = DateTime.now();
    final start = Timestamp.fromDate(DateTime(now.year, now.month, now.day));
    final topic = todayTopicRoom(now);
    final fes = currentFestival(now);
    Future<int> count(Query<Map<String, dynamic>> q) async {
      try {
        final r = await q.count().get();
        return r.count ?? 0;
      } catch (_) {
        return 0;
      }
    }

    final futures = <Future<void>>[
      for (final r in hirobaRooms)
        count(_col(r.id).where('createdAt', isGreaterThanOrEqualTo: start))
            .then((n) => _todayCount[r.id] = n),
      count(_col('topic').where('span', isEqualTo: topic.span)).then((n) => _todayCount['topic'] = n),
      if (fes != null)
        count(_col('fes_${fes.id}').where('span', isEqualTo: '${fes.id}-${now.year}'))
            .then((n) => _festivalCount = n),
    ];
    await Future.wait(futures);
    if (mounted) setState(() {});
  }

  void _open(HirobaRoom room) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => HirobaRoomPage(room: room)));
    _loadCounts();
  }

  Future<void> _invite(String text, BuildContext btnContext) async {
    final box = btnContext.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    try {
      await SharePlus.instance.share(ShareParams(text: '$text\n$inviteUrl', sharePositionOrigin: origin));
    } catch (e) {
      debugPrint('ひろばのシェアのエラー: $e');
    }
  }

  void _showRules() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('🐾 ひろばのきまり',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _brown)),
            const SizedBox(height: 12),
            for (final t in const [
              '見るだけでも大丈夫。部屋に入っても、だれにも知らされません',
              'スタンプを押すだけ、ひとことだけでも参加になります',
              '「名前を出さずに書く」をえらぶと「ないしょさん」として書けます',
              'ここからは、1対1のメッセージは送れません',
              '電話番号・メールアドレス・LINEのIDなどは書けません',
              'いやな投稿は、長押しして「通報」や「ブロック」ができます',
              'やさしい言葉で、みんなが楽しめる場所にしましょう',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('・', style: TextStyle(color: _brown)),
                  Expanded(child: Text(t, style: const TextStyle(color: _brown, height: 1.45))),
                ]),
              ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final fes = currentFestival(now);
    final topic = todayTopicRoom(now);
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: RefreshIndicator(
        onRefresh: _loadCounts,
        child: CustomScrollView(
          controller: _scroll,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header(fes)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              sliver: SliverList.list(children: [
                if (fes != null) _festivalCard(fes, now) else _nextFestival(now),
                const SizedBox(height: 12),
                _topicCard(topic),
                const SizedBox(height: 20),
                _sectionTitle('🏠 いつでも開いている部屋', '入るだけ・見るだけでも大丈夫'),
                const SizedBox(height: 10),
              ]),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 128,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _roomTile(hirobaRooms[i]),
                  childCount: hirobaRooms.length,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 20, 14, 30),
              sliver: SliverList.list(children: [
                _sectionTitle('📅 みんなで集まる', 'おさんぽ会・オフ会など（18歳以上）'),
                const SizedBox(height: 10),
                _eventsEntry(),
                const SizedBox(height: 14),
                _inviteCard(),
                const SizedBox(height: 10),
                Center(
                  child: TextButton.icon(
                    onPressed: _showRules,
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('ひろばのきまり'),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(HirobaFestival? fes) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 170 + top,
      child: FestiveBackdrop(
        colors: fes?.colors ?? const [Color(0xFFFFA26B), Color(0xFFFF6F91)],
        style: fes?.style ?? BackdropStyle.bunting,
        seed: 7,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, top + 56, 12, 16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('ひろば',
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 6)])),
                SizedBox(height: 4),
                Text('ペットのこと、気軽にひとこと。\n見るだけでも大丈夫です🐾',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
              ]),
            ),
            IconButton(
              tooltip: 'ひろばのきまり',
              onPressed: _showRules,
              icon: const Icon(Icons.info_outline, color: Colors.white),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String sub) {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _brown)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(sub,
            overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ),
    ]);
  }

  Widget _festivalCard(HirobaFestival fes, DateTime now) {
    final left = fes.end(now.year).difference(now).inDays;
    final n = _festivalCount;
    final done = n != null && n >= fes.goal;
    return Pressable(
      onTap: () => _open(fes.room(now.year)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: FestiveBackdrop(
          colors: fes.colors,
          style: fes.style,
          seed: fes.id.hashCode,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: Text(left <= 0 ? '今日まで！' : '期間限定・あと$left日',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fes.colors.last)),
                ),
              ]),
              const SizedBox(height: 6),
              Text('${fes.emoji} ${fes.name}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
              const SizedBox(height: 2),
              Text(fes.prompt,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text(
                done
                    ? '🎉 みんなで${fes.goal}こ達成！まだまだ書けます'
                    : 'みんなで${fes.goal}こ集めよう：${n ?? '…'} / ${fes.goal}',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: n == null ? null : (n / fes.goal).clamp(0, 1).toDouble(),
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.35),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                const Expanded(
                  child: Text('参加する →',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Builder(
                  builder: (bc) => TextButton.icon(
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.white, backgroundColor: Colors.white.withValues(alpha: 0.2)),
                    onPressed: () => _invite(
                        'AniMatchの「ひろば」で「${fes.name}」をやっています${fes.emoji}\n${fes.prompt}\nいっしょに参加しませんか？',
                        bc),
                    icon: const Icon(Icons.share, size: 16),
                    label: const Text('友達をさそう', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _nextFestival(DateTime now) {
    final (f, y) = nextFestival(now);
    final days = f.start(y).difference(DateTime(now.year, now.month, now.day)).inDays;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: f.colors.first.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        Text(f.emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('次のお祭り：${f.name}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: _brown)),
            Text('${f.month}月${f.startDay}日から（あと$days日）',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ]),
        ),
      ]),
    );
  }

  Widget _topicCard(HirobaRoom topic) {
    final n = _todayCount['topic'];
    return Pressable(
      onTap: () => _open(topic),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: topic.colors),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('💬 今日のお題',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Text(n == null || n == 0 ? 'いちばん乗りのチャンス' : '今日 $n件の答え',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ]),
          const SizedBox(height: 10),
          Text(topic.prompt ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _brown, height: 1.35)),
          const SizedBox(height: 4),
          Text('ひとことでOK。飼っていなくても答えられます',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Text('答える・みんなの答えを見る →',
                  style: TextStyle(fontWeight: FontWeight.bold, color: topic.colors.last)),
            ),
            Builder(
              builder: (bc) => IconButton(
                tooltip: '友達にも聞く',
                icon: Icon(Icons.share, size: 20, color: topic.colors.last),
                onPressed: () => _invite('今日のお題「${topic.prompt}」\nAniMatchの「ひろば」で答えてみませんか？🐾', bc),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _roomTile(HirobaRoom r) {
    final n = _todayCount[r.id];
    return Pressable(
      onTap: () => _open(r),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FestiveBackdrop(
          colors: r.colors,
          style: r.style,
          seed: r.id.hashCode,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 30, 10, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${r.emoji} ${r.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      shadows: [Shadow(color: Colors.black26, blurRadius: 4)])),
              const SizedBox(height: 2),
              Text(r.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(8)),
                child: Text(n == null ? '…' : (n == 0 ? '今日はまだ静か' : '今日 $n件'),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: r.colors.last)),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _eventsEntry() {
    return Pressable(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EventPage())),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8845A).withValues(alpha: 0.4)),
        ),
        child: const Row(children: [
          Text('🐕‍🦺', style: TextStyle(fontSize: 30)),
          SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('イベントを見る・ひらく',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _brown)),
              SizedBox(height: 2),
              Text('おさんぽ会やオフ会など、会って楽しむ集まり',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
          ),
          Icon(Icons.chevron_right, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _inviteCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFF1E6), Color(0xFFFFE3EC)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Text('👋', style: TextStyle(fontSize: 30)),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('友達をさそう', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _brown)),
            SizedBox(height: 2),
            Text('知っている人がいると、話しやすくなります', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ]),
        ),
        Builder(
          builder: (bc) => ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8845A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => _invite('AniMatchの「ひろば」で、ペットの話を気軽にしませんか？🐾\n見るだけでも大丈夫です', bc),
            child: const Text('さそう'),
          ),
        ),
      ]),
    );
  }
}
