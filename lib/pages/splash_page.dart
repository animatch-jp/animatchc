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
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), () {
      _checkLoginState();
    });
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
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  color: Colors.white,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: MediaQuery.of(context).size.width * 0.8,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 60),
                if (_hasError) ...[
                  const Text('接続がうまくいきませんでした',
                      style: TextStyle(fontSize: 13, color: Color(0xFF3D2B1F))),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _checkLoginState,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8845A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    child: const Text('もう一度試す'),
                  ),
                ] else
                  const CircularProgressIndicator(
                      color: Color(0xFFE8845A),
                      strokeWidth: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
