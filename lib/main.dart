import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'SETTING/app_language.dart';
import 'auth/login_screen.dart';
import 'filebase/firebase_options.dart';
import 'home_page.dart';
import 'Manage_Group/group_details_page.dart';
import 'Manage_Group/add_expense_page.dart';
import 'Manage_Group/Group_option/add_payment.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppLanguage(),
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
      title: 'Quan ly chi tieu',
      locale: appLang.locale,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006D4E),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
          fontFamily: 'Roboto',
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF006D4E),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return const HomePage();
          }

          return const LoginScreen();
        },
      ),
      routes: {
        '/home': (context) => const HomePage(),
        '/group_detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final groupId = args is String
              ? args
              : (args is Map<String, dynamic> ? (args['groupId'] ?? '') as String : '');
          return GroupDetailsPage(groupId: groupId);
        },
        '/group_details': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final groupId = args is String
              ? args
              : (args is Map<String, dynamic> ? (args['groupId'] ?? '') as String : '');
          return GroupDetailsPage(groupId: groupId);
        },
        '/add_expense': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final groupId = args is String
              ? args
              : (args is Map<String, dynamic> ? (args['groupId'] ?? '') as String : '');
          return AddExpensePage(groupId: groupId);
        },
        '/add_payment': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final groupId = args is String
              ? args
              : (args is Map<String, dynamic> ? (args['groupId'] ?? '') as String : '');
          return AddPayment(groupId: groupId);
        },
      },
    );
  }
}
