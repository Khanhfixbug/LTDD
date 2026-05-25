import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // Thêm provider
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'filebase_service.dart';
import 'package:screensetting/SETTING/app_language.dart';

class SettlementSuggestion {
  final String fromId;
  final String fromName;
  final String toId;
  final String toName;
  final double amount;
  bool isSelected;

  SettlementSuggestion({
    required this.fromId,
    required this.fromName,
    required this.toId,
    required this.toName,
    required this.amount,
    this.isSelected = true, // Mặc định tích chọn sẵn tất cả
  });
}

class SuggestSettlementPage extends StatefulWidget {
  final String groupId;
  final AppLanguage appLang;

  const SuggestSettlementPage({
    Key? key,
    required this.groupId,
    required this.appLang,
  }) : super(key: key);

  @override
  State<SuggestSettlementPage> createState() => _SuggestSettlementPageState();
}

class _SuggestSettlementPageState extends State<SuggestSettlementPage> {
  bool _isLoading = true;
  List<SettlementSuggestion> _suggestions = [];
  bool _selectAll = true;

  @override
  void initState() {
    super.initState();
    _calculateSettlements();
  }

  // Thuật toán Greedy tối ưu hóa số lượng giao dịch chuyển tiền
  Future<void> _calculateSettlements() async {
    try {
      final membersSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('members')
          .get();

      List<Map<String, dynamic>> debtors = []; // Nhóm người nợ (balance < 0)
      List<Map<String, dynamic>> creditors = []; // Nhóm chủ nợ (balance > 0)

      for (var doc in membersSnapshot.docs) {
        final data = doc.data();
        final String id = doc.id;
        final String name = data['displayName'] ?? data['name'] ?? 'Thành viên';
        final double balance = _readDouble(data['balance']);

        // Làm tròn số để tránh lỗi sai số dấu phẩy động của máy tính (0.00001)
        if (balance < -0.1) {
          debtors.add({'id': id, 'name': name, 'balance': balance.abs()});
        } else if (balance > 0.1) {
          creditors.add({'id': id, 'name': name, 'balance': balance});
        }
      }

      List<SettlementSuggestion> localSuggestions = [];

      int dIdx = 0;
      int cIdx = 0;

      while (dIdx < debtors.length && cIdx < creditors.length) {
        var debtor = debtors[dIdx];
        var creditor = creditors[cIdx];

        double dAmount = debtor['balance'];
        double cAmount = creditor['balance'];
        double minAmount = dAmount < cAmount ? dAmount : cAmount;

        if (minAmount > 0.5) {
          localSuggestions.add(
            SettlementSuggestion(
              fromId: debtor['id'],
              fromName: debtor['name'],
              toId: creditor['id'],
              toName: creditor['name'],
              amount: double.parse(minAmount.toStringAsFixed(2)),
            ),
          );
        }

        debtors[dIdx]['balance'] = dAmount - minAmount;
        creditors[cIdx]['balance'] = cAmount - minAmount;

        if (debtors[dIdx]['balance'] < 0.5) dIdx++;
        if (creditors[cIdx]['balance'] < 0.5) cIdx++;
      }

      setState(() {
        _suggestions = localSuggestions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Lỗi tính toán quyết toán nợ: $e");
    }
  }

  double _readDouble(dynamic val) {
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '0') ?? 0;
  }

  // Thực hiện trả tiền hàng loạt qua WriteBatch
  Future<void> _processSettlement() async {
    final selectedItems = _suggestions.where((s) => s.isSelected).toList();
    if (selectedItems.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final WriteBatch batch = FirebaseFirestore.instance.batch();
      final groupRef = FirebaseFirestore.instance.collection('groups').doc(widget.groupId);

      for (var item in selectedItems) {
        // 1. Cập nhật balance của người trả (Cộng thêm tiền về mức 0)
        final fromMemberRef = groupRef.collection('members').doc(item.fromId);
        batch.update(fromMemberRef, {'balance': FieldValue.increment(item.amount)});

        // 2. Cập nhật balance của người nhận (Trừ bớt khoản được trả)
        final toMemberRef = groupRef.collection('members').doc(item.toId);
        batch.update(toMemberRef, {'balance': FieldValue.increment(-item.amount)});

        // 3. Tạo chứng từ lưu vết trong bảng expenses (dưới dạng loại giao dịch: Trả nợ)
        final expenseRef = FirebaseFirestore.instance.collection('expenses').doc();
        batch.set(expenseRef, {
          'groupId': widget.groupId,
          'tenChiTieu': '${item.fromName} trả nợ cho ${item.toName}',
          'soTien': item.amount,
          'nguoiChi': item.fromName,
          'type': 'payment', // Đánh dấu đây là giao dịch trả nợ, không phải chi tiêu mua đồ
          'createdAt': FieldValue.serverTimestamp(),
          'payers': {item.fromId: item.amount},
          'nguoiHuongIds': [item.toId],
        });
      }

      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.appLang.t("Đã thực hiện thanh toán quyết toán thành công!"))),
      );
      Navigator.pop(context); // Quay về trang chi tiết nhóm
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Có lỗi xảy ra: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appLang.t("Gợi ý chia tiền / Trả nợ")),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _suggestions.isEmpty
          ? const Center(
        child: Text(
          "Nhóm đang có số dư cân bằng!\nKhông có nợ cần quyết toán.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : Column(
        children: [
          // Thanh chọn tất cả
          CheckboxListTile(
            title: const Text(
              "Chọn tất cả gợi ý",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            value: _selectAll,
            activeColor: Colors.blue[700],
            onChanged: (bool? val) {
              if (val != null) {
                setState(() {
                  _selectAll = val;
                  for (var s in _suggestions) {
                    s.isSelected = _selectAll;
                  }
                });
              }
            },
          ),
          const Divider(height: 1),

          // Danh sách hiển thị gợi ý
          Expanded(
            child: ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (context, idx) {
                final item = _suggestions[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: CheckboxListTile(
                    activeColor: Colors.blue[700],
                    value: item.isSelected,
                    onChanged: (bool? val) {
                      setState(() {
                        item.isSelected = val ?? false;
                        // Nếu có một cái bỏ tích thì bỏ tích ô "Chọn tất cả"
                        _selectAll = _suggestions.every((s) => s.isSelected);
                      });
                    },
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.fromName,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.grey, size: 20),
                        Expanded(
                          child: Text(
                            "  ${item.toName}",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Cần trả: ${widget.appLang.formatMoney(item.amount)}",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Nút xác nhận thực hiện thanh toán các mục được chọn
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _suggestions.any((s) => s.isSelected) ? _processSettlement : null,
                child: Text(
                  widget.appLang.t("Xác nhận trả luôn"),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}