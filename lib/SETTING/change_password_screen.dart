import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'app_language.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // 1. Tạo các controller để lấy dữ liệu từ TextField
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Hàm xử lý đổi mật khẩu
  Future<void> _updatePassword(bool isVN) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        _showSnackBar(isVN ? "Chưa đăng nhập!" : "Not logged in!", Colors.red);
        return;
      }

      // Kiểm tra mật khẩu mới và xác nhận mật khẩu
      if (_newPasswordController.text != _confirmPasswordController.text) {
        _showSnackBar(isVN ? "Mật khẩu không khớp!" : "Passwords do not match!", Colors.red);
        return;
      }
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);

      _showSnackBar(isVN ? "Đổi mật khẩu thành công!" : "Password updated successfully!", Colors.green);
      
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

    } on FirebaseAuthException catch (e) {
      String errorMsg = isVN ? "Lỗi: ${e.message}" : "Error: ${e.message}";
      if (e.code == 'wrong-password') {
        errorMsg = isVN ? "Mật khẩu hiện tại sai!" : "Wrong current password!";
      }
      _showSnackBar(errorMsg, Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLanguage = context.watch<AppLanguage>();
    final bool isVN = appLanguage.locale.languageCode == 'vi';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(isVN ? "Đổi mật khẩu" : "Change Password"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildPasswordField(_currentPasswordController, isVN ? "Mật khẩu hiện tại" : "Current Password"),
            const SizedBox(height: 20),
            _buildPasswordField(_newPasswordController, isVN ? "Mật khẩu mới" : "New Password"),
            const SizedBox(height: 20),
            _buildPasswordField(_confirmPasswordController, isVN ? "Nhập lại mật khẩu" : "Confirm Password"),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                onPressed: () => _updatePassword(isVN),
                child: Text(
                  isVN ? "Cập nhật" : "Update",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}