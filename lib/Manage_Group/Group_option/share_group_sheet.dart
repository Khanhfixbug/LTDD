import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:screensetting/SETTING/app_language.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShareGroupSheet extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String createdBy;
  final String createdDate;
  final int memberCount;
  final String description;

  const ShareGroupSheet({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.createdBy,
    required this.createdDate,
    required this.memberCount,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final appLanguage = Provider.of<AppLanguage>(context);

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
              Text(
                appLanguage.t("Chia sẻ và công khai nhóm"),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),

          // Thông tin nhóm
          _buildInfoRow(appLanguage.t("Tên nhóm"), groupName),
          FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('groups')
                .doc(groupId)
                .collection('members')
                .doc(createdBy) // Dùng mã ID truyền vào để đi dò tìm tên
                .get(),
            builder: (context, memberSnap) {
              String creatorName = createdBy; // Mặc định nếu chưa tải xong hoặc lỗi thì hiện ID gốc
              if (memberSnap.hasData && memberSnap.data!.exists) {
                final mData = memberSnap.data!.data() as Map<String, dynamic>;
                creatorName = mData['displayName'] ?? mData['name'] ?? creatorName;
              }
              return _buildInfoRow(appLanguage.t("Tạo bởi"), creatorName);
            },
          ),
          _buildInfoRow(appLanguage.t("Tạo ngày"), createdDate),
          _buildInfoRow(appLanguage.t("Số thành viên"), memberCount.toString()),
          _buildInfoRow(appLanguage.t("Mô tả"), description.isNotEmpty ? description : appLanguage.t("Chưa có mô tả")),

          const SizedBox(height: 25),

          // Hiển thị mã nhóm (groupCode)
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance.collection('groups').doc(groupId).get(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }


              final groupData = snap.data?.data() ?? {};
              final code = groupData['groupCode']?.toString() ?? groupId;



              return Column(
                children: [

                  // 1. Mã QR Code
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: QrImageView(
                      data: code, // Dữ liệu mã hóa (Mã nhóm)
                      version: QrVersions.auto,
                      size: 180.0,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF006D4E), // Màu đồng nhất với app
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF006D4E),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    appLanguage.t("Mã tham gia nhóm"),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(appLanguage.t("Đã sao chép mã nhóm!"))),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF006D4E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF006D4E).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.copy, size: 18, color: Color(0xFF006D4E)),
                          const SizedBox(width: 12),
                          Text(
                            code,
                            style: const TextStyle(
                              color: Color(0xFF006D4E),
                              fontSize: 20,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    appLanguage.t("Sử dụng mã này để mời người khác tham gia nhóm"),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
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
          Text(label, style: const TextStyle(color: Colors.black87, fontSize: 15)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}