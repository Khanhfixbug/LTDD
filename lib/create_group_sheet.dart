import 'package:flutter/material.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';
import 'package:provider/provider.dart';
import 'SETTING/app_language.dart';

class CreateGroupSheet extends StatelessWidget {
  const CreateGroupSheet({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy đối tượng ngôn ngữ từ Provider
    final lang = context.watch<AppLanguage>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            lang.t("Tạo nhóm hoặc tham gia nhóm"), // Đã bọc dịch
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateGroupScreen(),
                ),
              );
            },
            child: _buildItem(
              icon: Icons.group_add,
              title: lang.t("Tạo nhóm mới"), // Đã bọc dịch
              subtitle: lang.t("Lập nhóm để quản lý chi tiêu hiệu quả."), // Đã bọc dịch
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JoinGroupScreen(),
                ),
              );
            },
            child: _buildItem(
              icon: Icons.numbers,
              title: lang.t("Tham gia bằng mã nhóm"), // Đã bọc dịch
              subtitle: lang.t("Kết nối với nhóm hiện có bằng cách nhập mã."), // Đã bọc dịch
            ),
          ),
          const SizedBox(height: 16),
          _buildItem(
            icon: Icons.qr_code,
            title: lang.t("Tham gia bằng mã QR"), // Đã bọc dịch
            subtitle: lang.t("Quét mã QR để tham gia nhóm."), // Đã bọc dịch
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}