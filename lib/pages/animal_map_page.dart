import 'org_posts.dart';
import 'package:flutter/material.dart';
import '../widgets/verified_org_mark.dart';
import '../widgets/motion.dart';
import '../widgets/animaru_loading.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'organization_profile_page.dart';
import 'lost_pet_page.dart';
import 'volunteer_page.dart';
import 'hospital_tags.dart';
import 'prefectures.dart';
import 'adoption_page.dart';
import 'package:url_launcher/url_launcher.dart';



class AnimalMapPage extends StatefulWidget {
  // initialCategory: 最初に開くタブ（'all'・'org' など）
  const AnimalMapPage({super.key, this.initialCategory = 'all'});
  final String initialCategory;

  @override
  State<AnimalMapPage> createState() => _AnimalMapPageState();
}

class _AnimalMapPageState extends State<AnimalMapPage> {
late String _category = widget.initialCategory;
String? _hospitalAnimalFilter;
String? _hospitalAreaFilter;
final Set<String> _hospitalFacilityFilters = {};
// 団体・里親・迷子・ボランティアのタブで使う、ことばの検索と都道府県のしぼりこみ
final _searchCtrl = TextEditingController();
String _query = '';
String? _area;
// 「緊急の迷子をすべて見る」から開いたときは、迷子タブを「緊急」で開く
String? _lostStart;

@override
void dispose() {
  _searchCtrl.dispose();
  super.dispose();
}

Widget _filterBar() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.trim()),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: _category == 'org' ? '団体の名前・活動で検索' : '名前・種類・場所で検索',
                hintStyle: const TextStyle(fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: '消す',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(21), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _area == null ? Colors.white : const Color(0xFFE8845A).withOpacity(0.12),
            borderRadius: BorderRadius.circular(21),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _area,
              hint: const Text('全国', style: TextStyle(fontSize: 13)),
              style: const TextStyle(fontSize: 13, color: Color(0xFF3D2B1F)),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('全国')),
                ...prefectures.map((p) => DropdownMenuItem<String?>(value: p, child: Text(p))),
              ],
              onChanged: (v) => setState(() => _area = v),
            ),
          ),
        ),
      ],
    ),
  );
}

_MapFilter get _filter => _MapFilter(_query, _area);

Widget _categoryChip(String value, String label) {
final sel = _category == value;
return GestureDetector(
onTap: () => setState(() { _category = value; _lostStart = null; }),
child: Container(
margin: const EdgeInsets.only(right: 8),
padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
decoration: BoxDecoration(
color: sel ? const Color(0xFF2D6A4F) : Colors.white,
borderRadius: BorderRadius.circular(20),
boxShadow: sel
? []
: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)]),
child: Text(label,
style: TextStyle(
fontSize: 13,
color: sel ? Colors.white : Colors.grey[700],
fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
),
);
}

Widget _subChip(String label, bool selected, VoidCallback onTap, {bool facility = false}) {
return GestureDetector(
onTap: onTap,
child: Container(
margin: const EdgeInsets.only(right: 6),
padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
decoration: BoxDecoration(
color: selected
? (facility ? const Color(0xFF2D6A4F) : const Color(0xFF4DA8DA))
: (facility ? const Color(0xFF2D6A4F).withOpacity(0.08) : Colors.grey[100]),
borderRadius: BorderRadius.circular(14)),
child: Text(label,
style: TextStyle(
fontSize: 10,
fontWeight: FontWeight.bold,
color: selected
? Colors.white
: (facility ? const Color(0xFF2D6A4F) : Colors.grey[700]))),
),
);
}

Widget _chips() {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
    child: Wrap(
      runSpacing: 8,
      children: [
        _categoryChip('all', 'すべて'),
        _categoryChip('org', '🏠 団体'),
        _categoryChip('adoption', '🐾 里親'),
        _categoryChip('lost', '🔍 迷子情報'),
        _categoryChip('volunteer', '🤝 ボランティア'),
        _categoryChip('hospital', '🏥 動物病院'),
      ],
    ),
  );
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: const Color(0xFFFFF8F5),
appBar: AppBar(
title: const Text('どうぶつマップ 🐾',
style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
backgroundColor: const Color(0xFFFFF8F5),
elevation: 0,
),
body: _category == 'all'
? _TimelineList(
    header: _chips(),
    footer: const Column(children: [
      Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: LatestOrgPosts(key: ValueKey('latestOrgPosts')),
      ),
      _ImpactCard(),
    ]))
: Column(
children: [
const Padding(
padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
child: Text('団体・迷子情報・ボランティア・病院をまとめて探せます',
style: TextStyle(fontSize: 12, color: Colors.grey)),
),
_chips(),
if (_category == 'org' || _category == 'adoption' || _category == 'lost' || _category == 'volunteer')
  _filterBar(),
if (_category == 'hospital')
Container(
margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('都道府県', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
const SizedBox(height: 6),
SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
children: [
_subChip('すべて', _hospitalAreaFilter == null, () => setState(() => _hospitalAreaFilter = null)),
...prefectures.map((p) => _subChip(p, _hospitalAreaFilter == p, () => setState(() => _hospitalAreaFilter = _hospitalAreaFilter == p ? null : p))),
],
),
),
const SizedBox(height: 10),
Text('対応動物', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
const SizedBox(height: 6),
SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
children: [
_subChip('すべての動物', _hospitalAnimalFilter == null, () => setState(() => _hospitalAnimalFilter = null)),
...hospitalAnimalTags.map((t) => _subChip(t, _hospitalAnimalFilter == t, () => setState(() => _hospitalAnimalFilter = _hospitalAnimalFilter == t ? null : t))),
],
),
),
const SizedBox(height: 10),
Text('診療体制', style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
const SizedBox(height: 6),
SingleChildScrollView(
scrollDirection: Axis.horizontal,
child: Row(
children: [
_subChip('✅ 新規受付中', _hospitalFacilityFilters.contains('acceptingNew'), () => setState(() => _hospitalFacilityFilters.contains('acceptingNew') ? _hospitalFacilityFilters.remove('acceptingNew') : _hospitalFacilityFilters.add('acceptingNew')), facility: true),
_subChip('🏨 入院あり', _hospitalFacilityFilters.contains('hasInpatient'), () => setState(() => _hospitalFacilityFilters.contains('hasInpatient') ? _hospitalFacilityFilters.remove('hasInpatient') : _hospitalFacilityFilters.add('hasInpatient')), facility: true),
_subChip('🔬 CT設備', _hospitalFacilityFilters.contains('hasCT'), () => setState(() => _hospitalFacilityFilters.contains('hasCT') ? _hospitalFacilityFilters.remove('hasCT') : _hospitalFacilityFilters.add('hasCT')), facility: true),
_subChip('🌙 夜間対応', _hospitalFacilityFilters.contains('hasNightCare'), () => setState(() => _hospitalFacilityFilters.contains('hasNightCare') ? _hospitalFacilityFilters.remove('hasNightCare') : _hospitalFacilityFilters.add('hasNightCare')), facility: true),
],
),
),
],
),
),
  Expanded(
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        if (_category == 'org') ...[
          if (_filter.isEmpty) const LatestOrgPosts(limit: 3),
          _OrgList(filter: _filter),
        ],
        if (_category == 'adoption') _AdoptionList(filter: _filter),
        if (_category == 'lost') _LostList(key: ValueKey(_lostStart), filter: _filter, initialStatus: _lostStart),
        if (_category == 'volunteer') _VolunteerList(filter: _filter),
        if (_category == 'hospital')
          _HospitalList(
            animalFilter: _hospitalAnimalFilter,
            areaFilter: _hospitalAreaFilter,
            facilityFilters: _hospitalFacilityFilters,
          ),
      ],

    ),
  ),
],
),
  floatingActionButton: _category == 'lost'
      ? FloatingActionButton.extended(
    onPressed: () => showLostPetPostSheet(context),
    backgroundColor: const Color(0xFF3498DB),
    icon: const Icon(Icons.add, color: Colors.white),
    label: const Text('投稿する', style: TextStyle(color: Colors.white)),
  )
      : null,

);
}
}
class _TimelineList extends StatelessWidget {
  final Widget header;
  final Widget footer;
  const _TimelineList({required this.header, required this.footer});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lostPets')
          .where('status', isEqualTo: 'lost')
          .orderBy('createdAt', descending: true)
          .limit(15)
          .snapshots(),
      builder: (context, lostSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('volunteers')
              .where('status', isEqualTo: 'open')
              .orderBy('createdAt', descending: true)
              .limit(15)
              .snapshots(),
          builder: (context, volSnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('organizations')
                  .where('status', isEqualTo: 'approved')
                  .orderBy('createdAt', descending: true)
                  .limit(15)
                  .snapshots(),
              builder: (context, orgSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('hospitals')
                      .where('status', isEqualTo: 'approved')
                      .orderBy('createdAt', descending: true)
                      .limit(15)
                      .snapshots(),
                  builder: (context, hospSnap) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('adoptions')
                          .where('status', isEqualTo: 'available')
                          .orderBy('createdAt', descending: true)
                          .limit(15)
                          .snapshots(),
                      builder: (context, adoptSnap) {
                        // 1つの種類が読めなくても（データベースの索引がまだない、など）、
                        // ほかの種類は出す。読めなかった種類は、空として扱う
                        bool waiting(AsyncSnapshot<QuerySnapshot> s) => !s.hasData && !s.hasError;
                        for (final s in [lostSnap, volSnap, orgSnap, hospSnap, adoptSnap]) {
                          if (s.hasError) debugPrint('すべてタブ：読めなかった種類があります: ${s.error}');
                        }
                        List<QueryDocumentSnapshot> docsOf(AsyncSnapshot<QuerySnapshot> s) =>
                            s.data?.docs ?? const [];
                        if (waiting(lostSnap) ||
                            waiting(volSnap) ||
                            waiting(orgSnap) ||
                            waiting(hospSnap) ||
                            waiting(adoptSnap)) {
                          return ListView(children: [
                            header,
                            const Padding(
                              padding: EdgeInsets.all(40),
                              child: AnimaruLoading(),
                            ),
                          ]);
                        }

                        final items = <_TimelineItem>[];
                        for (final d in docsOf(lostSnap)) {
                          final data = d.data() as Map<String, dynamic>;
                          items.add(_TimelineItem('lost', '🔍', const Color(0xFF3498DB),
                              data['petName'] ?? '', data['createdAt'], d.id, data));
                        }
                        for (final d in docsOf(volSnap)) {
                          final data = d.data() as Map<String, dynamic>;
                          items.add(_TimelineItem('volunteer', '🤝', const Color(0xFFE8845A),
                              data['title'] ?? '', data['createdAt'], d.id, data));
                        }
                        for (final d in docsOf(orgSnap)) {
                          final data = d.data() as Map<String, dynamic>;
                          items.add(_TimelineItem('org', '🏠', const Color(0xFF2D6A4F),
                              '${data['name'] ?? ''}', data['createdAt'], d.id, data));
                        }
                        for (final d in docsOf(hospSnap)) {
                          final data = d.data() as Map<String, dynamic>;
                          items.add(_TimelineItem('hospital', '🏥', const Color(0xFF4DA8DA),
                              '${data['name'] ?? ''}', data['createdAt'], d.id, data));
                        }
                        for (final d in docsOf(adoptSnap)) {
                          final data = d.data() as Map<String, dynamic>;
                          items.add(_TimelineItem('adoption', '🐾', Colors.orange,
                              data['petName'] ?? '', data['createdAt'], d.id, data));
                        }

                        // 保存直後（createdAtがまだ空）の投稿は、いちばん新しい扱いにする
                        int ms(dynamic t) => t is Timestamp ? t.millisecondsSinceEpoch : 9999999999999;
                        items.sort((a, b) => ms(b.createdAt).compareTo(ms(a.createdAt)));

                        // 1つの種類で画面が埋まらないように、種類ごとに新しい8件までにする
                        final counts = <String, int>{};
                        final capped = items.where((it) {
                          final c = (counts[it.type] ?? 0) + 1;
                          counts[it.type] = c;
                          return c <= 8;
                        }).toList();
                        final topItems = capped.take(30).toList();

                        // 緊急の迷子：まだ見つかっていないものを新しい順に。上に大きく出すのは3つまで。
                        // 4つ以上あるときは「すべて見る」から、迷子タブの「緊急」で全部見られる
                        final urgentAll = items
                            .where((i) => i.type == 'lost' && i.data['urgent'] == true)
                            .toList();
                        final urgentItems = urgentAll.take(3).toList();
                        final urgentMore = urgentAll.length - urgentItems.length;
                        final gridItems = topItems.where((i) => !urgentItems.contains(i)).toList();

                        return ListView(
                          padding: const EdgeInsets.only(bottom: 16),
                          children: [
                            header,
                            if (topItems.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: Text('まだ投稿がありません。\nこれから、団体の里親募集やボランティア募集がふえていきます🐾', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, height: 1.6)),
                                ),
                              ),
                            if (urgentItems.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                                child: Text('🚨 緊急の迷子情報',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.red)),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  children: urgentItems
                                      .map((i) => FadeSlideIn(
                                            key: ValueKey('u${i.type}${i.id}'),
                                            child: Pulse(child: _TimelineCard(item: i)),
                                          ))
                                      .toList(),
                                ),
                              ),
                              if (urgentMore > 0)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                  child: OutlinedButton.icon(
                                    onPressed: () => setState(() {
                                      _lostStart = 'urgent';
                                      _category = 'lost';
                                    }),
                                    icon: const Icon(Icons.campaign_rounded, color: Colors.red),
                                    label: Text('緊急の迷子をすべて見る（ほかに$urgentMore件）',
                                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Colors.red[200]!),
                                      minimumSize: const Size.fromHeight(44),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                                ),
                            ],
                            if (gridItems.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                                child: Text('新着',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 250,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.66,
                                  ),
                                  itemCount: gridItems.length,
                                  itemBuilder: (_, i) => FadeSlideIn(
                                    key: ValueKey('g${gridItems[i].type}${gridItems[i].id}'),
                                    index: i,
                                    child: _TimelineTile(item: gridItems[i]),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            footer,
                          ],
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TimelineItem {
  final String type;
  final String emoji;
  final Color color;
  final String title;
  final dynamic createdAt;
  final String id;
  final Map<String, dynamic> data;

  _TimelineItem(this.type, this.emoji, this.color, this.title, this.createdAt, this.id, this.data);
}

String _timeAgoOf(dynamic createdAt) {
  if (createdAt is! Timestamp) return '';
  final now = DateTime.now();
  final diff = now.difference(createdAt.toDate());
  if (diff.inMinutes < 1) return 'たった今';
  if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
  if (diff.inHours < 24) return '${diff.inHours}時間前';
  if (diff.inDays < 7) return '${diff.inDays}日前';
  return '${createdAt.toDate().month}月${createdAt.toDate().day}日';
}

void _openTimelineItem(BuildContext context, _TimelineItem item) {
  switch (item.type) {
    case 'lost':
      showLostPetDetail(context, item.data, item.id);
      break;
    case 'volunteer':
      VolunteerPage.showDetail(context, item.id, item.data);
      break;
    case 'org':
      Navigator.push(context, MaterialPageRoute(builder: (_) => OrganizationProfilePage(orgId: item.id)));
      break;
    case 'hospital':
      showHospitalDetail(context, item.id, item.data);
      break;
    case 'adoption':
      showAdoptionDetail(context, item.data);
      break;
  }
}

// 種類ごとのラベルと、2行目の文
String _timelineLabel(_TimelineItem item, {bool short = false}) {
  switch (item.type) {
    case 'lost':
      return short ? '🔍 迷子' : '🔍 迷子情報';
    case 'volunteer':
      return short ? '🤝 ボランティア' : '🤝 ボランティア募集';
    case 'org':
      return short ? '🏠 団体' : '🏠 保護団体';
    case 'hospital':
      return short ? '🏥 病院' : '🏥 動物病院';
    default:
      return short ? '🐾 里親' : '🐾 里親募集';
  }
}

String _timelineSubtitle(_TimelineItem item) {
  final d = item.data;
  switch (item.type) {
    case 'lost':
    case 'volunteer':
      return (d['location'] ?? '').toString();
    case 'org':
    case 'hospital':
      return (d['area'] ?? '').toString().isNotEmpty
          ? (d['area'] ?? '').toString()
          : '新しく登録されました';
    default:
      return (d['type'] ?? '').toString();
  }
}

// 大きいカード（緊急の迷子で使う）
class _TimelineCard extends StatelessWidget {
  final _TimelineItem item;
  const _TimelineCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final d = item.data;
    return GestureDetector(
      onTap: () => _openTimelineItem(context, item),
      child: _PhotoCard(
        imageUrl: _photoOf(d),
        emoji: item.emoji,
        color: item.color,
        label: _timelineLabel(item),
        title: item.title,
        subtitle: _timelineSubtitle(item),
        meta: _timeAgoOf(item.createdAt),
        urgent: item.type == 'lost' && d['urgent'] == true,
        verified: item.type == 'adoption' || item.type == 'volunteer' ||
            (item.type == 'lost' && d['isOrganization'] == true) ||
            (item.type == 'org' && d['status'] == 'approved'),
      ),
    );
  }
}

// 2列で並べる小さいカード（新着）
class _TimelineTile extends StatelessWidget {
  final _TimelineItem item;
  const _TimelineTile({required this.item});

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [item.color.withOpacity(0.2), item.color.withOpacity(0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Text(item.emoji, style: const TextStyle(fontSize: 40))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photoOf(item.data);
    final meta = _timeAgoOf(item.createdAt);
    final subtitle = _timelineSubtitle(item);
    return GestureDetector(
      onTap: () => _openTimelineItem(context, item),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (photo.isNotEmpty)
                    Image.network(
                      photo,
                      fit: BoxFit.cover,
                      loadingBuilder: (c, child, progress) =>
                          progress == null ? child : Container(color: item.color.withOpacity(0.08)),
                      errorBuilder: (c, e, st) => _placeholder(),
                    )
                  else
                    _placeholder(),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: item.color, borderRadius: BorderRadius.circular(10)),
                      child: Text(_timelineLabel(item, short: true),
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (meta.isNotEmpty)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55), borderRadius: BorderRadius.circular(10)),
                        child: Text(meta, style: const TextStyle(fontSize: 10, color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 「AniMatchのこれまで」: 件数が1つでもあるときだけ表示（0・0・0は出さない）
class _ImpactCard extends StatefulWidget {
  const _ImpactCard();

  @override
  State<_ImpactCard> createState() => _ImpactCardState();
}

class _ImpactCardState extends State<_ImpactCard> {
  // 件数だけを数える（全部の投稿を読まないので、軽くて安い）。開いたときに1回だけ
  late final Future<List<int>> _counts = _load();

  static Future<int> _count(Query<Map<String, dynamic>> q) async {
    try {
      final r = await q.count().get();
      return r.count ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<List<int>> _load() {
    final db = FirebaseFirestore.instance;
    return Future.wait([
      _count(db.collection('adoptions').where('status', isEqualTo: 'adopted')),
      _count(db.collection('lostPets').where('status', isEqualTo: 'resolved')),
      _count(db.collection('volunteers').where('status', isEqualTo: 'open')),
    ]);
  }

  Widget _stat(String emoji, int count, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        CountUp(value: count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: _counts,
      builder: (context, snap) {
        final c = snap.data ?? const [0, 0, 0];
        final adopted = c[0], resolved = c[1], volunteers = c[2];
        if (adopted + resolved + volunteers == 0) return const SizedBox();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF2D6A4F), Color(0xFF52B788)]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🐾 AniMatchのこれまで',
                    style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('🏠', adopted, '里親決定'),
                    _stat('🔍', resolved, '再会できた'),
                    _stat('🤝', volunteers, 'ボランティア募集中'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

void showHospitalDetail(BuildContext context, String hospitalId, Map<String, dynamic> data) {

  final animalTags = List<String>.from(data['animalTags'] ?? []);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((data['imageUrl'] ?? '').toString().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(data['imageUrl'], width: double.infinity, height: 160, fit: BoxFit.cover),
              ),
            const SizedBox(height: 12),
            Text(data['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
            const SizedBox(height: 8),
            if ((data['address'] ?? '').toString().isNotEmpty) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(data['address'], style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
                ],
              ),
            ],
            if ((data['access'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.train_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(data['access'].toString(), style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
                ],
              ),
            ],
            if ((data['address'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => openHospitalInMaps(context, (data['name'] ?? '').toString(), data['address'].toString()),
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: const Text('地図で開く（道順も見られます）', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4DA8DA),
                    side: const BorderSide(color: Color(0xFF4DA8DA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
            if ((data['businessHours'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(data['businessHours'], style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
                ],
              ),
            ],
            if ((data['contactInfo'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_rounded, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(data['contactInfo'], style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                ],
              ),
            ],
            const SizedBox(height: 16),
            const Text('対応動物（自己申告）', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: animalTags.map((t) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFF4DA8DA).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Text(t, style: const TextStyle(fontSize: 11, color: Color(0xFF4DA8DA), fontWeight: FontWeight.bold)),
              )).toList(),
            ),
            const SizedBox(height: 16),
            const Text('診療体制', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (data['acceptingNew'] == true) hospitalBadge('新規受付中'),
                if (data['hasInpatient'] == true) hospitalBadge('入院施設あり'),
                if (data['hasCT'] == true) hospitalBadge('CT設備あり'),
                if (data['hasMRI'] == true) hospitalBadge('MRI設備あり'),
                if (data['hasNightCare'] == true) hospitalBadge('夜間・救急対応'),

              ],
            ),
            const SizedBox(height: 16),
            const Text('実際に診てもらえた動物（利用者による確認）', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('hospitals').doc(hospitalId).collection('tagVotes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final counts = <String, int>{};
                for (final doc in snapshot.data!.docs) {
                  final tags = List<String>.from((doc.data() as Map<String, dynamic>)['verifiedAnimalTags'] ?? []);
                  for (final t in tags) {
                    counts[t] = (counts[t] ?? 0) + 1;
                  }
                }
                if (counts.isEmpty) {
                  return Text('まだ確認はありません', style: TextStyle(color: Colors.grey[500], fontSize: 12));
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: counts.entries.map((e) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFF2D6A4F), borderRadius: BorderRadius.circular(10)),
                    child: Text('✓ ${e.key} (${e.value}人)', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  )).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('みんなの一言', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('hospitals').doc(hospitalId).collection('tagVotes').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final counts = <String, int>{};
                for (final doc in snapshot.data!.docs) {
                  final tags = List<String>.from((doc.data() as Map<String, dynamic>)['commentTags'] ?? []);
                  for (final t in tags) {
                    counts[t] = (counts[t] ?? 0) + 1;
                  }
                }
                if (counts.isEmpty) {
                  return Text('まだタグが付いていません', style: TextStyle(color: Colors.grey[500], fontSize: 12));
                }
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: counts.entries.map((e) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                    child: Text('${e.key} (${e.value})', style: const TextStyle(fontSize: 12, color: Color(0xFF3D2B1F))),
                  )).toList(),
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  showTagSelectSheet(context, hospitalId, animalTags);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4DA8DA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('この病院にタグを付ける', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
// 病院の名前と住所で、Googleマップを開く（APIキー・料金はいらない、ただのリンク）
Future<void> openHospitalInMaps(BuildContext context, String name, String address) async {
  final query = name.isEmpty ? address : '$name $address';
  final uri = Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': query});
  var opened = false;
  try {
    opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    opened = false;
  }
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('地図を開けませんでした。住所をコピーして、地図アプリで探してください')),
    );
  }
}

Widget hospitalBadge(String label) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: const Color(0xFF2D6A4F).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
    child: Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
  );
}

void showTagSelectSheet(BuildContext context, String hospitalId, List<String> hospitalAnimalTagsList) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _HospitalTagSelectSheet(hospitalId: hospitalId, hospitalAnimalTags: hospitalAnimalTagsList),
    ),
  );
}

class _HospitalList extends StatelessWidget {
final String? animalFilter;
final String? areaFilter;
final Set<String> facilityFilters;
const _HospitalList({this.animalFilter, this.areaFilter, this.facilityFilters = const {}});

@override
Widget build(BuildContext context) {
return StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance
.collection('hospitals')
.where('status', isEqualTo: 'approved')
.snapshots(),
builder: (context, snapshot) {
if (!snapshot.hasData) {
return const Padding(
padding: EdgeInsets.symmetric(vertical: 20),
child: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
);
}
final docs = snapshot.data!.docs.where((doc) {
final data = doc.data() as Map<String, dynamic>;
if (data['isPaused'] == true) return false;
if (areaFilter != null && data['area'] != areaFilter) return false;
if (animalFilter != null) {
final tags = List<String>.from(data['animalTags'] ?? []);
if (!tags.contains(animalFilter)) return false;
}
for (final f in facilityFilters) {
if (data[f] != true) return false;
}
return true;
}).toList();

if (docs.isEmpty) {
return Padding(
padding: const EdgeInsets.symmetric(vertical: 20),
child: Container(
padding: const EdgeInsets.all(20),
decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
child: Column(
children: [
const Text('🔍', style: TextStyle(fontSize: 26)),
const SizedBox(height: 8),
Text(
areaFilter != null
? '$areaFilter では、条件に合う病院がまだ登録されていません。\n都道府県の条件を外して、全国から探してみてください。'
: '条件に合う病院がまだ登録されていません。',
textAlign: TextAlign.center,
style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.6),
),
],
),
),
);
}
return Column(
children: docs.asMap().entries.map((entry) {
final doc = entry.value;
final data = doc.data() as Map<String, dynamic>;
final animalTags = List<String>.from(data['animalTags'] ?? []);
return FadeSlideIn(
  key: ValueKey(doc.id),
  index: entry.key,
  child: Pressable(
  onTap: () => showHospitalDetail(context, doc.id, data),

child: Container(
margin: const EdgeInsets.only(bottom: 10),
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(
color: Colors.white,
borderRadius: BorderRadius.circular(14),
boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)]),
child: Row(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Container(
width: 42,
height: 42,
decoration: BoxDecoration(
color: const Color(0xFF4DA8DA).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
child: const Center(child: Text('🏥', style: TextStyle(fontSize: 19))),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
if ((data['address'] ?? '').toString().isNotEmpty || (data['area'] ?? '').toString().isNotEmpty) ...[
const SizedBox(height: 3),
Row(
children: [
const Icon(Icons.location_on_rounded, size: 12, color: Colors.grey),
const SizedBox(width: 2),
Expanded(
child: Text(
(data['address'] ?? '').toString().isNotEmpty ? data['address'].toString() : data['area'].toString(),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(fontSize: 11, color: Colors.grey[600]),
),
),
],
),
],
if ((data['access'] ?? '').toString().isNotEmpty) ...[
const SizedBox(height: 2),
Row(
children: [
const Icon(Icons.train_rounded, size: 12, color: Colors.grey),
const SizedBox(width: 2),
Expanded(
child: Text(
data['access'].toString(),
maxLines: 1,
overflow: TextOverflow.ellipsis,
style: TextStyle(fontSize: 11, color: Colors.grey[600]),
),
),
],
),
],
if (animalTags.isNotEmpty) ...[
const SizedBox(height: 4),
Wrap(
spacing: 4,
children: animalTags.take(2).map((t) => Container(
padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
decoration: BoxDecoration(color: const Color(0xFF4DA8DA).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
child: Text(t, style: const TextStyle(fontSize: 9, color: Color(0xFF4DA8DA))),
)).toList(),
),
],
const SizedBox(height: 4),
StreamBuilder<QuerySnapshot>(
stream: FirebaseFirestore.instance.collection('hospitals').doc(doc.id).collection('tagVotes').snapshots(),
builder: (context, voteSnap) {
if (!voteSnap.hasData) return const SizedBox();
final verifiedCount = voteSnap.data!.docs.where((v) {
final vd = v.data() as Map<String, dynamic>;
final verified = List<String>.from(vd['verifiedAnimalTags'] ?? []);
return verified.isNotEmpty;
}).length;
if (verifiedCount == 0) return const SizedBox();
return Container(
padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
decoration: BoxDecoration(color: const Color(0xFF2D6A4F), borderRadius: BorderRadius.circular(6)),
child: Text('✓ 実際に診てもらえた $verifiedCount人', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
);
},
),
],
),
),
const Icon(Icons.chevron_right_rounded, color: Colors.grey),
],
),
),
),
);
}).toList(),
);
},
);
}



}
class _HospitalTagSelectSheet extends StatefulWidget {
  final String hospitalId;
  final List<String> hospitalAnimalTags;
  const _HospitalTagSelectSheet({required this.hospitalId, required this.hospitalAnimalTags});

  @override
  State<_HospitalTagSelectSheet> createState() => _HospitalTagSelectSheetState();
}

class _HospitalTagSelectSheetState extends State<_HospitalTagSelectSheet> {
List<String> _selectedCommentTags = [];
List<String> _selectedVerifiedTags = [];
bool _isSaving = false;
bool _alreadyVoted = false;
bool _isChecking = true;

@override
void initState() {
super.initState();
_checkAlreadyVoted();
}

Future<void> _checkAlreadyVoted() async {
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null) {
setState(() => _isChecking = false);
return;
}
final doc = await FirebaseFirestore.instance
.collection('hospitals')
.doc(widget.hospitalId)
.collection('tagVotes')
.doc(myUid)
.get();
setState(() {
_alreadyVoted = doc.exists;
_isChecking = false;
});
}

Future<void> _submit() async {
final myUid = FirebaseAuth.instance.currentUser?.uid;
if (myUid == null || (_selectedCommentTags.isEmpty && _selectedVerifiedTags.isEmpty)) return;

setState(() => _isSaving = true);

await FirebaseFirestore.instance
.collection('hospitals')
.doc(widget.hospitalId)
.collection('tagVotes')
.doc(myUid)
.set({
'commentTags': _selectedCommentTags,
'verifiedAnimalTags': _selectedVerifiedTags,
'createdAt': FieldValue.serverTimestamp(),
});

if (mounted) Navigator.pop(context);
}
@override
Widget build(BuildContext context) {
  if (_isChecking) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(child: CircularProgressIndicator(color: Color(0xFF4DA8DA))),
    );
  }

  if (_alreadyVoted) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('✅', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          const Text('すでにこの病院にタグを付けています', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ),
        ],
      ),
    );
  }

  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('この病院にタグを付ける', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('当てはまるものをすべて選んでください（1病院につき1回まで）', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 16),
        if (widget.hospitalAnimalTags.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFF2D6A4F).withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
            child: const Text('✓ 実際にこの動物を診てもらえましたか？',
                style: TextStyle(fontSize: 12, color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.hospitalAnimalTags.map((tag) {
              final sel = _selectedVerifiedTags.contains(tag);
              return GestureDetector(
                onTap: () => setState(() {
                  if (sel) {
                    _selectedVerifiedTags.remove(tag);
                  } else {
                    _selectedVerifiedTags.add(tag);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                      color: sel ? const Color(0xFF2D6A4F) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(tag, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700])),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
        const Text('一言（当てはまるものを選んでください）', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hospitalCommentTags.map((tag) {
            final sel = _selectedCommentTags.contains(tag);
            return GestureDetector(
              onTap: () => setState(() {
                if (sel) {
                  _selectedCommentTags.remove(tag);
                } else {
                  _selectedCommentTags.add(tag);
                }
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                    color: sel ? const Color(0xFF4DA8DA) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20)),
                child: Text(tag, style: TextStyle(fontSize: 12, color: sel ? Colors.white : Colors.grey[700])),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSaving || (_selectedCommentTags.isEmpty && _selectedVerifiedTags.isEmpty) ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4DA8DA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSaving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('送信する', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    ),
  );
}
}
class _OrgList extends StatelessWidget {
  final _MapFilter filter;
  const _OrgList({required this.filter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('organizations')
          .where('status', isEqualTo: 'approved')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
          );
        }
        final docs = snapshot.data!.docs
            .where((d) => filter.matches(d.data() as Map<String, dynamic>,
                ['name', 'area', 'activityDescription']))
            .toList();
        if (docs.isEmpty) return filter.empty('団体');
        return Column(
          children: docs.asMap().entries.map((entry) {
final doc = entry.value;
            final data = doc.data() as Map<String, dynamic>;
            return FadeSlideIn(
  key: ValueKey(doc.id),
  index: entry.key,
  child: Pressable(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => OrganizationProfilePage(orgId: doc.id))),
              child: _PhotoCard(
                imageUrl: _photoOf(data),
                emoji: '🏠',
                color: const Color(0xFF2D6A4F),
                label: '🏠 保護団体',
                verified: data['status'] == 'approved',
                title: data['name'] ?? '',
                subtitle: (data['area'] ?? '').toString(),
              ),
            ),
);
          }).toList(),
        );
      },
    );
  }
}
class _AdoptionList extends StatelessWidget {
  final _MapFilter filter;
  const _AdoptionList({required this.filter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('adoptions')
          .where('status', isEqualTo: 'available')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
          );
        }
        final all = snapshot.data!.docs;
        return FutureBuilder<Map<String, String>>(
          future: filter.area == null ? null : _OrgAreas.load(),
          builder: (context, areaSnap) {
        if (filter.area != null && !areaSnap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
          );
        }
        final areas = areaSnap.data ?? const <String, String>{};
        final docs = all.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return filter.matches(data, ['petName', 'type', 'personality', 'orgName'],
              areaValue: areas[data['orgId']] ?? '');
        }).toList();
        if (docs.isEmpty) return filter.empty('里親募集');
        return Column(
          children: docs.asMap().entries.map((entry) {
final doc = entry.value;
            final data = doc.data() as Map<String, dynamic>;
            return FadeSlideIn(
  key: ValueKey(doc.id),
  index: entry.key,
  child: Pressable(
              onTap: () => showAdoptionDetail(context, data),
              child: _PhotoCard(
                imageUrl: _photoOf(data),
                emoji: '🐾',
                color: Colors.orange,
                label: '🐾 里親募集',
                verified: true,
                title: data['petName'] ?? '',
                subtitle: (data['type'] ?? '').toString(),
              ),
            ),
);
          }).toList(),
        );
          },
        );
      },
    );
  }
}

class _LostList extends StatefulWidget {
  final _MapFilter filter;
  final String? initialStatus;
  const _LostList({super.key, required this.filter, this.initialStatus});

  @override
  State<_LostList> createState() => _LostListState();
}

class _LostListState extends State<_LostList> {
  late String _filter = widget.initialStatus ?? 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _LostFilterChip(label: 'すべて', value: 'all', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                _LostFilterChip(label: '迷子中', value: 'lost', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                _LostFilterChip(label: '見つかりました', value: 'resolved', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                _LostFilterChip(label: '緊急', value: 'urgent', selected: _filter, onTap: (v) => setState(() => _filter = v)),
                _LostFilterChip(label: 'マイ投稿', value: 'mine', selected: _filter, onTap: (v) => setState(() => _filter = v)),

              ],
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('lostPets')
              .orderBy('createdAt', descending: true)
              .limit(100) // 読みこみ回数をおさえる（新しい100件まで）
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: Color(0xFF3498DB))),
              );
            }
            final myUid = FirebaseAuth.instance.currentUser?.uid;
            var docs = snapshot.data!.docs;
            if (_filter == 'urgent') {
              docs = docs.where((d) => (d.data() as Map<String, dynamic>)['urgent'] == true).toList();
            } else if (_filter == 'mine') {
              docs = docs.where((d) => (d.data() as Map<String, dynamic>)['uid'] == myUid).toList();
            } else if (_filter != 'all') {
              docs = docs.where((d) => (d.data() as Map<String, dynamic>)['status'] == _filter).toList();
            }
            docs = docs
                .where((d) => widget.filter.matches(d.data() as Map<String, dynamic>,
                    ['petName', 'animalType', 'location', 'area', 'features', 'description']))
                .toList();
            if (docs.isEmpty) return widget.filter.empty('迷子情報');

            return Column(
              children: docs.asMap().entries.map((entry) {
final doc = entry.value;
                final data = doc.data() as Map<String, dynamic>;
                final isMinePost = data['uid'] == myUid;
                return FadeSlideIn(
  key: ValueKey(doc.id),
  index: entry.key,
  child: Pressable(
                  onTap: () => showLostPetDetail(context, data, doc.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMinePost ? const Color(0xFF3498DB).withOpacity(0.06) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: isMinePost
                          ? Border.all(color: const Color(0xFF3498DB), width: 1.2)
                          : data['urgent'] == true ? Border.all(color: Colors.red[300]!) : null,
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                              color: const Color(0xFF3498DB).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text(data['emoji'] ?? '🔍', style: const TextStyle(fontSize: 19))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isMinePost)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: const Color(0xFF3498DB), borderRadius: BorderRadius.circular(6)),
                                      child: const Text('自分の投稿', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  if (data['urgent'] == true)
                                    Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                                      child: const Text('緊急', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                    ),
                                  _LostStatusBadge(status: data['status'] ?? 'lost'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(data['petName'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3D2B1F))),
                              if ((data['location'] ?? '').toString().isNotEmpty)
                                Text(data['location'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
);
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
class _LostFilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Function(String) onTap;
  const _LostFilterChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
            color: sel ? const Color(0xFF3498DB) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: sel ? const Color(0xFF3498DB) : Colors.grey[300]!)),
        child: Text(label, style: TextStyle(fontSize: 11, color: sel ? Colors.white : Colors.grey[700], fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }
}
class _VolunteerList extends StatelessWidget {
  final _MapFilter filter;
  const _VolunteerList({required this.filter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('volunteers')
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: Color(0xFFE8845A))),
          );
        }
        final docs = snapshot.data!.docs
            .where((d) => filter.matches(d.data() as Map<String, dynamic>,
                ['title', 'location', 'area', 'orgName', 'description']))
            .toList();
        if (docs.isEmpty) return filter.empty('ボランティア募集');
        return Column(
          children: docs.asMap().entries.map((entry) {
final doc = entry.value;
            final data = doc.data() as Map<String, dynamic>;
            return FadeSlideIn(
  key: ValueKey(doc.id),
  index: entry.key,
  child: Pressable(
              onTap: () => VolunteerPage.showDetail(context, doc.id, data),

              child: _PhotoCard(
                imageUrl: _photoOf(data),
                emoji: '🤝',
                color: const Color(0xFFE8845A),
                label: '🤝 ボランティア募集',
                verified: true,
                title: data['title'] ?? '',
                subtitle: (data['location'] ?? '').toString(),
              ),
            ),
);
          }).toList(),
        );
      },
    );
  }
}
// 投稿に付いている写真のURLを探す（なければ空）
String _photoOf(Map<String, dynamic> data) {
  for (final key in const ['imageUrl', 'profileImageUrl', 'logoUrl', 'photoUrl']) {
    final v = (data[key] ?? '').toString();
    if (v.startsWith('http')) return v;
  }
  return '';
}

// 写真を大きく見せるカード（すべて／団体／里親／ボランティア共通）
class _PhotoCard extends StatelessWidget {
  final String imageUrl;
  final String emoji;
  final Color color;
  final String label;
  final String title;
  final String subtitle;
  final String meta;
  final bool urgent;
  // 運営が確認した団体（またはその投稿）なら、印をつける
  final bool verified;

  const _PhotoCard({
    required this.imageUrl,
    required this.emoji,
    required this.color,
    required this.label,
    required this.title,
    this.subtitle = '',
    this.meta = '',
    this.urgent = false,
    this.verified = false,
  });

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: 110,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.18), color.withOpacity(0.06)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 44))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: urgent ? Border.all(color: Colors.red[300]!, width: 1.5) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              if (imageUrl.isNotEmpty)
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(
                    imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (c, child, progress) => progress == null
                        ? child
                        : Container(color: color.withOpacity(0.08)),
                    errorBuilder: (c, e, st) => _placeholder(),
                  ),
                )
              else
                _placeholder(),
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                  child: Text(label,
                      style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              if (urgent)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                    child: const Text('緊急',
                        style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
                if (verified) ...[
                  const SizedBox(height: 4),
                  const VerifiedOrgMark(small: true),
                ],
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(meta, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LostStatusBadge extends StatelessWidget {
  final String status;
  const _LostStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isResolved = status == 'resolved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
          color: isResolved ? const Color(0xFF2D6A4F) : const Color(0xFF3498DB),
          borderRadius: BorderRadius.circular(6)),
      child: Text(isResolved ? '見つかりました' : '迷子中',
          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}


// ことばの検索と都道府県のしぼりこみ（読んだものを、アプリの中でしぼる）
class _MapFilter {
  final String query;
  final String? area;
  const _MapFilter(this.query, this.area);

  bool get isEmpty => query.isEmpty && area == null;

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s'), '');

  // fields: 検索する項目の名前 / areaValue: その投稿の都道府県
  bool matches(Map<String, dynamic> data, List<String> fields, {String? areaValue}) {
    if (area != null) {
      final a = areaValue ?? (data['area'] ?? '').toString();
      if (!a.contains(area!) && !(data['location'] ?? '').toString().contains(area!.replaceAll(RegExp(r'[都府県]$'), ''))) {
        return false;
      }
    }
    if (query.isEmpty) return true;
    final q = _norm(query);
    for (final f in fields) {
      if (_norm((data[f] ?? '').toString()).contains(q)) return true;
    }
    return false;
  }

  Widget empty(String what) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
            isEmpty ? '$whatが見つかりませんでした' : '条件に合う$whatはありませんでした。ことばや都道府県を変えてみてください',
            style: TextStyle(color: Colors.grey[500])),
      );
}

// 里親募集には都道府県がないので、出している団体の都道府県を使う（1回だけ読む）
class _OrgAreas {
  static Future<Map<String, String>>? _future;
  static Future<Map<String, String>> load() {
    return _future ??= FirebaseFirestore.instance
        .collection('organizations')
        .where('status', isEqualTo: 'approved')
        .get()
        .then((s) => {for (final d in s.docs) d.id: (d.data()['area'] ?? '').toString()})
        .catchError((e) {
      _future = null;
      debugPrint('団体の都道府県の読みこみエラー: $e');
      return <String, String>{};
    });
  }
}
