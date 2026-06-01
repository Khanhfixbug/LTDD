import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  // Xử lý nhiều người chi: Lưu trữ { memberId: soTienDongGop }
  Map<String, double> selectedPayers = {};
  // Bộ điều khiển nhập tiền động cho từng người chi để tránh mất dấu dữ liệu khi build lại UI
  final Map<String, TextEditingController> _payerControllers = {};

  // Xử lý nhiều người hưởng (Kế thừa từ giải pháp chia nhóm trước đó)
  List<String> selectedReceiverIds = [];

  bool _isButtonEnabled = false;
  bool _isLoading = false;
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

        // Chỉ gán giá trị mặc định nếu bộ dữ liệu chọn đang trống
        if (danhSachThanhVien.isNotEmpty) {
          // LẤY ID CHUẨN (Không lấy Tên) làm Key cho người chi
          if (selectedPayers.isEmpty) {
            final firstMemberId = danhSachThanhVien.first['id']?.toString() ?? '';
            if (firstMemberId.isNotEmpty) {
              selectedPayers[firstMemberId] = 0.0;
            }
          }

          // Lấy danh sách ID chuẩn làm người hưởng mặc định
          if (selectedReceiverIds.isEmpty) {
            selectedReceiverIds = danhSachThanhVien
                .map((m) => m['id']?.toString() ?? '')
                .where((id) => id.isNotEmpty)
                .toList();
          }
        }

        _validateForm();
      });
    });
  }

  void _validateForm() {
    final hasExpenseName = _tenChiTieu.text.trim().isNotEmpty;
    final hasReceivers = selectedReceiverIds.isNotEmpty;
    final hasPayers = selectedPayers.isNotEmpty;

    double totalAmount = 0;
    if (selectedPayers.length <= 1) {
      totalAmount = double.tryParse(_soTienChiTieu.text.trim()) ?? 0;
    } else {
      // Nếu nhiều người chi, tự động tính tổng tiền từ các ô con
      totalAmount = selectedPayers.values.fold(0, (sum, val) => sum + val);
      // Gán trực tiếp vào controller chính một cách an toàn
      _soTienChiTieu.text = totalAmount > 0 ? totalAmount.toStringAsFixed(1) : "";
    }

    setState(() {
      _isButtonEnabled = hasExpenseName && hasReceivers && hasPayers && totalAmount > 0;
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nhóm các thông tin cơ bản vào một Card chung
                  _buildSectionCard([
                    _buildLabel(appLanguage.t("Tên chi tiêu"), true),
                    _buildTextField(appLanguage.t("Nhập tên chi tiêu"), controller: _tenChiTieu, onChanged: (_) => _validateForm()),
                    const Divider(height: 30),
                    _buildLabel("${appLanguage.t("Số tiền")} (${appLanguage.selectedCurrency})", true),
                    _buildTextField(
                      appLanguage.t("Nhập số tiền"),
                      controller: _soTienChiTieu,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _validateForm(),
                      suffixText: appLanguage.selectedCurrency,
                      enabled: selectedPayers.length <= 1,
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Nhóm phần Người chi & Người nhận
                  _buildSectionCard([
                    _buildLabel(appLanguage.t("Người chi tiền"), true),
                    _buildMultiPayerSelector(appLanguage),
                    _buildDynamicPayersInputList(appLanguage),
                    const SizedBox(height: 15),
                    _buildLabel(appLanguage.t("Người được chi tiền"), true),
                    _buildMultiReceiverSelector(appLanguage),
                  ]),

                  const SizedBox(height: 16),

                  // Nhóm Ngày & Ghi chú & Ảnh
                  _buildSectionCard([
                    _buildLabel(appLanguage.t("Ngày"), false),
                    _buildDatePickerField(formattedDate),
                    const SizedBox(height: 15),
                    _buildLabel(appLanguage.t("Mô tả"), false),
                    _buildTextField(appLanguage.t("Ghi chú..."), controller: _ghiChuController, maxLines: 2),
                    const SizedBox(height: 15),
                    _buildLabel(appLanguage.t("Ảnh đính kèm"), false),
                    _buildUploadImage(),
                  ]),
                ],
              ),
            ),
          ),
          _buildBottomButton(appLanguage),
        ],
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
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
    bool enabled = true,
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
        enabled: enabled,
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

  // Thay thế hàm _buildDropdownField cũ bằng widget rỗng (hoặc xóa hẳn)
  Widget _buildDropdownField(List<Map<String, dynamic>> items, Function(String?)? onChanged) {
    return const SizedBox.shrink();
  }

  // Thay thế hàm _buildDropdownField2 cũ bằng widget rỗng (hoặc xóa hẳn)
  Widget _buildDropdownField2(List<Map<String, dynamic>> items, String hint, Function(String?)? onChanged) {
    return const SizedBox.shrink();
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

  // Widget hiển thị hộp bấm chọn danh sách NGƯỜI CHI TIỀN
  Widget _buildMultiPayerSelector(AppLanguage appLang) {
    String displayPayerText = "";
    if (selectedPayers.isEmpty) {
      displayPayerText = appLang.t("Chọn người chi tiền");
    } else if (selectedPayers.length == 1) {
      final m = danhSachThanhVien.firstWhere((e) => e['id'] == selectedPayers.keys.first, orElse: () => {});
      displayPayerText = _memberName(m);
    } else {
      displayPayerText = "${selectedPayers.length} ${appLang.t("người cùng chi")}";
    }

    return GestureDetector(
      onTap: () => _showMemberSelectionDialog(isPayer: true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(displayPayerText, style: TextStyle(color: selectedPayers.isEmpty ? Colors.grey[400] : Colors.black, fontSize: 15)),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị hộp bấm chọn danh sách NGƯỜI HƯỞNG THỤ
  Widget _buildMultiReceiverSelector(AppLanguage appLang) {
    return GestureDetector(
      onTap: () => _showMemberSelectionDialog(isPayer: false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedReceiverIds.isEmpty
                  ? appLang.t("Chọn người được chi tiền")
                  : "${selectedReceiverIds.length}/${danhSachThanhVien.length} ${appLang.t("người được chọn")}",
              style: TextStyle(color: selectedReceiverIds.isEmpty ? Colors.grey[400] : Colors.black, fontSize: 15),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // Hộp thoại đa năng dùng chung cho tích chọn Checkbox thành viên
  void _showMemberSelectionDialog({required bool isPayer}) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isPayer ? "Chọn những người chi tiền" : "Chọn những người hưởng chi tiêu"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: danhSachThanhVien.length,
              itemBuilder: (context, index) {
                final member = danhSachThanhVien[index];
                final String id = member['id']?.toString() ?? '';
                final name = _memberName(member);
                final bool isSelected = isPayer ? selectedPayers.containsKey(id) : selectedReceiverIds.contains(id);

                return CheckboxListTile(
                  title: Text(name),
                  activeColor: const Color(0xFF006D4E),
                  value: isSelected,
                  onChanged: (val) {
                    setDialogState(() {
                      if (isPayer) {
                        if (val == true) {
                          selectedPayers[id] = 0.0;
                        } else {
                          if (selectedPayers.length > 1) selectedPayers.remove(id);
                        }
                      } else {
                        if (val == true) {
                          selectedReceiverIds.add(id);
                        } else {
                          if (selectedReceiverIds.length > 1) selectedReceiverIds.remove(id);
                        }
                      }
                    });
                    setState(() {});
                    _validateForm();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Xong", style: TextStyle(color: Color(0xFF006D4E), fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  // CHÌA KHÓA THÔNG MINH: Mục nhập riêng biệt xuất hiện khi có từ 2 người chi trở lên
  Widget _buildDynamicPayersInputList(AppLanguage appLang) {
    if (selectedPayers.length <= 1) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildLabel(appLang.t("Nhập số tiền chi chi tiết cho từng người"), false),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blueGrey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: selectedPayers.keys.length,
            itemBuilder: (context, idx) {
              final id = selectedPayers.keys.elementAt(idx);
              final member = danhSachThanhVien.firstWhere((m) => m['id'] == id, orElse: () => {});

              if (!_payerControllers.containsKey(id)) {
                _payerControllers[id] = TextEditingController(
                    text: selectedPayers[id] == 0.0 ? "" : selectedPayers[id].toString()
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(_memberName(member), style: const TextStyle(fontWeight: FontWeight.w500))),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                        child: TextField(
                          controller: _payerControllers[id],
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: "0",
                            suffixText: appLang.selectedCurrency,
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (val) {
                            setState(() {
                              selectedPayers[id] = double.tryParse(val.trim()) ?? 0.0;
                              _validateForm();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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
            Map<String, double> finalPayersMap = {};
            double tongSoTien = 0.0;

            if (selectedReceiverIds.isEmpty) {
              throw Exception("Vui lòng chọn ít nhất một người hưởng!");
            }

            // Trường hợp 1 người chi tiền
            if (selectedPayers.length <= 1) {
              String uniqueId = '';

              if (selectedPayers.isNotEmpty) {
                uniqueId = selectedPayers.keys.first.trim();
              }

              // BẪY LỖI: Nếu uniqueId bằng tên "toan" hoặc trống, ép tìm lại ID từ danh sách thành viên gốc
              if (uniqueId.isEmpty || !danhSachThanhVien.any((m) => m['id']?.toString() == uniqueId)) {
                // Giả định người chi đầu tiên trong danh sách là người bấm
                if (danhSachThanhVien.isNotEmpty) {
                  uniqueId = danhSachThanhVien.first['id']?.toString() ?? '';
                }
              }

              if (uniqueId.isEmpty) {
                throw Exception("Không tìm thấy mã ID hợp lệ của người chi tiền!");
              }

              tongSoTien = double.tryParse(_soTienChiTieu.text.trim()) ?? 0.0;
              if (tongSoTien <= 0) throw Exception("Vui lòng nhập số tiền lớn hơn 0");

              finalPayersMap[uniqueId] = tongSoTien;
            } else {
              // Trường hợp nhiều người chi tiền
              selectedPayers.forEach((key, value) {
                if (value > 0 && key.trim().isNotEmpty) {
                  finalPayersMap[key.trim()] = value;
                }
              });
              tongSoTien = finalPayersMap.values.fold(0.0, (s, e) => s + e);
            }

            if (finalPayersMap.isEmpty || tongSoTien <= 0) {
              throw Exception("Số tiền phân bổ chi tiêu không hợp lệ!");
            }

            // Làm sạch danh sách ID người hưởng thụ
            final List<String> cleanReceiverIds = selectedReceiverIds
                .map((id) => id.trim())
                .where((id) => id.isNotEmpty)
                .toList();

            if (cleanReceiverIds.isEmpty) {
              throw Exception("Danh sách người hưởng thụ không hợp lệ!");
            }

            // Gọi dịch vụ đẩy lên Firebase Firestore
            await _firebaseService.addExpense(
              groupId: widget.groupId,
              tenChiTieu: _tenChiTieu.text.trim(),
              payers: finalPayersMap,
              nguoiHuongIds: cleanReceiverIds,
              ghiChu: _ghiChuController.text.trim(),
              ngayTao: selectedDate,
              attachmentBase64: _attachmentBase64,
            );

            await FirebaseFirestore.instance.collection('groups').doc(widget.groupId).update({
              'lastActivity': FieldValue.serverTimestamp(),
            });

            if (mounted) Navigator.pop(context, true);
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Lỗi: ${e.toString()}"),
                backgroundColor: Colors.red,
              ),
            );
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
    for (var ctrl in _payerControllers.values) {
      ctrl.dispose();
    }
  }
}