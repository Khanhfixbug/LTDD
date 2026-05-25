import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../SETTING/app_language.dart';
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
  final GroupRepository _repository = GroupRepository();

  String? _selectedGroupType;
  bool _isCreatingGroup = false;

  static const List<String> _groupTypes = [
    'Du lịch',
    'Gia đình',
    'Bạn bè',
    'Đồng nghiệp',
    'Khác',
  ];

  bool get _isCustomType => _selectedGroupType == 'Khác';

  String get _resolvedGroupType {
    if (_selectedGroupType == null) return '';
    if (_selectedGroupType != 'Khác') return _selectedGroupType!;

    final customValue = _customGroupTypeController.text.trim();
    return customValue.isEmpty ? 'Khác' : customValue;
  }

  bool get _isValidForm =>
      !_isCreatingGroup &&
      _nameController.text.trim().isNotEmpty &&
      _selectedGroupType != null;

  @override
  Widget build(BuildContext context) {
    final appLang = context.watch<AppLanguage>();

    return Scaffold(
      appBar: AppBar(title: Text(appLang.t('Tạo nhóm mới'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _requiredLabel(appLang.t('Tên nhóm')),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: appLang.t('Nhập tên nhóm'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _requiredLabel(appLang.t('Loại nhóm')),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showGroupTypeSheet,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: const InputDecoration(),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedGroupType == null
                                    ? appLang.t('Chọn loại nhóm')
                                    : _resolvedGroupType,
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
                        hintText:
                            appLang.t('Nhập mô tả cho nhóm (tùy chọn)'),
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
                    disabledBackgroundColor: Colors.blue.shade200,
                  ),
                  onPressed: _isValidForm ? _handleContinue : null,
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

  Future<void> _showGroupTypeSheet() async {
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
              title: Text(groupType),
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

  Future<void> _handleContinue() async {
    FocusScope.of(context).unfocus();

    setState(() => _isCreatingGroup = true);

    try {
      await _repository.createGroup(
        draft: GroupDraft(
          groupName: _nameController.text.trim(),
          groupType: _resolvedGroupType,
          description: _descriptionController.text.trim(),
        ),
        ownerDisplayName: '',
        members: const [],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo nhóm thành công.')),
      );

      // Add delay to ensure Firebase transaction completes and indexes update
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tạo nhóm: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreatingGroup = false);
      }
    }
  }

  Widget _requiredLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          children: const [
            TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _customGroupTypeController.dispose();
    super.dispose();
  }
}
