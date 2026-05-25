import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import '../filebase_service.dart';

class AddPayment extends StatefulWidget {
  final String groupId;
  const AddPayment({super.key, required this.groupId});

  @override
  State<AddPayment> createState() => _AddPaymentState();
}

class _AddPaymentState extends State<AddPayment> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  String? _attachmentBase64;

  List<Map<String, dynamic>> memberList = [];
  String? payerName; // Người chi (Sender)
  String? receiverName; // Người nhận (Receiver)
  bool _isButtonEnabled = false;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMembersFromFirebase();
  }

  Future<void> _loadMembersFromFirebase() async {
    String currentUser = await _firebaseService.getCurrentUserName();
    String currentUserLower = currentUser.toLowerCase();

    _firebaseService.getMembers(widget.groupId).listen((members) {
      if (mounted) {
        setState(() {
          List<Map<String, dynamic>> sortedMembers = List.from(members);

          sortedMembers.sort((a, b) {
            String nameA = a['name'].toString().toLowerCase();
            String nameB = b['name'].toString().toLowerCase();
            if (nameA == currentUserLower) return -1;
            if (nameB == currentUserLower) return 1;
            return 0;
          });

          memberList = sortedMembers;

          if (memberList.isNotEmpty) {
            payerName = memberList[0]['name'].toString();
            receiverName = memberList.length > 1
                ? memberList[1]['name'].toString()
                : null;
          }
          _validateForm();
        });
      }
    });
  }

  void _validateForm() {
    setState(() {
      _isButtonEnabled =
          _amountController.text.trim().isNotEmpty &&
          payerName != null &&
          receiverName != null &&
          payerName != receiverName;
    });
  }

  String get formattedDate =>
      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 15,
              right: 15,
              bottom: 30,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[700]!, Colors.green[400]!],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  "Thêm thanh toán",
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
                  _buildLabel("Người trả", true),
                  _buildDropdown(payerName, (val) {
                    setState(() {
                      payerName = val;
                      _validateForm();
                    });
                  }, "Chọn người trả"),

                  const SizedBox(height: 20),

                  _buildLabel("Người nhận", true),
                  _buildDropdown(receiverName, (val) {
                    setState(() {
                      receiverName = val;
                      _validateForm();
                    });
                  }, "Chọn người nhận"),

                  const SizedBox(height: 20),

                  _buildLabel("Số tiền", true),
                  _buildTextField(
                    "Nhập số tiền",
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (v) => _validateForm(),
                  ),

                  const SizedBox(height: 20),

                  _buildLabel("Ngày", false),
                  _buildDatePicker(),

                  const SizedBox(height: 20),

                  _buildLabel("Ghi chú", false),
                  _buildTextField(
                    "Ghi chú (Tùy chọn)",
                    controller: _descriptionController,
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

  // --- WIDGET HELPER ---

  Widget _buildLabel(String text, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(
    String? value,
    Function(String?) onChanged,
    String hint,
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
          value: memberList.any((e) => e['name'] == value) ? value : null,
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: Colors.grey[400])),
          items: memberList
              .map(
                (m) => DropdownMenuItem(
                  value: m['name'].toString(),
                  child: Text(m['name'].toString()),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) setState(() => selectedDate = picked);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(formattedDate, style: const TextStyle(fontSize: 16)),
            const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadImage() {
    return GestureDetector(
      onTap: () => _showImageSourceActionSheet(),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: _attachmentBase64 == null
            ? const Icon(
                Icons.add_a_photo_outlined,
                color: Colors.green,
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
        setState(() => _attachmentBase64 = base64Encode(bytes));
      }
    } catch (e) {
      // ignore
    }
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isButtonEnabled
            ? () async {
                final payerId =
                    memberList.firstWhere(
                      (m) => m['name'] == payerName,
                    )['id'] ??
                    '';
                final receiverId =
                    memberList.firstWhere(
                      (m) => m['name'] == receiverName,
                    )['id'] ??
                    '';
                await _firebaseService.addPayment(
                  groupId: widget.groupId,
                  soTien: double.tryParse(_amountController.text) ?? 0,
                  nguoiChi: payerName!,
                  nguoiHuong: receiverName!,
                  nguoiChiId: payerId,
                  nguoiHuongId: receiverId,
                  ghiChu: _descriptionController.text,
                  ngayTao: selectedDate,
                  attachmentBase64: _attachmentBase64,
                );
                if (mounted) Navigator.pop(context);
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isButtonEnabled
              ? Colors.green[700]
              : Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          "Xác nhận thanh toán",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
