import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../SETTING/app_language.dart';

const createGroupAction = 'create';
const joinGroupAction = 'join';

class CreateGroupSheet extends StatelessWidget {
  const CreateGroupSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguage>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
          Text(
            lang.t('Nhóm'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _SheetAction(
            icon: Icons.group_add_rounded,
            title: lang.t('Tạo nhóm mới'),
            subtitle: lang.t('Lập nhóm để quản lý chi tiêu cùng nhau.'),
            onTap: () {
              Navigator.of(context).pop(createGroupAction);
            },
          ),
          const SizedBox(height: 12),
          _SheetAction(
            icon: Icons.vpn_key_outlined,
            title: lang.t('Tham gia nhóm bằng mã'),
            subtitle: lang.t(
              'Nhập mã nhóm để xem thông tin và xác nhận tham gia.',
            ),
            onTap: () {
              Navigator.of(context).pop(joinGroupAction);
            },
          ),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EEF7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.blue.shade700),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF5B6675),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A96A8)),
          ],
        ),
      ),
    );
  }
}
