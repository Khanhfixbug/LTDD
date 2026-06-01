import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../SETTING/app_language.dart';
import 'create_group_members_screen.dart';
import 'group_repository.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customGroupTypeController =
      TextEditingController();

  String? _selectedGroupType;

  static const List<String> _groupTypes = [
    'Du lịch',
    'Gia đình',
    'Bạn bè',
    'Đồng nghiệp',
    'Người yêu',
    'Khác',
  ];

  bool get _isCustomType => _selectedGroupType == 'Khác';

  // Lấy giá trị thực tế để gửi lên Firebase (Dạng gốc chưa dịch)
  String get _resolvedGroupType {
    if (_selectedGroupType == null) return '';
    if (_selectedGroupType != 'Khác') return _selectedGroupType!;

    final customValue = _customGroupTypeController.text.trim();
    return customValue.isEmpty ? 'Khác' : customValue;
  }

  // Hàm helper để hiển thị text đã dịch trên UI
  String _getDisplayText(AppLanguage appLang) {
    if (_selectedGroupType == null) return appLang.t('Chọn loại nhóm');
    if (_selectedGroupType == 'Khác') {
      final customValue = _customGroupTypeController.text.trim();
      return customValue.isEmpty ? appLang.t('Khác') : customValue;
    }
    return appLang.t(_selectedGroupType!);
  }

  bool get _isValidForm =>
      _nameController.text.trim().isNotEmpty && _selectedGroupType != null;

  @override
  Widget build(BuildContext context) {
    final appLang = context.watch<AppLanguage>();

    return Scaffold(
      appBar: AppBar(
        title: Text(appLang.t('Tạo nhóm mới')),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        appLang.t('Tên nhóm *'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: appLang.t('Nhập tên nhóm'),
                        border: OutlineInputBorder(
borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        appLang.t('Loại nhóm *'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _showGroupTypeSheet(appLang),
                      borderRadius: BorderRadius.circular(10),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getDisplayText(appLang),
                                style: TextStyle(
                                  color: _selectedGroupType == null
                                      ? Colors.grey.shade600
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down_rounded),
                          ],
                        ),
                      ),
                    ),
                    if (_isCustomType) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customGroupTypeController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: appLang.t('Nhập loại nhóm'),
                          helperText: appLang.t('(Tùy chọn)'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        appLang.t('Mô tả'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: appLang.t('Nhập mô tả cho nhóm (tùy chọn)'),
border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    disabledBackgroundColor: Colors.blue.shade200,
                  ),
                  onPressed: _isValidForm
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateGroupMembersScreen(
                                draft: GroupDraft(
                                  groupName: _nameController.text.trim(),
                                  groupType: _resolvedGroupType,
                                  description:
                                      _descriptionController.text.trim(),
                                ),
                              ),
                            ),
                          );
                        }
                      : null,
                  child: Text(
                    appLang.t('Tiếp tục'),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showGroupTypeSheet(AppLanguage appLang) async {
    final selectedType = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: _groupTypes.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final groupType = _groupTypes[index];
            return ListTile(
              title: Text(appLang.t(groupType)), // Dịch text trong danh sách
              onTap: () => Navigator.pop(context, groupType),
            );
          },
        ),
      ),
    );

    if (!mounted || selectedType == null) return;

    setState(() {
      _selectedGroupType = selectedType;
      if (selectedType != 'Khác') {
        _customGroupTypeController.clear();
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _customGroupTypeController.dispose();
    super.dispose();
  }
}