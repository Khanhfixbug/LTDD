import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'app_language.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Lấy thông tin hiện tại từ Firebase user
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? "Nguyen Duy Khanh");
    _emailController = TextEditingController(text: user?.email ?? "khanh@example.com");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // 2. Hàm xử lý CẬP NHẬT
  Future<void> _updateProfile() async {
    final lang = Provider.of<AppLanguage>(context, listen: false);
    
    // Hiện vòng xoay chờ
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Cập nhật tên vào Firebase Auth
        await user.updateDisplayName(_nameController.text);
        
        // Cập nhật vào Firestore để lưu lâu dài
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': _nameController.text,
          'email': _emailController.text,
        }, SetOptions(merge: true));

        // Tắt loading
        Navigator.pop(context);

        setState(() {
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(lang.t("Cập nhật thành công!"))),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      print("Lỗi: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final lang = context.watch<AppLanguage>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(lang.t("Thông tin cá nhân"), style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: width * 0.15,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                    child: _imageFile == null ? Icon(Icons.person, size: width * 0.2, color: Colors.blue) : null,
                  ),
                  Positioned(bottom: 0, right: 0, child: GestureDetector(onTap: _pickImage, child: const CircleAvatar(radius: 18, backgroundColor: Colors.blue, child: Icon(Icons.camera_alt, color: Colors.white, size: 18)))),
                ],
              ),
              const SizedBox(height: 30),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: lang.t("Tên hiển thị"),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: lang.t("Email"),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 30),

              // NÚT CẬP NHẬT
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: _updateProfile,
                  child: Text(lang.t("Cập nhật"), style: const TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}