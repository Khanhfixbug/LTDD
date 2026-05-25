import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'app_language.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appLanguage = context.watch<AppLanguage>();
    final bool isVN = appLanguage.locale.languageCode == 'vi';
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(isVN ? "Nhóm lưu trữ" : "Archived Groups"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .where('userId', isEqualTo: user?.uid)
            .where('isArchived', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                isVN ? "Không có nhóm lưu trữ" : "No archived groups",
                style: const TextStyle(fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var group = snapshot.data!.docs[index];
              return ListTile(
                leading: const Icon(Icons.archive, color: Colors.blue),
                title: Text(group['name']), // Giả sử field tên nhóm là 'name'
                subtitle: Text(isVN ? "Đã lưu trữ" : "Archived"),
                trailing: IconButton(
                  icon: const Icon(Icons.unarchive),
                  onPressed: () {
                    group.reference.update({'isArchived': false});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}