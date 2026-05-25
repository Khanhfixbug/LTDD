import 'package:flutter/material.dart';

import '../CREATE_JOIN_GROUP/group_repository.dart';

class AddMemberSheet extends StatefulWidget {
  final String groupId;

  const AddMemberSheet({
    super.key,
    required this.groupId,
  });

  @override
  State<AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<AddMemberSheet> {
  final TextEditingController _emailController = TextEditingController();
  final _repository = GroupRepository();

  bool _isButtonEnabled = false;
  bool _isLoading = false;

  void _validateForm() {
    setState(() {
      _isButtonEnabled = _emailController.text.trim().isNotEmpty;
    });
  }

  Future<void> _sendInvitation() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final member = await _repository.findUserByEmail(email);
      if (member == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Người dùng không tồn tại')),
        );
        return;
      }

      await _repository.inviteMemberToGroup(
        groupId: widget.groupId,
        member: member,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lời mời tham gia nhóm')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể gửi lời mời: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD8E0EC),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mời thành viên',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: const TextSpan(
              text: 'Email',
              style: TextStyle(
                color: Color(0xFF006D4E),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              children: [
                TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailController,
            onChanged: (v) => _validateForm(),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Nhập email thành viên',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  _isButtonEnabled && !_isLoading ? _sendInvitation : null,
              child: _isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Gửi lời mời'),
            ),
          ),
          const SizedBox(height: 20),
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
