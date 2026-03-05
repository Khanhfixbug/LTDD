import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông tin về chúng tôi"),
        backgroundColor: Colors.blue,
      ),

      body: const Padding(
        padding: EdgeInsets.all(20),

        child: Text(
          "Ứng dụng giúp bạn quản lý chi tiêu nhóm, chia tiền và theo dõi các khoản nợ giữa bạn bè.",
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}