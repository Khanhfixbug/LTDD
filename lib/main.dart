import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'SETTING/app_language.dart';
import 'auth/login_screen.dart';
import 'filebase/firebase_options.dart';
import 'home_page.dart';
import 'Manage_Group/group_details_page.dart';
import 'Manage_Group/add_expense_page.dart';
import 'Manage_Group/add_payment.dart';

const String kRememberLoginKey = 'remember_login';

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
      home: const _AuthGate(),
      routes: {
        '/home': (context) => const HomePage(),
        '/group_detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final groupId = args is String
              ? args
              : (args is Map<String, dynamic>
                    ? (args['groupId'] ?? '') as String
                    : '');
          return GroupDetailsPage(groupId: groupId);
        },
        '/group_details': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final groupId = args is String
              ? args
              : (args is Map<String, dynamic>
                    ? (args['groupId'] ?? '') as String
                    : '');
          return GroupDetailsPage(groupId: groupId);
        },
        '/add_expense': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final groupId = args is String
              ? args
              : (args is Map<String, dynamic>
                    ? (args['groupId'] ?? '') as String
                    : '');
          return AddExpensePage(groupId: groupId);
        },
        '/add_payment': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final groupId = args is String
              ? args
              : (args is Map<String, dynamic>
                    ? (args['groupId'] ?? '') as String
                    : '');
          return AddPayment(groupId: groupId);
        },
      },
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  bool? _rememberLogin;

  @override
  void initState() {
    super.initState();
    _loadRememberLogin();
  }

  Future<void> _loadRememberLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(kRememberLoginKey) ?? false;
    if (!remember && FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
    }
    if (!mounted) return;
    setState(() {
      _rememberLogin = remember;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_rememberLogin == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<User?>(
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
    );
  }
}
