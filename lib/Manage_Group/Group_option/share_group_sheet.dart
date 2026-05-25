import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class ShareGroupSheet extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String createdBy;
  final String createdDate;
  final int memberCount;

  const ShareGroupSheet({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.createdBy,
    required this.createdDate,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Chia sẻ và công khai nhóm",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),

          // Thông tin nhóm
          _buildInfoRow("Tên nhóm", groupName),
          _buildInfoRow("Tạo bởi", createdBy),
          _buildInfoRow("Tạo ngày", createdDate),
          _buildInfoRow("Số thành viên", memberCount.toString()),
          _buildInfoRow("Mô tả", "Nhóm quản lý chi tiêu"),

          const SizedBox(height: 20),

          const SizedBox(height: 15),

          // Hiển thị mã nhóm (groupCode) đã được tạo khi tạo nhóm
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance
                .collection('groups')
                .doc(groupId)
                .get(),
            builder: (context, snap) {
              final code =
                  snap.data?.data()?['groupCode']?.toString() ?? groupId;
              return Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Đã sao chép mã nhóm!")),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.copy,
                            size: 16,
                            color: Color(0xFF006D4E),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            code,
                            style: const TextStyle(
                              color: Color(0xFF006D4E),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Sử dụng mã này để mời người khác tham gia nhóm",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
