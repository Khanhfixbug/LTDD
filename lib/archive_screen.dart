import 'package:flutter/material.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nhóm lưu trữ"),
        backgroundColor: Colors.blue,
      ),

      body: const Center(
        child: Text(
          "Không có nhóm lưu trữ",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}