import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'dart:ui';
import 'pages/splash_page.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
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
  } else {
    await Firebase.initializeApp();
  }

  if (!kIsWeb) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AniMatch',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja'),
      ],
      locale: const Locale('ja'),
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
