import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAOX2iDulFwGpsnILKyQMES5K1kIz0xk98",
      authDomain: "animatch-9d840.firebaseapp.com",
      projectId: "animatch-9d840",
      storageBucket: "animatch-9d840.firebasestorage.app",
      messagingSenderId: "807134009565",
      appId: "1:807134009565:web:dc05ec22cc5714398ca334",
      measurementId: "G-VNMQ4CVW01",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AniMatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE8845A)),
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const SplashPage(),
    );
  }
}
