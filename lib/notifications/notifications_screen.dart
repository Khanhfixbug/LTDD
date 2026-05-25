import 'package:flutter/material.dart';

import '../CREATE_JOIN_GROUP/group_repository.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repository = GroupRepository();
  final Set<String> _processingIds = {};
  late final Stream<List<GroupInvitation>> _invitationStream;

  @override
  void initState() {
    super.initState();
    _invitationStream = _repository.watchCurrentUserPendingInvitations();
  }

  Future<void> _acceptInvitation(GroupInvitation invitation) async {
    setState(() => _processingIds.add(invitation.invitationId));

    try {
      await _repository.acceptInvitation(invitation);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tham gia nhóm.')),
      );

      // Add delay to ensure Firebase transaction completes and indexes update
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chấp nhận lời mời: $e'),
          backgroundColor: Colors.red,
        ),
      );

      if (mounted) {
        setState(() => _processingIds.remove(invitation.invitationId));
      }
    }
  }

  Future<void> _declineInvitation(GroupInvitation invitation) async {
    setState(() => _processingIds.add(invitation.invitationId));

    try {
      await _repository.declineInvitation(invitation.invitationId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã từ chối lời mời.')),
      );

      // Add delay to ensure Firebase transaction completes and indexes update
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể từ chối lời mời: $e'),
          backgroundColor: Colors.red,
        ),
      );

      if (mounted) {
        setState(() => _processingIds.remove(invitation.invitationId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: StreamBuilder<List<GroupInvitation>>(
        stream: _invitationStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final invitations = snapshot.data ?? [];
          if (invitations.isEmpty) {
            return const Center(child: Text('Không có thông báo mới.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invitations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              final isProcessing =
                  _processingIds.contains(invitation.invitationId);
              final inviter = invitation.fromDisplayName.isEmpty
                  ? 'Một người dùng'
                  : invitation.fromDisplayName;

              return Container(
                padding: const EdgeInsets.all(16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(
                            Icons.group_add_outlined,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lời mời vào nhóm ${invitation.groupName}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$inviter đã mời bạn tham gia nhóm.',
                                style: const TextStyle(
                                  color: Color(0xFF5B6675),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isProcessing
                                ? null
                                : () => _declineInvitation(invitation),
                            child: const Text('Từ chối'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isProcessing
                                ? null
                                : () => _acceptInvitation(invitation),
                            child: isProcessing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Chấp nhận'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
