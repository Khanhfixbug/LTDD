import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'add_payment.dart';
import 'Group_option/share_group_sheet.dart';
import 'add_expense_page.dart';
import 'add_member_sheet.dart';
import 'suggest_settlement_page.dart';
import 'transaction_detail_page.dart';
import 'all_transactions_page.dart';
import 'Group_option/update_group_page.dart';
import 'package:screensetting/SETTING/app_language.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupId;

  const GroupDetailsPage({super.key, required this.groupId});

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  bool isDuNoSelected = true;
  final currentUser = FirebaseAuth.instance.currentUser;

  // Hiển thị Menu tùy chỉnh
  void _showMenu(BuildContext context, Map<String, dynamic> groupData, AppLanguage appLang) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      appLang.t("Tùy chỉnh"),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                _buildMenuItem(Icons.edit, appLang.t("Chỉnh sửa"), () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CapNhatNhom(
                        groupId: widget.groupId,
                        initialName: groupData['groupName'] ?? "",
                        initialType: groupData['groupType'] ?? "",
                        initialDescription: groupData['description'] ?? "",
                      ),
                    ),
                  );
                }),
                _buildMenuItem(Icons.archive_outlined, appLang.t("Lưu trữ"), () {
                  Navigator.pop(context); // Đóng menu trước khi hiện dialog xác nhận
                  _handleArchive(context, appLang);
                }),
                _buildMenuItem(Icons.share_outlined, appLang.t("Chia sẻ"), () {
                  Navigator.pop(context);
                  _showShareSheet(context, groupData, appLang);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // Logic xử lý lưu trữ nhóm
  void _handleArchive(BuildContext context, AppLanguage appLang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(appLang.t("Xác nhận")),
        content: Text(appLang.t("Bạn có muốn lưu trữ nhóm này không?")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(appLang.t("Hủy"))
          ),
          TextButton(
            onPressed: () async {
              // 1. Đóng dialog xác nhận ngay lập tức
              Navigator.pop(ctx);

              try {
                // 2. Cập nhật Firestore
                await FirebaseFirestore.instance
                    .collection('groups')
                    .doc(widget.groupId)
                    .update({'isArchived': true});

                // 3. Quay về màn hình danh sách nhóm (HomePage)
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLang.t("Đã lưu trữ")))
                  );
                }
              } catch (e) {
                debugPrint("Lỗi lưu trữ: $e");
              }
            },
            child: Text(
                appLang.t("Lưu trữ"),
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }

  void _showShareSheet(BuildContext context, Map<String, dynamic> data, AppLanguage appLang) async {
    QuerySnapshot membersSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('members')
        .get();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => ShareGroupSheet(
        groupId: widget.groupId,
        groupName: data['groupName'] ?? appLang.t("Nhóm"),
        createdBy: data['createdBy'] ?? "Admin",
        createdDate: _formatTimestamp(data['createdAt']),
        memberCount: membersSnapshot.docs.length,
        description: data['description'] ?? data['groupDescription'] ?? "",
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue[700]),
      title: Text(title),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLanguage = Provider.of<AppLanguage>(context);
    final String gId = widget.groupId.trim();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('groups').doc(gId).snapshots(),
        builder: (context, groupSnap) {
          if (!groupSnap.hasData) return const Center(child: CircularProgressIndicator());
          final groupData = groupSnap.data!.data() as Map<String, dynamic>? ?? {};

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 50, left: 15, right: 15, bottom: 70),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue[700]!, Colors.blue[400]!]),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          groupData['groupName'] ?? appLanguage.t("Tên nhóm"),
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4), // Tạo khoảng cách nhỏ giữa Tên và Mô tả
                        Text(
                          // Bốc trường description từ groupData, nếu trống thì hiện "Chưa có mô tả" làm dự phòng
                          groupData['description'] ?? groupData['groupDescription'] ?? appLanguage.t("Chưa có mô tả nhóm"),
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                          maxLines: 1, // Tránh việc mô tả quá dài làm vỡ bố cục giao diện Header
                          overflow: TextOverflow.ellipsis, // Nếu mô tả quá dài sẽ tự động hiển thị dấu ...
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () => _showMenu(context, groupData, appLanguage),
                    ),
                  ],
                ),
              ),

              Transform.translate(
                offset: const Offset(0, -40),
                child: _buildSummaryCard(appLanguage),
              ),

              _buildToggleButtons(appLanguage),
              const SizedBox(height: 10),

              Expanded(
                child: isDuNoSelected
                    ? _buildMemberTab(appLanguage)
                    : _buildActivityTab(appLanguage),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(AppLanguage appLang) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('expenses')
          .where('groupId', isEqualTo: widget.groupId)
          .snapshots(),
      builder: (context, snapshot) {
        double tongNhom = 0;
        double tongToi = 0;

        if (snapshot.hasData) {
          final String myUid = currentUser?.uid ?? '';
          final String myEmail = currentUser?.email ?? '';

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            double amount = _readDouble(data['soTien'] ?? data['amount']);
            tongNhom += amount;

            // --- BƯỚC CẬP NHẬT: TÍNH TOÁN THEO CẤU TRÚC PAYERS MỚI ---
            if (data.containsKey('payers') && data['payers'] is Map) {
              final payersMap = data['payers'] as Map<String, dynamic>;

              // Kiểm tra xem ID (hoặc Email) của bạn có đóng góp tiền trong hóa đơn này không
              if (payersMap.containsKey(myUid)) {
                tongToi += _readDouble(payersMap[myUid]);
              } else if (payersMap.containsKey(myEmail)) {
                tongToi += _readDouble(payersMap[myEmail]);
              }
            }
            // CƠ CHẾ DỰ PHÒNG: Dành cho các hóa đơn cũ lưu theo dạng một người chi đơn lẻ
            else {
              if (data['nguoiChiId'] == myUid || data['nguoiChiId'] == myEmail) {
                tongToi += amount;
              }
            }
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            children: [
              _rowInfo(appLang.t("Tổng chi nhóm"), appLang.formatMoney(tongNhom)),
              _rowInfo(appLang.t("Tôi đã chi"), appLang.formatMoney(tongToi), isBold: true),
              const Divider(height: 25),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: _quickAction(Icons.add_shopping_cart, appLang.t("Thêm chi tiêu"), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AddExpensePage(groupId: widget.groupId)));
                    }),
                  ),
                  Expanded(
                    child: _quickAction(Icons.payment, appLang.t("Thanh toán"), () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AddPayment(groupId: widget.groupId)));
                    }),
                  ),

                  // --- THÊM NÚT GỢI Ý CHIA TIỀN ---
                  Expanded(
                    child: _quickAction(Icons.lightbulb_outline, appLang.t("Gợi ý chia tiên"), () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SuggestSettlementPage(
                            groupId: widget.groupId,
                            appLang: appLang,
                          ),
                        ),
                      );
                    }),
                  ),
                  // ----------------------------------------

                  Expanded(
                    child: _quickAction(Icons.person_add, appLang.t("Thêm bạn"), () {
                      showModalBottomSheet(
                        context: context,
                        builder: (_) => AddMemberSheet(groupId: widget.groupId, onMemberAdded: (_) {}),
                      );
                    }),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildMemberTab(AppLanguage appLang) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('members')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final members = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final m = members[index].data() as Map<String, dynamic>;
            double balance = _readDouble(m['balance']);
            String label = balance >= 0 ? appLang.t("Dư") : appLang.t("Nợ");

            return _buildMemberTile(
              m['displayName'] ?? m['name'] ?? appLang.t("Thành viên"),
              balance,
              appLang,
            );
          },
        );
      },
    );
  }

  Widget _buildActivityTab(AppLanguage appLang) {
    // BƯỚC 1: Dùng StreamBuilder để lấy toàn bộ thành viên trong nhóm về làm bộ nhớ đệm (Cache)
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupId)
          .collection('members')
          .snapshots(),
      builder: (context, membersSnapshot) {
        // Tạo một Map trống để lưu: { 'Mã-ID': 'Tên hiển thị thật' }
        Map<String, String> memberMap = {};

        if (membersSnapshot.hasData) {
          for (var doc in membersSnapshot.data!.docs) {
            final mData = doc.data() as Map<String, dynamic>;
            String name = mData['displayName'] ?? mData['name'] ?? doc.id;
            memberMap[doc.id] = name; // Lưu ID và Tên tương ứng vào Map
          }
        }

        // BƯỚC 2: Gọi Stream lấy danh sách các giao dịch (Giữ nguyên logic cũ của Toản)
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('expenses')
              .where('groupId', isEqualTo: widget.groupId)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    "Lỗi truy vấn: ${snapshot.error}",
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            if (docs.isEmpty) return Center(child: Text(appLang.t("Chưa có giao dịch")));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- KHU VỰC TIÊU ĐỀ MỚI THÊM ---
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 15, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end, // Căn đều phần chân chữ
                    children: [
                      // Bên trái: Chữ tiêu đề và Ngày hiện tại
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appLang.t("Giao dịch gần nhất"),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            // Hiển thị ngày hôm nay (Ví dụ: 25/05/2026)
                            "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      // Bên phải: Nút "Tất cả" để chuyển trang
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AllTransactionsPage(
                                groupId: widget.groupId,
                                appLang: appLang,
                                memberMap: memberMap, // Truyền luôn bộ nhớ đệm Tên thành viên sang trang mới
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          appLang.t("Tất cả"),
                          style: const TextStyle(
                            color: Color(0xFF006D4E), // Màu chủ đạo của app
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Danh sách giao dịch gần nhất (Bọc Expanded để không bị vỡ khung trong Column)
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    // Giới hạn hiển thị khoảng 5-10 giao dịch gần nhất ở màn hình chính cho đẹp và mượt
                    itemCount: docs.length > 5 ? 5 : docs.length,
                    itemBuilder: (context, index) {
                      final docSnapshot = docs[index];
                      final data = docSnapshot.data() as Map<String, dynamic>;

                      // ... (Giữ nguyên toàn bộ logic xử lý dữ liệu và return InkWell bên trong ListView cũ của Toản) ...
                      String rawPayerId = '';
                      if (data['payers'] is Map && (data['payers'] as Map).isNotEmpty) {
                        rawPayerId = (data['payers'] as Map).keys.first.toString();
                      } else if (data['nguoiChi'] != null) {
                        rawPayerId = data['nguoiChi'].toString();
                      }
                      String finalPayerName = memberMap[rawPayerId] ?? rawPayerId;
                      if (finalPayerName.isEmpty) finalPayerName = '...';

                      String displayTitle = data['tenChiTieu'] ?? appLang.t("Chi tiêu");
                      if (data['type'] == 'payment' && (data['tenChiTieu'] == null || data['tenChiTieu'].toString().isEmpty)) {
                        displayTitle = appLang.t("Thanh toán nợ");
                      }

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionDetailPage(
                                transactionDoc: docSnapshot,
                                groupId: widget.groupId,
                                appLang: appLang,
                                onEditTrigger: (ctx, doc) => _showExpenseDetailsSheet(ctx, doc, appLang),
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: _buildTransactionItem(
                          displayTitle,
                          "${appLang.t("Người chi")}: $finalPayerName",
                          appLang.formatMoney(_readDouble(data['soTien'])),
                          _formatTimestamp(data['createdAt']),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMemberTile(String name, double balance, AppLanguage appLang) {
    final bool isReceive = balance >= 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.blue[50], child: Text(name[0].toUpperCase())),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(isReceive ? appLang.t("Dư") : appLang.t("Nợ")),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isReceive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 16, color: isReceive ? Colors.green : Colors.red),
            const SizedBox(width: 8),
            Icon(Icons.monetization_on_rounded, size: 16, color: Colors.amber[700]),
            const SizedBox(width: 4),
            Text(appLang.formatMoney(balance.abs()),
                style: TextStyle(fontWeight: FontWeight.bold, color: isReceive ? Colors.green : Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(String title, String sub, String amount, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: const Icon(Icons.receipt_long, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$sub\n$date", style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.monetization_on_rounded, size: 16, color: Colors.amber[700]),
            const SizedBox(width: 4),
            Text(amount, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButtons(AppLanguage appLang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _toggleBtn(appLang.t("Dư nợ"), isDuNoSelected, () => setState(() => isDuNoSelected = true))),
          const SizedBox(width: 10),
          Expanded(child: _toggleBtn(appLang.t("Hoạt động"), !isDuNoSelected, () => setState(() => isDuNoSelected = false))),
        ],
      ),
    );
  }

  Widget _toggleBtn(String text, bool active, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: active ? Colors.blue[700] : Colors.white,
        foregroundColor: active ? Colors.white : Colors.blue[700],
        elevation: active ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: onTap,
      child: Text(text),
    );
  }

  Widget _rowInfo(String title, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15)),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CircleAvatar(backgroundColor: Colors.blue[50], child: Icon(icon, color: Colors.blue[700])),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

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
                  return const SizedBox(height: 200,
                      child: Center(child: CircularProgressIndicator()));
                }

                final groupMembers = memberSnapshot.data!.docs;

                return Padding(
                  padding: EdgeInsets.only(
                    top: 20, left: 20, right: 20,
                    bottom: MediaQuery
                        .of(context)
                        .viewInsets
                        .bottom + 20,
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
                              expenseData['tenChiTieu'] ??
                                  appLang.t("Chi tiết chi tiêu"),
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "${appLang.formatMoney(totalAmount)}",
                            style: const TextStyle(fontSize: 18,
                                color: Colors.red,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      if ((expenseData['ghiChu'] ?? '')
                          .toString()
                          .isNotEmpty)
                        Text("${appLang.t(
                            "Ghi chú")}: ${expenseData['ghiChu']}",
                            style: TextStyle(color: Colors.grey[600])),

                      const Divider(height: 30),
                      Text(
                        "${appLang.t(
                            "Phân chia suất ăn (bao gồm người đi kèm)")}:",
                        style: const TextStyle(fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),

                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery
                            .of(context)
                            .size
                            .height * 0.35),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: groupMembers.length,
                          itemBuilder: (context, idx) {
                            final mDoc = groupMembers[idx];
                            final mData = mDoc.data() as Map<String, dynamic>;
                            final String mId = mDoc.id;
                            final String mName = mData['displayName'] ??
                                mData['name'] ?? 'Thành viên';

                            bool isReceiver = localReceiverCounts.containsKey(
                                mId);
                            int currentCount = localReceiverCounts[mId] ?? 0;
                            double currentMemberTotal = currentCount *
                                perSeatAmount;

                            return CheckboxListTile(
                              title: Text(mName, style: const TextStyle(
                                  fontWeight: FontWeight.w500)),
                              subtitle: isReceiver
                                  ? Text(
                                "Suất: $currentCount | Trả: ${appLang
                                    .formatMoney(currentMemberTotal)}",
                                style: TextStyle(color: Colors.blue[700],
                                    fontWeight: FontWeight.bold),
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
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red),
                                    onPressed: () {
                                      if (currentCount > 1) {
                                        setSheetState(() =>
                                        localReceiverCounts[mId] =
                                            currentCount - 1);
                                      }
                                    },
                                  ),
                                  Text("$currentCount", style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline,
                                        color: Colors.green),
                                    onPressed: () {
                                      setSheetState(() =>
                                      localReceiverCounts[mId] =
                                          currentCount + 1);
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
                          Text("Tổng số suất ăn: $totalSeats",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text("1 suất = ${appLang.formatMoney(
                              perSeatAmount)} ",
                              style: const TextStyle(color: Colors.grey)),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: localReceiverCounts.isEmpty
                              ? null
                              : () async {
                            Navigator.pop(context);

                            final WriteBatch batch = FirebaseFirestore.instance
                                .batch();
                            final groupRef = FirebaseFirestore.instance
                                .collection('groups').doc(widget.groupId);

                            // 1. Hoàn tác số dư cũ
                            payers.forEach((pId, pAmount) {
                              final pRef = groupRef.collection('members').doc(
                                  pId);
                              batch.update(pRef, {
                                'balance': FieldValue.increment(
                                    -_readDouble(pAmount))
                              });
                            });

                            final int oldReceiversCount = oldReceiverIds.isEmpty
                                ? 1
                                : oldReceiverIds.length;
                            final double oldShare = totalAmount /
                                oldReceiversCount;
                            for (String rId in oldReceiverIds) {
                              final rRef = groupRef.collection('members').doc(
                                  rId);
                              batch.update(rRef,
                                  {'balance': FieldValue.increment(oldShare)});
                            }

                            // 2. Thiết lập tính toán số dư suất ăn mới
                            payers.forEach((pId, pAmount) {
                              final pRef = groupRef.collection('members').doc(
                                  pId);
                              batch.update(pRef, {
                                'balance': FieldValue.increment(
                                    _readDouble(pAmount))
                              });
                            });

                            localReceiverCounts.forEach((rId, count) {
                              final rRef = groupRef.collection('members').doc(
                                  rId);
                              double memberNewShare = count * perSeatAmount;
                              batch.update(rRef, {
                                'balance': FieldValue.increment(-memberNewShare)
                              });
                            });

                            final expenseRef = FirebaseFirestore.instance
                                .collection('expenses').doc(expenseId);
                            batch.update(expenseRef, {
                              'nguoiHuongIds': localReceiverCounts.keys
                                  .toList(),
                              'receiverCounts': localReceiverCounts,
                            });

                            await batch.commit();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(appLang.t(
                                    "Đã cập nhật phân bổ chi tiêu thành công!"))),
                              );
                            }
                          },
                          child: Text(appLang.t("Lưu"), style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              }
            );
          },
        );
      },
    );
  }

  double _readDouble(dynamic val) {
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '0') ?? 0;
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }
    return value?.toString() ?? "";
  }
}

