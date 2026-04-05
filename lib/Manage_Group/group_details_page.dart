import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Đảm bảo các đường dẫn này khớp với cấu trúc thư mục của bạn
import 'Group_option/add_payment.dart';
import 'Group_option/share_group_sheet.dart';
import 'add_expense_page.dart';
import 'add_member_sheet.dart';
import 'update_group_page.dart';
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

  void _showShareSheet(BuildContext context, Map<String, dynamic> data, AppLanguage appLang) {
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
        memberCount: 0,
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
                      children: [
                        Text(
                          groupData['groupName'] ?? appLanguage.t("Tên nhóm"),
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(appLanguage.t("Chi tiết chi tiêu"), style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            double amount = _readDouble(data['soTien'] ?? data['amount']);
            tongNhom += amount;
            if (data['payerId'] == currentUser?.uid || data['userId'] == currentUser?.uid) {
              tongToi += amount;
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
                  _quickAction(Icons.add_shopping_cart, appLang.t("Chi tiêu"), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddExpensePage(groupId: widget.groupId)));
                  }),
                  _quickAction(Icons.payment, appLang.t("Trả nợ"), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AddPayment(groupId: widget.groupId)));
                  }),
                  _quickAction(Icons.person_add, appLang.t("Thêm bạn"), () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => AddMemberSheet(groupId: widget.groupId, onMemberAdded: (_) {}),
                    );
                  }),
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
              "$label: ${appLang.formatMoney(balance.abs())}",
              balance >= 0 ? Colors.green : Colors.red,
            );
          },
        );
      },
    );
  }

  Widget _buildActivityTab(AppLanguage appLang) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('expenses')
          .where('groupId', isEqualTo: widget.groupId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;

        if (docs.isEmpty) return Center(child: Text(appLang.t("Chưa có giao dịch")));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildTransactionItem(
              data['tenChiTieu'] ?? appLang.t("Chi tiêu"),
              "${appLang.t("Người chi")}: ${data['nguoiChi'] ?? '...'}",
              appLang.formatMoney(_readDouble(data['soTien'])),
              _formatTimestamp(data['createdAt']),
            );
          },
        );
      },
    );
  }

  Widget _buildMemberTile(String name, String sub, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : "?"),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      ),
    );
  }

  Widget _buildTransactionItem(String title, String sub, String amount, String date) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.receipt_long, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("$sub\n$date", style: const TextStyle(fontSize: 12)),
        trailing: Text(amount, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        isThreeLine: true,
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