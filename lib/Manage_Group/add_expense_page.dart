import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // Thêm provider
import 'dart:convert';

import 'filebase_service.dart';
import 'package:screensetting/SETTING/app_language.dart';

class AddExpensePage extends StatefulWidget {
  final String groupId;

  const AddExpensePage({super.key, required this.groupId});

  @override
  State<AddExpensePage> createState() => _AddExpensePage();
}

class _AddExpensePage extends State<AddExpensePage> {
  final TextEditingController _tenChiTieu = TextEditingController();
  final TextEditingController _soTienChiTieu = TextEditingController();
  final TextEditingController _ghiChuController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  String? _attachmentBase64;

  List<Map<String, dynamic>> danhSachThanhVien = [];
  String? selectedValue; // Người chi
  String? selectedValue2; // Người hưởng
  bool _isButtonEnabled = false;
  bool _isLoading = false; // Trạng thái đang lưu
  DateTime selectedDate = DateTime.now();

  String get formattedDate =>
      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";

  @override
  void initState() {
    super.initState();
    _loadMembersFromFirebase();
  }

  Future<void> _loadMembersFromFirebase() async {
    final currentUser = await _firebaseService.getCurrentUserName();
    final currentUserLower = currentUser.toLowerCase();

    _firebaseService.getMembers(widget.groupId).listen((members) {
      if (!mounted) return;

      setState(() {
        final sortedMembers = List<Map<String, dynamic>>.from(members);
        sortedMembers.sort((a, b) {
          final nameA = _memberName(a).toLowerCase();
          final nameB = _memberName(b).toLowerCase();
          if (nameA == currentUserLower) return -1;
          if (nameB == currentUserLower) return 1;
          return nameA.compareTo(nameB);
        });

        danhSachThanhVien = sortedMembers;

        // Chỉ gán giá trị mặc định nếu chưa chọn
        if (danhSachThanhVien.isNotEmpty) {
          selectedValue ??= _memberName(danhSachThanhVien.first);
          if (selectedValue2 == null) {
            selectedValue2 = danhSachThanhVien.length > 1
                ? _memberName(danhSachThanhVien[1])
                : _memberName(danhSachThanhVien.first);
          }
        }

        _validateForm();
      });
    });
  }

  void _validateForm() {
    setState(() {
      _isButtonEnabled = _tenChiTieu.text.trim().isNotEmpty &&
          _soTienChiTieu.text.trim().isNotEmpty &&
          selectedValue != null &&
          selectedValue2 != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lấy instance của AppLanguage
    final appLanguage = context.watch<AppLanguage>();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
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
                  appLanguage.t("Thêm chi tiêu"),
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
                  _buildLabel(appLanguage.t("Tên chi tiêu"), true),
                  _buildTextField(
                    appLanguage.t("Nhập tên chi tiêu"),
                    controller: _tenChiTieu,
                    onChanged: (_) => _validateForm(),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("${appLanguage.t("Số tiền")} (${appLanguage.selectedCurrency})", true),
                  _buildTextField(
                    appLanguage.t("Nhập số tiền"),
                    controller: _soTienChiTieu,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => _validateForm(),
                    suffixText: appLanguage.selectedCurrency,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel(appLanguage.t("Người chi tiền"), true),
                  _buildDropdownField(danhSachThanhVien, (newValue) {
                    setState(() {
                      selectedValue = newValue;
                      _validateForm();
                    });
                  }),
                  const SizedBox(height: 20),
                  _buildLabel(appLanguage.t("Người được chi tiền"), true),
                  _buildDropdownField2(
                    danhSachThanhVien,
                    appLanguage.t("Chọn người được chi tiền"),
                    (newValue) {
                      setState(() {
                        selectedValue2 = newValue;
                        _validateForm();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildLabel(appLanguage.t("Ngày"), false),
                  _buildDatePickerField(formattedDate),
                  const SizedBox(height: 20),
                  _buildLabel(appLanguage.t("Mô tả"), false),
                  _buildTextField(
                    appLanguage.t("Nhập ghi chú cho nhóm (Tùy chọn)"),
                    controller: _ghiChuController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel(appLanguage.t("Ảnh"), false),
                  _buildUploadImage(),
                ],
              ),
            ),
          ),
          _buildBottomButton(appLanguage),
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
          style: const TextStyle(
            color: Color(0xFF006D4E),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          children: [
            if (isRequired)
              const TextSpan(
                text: " *",
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hint, {
    TextEditingController? controller,
    Function(String)? onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? suffixText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          suffixText: suffixText,
          suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdownField(List<Map<String, dynamic>> items, Function(String?)? onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((e) => _memberName(e) == selectedValue) ? selectedValue : null,
          isExpanded: true,
          items: items.map((member) {
            return DropdownMenuItem<String>(
              value: _memberName(member),
              child: Text(_memberName(member)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDropdownField2(List<Map<String, dynamic>> items, String hint, Function(String?)? onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((e) => _memberName(e) == selectedValue2) ? selectedValue2 : null,
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          items: items.map((member) {
            return DropdownMenuItem<String>(
              value: _memberName(member),
              child: Text(_memberName(member)),
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
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(1990),
          lastDate: DateTime(2100),
        );
        if (picked != null) setState(() => selectedDate = picked);
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
            const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadImage() {
    return GestureDetector(
      onTap: () => _showImageSourceActionSheet(),
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _attachmentBase64 == null
            ? const Icon(Icons.cloud_upload_outlined, color: Color(0xFF006D4E), size: 30)
            : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(base64Decode(_attachmentBase64!), fit: BoxFit.cover),
              ),
      ),
    );
  }

  Future<void> _showImageSourceActionSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Thư viện'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Máy ảnh'),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            if (_attachmentBase64 != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa ảnh'),
                onTap: () { Navigator.pop(context); setState(() => _attachmentBase64 = null); },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: source, imageQuality: 70);
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() => _attachmentBase64 = base64Encode(bytes));
    }
  }

  Widget _buildBottomButton(AppLanguage appLanguage) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isButtonEnabled && !_isLoading) ? () async {
          setState(() => _isLoading = true);
          try {
            final soTien = double.tryParse(_soTienChiTieu.text.trim()) ?? 0;
            
            // Tìm ID an toàn
            final payer = danhSachThanhVien.firstWhere((m) => _memberName(m) == selectedValue, orElse: () => {});
            final receiver = danhSachThanhVien.firstWhere((m) => _memberName(m) == selectedValue2, orElse: () => {});

            await _firebaseService.addExpense(
              groupId: widget.groupId,
              tenChiTieu: _tenChiTieu.text.trim(),
              soTien: soTien,
              nguoiChi: selectedValue!,
              nguoiHuong: selectedValue2!,
              nguoiChiId: payer['id'] ?? '',
              nguoiHuongId: receiver['id'] ?? '',
              ghiChu: _ghiChuController.text,
              ngayTao: selectedDate,
              attachmentBase64: _attachmentBase64,
            );

            if (mounted) Navigator.pop(context, true);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
          } finally {
            if (mounted) setState(() => _isLoading = false);
          }
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isButtonEnabled ? const Color(0xFF006D4E) : Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(
              appLanguage.t("Thêm chi tiêu"),
              style: TextStyle(color: _isButtonEnabled ? Colors.white : Colors.grey[600], fontWeight: FontWeight.bold),
            ),
      ),
    );
  }

  String _memberName(Map<String, dynamic> member) {
    return (member['name'] ?? member['displayName'] ?? member['email'] ?? "User").toString();
  }

  @override
  void dispose() {
    _tenChiTieu.dispose();
    _soTienChiTieu.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }
}