import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/animaru.dart';
import 'root_page.dart';

/// 登録が終わったときの「ようこそ」の画面。
/// 肉球が降ってきて、あにまるがはねて、最初のバッジ「はじめの一歩」がもらえる。
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key, this.petCount = 0});
  final int petCount;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..forward();
  late final AnimationController _rain = AnimationController(
      vsync: this, duration: const Duration(seconds: 4))
    ..repeat();
  String _name = '';

  static const firstBadge = 'はじめの一歩';

  @override
  void initState() {
    super.initState();
    _giveFirstBadge();
  }

  Future<void> _giveFirstBadge() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final ref = FirebaseFirestore.instance.collection('users').doc(uid);
      final d = await ref.get();
      if (mounted) setState(() => _name = (d.data()?['name'] ?? '') as String);
      await ref.update({'badges': FieldValue.arrayUnion([firstBadge])});
    } catch (_) {
      // バッジをつけられなくても、はじめることはできる
    }
  }

  @override
  void dispose() {
    _in.dispose();
    _rain.dispose();
    super.dispose();
  }

  double _part(double a, double b, [Curve c = Curves.easeOut]) =>
      c.transform(((_in.value - a) / (b - a)).clamp(0.0, 1.0));

  void _start() {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, __, ___) => const RootPage(),
        transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      body: AnimatedBuilder(
        animation: Listenable.merge([_in, _rain]),
        builder: (context, _) {
          return Stack(
            children: [
              // 降ってくる肉球
              ...List.generate(14, (i) {
                final r = math.Random(i * 31 + 7);
                final x = r.nextDouble() * size.width;
                final speed = 0.6 + r.nextDouble() * 0.6;
                final y = ((_rain.value * speed + r.nextDouble()) % 1.0) * (size.height + 60) - 40;
                return Positioned(
                  left: x,
                  top: y,
                  child: Opacity(
                    opacity: 0.18 + r.nextDouble() * 0.2,
                    child: Transform.rotate(
                      angle: r.nextDouble() * 1.2 - 0.6,
                      child: Icon(Icons.pets,
                          size: 16 + r.nextDouble() * 14,
                          color: i.isEven ? const Color(0xFFE8845A) : const Color(0xFF4E8A6E)),
                    ),
                  ),
                );
              }),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      Transform.translate(
                        offset: Offset(0, 60 * (1 - _part(0, 0.5, Curves.elasticOut))),
                        child: Opacity(
                          opacity: _part(0, 0.2),
                          child: const Animaru(size: 170, wave: true),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Opacity(
                        opacity: _part(0.3, 0.55),
                        child: Text(
                          _name.isEmpty ? 'ようこそ！' : 'ようこそ、$_nameさん！',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: _part(0.4, 0.65),
                        child: Text(
                          widget.petCount > 0
                              ? 'うちの子の登録もありがとう。あにまるといっしょに、動物好きの輪を広げよう'
                              : 'あにまるといっしょに、動物好きの輪を広げよう',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, height: 1.6, color: Colors.grey[700]),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // 最初のバッジ
                      Transform.scale(
                        scale: 0.6 + 0.4 * _part(0.6, 0.9, Curves.elasticOut),
                        child: Opacity(
                          opacity: _part(0.6, 0.75),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFF2B830), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                    color: const Color(0xFFF2B830).withOpacity(0.25),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4)),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('🐾', style: TextStyle(fontSize: 30)),
                                SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('バッジをもらいました',
                                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text('はじめの一歩',
                                        style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF3D2B1F))),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 3),
                      Opacity(
                        opacity: _part(0.8, 1),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _start,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8845A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('AniMatchをはじめる',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
