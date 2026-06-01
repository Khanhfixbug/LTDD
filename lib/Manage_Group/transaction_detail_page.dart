import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:screensetting/SETTING/app_language.dart'; // Toản kiểm tra lại đường dẫn này

class TransactionDetailPage extends StatefulWidget {
  final DocumentSnapshot transactionDoc;
  final String groupId;
  final AppLanguage appLang;
  // Truyền hàm mở Bottom Sheet từ trang cũ sang để tái sử dụng
  final Function(BuildContext, DocumentSnapshot) onEditTrigger;

  const TransactionDetailPage({
    Key? key,
    required this.transactionDoc,
    required this.groupId,
    required this.appLang,
    required this.onEditTrigger,
  }) : super(key: key);

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {

  Future<Map<String, String>> _getMemberNamesMap() async {
    Map<String, String> memberMap = {};
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId) // Nằm ở đây mới hiểu 'widget.groupId'
          .collection('members')
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        String name = data['displayName'] ?? data['name'] ?? 'Thành viên';
        memberMap[doc.id] = name;
      }
    } catch (e) {
      print("Lỗi lấy danh sách tên thành viên: $e");
    }
    return memberMap;
  }
  // Hàm xử lý xóa giao dịch (Cần hoàn tác balance trước khi xóa)
  Future<void> _deleteTransaction() async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.appLang.t("Xác nhận xóa")),
        content: Text(widget.appLang.t("Bạn có chắc chắn muốn xóa giao dịch này? Số dư các thành viên sẽ được hoàn tác.")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(widget.appLang.t("Hủy"))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(widget.appLang.t("Xóa"), style: const TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final data = widget.transactionDoc.data() as Map<String, dynamic>;
      final double amount = (data['soTien'] ?? data['amount'] ?? 0).toDouble();
      final Map<String, dynamic> payers = data['payers'] is Map ? Map<String, dynamic>.from(data['payers']) : {};
      final List<String> receiverIds = List<String>.from(data['nguoiHuongIds'] ?? []);
      final Map<String, dynamic> receiverCounts = data['receiverCounts'] is Map ? Map<String, dynamic>.from(data['receiverCounts']) : {};

      final batch = FirebaseFirestore.instance.batch();
      final groupRef = FirebaseFirestore.instance.collection('groups').doc(widget.groupId);

      // 1. Hoàn tác tiền cho người trả (Trả lại tiền họ đã bỏ ra -> giảm balance)
      payers.forEach((pId, pAmount) {
        batch.update(groupRef.collection('members').doc(pId), {
          'balance': FieldValue.increment(-pAmount.toDouble())
        });
      });

      // 2. Hoàn tác tiền cho người hưởng (Trả lại tiền họ bị trừ -> tăng balance)
      if (receiverCounts.isNotEmpty) {
        int totalSeats = receiverCounts.values.fold(0, (sum, count) => sum + (count as int));
        double perSeat = amount / (totalSeats > 0 ? totalSeats : 1);
        receiverCounts.forEach((rId, count) {
          batch.update(groupRef.collection('members').doc(rId), {
            'balance': FieldValue.increment(count * perSeat)
          });
        });
      } else {
        double share = amount / (receiverIds.isEmpty ? 1 : receiverIds.length);
        for (var rId in receiverIds) {
          batch.update(groupRef.collection('members').doc(rId), {'balance': FieldValue.increment(share)});
        }
      }

      // 3. Xóa document giao dịch
      batch.delete(widget.transactionDoc.reference);

      await batch.commit();
      Navigator.pop(context); // Quay lại màn hình nhóm
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.appLang.t("Đã xóa giao dịch"))));
    } catch (e) {
      print("Lỗi xóa: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.transactionDoc.data() as Map<String, dynamic>;
    final bool isPayment = data['type'] == 'payment';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appLang.t("Chi tiết giao dịch")),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteTransaction),
        ],
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _getMemberNamesMap(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final memberNamesMap = snapshot.data!;

          // 1. Xử lý đổi ID Người chi thành Tên hiển thị
          String payerName = '...';
          if (data['payers'] is Map && (data['payers'] as Map).isNotEmpty) {
            String firstPayerId = (data['payers'] as Map).keys.first.toString();
            payerName = memberNamesMap[firstPayerId] ?? data['nguoiChi'] ?? firstPayerId;
          } else {
            payerName = data['nguoiChi'] ?? '...';
          }

          // 2. Xử lý đổi danh sách ID Người hưởng thành chuỗi các Tên cách nhau bằng dấu phẩy
          String receiversDisplay = '';
          if (isPayment) {
          // Lấy ra ID của người nhận tiền (thường lưu trong danh sách nguoiHuongIds)
          final List<String> receiverIds = List<String>.from(data['nguoiHuongIds'] ?? []);
          if (receiverIds.isNotEmpty) {
          String firstReceiverId = receiverIds.first;
          // Tìm tên trong map hội viên, nếu không thấy thì hiện ID hoặc chữ 'Người nhận'
          receiversDisplay = memberNamesMap[firstReceiverId] ?? firstReceiverId;
          } else {
          receiversDisplay = widget.appLang.t("Người nhận");
          }
          } else {
            final List<String> receiverIds = List<String>.from(data['nguoiHuongIds'] ?? []);
            final Map<String, dynamic> receiverCounts = data['receiverCounts'] is Map
                ? Map<String, dynamic>.from(data['receiverCounts'])
                : {};

            if (receiverIds.isEmpty) {
              receiversDisplay = widget.appLang.t("Không có người hưởng");
            } else {
              List<String> namedList = [];
              for (var rId in receiverIds) {
                String name = memberNamesMap[rId] ?? rId;
                int count = receiverCounts[rId] is num ? (receiverCounts[rId] as num).toInt() : 1;

                if (count > 1) {
                  namedList.add("$name (+${count - 1} suất đi kèm)");
                } else {
                  namedList.add(name);
                }
              }
              receiversDisplay = namedList.join(', ');
            }
          }

          // Phần UI cũ , chỉ cần đổi giá trị truyền vào 'content' của 2 thẻ Card thông tin
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header: Số tiền và Tên
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      Icon(isPayment ? Icons.handshake : Icons.shopping_bag, size: 50, color: Colors.blue),
                      const SizedBox(height: 15),
                      Text(
                        data['tenChiTieu'] ?? "",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${widget.appLang.formatMoney(data['soTien'] ?? 0)}",
                        style: TextStyle(fontSize: 30, color: Colors.red[700], fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(_formatDateTime(data['createdAt']), style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Chi tiết Người trả / Người hưởng
                _buildInfoCard(
                  title: widget.appLang.t("Trả bởi"),
                  content: payerName, //ĐỔI THÀNH BIẾN payerName
                  icon: Icons.arrow_upward,
                  iconColor: Colors.orange,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  title: widget.appLang.t("Trả cho / Người hưởng"),
                  content: receiversDisplay, //ĐỔI THÀNH BIẾN receiversDisplay
                  icon: Icons.arrow_downward,
                  iconColor: Colors.green,
                ),

                const SizedBox(height: 40),

                // Nút Chỉnh sửa
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    icon: const Icon(Icons.edit),
                    label: Text(widget.appLang.t("Chỉnh sửa"), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      widget.onEditTrigger(context, widget.transactionDoc);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content, required IconData icon, required Color iconColor}) {
    return Container(
      width: double.infinity, // Thêm cho card co giãn hết chiều rộng
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Giúp icon canh trên khi chuỗi tên xuống nhiều dòng
        children: [
          CircleAvatar(backgroundColor: iconColor.withOpacity(0.1), child: Icon(icon, color: iconColor)),
          const SizedBox(width: 15),
          // BỌC THÊM THẺ EXPANDED Ở ĐÂY ĐỂ TRÁNH LỖI tràn viền (OVERFLOW)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(content, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _formatDateTime(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }
    return value?.toString() ?? "";
  }
}