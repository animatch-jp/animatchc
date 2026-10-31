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
  // タップしたとき：ロゴがはずむ
  late final AnimationController _pop;
  // タップしたところから、肉球がぱっと広がる
  final List<_Burst> _bursts = [];
  // 次に開く画面（ログイン・ホームなど）。タップされるまで待つ。
  Widget? _next;
  bool _leaving = false;

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
    _pop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    // 動きを見せている間に、次の画面を調べておく（タップされたらすぐ進める）
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLoginState());
  }

  // 0〜1 の中の、start〜end の間だけ動く値
  double _part(double start, double end, {Curve curve = Curves.easeOut}) {
    final t = ((_intro.value - start) / (end - start)).clamp(0.0, 1.0);
    return curve.transform(t);
  }

  Future<void> _checkLoginState() async {
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _next = null;
    });
    // Web版では、ログイン状態の読みこみに少し時間がかかるので、最初の知らせを待つ
    User? user;
    try {
      user = await FirebaseAuth.instance
          .authStateChanges()
          .first
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      user = FirebaseAuth.instance.currentUser;
    }
    if (!mounted) return;
    if (user == null) {
      setState(() => _next = const LoginPage());
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
          setState(() => _next = const OrganizationHomePage());
        } else {
          setState(() => _next = const OrganizationPendingPage());
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
          setState(() => _next = const HospitalHomePage());
        } else {
          setState(() => _next = const HospitalPendingPage());
        }
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      if (!userDoc.exists) {
        setState(() => _next = const ProfileSetupPage());
      } else {
        setState(() => _next = const RootPage());
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
    _pop.dispose();
    for (final b in _bursts) {
      b.ctrl.dispose();
    }
    super.dispose();
  }

  // 動きが終わって、次の画面もわかっていれば、タップで進める
  bool get _ready => _next != null && _intro.value >= 0.85 && !_hasError;

  void _go() {
    if (_leaving || _next == null) return;
    _leaving = true;
    final next = _next!;
    Future.delayed(const Duration(milliseconds: 380), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, __, ___) => next,
          transitionsBuilder: (_, a, __, child) =>
              FadeTransition(opacity: a, child: child),
        ),
      );
    });
  }

  void _onTap(TapDownDetails d) {
    if (_ready) _go();
    _pop.forward(from: 0);
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final burst = _Burst(d.localPosition, ctrl, _bursts.length.isEven);
    setState(() => _bursts.add(burst));
    ctrl.forward().whenComplete(() {
      if (!mounted) return;
      setState(() => _bursts.remove(burst));
      ctrl.dispose();
    });
  }

  // タップしたところから、6つの肉球が外へ広がる
  Widget _burstWidget(_Burst b) {
    return AnimatedBuilder(
      animation: b.ctrl,
      builder: (context, _) {
        final t = Curves.easeOut.transform(b.ctrl.value);
        return Stack(
          children: List.generate(6, (i) {
            final angle = i / 6 * math.pi * 2 + (b.flip ? 0.5 : 0);
            final dist = 70 * t;
            return Positioned(
              left: b.pos.dx + math.cos(angle) * dist - 11,
              top: b.pos.dy + math.sin(angle) * dist - 11,
              child: Opacity(
                opacity: (1 - b.ctrl.value).clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: angle + math.pi / 2,
                  child: Transform.scale(
                    scale: 0.5 + 0.7 * t,
                    child: Icon(Icons.pets,
                        size: 22, color: i.isEven ? _orange : _green),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
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

  // 準備ができたら：「タップしてはじめる」
  Widget _tapHint() {
    final hop = math.sin(_loop.value * math.pi * 2);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          offset: Offset(0, -4 * hop.abs()),
          child: const Icon(Icons.touch_app_rounded, color: _orange, size: 30),
        ),
        const SizedBox(height: 6),
        Opacity(
          opacity: 0.6 + 0.4 * hop.abs(),
          child: const Text('タップしてはじめる',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Color(0xFF3D2B1F))),
        ),
      ],
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
        animation: Listenable.merge([_intro, _loop, _pop]),
        builder: (context, _) {
          final logoIn = _part(0.35, 0.75, curve: Curves.elasticOut);
          final logoFade = _part(0.35, 0.5);
          final wobble = math.sin(_part(0.35, 0.8) * math.pi * 3) *
              0.04 *
              (1 - _part(0.35, 0.8));
          final bottomIn = _part(0.8, 1.0);
          final popScale = 1 + 0.12 * math.sin(_pop.value * math.pi);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: _onTap,
            child: Stack(
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
                          scale: (0.5 + 0.5 * logoIn) * popScale,
                          child: _shine(Image.asset(
                            'assets/images/logo_clear.png',
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
                            : _ready
                                ? _tapHint()
                                : _loadingPaws(),
                      ),
                    ),
                  ],
                ),
              ),
              ..._bursts.map((b) => Positioned.fill(child: IgnorePointer(child: _burstWidget(b)))),
            ],
          ),
          );
        },
      ),
    );
  }
}

class _Burst {
  _Burst(this.pos, this.ctrl, this.flip);
  final Offset pos;
  final AnimationController ctrl;
  final bool flip;
}
