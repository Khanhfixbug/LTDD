import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'SETTING/app_language.dart';
import 'auth/login_screen.dart';
import 'filebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => AppLanguage(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final appLang = context.watch<AppLanguage>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: appLang.locale,
      home: const LoginScreen(),
    );
  }
}
