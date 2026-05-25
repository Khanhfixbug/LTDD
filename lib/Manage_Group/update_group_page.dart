import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  bool _isButtomEnabled = false;
  bool _isSaving = false;

  final List<String> _types = ["Gia đình", "Người yêu", "Nhóm bạn", "Du lịch", "Khác"];

  @override
  void initState() {
    super.initState();
    _tenNhom.text = widget.initialName;
    selectedVlaue = widget.initialType.isNotEmpty ? widget.initialType : _types[0];
    _moTaController.text = widget.initialDescription;
    _validdateForm();
  }

  Future<void> _saveChanges() async {
    final name = _tenNhom.text.trim();
    final type = selectedVlaue ?? '';
    final desc = _moTaController.text.trim();
    if (name.isEmpty || type.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
        'groupName': name,
        'groupType': type,
        'description': desc,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật nhóm thành công')));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Không thể cập nhật nhóm: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          // header
          Container(
            padding: const EdgeInsets.only(top: 50, left: 15, right: 15, bottom: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.blue[700]!, Colors.blue[400]!]),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('Cập nhật nhóm', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
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
                  _buildLabel('Tên nhóm', true),
                  _buildTextField('Tên nhóm', Icons.group_outlined, controller: _tenNhom, onChanged: (_) => _validdateForm()),
                  const SizedBox(height: 20),
                  _buildLabel('Loại nhóm', true),
                  _buildDropdownField(_types, (newValue) {
                    setState(() {
                      selectedVlaue = newValue;
                      _validdateForm();
                    });
                  }),
                  const SizedBox(height: 20),
                  _buildLabel('Mô tả', false),
                  _buildTextField('Nhập mô tả (tùy chọn)', Icons.note_alt_outlined, controller: _moTaController, maxLines: 3, onChanged: (_) => _validdateForm()),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isButtomEnabled && !_isSaving ? _saveChanges : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isButtomEnabled ? const Color(0xFF006D4E) : Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Xác nhận', style: TextStyle(color: _isButtomEnabled ? Colors.white : Colors.grey[600])),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tenNhom.dispose();
    _moTaController.dispose();
    super.dispose();
  }

  void _validdateForm() {
    setState(() {
      _isButtomEnabled = _tenNhom.text.trim().isNotEmpty && (selectedVlaue != null && selectedVlaue!.isNotEmpty);
    });
  }

  // label builder
  Widget _buildLabel(String text, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(color: Color(0xFF006D4E), fontSize: 15, fontWeight: FontWeight.bold),
          children: [if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, {TextEditingController? controller, Function(String)? onChanged, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon, color: Colors.grey[400]), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12)),
      ),
    );
  }

  Widget _buildDropdownField(List<String> items, Function(String?)? onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[200]!)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedVlaue ?? items[0],
          isExpanded: true,
          items: items.map((String value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}