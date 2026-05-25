import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'SETTING/app_language.dart';
import 'auth/email_verification_screen.dart';
import 'auth/login_repository.dart';
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

  static const _primaryBlue = Color(0xFF1E73E8);
  static const _background = Color(0xFFF5F7FB);
  static const _surface = Colors.white;

  @override
  Widget build(BuildContext context) {
    final appLang = context.watch<AppLanguage>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quan ly chi tieu',
      locale: appLang.locale,
      theme: ThemeData(
        scaffoldBackgroundColor: _background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryBlue,
          primary: _primaryBlue,
          surface: _surface,
          background: _background,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
          fontFamily: 'Roboto',
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: _surface,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFFD8E0EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: Color(0xFFD8E0EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(14)),
            borderSide: BorderSide(color: _primaryBlue, width: 1.4),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryBlue,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
            textStyle: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryBlue,
            side: BorderSide(color: Color(0xFFB7C7DD)),
            minimumSize: Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(14)),
            ),
          ),
        ),
      ),
      home: const AuthGate(),
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

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Future<void> _sessionCheck = _checkSavedSession();

  Future<void> _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberLogin =
        prefs.getBool(LoginRepository.rememberLoginKey) ?? false;

    if (!rememberLogin && FirebaseAuth.instance.currentUser != null) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _sessionCheck,
      builder: (context, sessionSnapshot) {
        if (sessionSnapshot.connectionState != ConnectionState.done) {
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

            final user = snapshot.data;
            if (user != null && user.emailVerified) {
              return const HomePage();
            }

            if (user != null) {
              return const EmailVerificationScreen();
            }

            return const LoginScreen();
          },
        );
      },
    );
  }
}
