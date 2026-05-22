import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/login_screen.dart';
import 'app_language.dart';
import 'profile_screen.dart';
import 'change_password_screen.dart';
import 'archive_screen.dart';
import 'language_screen.dart';
import 'currency_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;
    final appLanguage = context.watch<AppLanguage>();

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isTablet = constraints.maxWidth > 600;

        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: Text(appLanguage.t("Cài đặt")),
            backgroundColor: Colors.blue,
          ),
          body: Center(
            child: SizedBox(
              width: isTablet ? 500 : width,
              child: Column(
                children: [
                  SizedBox(height: height * 0.02),

                  /// 🔥 STREAM USER -> AUTO UPDATE UI
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      final user = snapshot.data;

                      return Column(
                        children: [
                          CircleAvatar(
                            radius: isTablet ? 60 : width * 0.12,
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(Icons.person,
                                size: isTablet ? 60 : 40,
                                color: Colors.blue),
                          ),
                          const SizedBox(height: 10),

                          /// NAME
                          Text(
                            user?.displayName ??
                                appLanguage.t("Chưa có tên"),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),

                          /// EMAIL
                          Text(
                            user?.email ??
                                appLanguage.t("Chưa có email"),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: height * 0.02),

                  /// MENU
                  Expanded(
                    child: Container(
                      margin:
                          EdgeInsets.symmetric(horizontal: width * 0.05),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ListView(
                        children: [
                          SettingItem(
                            icon: Icons.person_outline,
                            title:
                                appLanguage.t("Thông tin cá nhân"),
                            page: const ProfileScreen(),
                          ),
                          SettingItem(
                            icon: Icons.lock_outline,
                            title:
                                appLanguage.t("Đổi mật khẩu"),
                            page:
                                const ChangePasswordScreen(),
                          ),
                          SettingItem(
                            icon: Icons.folder_outlined,
                            title:
                                appLanguage.t("Nhóm lưu trữ"),
                            page: const ArchiveScreen(),
                          ),
                          SettingItem(
                            icon: Icons.language,
                            title: appLanguage.t("Ngôn ngữ"),
                            page: const LanguageScreen(),
                          ),
                          SettingItem(
                            icon: Icons
                                .account_balance_wallet_outlined,
                            title: appLanguage
                                .t("Đơn vị tiền tệ"),
                            page: const CurrencyScreen(),
                          ),
                          SettingItem(
                            icon: Icons.info_outline,
                            title: appLanguage
                                .t("Thông tin về chúng tôi"),
                            page: const AboutScreen(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// LOGOUT
                  Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();

                          Navigator.of(context)
                              .pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: Text(
                          appLanguage.t("Đăng xuất"),
                          style: const TextStyle(
                              color: Colors.white),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget page;

  const SettingItem({
    super.key,
    required this.icon,
    required this.title,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(title),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
    );
  }
}