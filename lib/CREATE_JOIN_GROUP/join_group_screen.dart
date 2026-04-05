import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../SETTING/app_language.dart';
import 'group_repository.dart';
import 'join_group_summary_screen.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final TextEditingController _codeController = TextEditingController();
  final GroupRepository _repository = GroupRepository();

  bool _isSubmitting = false;

  bool get _canContinue =>
      !_isSubmitting && _codeController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final appLang = context.watch<AppLanguage>();

    return Scaffold(
      appBar: AppBar(
        title: Text(appLang.t('Tham gia nhóm')),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              appLang.t('Mã nhóm *'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _codeController,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.none,
              decoration: InputDecoration(
                hintText: appLang.t('Nhập mã nhóm'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.blue.shade200,
                ),
                onPressed: _canContinue ? _handleContinue : null,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        appLang.t('Tiếp tục'),
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
    });

    try {
      final group = await _repository.findGroupByCode(_codeController.text);
      if (!mounted) {
        return;
      }

      if (group == null) {
        _showMessage('Không tìm thấy nhóm với mã bạn đã nhập.', isError: true);
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JoinGroupSummaryScreen(group: group),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Không thể tìm nhóm: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }
}
