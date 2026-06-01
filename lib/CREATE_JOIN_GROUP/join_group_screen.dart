import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../SETTING/app_language.dart';
import 'group_repository.dart';
import 'join_group_summary_screen.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key, this.scanOnOpen = false});

  final bool scanOnOpen;

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final TextEditingController _codeController = TextEditingController();
  final GroupRepository _repository = GroupRepository();

  bool _isSubmitting = false;
  bool _didAutoScan = false;

  bool get _canContinue =>
      !_isSubmitting && _codeController.text.trim().isNotEmpty;

  bool get _isQrSupportedPlatform {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      default:
        return false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.scanOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didAutoScan) return;
        _didAutoScan = true;
        _openQrScanner();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLang = context.watch<AppLanguage>();
    final isQrMode = widget.scanOnOpen;

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
            if (!isQrMode) ...[
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
            ] else ...[
              Text(
                appLang.t('Quét mã QR của nhóm để tham gia nhanh'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: _isSubmitting ? null : _openQrScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(appLang.t('Quét mã QR để tham gia')),
              ),
            ),
            const Spacer(),
            if (!isQrMode)
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
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
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
    await _findAndOpenGroup(_codeController.text);
  }

  Future<void> _findAndOpenGroup(String code) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final group = await _repository.findGroupByCode(code);
      if (!mounted) return;

      if (group == null) {
        _showMessage('Không tìm thấy nhóm với mã bạn đã nhập.', isError: true);
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JoinGroupSummaryScreen(group: group),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Không thể tìm nhóm: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _openQrScanner() async {
    if (_isSubmitting) return;

    if (!_isQrSupportedPlatform) {
      _showMessage(
        'Thiết bị hiện tại chưa hỗ trợ quét QR. Vui lòng dùng Android/iOS.',
        isError: true,
      );
      return;
    }

    try {
      final code = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const _QrScanPage()),
      );
      if (!mounted || code == null || code.trim().isEmpty) return;

      _codeController.text = code.trim();
      setState(() {});
      await _findAndOpenGroup(code);
    } on MissingPluginException {
      if (!mounted) return;
      _showMessage(
        'Plugin quét QR chưa được đăng ký. Hãy tắt app và chạy lại hoàn toàn (không dùng hot reload).',
        isError: true,
      );
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

class _QrScanPage extends StatefulWidget {
  const _QrScanPage();

  @override
  State<_QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<_QrScanPage> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét mã QR')),
      body: MobileScanner(
        errorBuilder: (context, error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'Không thể truy cập camera. Vui lòng cấp quyền camera trong cài đặt ứng dụng.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          );
        },
        onDetect: (capture) {
          if (_handled) return;
          final value = capture.barcodes.firstOrNull?.rawValue?.trim();
          if (value == null || value.isEmpty) return;
          _handled = true;
          Navigator.of(context).pop(value);
        },
      ),
    );
  }
}
