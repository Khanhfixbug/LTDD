import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../SETTING/app_language.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final TextEditingController codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Lấy instance của AppLanguage để sử dụng trong toàn bộ build method
    final appLang = context.watch<AppLanguage>();

    return Scaffold(
      appBar: AppBar(
        title: Text(appLang.t("Tham gia nhóm")), // Đã thêm dấu đóng ngoặc )
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              appLang.t("Mã nhóm *"),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: appLang.t("Nhập mã nhóm"),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                onPressed: () {
                  // Xử lý logic tham gia nhóm tại đây
                },
                child: Text(
                  appLang.t("Tiếp tục"),
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }
}