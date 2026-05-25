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
      appBar: AppBar(
        title: Text(appLang.t('Thông tin nhóm')),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildInfoTile('Tên nhóm', group.groupName),
                  _buildInfoTile(
                    'Người tạo',
                    group.ownerName.isEmpty ? 'Chưa có thông tin' : group.ownerName,
                  ),
                  _buildInfoTile('Ngày tạo', _formatDate(group.createdAt)),
                  _buildInfoTile('Số thành viên', '${group.memberCount}'),
                  _buildInfoTile(
                    'Mô tả',
                    group.description.isEmpty ? 'Không có mô tả' : group.description,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handleJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.blue.shade200,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Xác nhận'),
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
            color: Colors.black.withOpacity(0.04),
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

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Chưa có';
    }

    final createdAt = timestamp.toDate();
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  Future<void> _handleJoin() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final isMember =
          await _repository.isCurrentUserMember(widget.group.groupId);
      if (!mounted) {
        return;
      }

      if (isMember) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Không thể tham gia'),
            content: const Text('Bạn đã là thành viên của nhóm này rồi.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
        return;
      }

      await _repository.joinGroup(widget.group.groupId);
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Tham gia thành công'),
          content: const Text('Bạn đã tham gia nhóm thành công.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );

      if (!mounted) {
        return;
      }

      // Add delay to ensure Firebase transaction completes and indexes update
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );

    } catch (e) {
      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Có lỗi xảy ra'),
          content: Text('Không thể tham gia nhóm: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
