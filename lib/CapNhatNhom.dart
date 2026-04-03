import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'SETTING/app_language.dart';

class CapNhatNhom extends StatefulWidget {
  const CapNhatNhom({super.key});

  @override
  State<CapNhatNhom> createState() => _CapNhatNhomState();
}

class _CapNhatNhomState extends State<CapNhatNhom> {
  final TextEditingController _tenNhom = TextEditingController();
  bool _isButtonEnabled = false;
  String? selectedValue = "Khác"; // Giá trị mặc định

  @override
  void initState() {
    super.initState();
    _tenNhom.text = "ltdd"; // Giả sử giá trị cũ là ltdd
    _validateForm();
  }

  @override
  void dispose() {
    _tenNhom.dispose();
    super.dispose();
  }

  void _validateForm() {
    setState(() {
      _isButtonEnabled = _tenNhom.text.trim().isNotEmpty && selectedValue != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = context.watch<AppLanguage>();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(top: 50, left: 15, right: 15, bottom: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[400]!],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  language.t("Cập nhật nhóm"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
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
                  _buildLabel(language.t("Tên nhóm"), true),
                  _buildTextField(
                    "ltdd",
                    Icons.group_outlined,
                    controller: _tenNhom,
                    onChanged: (value) => _validateForm(),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildLabel(language.t("Loại nhóm"), true),
                  _buildDropdownField(
                    ["Gia đình", "Người yêu", "Nhóm bạn", "Du lịch", "Khác"],
                    (newValue) {
                      setState(() {
                        selectedValue = newValue;
                        _validateForm();
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildLabel(language.t("Mô tả"), false),
                  _buildTextField(
                    language.t("Nhập ghi chú cho nhóm (tùy chọn)"),
                    Icons.note_alt_outlined,
                    maxLines: 3,
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
                onPressed: _isButtonEnabled
                    ? () {
                        print("Đã cập nhật!");
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isButtonEnabled ? const Color(0xFF006D4E) : Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: _isButtonEnabled ? 2 : 0,
                ),
                child: Text(
                  language.t("Xác nhận"),
                  style: TextStyle(
                    color: _isButtonEnabled ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(color: Color(0xFF006D4E), fontSize: 15, fontWeight: FontWeight.bold),
          children: [
            if (isRequired) const TextSpan(text: " *", style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, IconData icon, {TextEditingController? controller, Function(String)? onChanged, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(icon, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdownField(List<String> items, Function(String?)? onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          items: items.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}