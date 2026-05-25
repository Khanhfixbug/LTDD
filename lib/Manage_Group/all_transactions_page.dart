import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:screensetting/SETTING/app_language.dart'; // Toản kiểm tra lại đường dẫn import này cho đúng nhé
import 'transaction_detail_page.dart';

class AllTransactionsPage extends StatefulWidget {
  final String groupId;
  final AppLanguage appLang;
  final Map<String, String> memberMap; // Nhận map ID -> Tên từ trang trước để dùng luôn không cần load lại

  const AllTransactionsPage({
    super.key,
    required this.groupId,
    required this.appLang,
    required this.memberMap,
  });

  @override
  State<AllTransactionsPage> createState() => _AllTransactionsPageState();
}

class _AllTransactionsPageState extends State<AllTransactionsPage> {
  // Bộ lọc hiện tại: 'all' (Tất cả), 'expense' (Chi tiêu), 'payment' (Thanh toán nợ)
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appLang.t("Tất cả giao dịch")),
        backgroundColor: const Color(0xFF006D4E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // THANH CHỌN BỘ LỌC (FILTER TABS)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.grey[100],
            child: Row(
              children: [
                _buildFilterButton('all', widget.appLang.t("Tất cả")),
                const SizedBox(width: 10),
                _buildFilterButton('expense', widget.appLang.t("Chi tiêu")),
                const SizedBox(width: 10),
                _buildFilterButton('payment', widget.appLang.t("Thanh toán")),
              ],
            ),
          ),

          // DANH SÁCH GIAO DỊCH SAU KHI LỌC
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('expenses')
                  .where('groupId', isEqualTo: widget.groupId)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Lỗi: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Thực hiện lọc dữ liệu cục bộ ngay trên máy để tăng tốc độ phản hồi
                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final type = data['type']?.toString() ?? 'expense'; // Mặc định nếu không có type là chi tiêu

                  if (_selectedFilter == 'all') return true;
                  if (_selectedFilter == 'expense') return type != 'payment'; // Loại trừ các hóa đơn thanh toán nợ
                  if (_selectedFilter == 'payment') return type == 'payment';
                  return true;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(widget.appLang.t("Không có giao dịch phù hợp")),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final docSnapshot = filteredDocs[index];
                    final data = docSnapshot.data() as Map<String, dynamic>;

                    // Dịch ID sang tên người chi
                    String rawPayerId = '';
                    if (data['payers'] is Map && (data['payers'] as Map).isNotEmpty) {
                      rawPayerId = (data['payers'] as Map).keys.first.toString();
                    } else if (data['nguoiChi'] != null) {
                      rawPayerId = data['nguoiChi'].toString();
                    }
                    String finalPayerName = widget.memberMap[rawPayerId] ?? rawPayerId;

                    // Xử lý tiêu đề hiển thị phù hợp loại giao dịch
                    String displayTitle = data['tenChiTieu'] ?? widget.appLang.t("Chi tiêu");
                    if (data['type'] == 'payment' && (data['tenChiTieu'] == null || data['tenChiTieu'].toString().isEmpty)) {
                      displayTitle = widget.appLang.t("Thanh toán nợ");
                    }

                    return InkWell(
                      onTap: () {
                        // LỆNH ĐIỀU HƯỚNG SANG TRANG CHI TIẾT GIAO DỊCH
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TransactionDetailPage(
                              transactionDoc: docSnapshot, // Truyền tài liệu giao dịch hiện tại
                              groupId: widget.groupId,     // Truyền mã nhóm
                              appLang: widget.appLang,     // Truyền ngôn ngữ app
                              // Nếu trang AllTransactionsPage không có hàm mở bottom sheet chỉnh sửa,
                              // Toản có thể để trống hoặc tạm thời truyền một hàm trống như dưới đây:
                              onEditTrigger: (ctx, doc) => _showExpenseDetailsSheet(ctx, doc, widget.appLang),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: data['type'] == 'payment' ? Colors.orange[100] : const Color(0xFF006D4E).withOpacity(0.1),
                            child: Icon(
                              data['type'] == 'payment' ? Icons.handshake : Icons.shopping_cart,
                              color: data['type'] == 'payment' ? Colors.orange : const Color(0xFF006D4E),
                            ),
                          ),
                          title: Text(displayTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            "${widget.appLang.t("Người chi")}: $finalPayerName\n${_formatTimestamp(data['createdAt'])}",
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            widget.appLang.formatMoney(_readDouble(data['soTien'])),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: data['type'] == 'payment' ? Colors.green : Colors.red[700],
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget thiết kế nút chọn bộ lọc dạng bo góc gọn gàng
  Widget _buildFilterButton(String filterType, String title) {
    final isSelected = _selectedFilter == filterType;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filterType;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF006D4E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF006D4E) : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // --- Các hàm bổ trợ đọc dữ liệu (Toản nhớ kiểm tra tính đồng bộ với file gốc nhé) ---
  double _readDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      DateTime dt = timestamp.toDate();
      return "${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    return timestamp.toString();
  }

  // 🌟 THÊM HÀM NÀY VÀO CUỐI FILE ALL_TRANSACTIONS_PAGE.DART
  void _showExpenseDetailsSheet(BuildContext context, DocumentSnapshot expenseDoc, AppLanguage appLang) {
    final expenseData = expenseDoc.data() as Map<String, dynamic>? ?? {};
    final String expenseId = expenseDoc.id;
    final double totalAmount = _readDouble(expenseData['soTien'] ?? expenseData['amount']);
    final Map<String, dynamic> payers = expenseData['payers'] is Map ? Map<String, dynamic>.from(expenseData['payers']) : {};
    final List<String> oldReceiverIds = List<String>.from(expenseData['nguoiHuongIds'] ?? []);

    final Map<String, int> localReceiverCounts = {};
    for (var rId in oldReceiverIds) {
      if (rId.isNotEmpty) localReceiverCounts[rId] = 1;
    }

    if (expenseData['receiverCounts'] is Map) {
      final savedCounts = expenseData['receiverCounts'] as Map;
      savedCounts.forEach((k, v) {
        localReceiverCounts[k.toString()] = int.tryParse(v.toString()) ?? 1;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            int totalSeats = localReceiverCounts.values.fold(0, (sum, count) => sum + count);
            if (totalSeats <= 0) totalSeats = 1;
            double perSeatAmount = totalAmount / totalSeats;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('members')
                  .snapshots(),
              builder: (context, memberSnapshot) {
                if (!memberSnapshot.hasData) {
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                }
                final groupMembers = memberSnapshot.data!.docs;

                return Padding(
                  padding: EdgeInsets.only(
                    top: 20, left: 20, right: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              expenseData['tenChiTieu'] ?? appLang.t("Chi tiết chi tiêu"),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "${appLang.formatMoney(totalAmount)}",
                            style: const TextStyle(fontSize: 18, color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      if ((expenseData['ghiChu'] ?? '').toString().isNotEmpty)
                        Text("${appLang.t("Ghi chú")}: ${expenseData['ghiChu']}", style: TextStyle(color: Colors.grey[600])),
                      const Divider(height: 30),
                      Text(
                        "${appLang.t("Phân chia suất ăn (bao gồm người đi kèm)")}:",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.35),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: groupMembers.length,
                          itemBuilder: (context, idx) {
                            final mDoc = groupMembers[idx];
                            final mData = mDoc.data() as Map<String, dynamic>;
                            final String mId = mDoc.id;
                            final String mName = mData['displayName'] ?? mData['name'] ?? 'Thành viên';

                            bool isReceiver = localReceiverCounts.containsKey(mId);
                            int currentCount = localReceiverCounts[mId] ?? 0;
                            double currentMemberTotal = currentCount * perSeatAmount;

                            return CheckboxListTile(
                              title: Text(mName, style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: isReceiver
                                  ? Text(
                                "Suất: $currentCount | Trả: ${appLang.formatMoney(currentMemberTotal)}",
                                style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
                              )
                                  : Text(appLang.t("Không tham gia hưởng")),
                              value: isReceiver,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (bool? checked) {
                                setSheetState(() {
                                  if (checked == true) {
                                    localReceiverCounts[mId] = 1;
                                  } else {
                                    localReceiverCounts.remove(mId);
                                  }
                                });
                              },
                              secondary: isReceiver
                                  ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () {
                                      if (currentCount > 1) {
                                        setSheetState(() => localReceiverCounts[mId] = currentCount - 1);
                                      }
                                    },
                                  ),
                                  Text("$currentCount", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                    onPressed: () {
                                      setSheetState(() => localReceiverCounts[mId] = currentCount + 1);
                                    },
                                  ),
                                ],
                              )
                                  : null,
                            );
                          },
                        ),
                      ),
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Tổng số suất ăn: $totalSeats", style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text("1 suất = ${appLang.formatMoney(perSeatAmount)} ", style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: localReceiverCounts.isEmpty
                              ? null
                              : () async {
                            Navigator.pop(context);
                            final WriteBatch batch = FirebaseFirestore.instance.batch();
                            final groupRef = FirebaseFirestore.instance.collection('groups').doc(widget.groupId);

                            // Hoàn tác số dư cũ
                            payers.forEach((pId, pAmount) {
                              final pRef = groupRef.collection('members').doc(pId);
                              batch.update(pRef, {'balance': FieldValue.increment(-_readDouble(pAmount))});
                            });

                            final int oldReceiversCount = oldReceiverIds.isEmpty ? 1 : oldReceiverIds.length;
                            final double oldShare = totalAmount / oldReceiversCount;
                            for (String rId in oldReceiverIds) {
                              final rRef = groupRef.collection('members').doc(rId);
                              batch.update(rRef, {'balance': FieldValue.increment(oldShare)});
                            }

                            // Thiết lập số dư mới
                            payers.forEach((pId, pAmount) {
                              final pRef = groupRef.collection('members').doc(pId);
                              batch.update(pRef, {'balance': FieldValue.increment(_readDouble(pAmount))});
                            });

                            localReceiverCounts.forEach((rId, count) {
                              final rRef = groupRef.collection('members').doc(rId);
                              double memberNewShare = count * perSeatAmount;
                              batch.update(rRef, {'balance': FieldValue.increment(-memberNewShare)});
                            });

                            final expenseRef = FirebaseFirestore.instance.collection('expenses').doc(expenseId);
                            batch.update(expenseRef, {
                              'nguoiHuongIds': localReceiverCounts.keys.toList(),
                              'receiverCounts': localReceiverCounts,
                            });
                            //THÊM DÒNG NÀY VÀO ĐÂY: Cập nhật mốc thời gian hoạt động mới nhất cho nhóm
                            batch.update(groupRef, {'lastActivity': FieldValue.serverTimestamp()});
                            await batch.commit();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(appLang.t("Đã cập nhật phân bổ chi tiêu thành công!"))),
                              );
                            }
                          },
                          child: Text(appLang.t("Lưu"), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}