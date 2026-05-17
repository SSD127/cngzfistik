import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Yakalanmamış async hataları (Flutter Web'de "converted Future" hataları)
  // uygulamayı çöküşe götürmesin; sadece konsola yaz.
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Yakalanmamış hata: $error');
    return true;
  };

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Offline persistence (Gereksinim 23.1) — sadece okuma önbelleği
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const ProviderScope(child: App()));
}
