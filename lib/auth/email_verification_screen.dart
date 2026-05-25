import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../home_page.dart';
import 'login_repository.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, this.sendEmailOnOpen = false});

  final bool sendEmailOnOpen;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _repository = LoginRepository();

  bool _isChecking = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    if (widget.sendEmailOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendVerificationEmail(showSuccessMessage: false);
      });
    }
  }

  Future<void> _sendVerificationEmail({bool showSuccessMessage = true}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      await user.sendEmailVerification();
      if (!mounted || !showSuccessMessage) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi email xác minh.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      var message = 'Không thể gửi email xác minh. Vui lòng thử lại.';
      if (e.code == 'too-many-requests') {
        message = 'Bạn gửi quá nhiều lần. Vui lòng chờ một lúc rồi thử lại.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _checkVerification() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isChecking = true);

    try {
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser?.emailVerified != true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email chưa được xác minh.')),
        );
        return;
      }

      await _repository.markEmailVerified(refreshedUser!.uid);
      if (!mounted) return;

      // Add delay before navigating to HomePage to ensure data consistency
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác minh email'),
        actions: [
          TextButton(
            onPressed: _isChecking || _isSending ? null : _signOut,
            child: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_unread_outlined,
                        size: 44,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Kiểm tra email của bạn',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chúng tôi đã gửi email xác minh đến $email. Sau khi bấm vào liên kết trong email, quay lại ứng dụng và bấm nút bên dưới để tiếp tục.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        height: 1.45,
                        color: Color(0xFF5B6675),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isChecking || _isSending
                            ? null
                            : _checkVerification,
                        icon: _isChecking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.verified_outlined),
                        label: const Text('Tôi đã xác minh email'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _isChecking || _isSending
                          ? null
                          : () => _sendVerificationEmail(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text(
                        _isSending ? 'Đang gửi...' : 'Gửi lại email xác minh',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
