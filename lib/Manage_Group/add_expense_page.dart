import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import 'filebase_service.dart';

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
  String? selectedValue;
  String? selectedValue2;
  bool _isButtomEnabled = false;
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
      if (!mounted) {
        return;
      }

      setState(() {
        final sortedMembers = List<Map<String, dynamic>>.from(members);
        sortedMembers.sort((a, b) {
          final nameA = _memberName(a).toLowerCase();
          final nameB = _memberName(b).toLowerCase();
          if (nameA == currentUserLower) {
            return -1;
          }
          if (nameB == currentUserLower) {
            return 1;
          }
          return nameA.compareTo(nameB);
        });

        danhSachThanhVien = sortedMembers;

        if (danhSachThanhVien.isNotEmpty) {
          selectedValue = _memberName(danhSachThanhVien.first);
          selectedValue2 = danhSachThanhVien.length > 1
              ? _memberName(danhSachThanhVien[1])
              : _memberName(danhSachThanhVien.first);
        }

        _validdateForm();
      });
    });
  }

  void _validdateForm() {
    setState(() {
      _isButtomEnabled =
          _tenChiTieu.text.trim().isNotEmpty &&
          _soTienChiTieu.text.trim().isNotEmpty &&
          selectedValue != null &&
          selectedValue2 != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 15,
              right: 15,
              bottom: 30,
            ),
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
                const Text(
                  "Thêm chi tiêu",
                  style: TextStyle(
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
                  _buildLabel("Tên chi tiêu", true),
                  _buildTextField(
                    "Nhập tên chi tiêu",
                    controller: _tenChiTieu,
                    onChanged: (_) => _validdateForm(),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Số tiền", true),
                  _buildTextField(
                    "Nhập số tiền",
                    controller: _soTienChiTieu,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _validdateForm(),
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Người chi tiền", true),
                  _buildDropdownField(danhSachThanhVien, (newValue) {
                    setState(() {
                      selectedValue = newValue;
                      _validdateForm();
                    });
                  }),
                  const SizedBox(height: 20),
                  _buildLabel("Người được chi tiền", true),
                  _buildDropdownField2(
                    danhSachThanhVien,
                    "Chọn người được chi tiền",
                    (newValue) {
                      setState(() {
                        selectedValue2 = newValue;
                        _validdateForm();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Ngày", false),
                  _buildDatePickerField(formattedDate),
                  const SizedBox(height: 20),
                  _buildLabel("Mô tả", false),
                  _buildTextField(
                    "Nhập ghi chú cho nhóm (Tùy chọn)",
                    controller: _ghiChuController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  _buildLabel("Ảnh", false),
                  _buildUploadImage(),
                ],
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
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
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey[400]) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    List<Map<String, dynamic>> items,
    Function(String?)? onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((e) => _memberName(e) == selectedValue)
              ? selectedValue
              : (items.isNotEmpty ? _memberName(items.first) : null),
          isExpanded: true,
          hint: const Text("Chọn người chi"),
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

  Widget _buildDropdownField2(
    List<Map<String, dynamic>> items,
    String hint,
    Function(String?)? onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.any((e) => _memberName(e) == selectedValue2)
              ? selectedValue2
              : null,
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
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
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Colors.grey,
            ),
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
        ),
        child: _attachmentBase64 == null
            ? const Icon(
                Icons.cloud_upload_outlined,
                color: Color(0xFF006D4E),
                size: 30,
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(_attachmentBase64!),
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }

  Future<void> _showImageSourceActionSheet() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Thư viện'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Máy ảnh'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_attachmentBase64 != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Xóa ảnh'),
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() => _attachmentBase64 = null);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _attachmentBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      // ignore errors for now
    }
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isButtomEnabled
            ? () async {
                final soTien = double.tryParse(_soTienChiTieu.text.trim());
                final tenGiaoDich = _tenChiTieu.text.trim();

                if (soTien == null || soTien <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Số tiền không hợp lệ")),
                  );
                  return;
                }

                await _firebaseService.addExpense(
                  groupId: widget.groupId,
                  tenChiTieu: tenGiaoDich,
                  soTien: soTien,
                  nguoiChi: selectedValue!,
                  nguoiHuong: selectedValue2!,
                  nguoiChiId:
                      danhSachThanhVien.firstWhere(
                        (m) => _memberName(m) == selectedValue,
                      )['id'] ??
                      '',
                  nguoiHuongId:
                      danhSachThanhVien.firstWhere(
                        (m) => _memberName(m) == selectedValue2,
                      )['id'] ??
                      '',
                  ghiChu: _ghiChuController.text,
                  ngayTao: selectedDate,
                  attachmentBase64: _attachmentBase64,
                );

                if (mounted) {
                  Navigator.pop(context, true);
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isButtomEnabled
              ? const Color(0xFF006D4E)
              : Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: _isButtomEnabled ? 2 : 0,
        ),
        child: Text(
          "Thêm chi tiêu",
          style: TextStyle(
            color: _isButtomEnabled ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  String _memberName(Map<String, dynamic> member) {
    return (member['name'] ??
            member['displayName'] ??
            member['email'] ??
            "Nguoi dung")
        .toString();
  }

  @override
  void dispose() {
    _tenChiTieu.dispose();
    _soTienChiTieu.dispose();
    _ghiChuController.dispose();
    super.dispose();
  }
}
