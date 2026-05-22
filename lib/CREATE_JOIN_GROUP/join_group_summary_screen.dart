import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../SETTING/app_language.dart';
import '../home_page.dart';
import 'group_repository.dart';

class JoinGroupSummaryScreen extends StatefulWidget {
  const JoinGroupSummaryScreen({
    super.key,
    required this.group,
  });

  final GroupDetails group;

  @override
  State<JoinGroupSummaryScreen> createState() => _JoinGroupSummaryScreenState();
}

class _JoinGroupSummaryScreenState extends State<JoinGroupSummaryScreen> {
  final GroupRepository _repository = GroupRepository();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final appLang = context.watch<AppLanguage>();
    final group = widget.group;

    return Scaffold(
      backgroundColor: Colors.grey[100], // Màu nền nhẹ nhàng đồng bộ logic UI
      appBar: AppBar(
        title: Text(appLang.t('Thông tin nhóm')),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildInfoTile(appLang.t('Tên nhóm'), group.groupName),
                  _buildInfoTile(
                    appLang.t('Người tạo'),
                    group.ownerName.isEmpty ? appLang.t('Chưa có thông tin') : group.ownerName,
                  ),
                  _buildInfoTile(appLang.t('Ngày tạo'), _formatDate(group.createdAt, appLang)),
                  _buildInfoTile(appLang.t('Số thành viên'), '${group.memberCount}'),
                  _buildInfoTile(
                    appLang.t('Mô tả'),
                    group.description.isEmpty ? appLang.t('Không có mô tả') : group.description,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : () => _handleJoin(appLang),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.blue.shade200,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        appLang.t('Xác nhận'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp? timestamp, AppLanguage appLang) {
    if (timestamp == null) {
      return appLang.t('Chưa có');
    }

    final createdAt = timestamp.toDate();
    // Bạn có thể tùy biến format dd/mm/yyyy hoặc mm/dd/yyyy tùy theo appLang.locale nếu cần
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  Future<void> _handleJoin(AppLanguage appLang) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final isMember = await _repository.isCurrentUserMember(widget.group.groupId);
      if (!mounted) return;

      if (isMember) {
        _showDialog(
          title: appLang.t('Không thể tham gia'),
          content: appLang.t('Bạn đã là thành viên của nhóm này rồi.'),
          buttonText: appLang.t('Đóng'),
        );
        return;
      }

      await _repository.joinGroup(widget.group.groupId);
      if (!mounted) return;

      await _showDialog(
        title: appLang.t('Tham gia thành công'),
        content: appLang.t('Bạn đã tham gia nhóm thành công.'),
        buttonText: appLang.t('Đóng'),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      _showDialog(
        title: appLang.t('Có lỗi xảy ra'),
        content: '${appLang.t('Không thể tham gia nhóm')}: $e',
        buttonText: appLang.t('Đóng'),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _showDialog({
    required String title,
    required String content,
    required String buttonText,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(buttonText, style: const TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
}