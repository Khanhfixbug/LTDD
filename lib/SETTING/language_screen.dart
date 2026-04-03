import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_language.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLanguage = context.watch<AppLanguage>();
    final currentLang = appLanguage.locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        title: Text(appLanguage.t("Ngôn ngữ")), 
        backgroundColor: Colors.blue,
      ),

      body: Column(
        children: [
          RadioListTile<String>( 
            title: const Text("Tiếng Việt"),
            value: "vi",
            groupValue: currentLang,
            onChanged: (value) {
              context.read<AppLanguage>().changeLanguage(value!);
            },
          ),

          RadioListTile<String>(
            title: const Text("English"),
            value: "en",
            groupValue: currentLang,
            onChanged: (value) {
              context.read<AppLanguage>().changeLanguage(value!);
            },
          ),
        ],
      ),
    );
  }
}