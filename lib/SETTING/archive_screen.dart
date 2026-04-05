import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:screensetting/SETTING/app_language.dart'; // Đảm bảo đúng path này

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng Watch để lắng nghe thay đổi ngôn ngữ
    final appLanguage = context.watch<AppLanguage>();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(child: Text(appLanguage.t("Chưa đăng nhập"))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // Sử dụng appLanguage.t để đồng bộ với các file json
        title: Text(appLanguage.t("Nhóm lưu trữ")),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .where('userIds', arrayContains: user.uid)
            .where('isArchived', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                appLanguage.t("Không có nhóm lưu trữ"),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var group = snapshot.data!.docs[index];
              final data = group.data() as Map<String, dynamic>;

              final groupName = data['groupName'] ?? data['name'] ?? appLanguage.t("Không tên");

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.archive, color: Colors.white),
                  ),
                  title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(appLanguage.t("Đã lưu trữ")),
                  trailing: IconButton(
                    icon: const Icon(Icons.unarchive, color: Colors.blue),
                    onPressed: () async {
                      try {
                        await group.reference.update({
                          'isArchived': false,
                        });

                        // Kiểm tra mounted trước khi dùng context sau hàm async
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(appLanguage.t("Đã khôi phục nhóm")),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint("Lỗi khôi phục: $e");
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}