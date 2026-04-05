import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screensetting/SETTING/app_language.dart'; // Đảm bảo đúng đường dẫn

class AddMemberSheet extends StatefulWidget {
  final String groupId;
  final Function(String) onMemberAdded;

  const AddMemberSheet({
    super.key,
    required this.groupId,
    required this.onMemberAdded,
  });

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  final TextEditingController _emailController = TextEditingController();
  bool _isButtonEnabled = false;
  bool _isLoading = false;

  // Kiểm tra email hợp lệ đơn giản
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  void _validateForm() {
    setState(() {
      _isButtonEnabled = _isValidEmail(_emailController.text.trim());
    });
  }

  Future<void> _addMemberByEmail(AppLanguage appLang) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      // 1. Tìm người dùng theo email
      final usersQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (usersQuery.docs.isEmpty) {
        if (mounted) {
          _showSnackBar(context, appLang.t('Người dùng không tồn tại'));
        }
        return;
      }

      final userDoc = usersQuery.docs.first;
      final userId = userDoc.id;
      final userData = userDoc.data();
      final displayName = (userData['displayName'] ?? userData['name'] ?? userData['email'] ?? '').toString().trim();

      // 2. Kiểm tra xem đã là thành viên chưa
      final memberRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('members')
          .doc(userId);

      final existing = await memberRef.get();
      if (existing.exists) {
        if (mounted) {
          _showSnackBar(context, appLang.t('Người này đã là thành viên'));
        }
        return;
      }

      // 3. Thêm vào sub-collection members
      await memberRef.set({
        'userId': userId,
        'email': email,
        'displayName': displayName.isEmpty ? email : displayName,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'balance': 0,
      });

      if (mounted) {
        _showSnackBar(context, appLang.t('Đã thêm thành viên'));
        widget.onMemberAdded(userId);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(context, appLang.t('Có lỗi xảy ra'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final appLanguage = Provider.of<AppLanguage>(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                appLanguage.t('Thêm bạn'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 15),

          // Label Email
          RichText(
            text: TextSpan(
              text: appLanguage.t('Email'),
              style: const TextStyle(
                color: Color(0xFF006D4E),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
              children: const [TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
            ),
          ),
          const SizedBox(height: 10),

          // Input Email
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)
              ],
            ),
            child: TextField(
              controller: _emailController,
              onChanged: (v) => _validateForm(),
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: appLanguage.t('Nhập email bạn bè'),
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // Nút Thêm
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isButtonEnabled && !_isLoading ? () => _addMemberByEmail(appLanguage) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isButtonEnabled ? const Color(0xFF006D4E) : Colors.grey[300],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 18, 
                      width: 18, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    )
                  : Text(
                      appLanguage.t('Thêm'), 
                      style: TextStyle(
                        color: _isButtonEnabled ? Colors.white : Colors.grey[600], 
                        fontWeight: FontWeight.bold
                      )
                    ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}