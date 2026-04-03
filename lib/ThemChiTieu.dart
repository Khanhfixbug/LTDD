import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'SETTING/app_language.dart';

class ThemChiTieu extends StatefulWidget {
  const ThemChiTieu({super.key});

  @override
  State<ThemChiTieu> createState() => _ThemChiTieu();
}

class _ThemChiTieu extends State<ThemChiTieu> {
  final TextEditingController _tenChiTieu = TextEditingController();
  final TextEditingController _soTienChiTieu = TextEditingController();
  final TextEditingController _moTa = TextEditingController();

  String? selectedValue;
  String? selectedValue2;
  DateTime selectedDate = DateTime.now();
  bool _isButtomEnabled = false;

  String get formattedDate =>
      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";

  @override
  void dispose() {
    _tenChiTieu.dispose();
    _soTienChiTieu.dispose();
    _moTa.dispose();
    super.dispose();
  }

  void _validdateForm() {
    setState(() {
      _isButtomEnabled = _tenChiTieu.text.trim().isNotEmpty &&
          _soTienChiTieu.text.trim().isNotEmpty &&
          selectedValue != null &&
          selectedValue2 != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lấy instance của AppLanguage để sử dụng hàm t()
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
                  language.t("Thêm chi tiêu"),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Form Nhập liệu
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(language.t("Tên chi tiêu"), true),
                  _buildTextField(
                    language.t("Nhập tên chi tiêu"),
                    controller: _tenChiTieu,
                    onChanged: (value) => _validdateForm(),
                  ),

                  const SizedBox(height: 20),

                  _buildLabel(language.t("Số tiền"), true),
                  _buildTextField(
                    language.t("Nhập số tiền"),
                    controller: _soTienChiTieu,
                    onChanged: (value) => _validdateForm(),
                  ),

                  const SizedBox(height: 20),

                  _buildLabel(language.t("Người chi tiền"), true),
                  _buildDropdownField(["toan", "a", "bc"], (newValue) {
                    setState(() {
                      selectedValue = newValue;
                      _validdateForm();
                    });
                  }),

                  const SizedBox(height: 20),

                  _buildLabel(language.t("Người được chi tiền"), true),
                  _buildDropdownField2(
                    ["toan", "a", "bc"],
                    language.t("Chọn người được chi tiền"),
                    (newValue) {
                      setState(() {
                        selectedValue2 = newValue;
                        _validdateForm();
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildLabel(language.t("Ngày"), false),
                  _buildDatePickerField(formattedDate),

                  const SizedBox(height: 20),

                  _buildLabel(language.t("Mô tả"), false),
                  _buildTextField(
                    language.t("Nhập ghi chú (Tùy chọn)"),
                    controller: _moTa,
                  ),

                  const SizedBox(height: 20),

                  _buildLabel(language.t("Ảnh"), false),
                  _buildUploadImage(),
                ],
              ),
            ),
          ),

          _buildBottomButton(language),
        ],
      ),
    );
  }

  // --- Các Widget bổ trợ (Helper Widgets) ---

  Widget _buildLabel(String text, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          text: text,
          style: const TextStyle(
              color: Color(0xFF006D4E),
              fontSize: 15,
              fontWeight: FontWeight.bold),
          children: [
            if (isRequired)
              const TextSpan(
                  text: " *", style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint,
      {TextEditingController? controller,
      Function(String)? onChanged,
      IconData? icon,
      int maxLines = 1}) {
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
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey[400]) : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
      List<String> items, Function(String?)? onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue ?? items[0],
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

  Widget _buildDropdownField2(
      List<String> items, String hint, Function(String?)? onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue2,
          isExpanded: true,
          hint: Text(hint,
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
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

  Widget _buildDatePickerField(String date) {
    return GestureDetector(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(1990),
          lastDate: DateTime(2100),
        );
        if (picked != null && picked != selectedDate) {
          setState(() {
            selectedDate = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(date, style: const TextStyle(fontSize: 16)),
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadImage() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF006D4E), style: BorderStyle.none),
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey[50],
      ),
      child: const Icon(Icons.cloud_upload_outlined,
          color: Color(0xFF006D4E), size: 30),
    );
  }

  Widget _buildBottomButton(AppLanguage language) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isButtomEnabled
            ? () {
                print("Đã thêm chi tiêu!");
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _isButtomEnabled ? const Color(0xFF006D4E) : Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: _isButtomEnabled ? 2 : 0,
        ),
        child: Text(
          language.t("Thêm chi tiêu"),
          style: TextStyle(
              color: _isButtomEnabled ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}