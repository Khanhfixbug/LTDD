import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../SETTING/app_language.dart';
import '../home_page.dart';
import 'group_repository.dart';

class CreateGroupMembersScreen extends StatefulWidget {
  const CreateGroupMembersScreen({
    super.key,
    required this.draft,
  });

  final GroupDraft draft;

  @override
  State<CreateGroupMembersScreen> createState() =>
      _CreateGroupMembersScreenState();
}

class _CreateGroupMembersScreenState extends State<CreateGroupMembersScreen> {
  final _yourNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _repository = GroupRepository();
  final List<GroupMemberCandidate> _members = [];

  bool _isAddingMember = false;
  bool _isCreatingGroup = false;
  bool _isLoadingDefaultName = false;

  @override
  void initState() {
    super.initState();
    _yourNameController.text =
        FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
    _loadDefaultDisplayName();
  }

  bool get _canCreateGroup => !_isCreatingGroup && !_isLoadingDefaultName;

  @override
  Widget build(BuildContext context) {
    final appLang = context.watch<AppLanguage>();

    return Scaffold(
      appBar: AppBar(
        title: Text(appLang.t('Thêm thành viên')),
        backgroundColor: Colors.blue,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Text(
                      appLang.t('Tên của bạn *'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _yourNameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        helperText: appLang.t(
                          'Để trống sẽ tự động dùng tên user của bạn',
                        ),
                        hintText: appLang.t('Nhập tên hiển thị của bạn'),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      appLang.t('Thêm thành viên bằng email'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: appLang.t('Nhập email thành viên'),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isAddingMember ? null : _handleAddMember,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: _isAddingMember
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(appLang.t('Thêm')),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      appLang.t('Danh sách thành viên'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_members.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          appLang.t('Chưa có thành viên nào được thêm'),
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      )
                    else
                      ..._members.map(
                        (member) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: const Icon(
                                Icons.person_outline,
                                color: Colors.blue,
                              ),
                            ),
                            title: Text(
                              member.displayName.isEmpty
                                  ? member.email
                                  : member.displayName,
                            ),
                            subtitle: Text(member.email),
                            trailing: IconButton(
                              onPressed: () {
                                setState(() {
                                  _members.removeWhere(
                                    (item) => item.userId == member.userId,
                                  );
                                });
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _canCreateGroup ? _handleCreateGroup : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.blue.shade200,
                    foregroundColor: Colors.white,
                  ),
                  child: _isCreatingGroup
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(appLang.t('Tạo nhóm')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddMember() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (!_isValidEmail(email)) {
      _showMessage('Email chưa đúng định dạng.', isError: true);
      return;
    }

    if (currentUser?.email?.trim() == email) {
      _showMessage(
        'Bạn đã là chủ nhóm, không cần thêm lại.',
        isError: true,
      );
      return;
    }

    if (_members.any((member) => member.email == email)) {
      _showMessage('Thành viên này đã có trong danh sách.', isError: true);
      return;
    }

    setState(() {
      _isAddingMember = true;
    });

    try {
      final member = await _repository.findUserByEmail(email);
      if (!mounted) {
        return;
      }

      if (member == null) {
        _showMessage(
          'Không tìm thấy người dùng với email này trong collection users.',
          isError: true,
        );
        return;
      }

      setState(() {
        _members.add(member);
        _emailController.clear();
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Không thể thêm thành viên: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isAddingMember = false;
        });
      }
    }
  }

  Future<void> _handleCreateGroup() async {
    FocusScope.of(context).unfocus();

    if (_yourNameController.text.trim().isEmpty && false) {
      _showMessage('Vui lòng nhập tên của bạn.', isError: true);
      return;
    }

    setState(() {
      _isCreatingGroup = true;
    });

    try {
      final groupId = await _repository.createGroup(
        draft: widget.draft,
        ownerDisplayName: _yourNameController.text.trim(),
        members: _members,
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Tạo nhóm thành công'),
          content: Text('Nhóm đã được tạo thành công. ID: $groupId'),
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

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage('Không thể tạo nhóm: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingGroup = false;
        });
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Future<void> _loadDefaultDisplayName() async {
    setState(() {
      _isLoadingDefaultName = true;
    });

    try {
      final defaultName = await _repository.getCurrentUserDefaultDisplayName();
      if (!mounted || _yourNameController.text.trim().isNotEmpty) {
        return;
      }

      _yourNameController.text = defaultName;
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDefaultName = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _yourNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
