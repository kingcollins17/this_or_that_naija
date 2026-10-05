import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'services/local_storage_service.dart';
import 'providers/voting_provider.dart';
import 'screens/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await LocalStorageService.init();

  final container = ProviderContainer();
  try {
    await container.read(votingRepositoryProvider).ensureAnonymousAuth();
  } catch (e) {
    debugPrint("Failed to perform auto anonymous sign in: $e");
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ThisOrThatApp(),
    ),
  );
}

class ThisOrThatApp extends StatelessWidget {
  const ThisOrThatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'This or That Naija',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const GameScreen(),
    );
  }
}
