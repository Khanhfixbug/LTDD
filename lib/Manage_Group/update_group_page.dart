import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Thêm provider
import 'package:screensetting/SETTING/app_language.dart'; // Đảm bảo đúng đường dẫn

class CapNhatNhom extends StatefulWidget {
  final String groupId;
  final String initialName;
  final String initialType;
  final String initialDescription;

  const CapNhatNhom({
    super.key,
    required this.groupId,
    this.initialName = '',
    this.initialType = '',
    this.initialDescription = '',
  });

  @override
  State<CapNhatNhom> createState() => _CapNhatNhom();
}

class _CapNhatNhom extends State<CapNhatNhom> {
  final TextEditingController _tenNhom = TextEditingController();
  final TextEditingController _moTaController = TextEditingController();

  String? selectedVlaue;
  bool _isButtonEnabled = false; // Sửa lỗi chính tả
  bool _isSaving = false;

  // Danh sách types nên để key tiếng Việt để khớp với logic cũ hoặc dùng key hệ thống
  final List<String> _types = ["Gia đình", "Người yêu", "Nhóm bạn", "Du lịch", "Khác"];

  @override
  void initState() {
    super.initState();
    _tenNhom.text = widget.initialName;
    _moTaController.text = widget.initialDescription;
    selectedVlaue = widget.initialType.isNotEmpty ? widget.initialType : _types[0];
    
    _tenNhom.addListener(_validateForm);
    _moTaController.addListener(_validateForm);
  }

  void _validateForm() {
    final name = _tenNhom.text.trim();
    final hasChanged = name != widget.initialName || 
                       selectedVlaue != widget.initialType || 
                       _moTaController.text.trim() != widget.initialDescription;

    setState(() {
      _isButtonEnabled = name.isNotEmpty && hasChanged;
    });
  }

  Future<void> _saveChanges(AppLanguage appLang) async {
    final name = _tenNhom.text.trim();
    final type = selectedVlaue ?? '';
    final desc = _moTaController.text.trim();

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
        'groupName': name,
        'groupType': type,
        'description': desc,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(appLang.t('Cập nhật nhóm thành công')))
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${appLang.t('Không thể cập nhật nhóm')}: $e'))
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gọi provider ở đây
    final appLanguage = Provider.of<AppLanguage>(context);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 50, left: 15, right: 15, bottom: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue[700]!, Colors.blue[400]!]),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  appLanguage.t('Cập nhật nhóm'), // Dùng hàm t()
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(appLanguage.t('Tên nhóm'), true),
                  _buildTextField(
                    appLanguage.t('Tên nhóm'), 
                    Icons.group_outlined, 
                    controller: _tenNhom
                  ),
                  const SizedBox(height: 20),
                  _buildLabel(appLanguage.t('Loại nhóm'), true),
                  _buildDropdownField(_types, (newValue) {
                    setState(() {
                      selectedVlaue = newValue;
                      _validateForm();
                    });
                  }, appLanguage),
                  const SizedBox(height: 20),
                  _buildLabel(appLanguage.t('Mô tả'), false),
                  _buildTextField(
                    appLanguage.t('Nhập mô tả (tùy chọn)'), 
                    Icons.note_alt_outlined, 
                    controller: _moTaController, 
                    maxLines: 3
                  ),
                ],
              ),
            ),
          ),

          // Nút xác nhận
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isButtonEnabled && !_isSaving ? () => _saveChanges(appLanguage) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isButtonEnabled ? const Color(0xFF006D4E) : Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(
                      appLanguage.t('Xác nhận'),
                      style: TextStyle(color: _isButtonEnabled ? Colors.white : Colors.grey[600]),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Cập nhật các Widget Helper để nhận label từ bên ngoài
  Widget _buildLabel(String text, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10), // Giảm padding cho cân đối
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(color: Color(0xFF006D4E), fontSize: 15, fontWeight: FontWeight.bold),
          children: [if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, {TextEditingController? controller, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint, 
          prefixIcon: Icon(icon, color: Colors.grey[400]), 
          border: InputBorder.none, 
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12)
        ),
      ),
    );
  }

  Widget _buildDropdownField(List<String> items, Function(String?)? onChanged, AppLanguage appLang) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(10), 
        border: Border.all(color: Colors.grey[200]!)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedVlaue,
          isExpanded: true,
          items: items.map((val) => DropdownMenuItem(value: val, child: Text(appLang.t(val)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tenNhom.dispose();
    _moTaController.dispose();
    super.dispose();
  }
}