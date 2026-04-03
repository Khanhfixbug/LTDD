import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_language.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLanguage = context.watch<AppLanguage>();
    final bool isVN = appLanguage.locale.languageCode == 'vi';

    return Scaffold(
      appBar: AppBar(
        title: Text(isVN ? "Thông tin về chúng tôi" : "About Us"),
        backgroundColor: Colors.blue,
      ),

      body: Padding( 
        padding: const EdgeInsets.all(20),
        child: Text(
          isVN 
            ? "Ứng dụng giúp bạn quản lý chi tiêu nhóm, chia tiền và theo dõi các khoản nợ giữa bạn bè."
            : "The app helps you manage group expenses, split bills, and track debts between friends.",
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}