import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../SETTING/app_language.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();

  String groupType = "Khác";

  @override
  Widget build(BuildContext context) {
    // Khai báo biến language để sử dụng ngắn gọn và tránh lỗi trong const
    final appLang = context.watch<AppLanguage>();

    return Scaffold(
      appBar: AppBar(
        title: Text(appLang.t("Tạo nhóm mới")), // Thêm )
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                appLang.t("Tên nhóm *"),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: appLang.t("Nhập tên nhóm"),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                appLang.t("Loại nhóm *"),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: groupType,
              // Xóa 'const' ở items vì nội dung Text thay đổi theo ngôn ngữ
              items: [
                DropdownMenuItem(
                    value: "Khác", child: Text(appLang.t("Khác"))),
                DropdownMenuItem(
                    value: "Gia đình", child: Text(appLang.t("Gia đình"))),
                DropdownMenuItem(
                    value: "Du lịch", child: Text(appLang.t("Du lịch"))),
              ],
              onChanged: (value) {
                setState(() {
                  groupType = value!;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                appLang.t("Mô tả"),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: appLang.t("Nhập ghi chú cho nhóm (Tùy chọn)"),
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
                  // Xử lý logic tạo nhóm
                },
                child: Text(
                  appLang.t("Tiếp tục"),
                  style: const TextStyle(color: Colors.white),
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
    nameController.dispose();
    descController.dispose();
    super.dispose();
  }
}