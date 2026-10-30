import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'root_page.dart';
import 'profile_setup_page.dart';
import 'organization_home_page.dart';
import 'organization_pending_page.dart';
import 'hospital_home_page.dart';
import 'hospital_pending_page.dart';


class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  // 最初の登場（足あと → ロゴ → 光）
  late final AnimationController _intro;
  // ずっとくり返す動き（背景の丸、読みこみ中の肉球）
  late final AnimationController _loop;
  bool _hasError = false;

  static const _orange = Color(0xFFE8845A);
  static const _green = Color(0xFF4E8A6E);

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..forward();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    Future.delayed(const Duration(milliseconds: 3000), () {
      _checkLoginState();
    });
  }

  // 0〜1 の中の、start〜end の間だけ動く値
  double _part(double start, double end, {Curve curve = Curves.easeOut}) {
    final t = ((_intro.value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  Future<void> _checkLoginState() async {
    if (!mounted) return;
    setState(() => _hasError = false);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }

    try {
      final orgDoc = await FirebaseFirestore.instance
          .collection('organizations')
          .doc(user.uid)
          .get();

      if (orgDoc.exists) {
        final status = orgDoc.data()?['status'] ?? 'pending';
        if (!mounted) return;
        if (status == 'approved') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const OrganizationHomePage()));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const OrganizationPendingPage()));
        }
        return;
      }

      final hospitalDoc = await FirebaseFirestore.instance
          .collection('hospitals')
          .doc(user.uid)
          .get();

      if (hospitalDoc.exists) {
        final status = hospitalDoc.data()?['status'] ?? 'pending';
        if (!mounted) return;
        if (status == 'approved') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const HospitalHomePage()));
        } else {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const HospitalPendingPage()));
        }
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      if (!userDoc.exists) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const ProfileSetupPage()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const RootPage()));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _hasError = true);
    }
  }


  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  // 下から歩いてくる足あと（左右交互）
  Widget _footsteps(double width) {
    const steps = 5;
    final children = <Widget>[];
    for (var i = 0; i < steps; i++) {
      final start = i * 0.09;
      final appear = _part(start, start + 0.12, curve: Curves.easeOutBack);
      final vanish = _part(0.55, 0.75);
      final opacity = (appear.clamp(0.0, 1.0) * (1 - vanish)).clamp(0.0, 1.0);
      final left = i.isEven;
      children.add(Positioned(
        bottom: 40.0 + i * 62,
        left: width / 2 + (left ? -34 : 10),
        child: Opacity(
          opacity: opacity * 0.55,
          child: Transform.rotate(
            angle: left ? -0.25 : 0.25,
            child: Transform.scale(
              scale: 0.4 + 0.6 * appear,
              child: Icon(Icons.pets,
                  size: 26, color: i.isEven ? _orange : _green),
            ),
          ),
        ),
      ));
    }
    return Stack(children: children);
  }

  // 背景で、ふわふわ広がる丸
  Widget _ripples(double size) {
    final show = _part(0.45, 0.8);
    return IgnorePointer(
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(2, (i) {
          final t = (_loop.value + i * 0.5) % 1.0;
          return Opacity(
            opacity: (1 - t) * 0.18 * show,
            child: Container(
              width: size * (0.5 + t * 0.7),
              height: size * (0.5 + t * 0.7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i == 0 ? _orange : _green,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ロゴの上をすっと通る光
  Widget _shine(Widget child) {
    final t = _part(0.75, 1.0, curve: Curves.easeInOut);
    if (t <= 0 || t >= 1) return child;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (rect) {
        final x = -0.5 + t * 2.0;
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withOpacity(0),
            Colors.white.withOpacity(0.65),
            Colors.white.withOpacity(0),
          ],
          stops: [
            (x - 0.15).clamp(0.0, 1.0),
            x.clamp(0.0, 1.0),
            (x + 0.15).clamp(0.0, 1.0),
          ],
        ).createShader(rect);
      },
      child: child,
    );
  }

  // 読みこみ中：肉球が3つ、順番にぴょこぴょこ
  Widget _loadingPaws() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final t = (_loop.value - i * 0.18) % 1.0;
        final hop = t < 0.4 ? math.sin(t / 0.4 * math.pi) : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Transform.translate(
            offset: Offset(0, -10 * hop),
            child: Opacity(
              opacity: 0.45 + 0.55 * hop,
              child: Icon(Icons.pets,
                  size: 18, color: i == 1 ? _green : _orange),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _loop]),
        builder: (context, _) {
          final logoIn = _part(0.35, 0.75, curve: Curves.elasticOut);
          final logoFade = _part(0.35, 0.5);
          final wobble = math.sin(_part(0.35, 0.8) * math.pi * 3) *
              0.04 *
              (1 - _part(0.35, 0.8));
          final bottomIn = _part(0.8, 1.0);
          return Stack(
            children: [
              Positioned.fill(child: _footsteps(size.width)),
              Center(child: _ripples(size.width * 0.9)),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Opacity(
                      opacity: logoFade,
                      child: Transform.rotate(
                        angle: wobble,
                        child: Transform.scale(
                          scale: 0.5 + 0.5 * logoIn,
                          child: _shine(Image.asset(
                            'assets/images/logo.png',
                            width: size.width * 0.8,
                            fit: BoxFit.contain,
                          )),
                        ),
                      ),
                    ),
                    const SizedBox(height: 60),
                    Opacity(
                      opacity: _hasError ? 1 : bottomIn,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - bottomIn)),
                        child: _hasError
                            ? Column(children: [
                                const Text('接続がうまくいきませんでした',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF3D2B1F))),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _checkLoginState,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _orange,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                  ),
                                  child: const Text('もう一度試す'),
                                ),
                              ])
                            : _loadingPaws(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
