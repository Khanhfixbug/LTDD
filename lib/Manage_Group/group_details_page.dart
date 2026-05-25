
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'Group_option/add_payment.dart';
import 'Group_option/share_group_sheet.dart';
import 'add_expense_page.dart';
import 'add_member_sheet.dart';
import 'update_group_page.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupId;

  const GroupDetailsPage({super.key, required this.groupId});

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPage();
}

class _GroupDetailsPage extends State<GroupDetailsPage> {
  bool isDuNoSelected = true;
  double _averageCost = 0;
  String groupName = "Loading...";
  String createdBy = "...";
  String createdDate = "...";
  String groupType = "";
  String groupDescription = "";

  List<Map<String, dynamic>> danhSachThanhVien = [];
  List<Map<String, dynamic>> lichSuGiaoDich = [];
  double tongChiNhom = 0;
  double tongChiToi = 0;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null) {
      _refreshData();
    }
  }

  Future<void> _refreshData() async {
    final currentId = widget.groupId.trim();
    if (currentId.isEmpty) {
      return;
    }

    final groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(currentId)
        .get();

    if (!groupDoc.exists) {
      if (!mounted) {
        return;
      }

      setState(() {
        groupName = "Nhóm không tồn tại";
        createdBy = "Không rõ";
        createdDate = "...";
        danhSachThanhVien = [];
        lichSuGiaoDich = [];
        tongChiNhom = 0;
        tongChiToi = 0;
        _averageCost = 0;
      });
      return;
    }

    final data = groupDoc.data() ?? <String, dynamic>{};
    final membersSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(currentId)
        .collection('members')
        .get();
    final expensesSnapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('groupId', isEqualTo: currentId)
        .get();

    final membersData = membersSnapshot.docs
        .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
        .toList();
    final expensesData = expensesSnapshot.docs
        .map((doc) => <String, dynamic>{'id': doc.id, ...doc.data()})
        .toList();

    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? '';
    final currentEmail = (currentUser?.email ?? '').trim().toLowerCase();
    final currentDisplayName =
        (currentUser?.displayName ?? '').trim().toLowerCase();

    String ownerName = "Người tạo";
    final ownerMember = membersData.cast<Map<String, dynamic>?>().firstWhere(
          (member) =>
              (member?['role'] == 'owner') ||
              (member?['userId'] == data['createdBy']),
          orElse: () => null,
        );
    if (ownerMember != null) {
      ownerName = _memberName(ownerMember);
    } else if ((data['createdBy'] ?? '').toString().isNotEmpty) {
      final ownerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(data['createdBy'].toString())
          .get();
      final ownerData = ownerDoc.data() ?? <String, dynamic>{};
      ownerName = (ownerData['displayName'] ??
              ownerData['email'] ??
              ownerName)
          .toString();
    }

    double tempTongNhom = 0;
    double tempTongToi = 0;
    final processedExpenses = <Map<String, dynamic>>[];

    for (final item in expensesData) {
      final amount = _readAmount(item);
      final payer = _readPayer(item);

      tempTongNhom += amount;
      if (_isCurrentUser(payer, currentUserId, currentDisplayName, currentEmail)) {
        tempTongToi += amount;
      }

      processedExpenses.add({
        "ten": (item['tenChiTieu'] ?? item['title'] ?? "Chi tiêu").toString(),
        "nguoi": payer,
        "tien": "${amount.toStringAsFixed(0)}đ",
        "ngay": _formatExpenseDate(item),
      });
    }

    if (!mounted) {
      return;
    }

    setState(() {
      groupName = (data['groupName'] ?? data['name'] ?? "Tên nhóm").toString();
      groupType = (data['groupType'] ?? '').toString();
      groupDescription = (data['description'] ?? '').toString();
      createdBy = ownerName;
      createdDate = _formatTimestamp(data['createdAt']);
      danhSachThanhVien = membersData;
      lichSuGiaoDich = processedExpenses;
      tongChiNhom = tempTongNhom;
      tongChiToi = tempTongToi;
      _averageCost = tempTongNhom / (membersData.isNotEmpty ? membersData.length : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 50, left: 15, right: 15, bottom: 70),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[400]!],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            print('[GroupDetailsPage] back pressed for group ${widget.groupId}');
                            Navigator.pop(context);
                          },
                    ),
                    Column(
                      children: [
                        Text(
                          groupName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${danhSachThanhVien.length} thành viên",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () {
                        _showMunu(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -40),
            child: _buildSummaryCard(),
          ),
          _buildToggleButtons(),
          const SizedBox(height: 20),
          Expanded(
            child: isDuNoSelected
                ? _buildDanhSachThanhVien()
                : _buildLichSuHoatDong(),
          ),
        ],
      ),
    );
  }

  void _showMunu(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Tùy chỉnh",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                _buildMenuItem(Icons.edit, "Chỉnh sửa", () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CapNhatNhom(
                        groupId: widget.groupId,
                        initialName: groupName,
                        initialType: groupType,
                        initialDescription: groupDescription,
                      ),
                    ),
                  ).then((value) {
                    if (value == true) {
                      _refreshData();
                    }
                  });
                }),
               _buildMenuItem(Icons.archive_outlined, "Lưu trữ", () async {
                    Navigator.pop(context);

                    try {
                     await FirebaseFirestore.instance
                          .collection('groups')
                          .doc(widget.groupId)
                          .update({
                        'isArchived': true,
                      });
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Đã lưu trữ nhóm"),
                        ),
                      );

                     if (Navigator.canPop(context)) {
                      Navigator.pop(context, true);
                    }

                    } catch (e) {
                      debugPrint("Archive error: $e");

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Lỗi: $e"),
                        ),
                      );
                    }
                  }),
                _buildMenuItem(Icons.share_outlined, "Chia sẻ", () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                    ),
                    builder: (context) => ShareGroupSheet(
                      groupId: widget.groupId,
                      groupName: groupName,
                      createdBy: createdBy,
                      createdDate: createdDate,
                      memberCount: danhSachThanhVien.length,
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1976D2)),
      title: Text(title),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          _rowInfo("Tổng chi của nhóm", "${tongChiNhom.toStringAsFixed(0)}đ"),
          _rowInfo("Tổng chi của tôi", "${tongChiToi.toStringAsFixed(0)}đ"),
          _rowInfo("Trung bình mỗi người", "${_averageCost.toStringAsFixed(0)}đ"),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _quickAction(Icons.post_add, "Thêm chi tiêu"),
              _quickAction(Icons.swap_horiz, "Thêm thanh toán"),
              _quickAction(Icons.lightbulb_outline, "Gợi ý"),
              _quickAction(Icons.person_add_alt, "Thêm bạn"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rowInfo(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String title) {
    return GestureDetector(
      onTap: () {
        if (title == "Thêm chi tiêu") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddExpensePage(groupId: widget.groupId),
            ),
          ).then((_) => _refreshData());
        } else if (title == "Thêm thanh toán") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPayment(groupId: widget.groupId),
            ),
          ).then((_) => _refreshData());
        } else if (title == "Thêm bạn") {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => AddMemberSheet(
              groupId: widget.groupId,
            ),
          );
        }
      },
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF006D4E)),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildToggleButtons() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF1976D2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isDuNoSelected = true),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDuNoSelected
                      ? const Color(0xFF1976D2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.money,
                      color: isDuNoSelected
                          ? Colors.white
                          : const Color(0xFF1976D2),
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "Dư nợ",
                      style: TextStyle(
                        color: isDuNoSelected
                            ? Colors.white
                            : const Color(0xFF1976D2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isDuNoSelected = false),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: !isDuNoSelected
                      ? const Color(0xFF1976D2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      color: !isDuNoSelected
                          ? Colors.white
                          : const Color(0xFF1976D2),
                      size: 18,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      "Hoạt động",
                      style: TextStyle(
                        color: !isDuNoSelected
                            ? Colors.white
                            : const Color(0xFF1976D2),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberItem(String name, String role, String amount, Color amountColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Text(
              name.isEmpty ? "?" : name[0].toUpperCase(),
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(role, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
              ),
              const Text("Số dư", style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDanhSachThanhVien() {
    if (widget.groupId.trim().isEmpty) {
      return const Center(child: Text("Thiếu mã nhóm"));
    }

    if (danhSachThanhVien.isEmpty) {
      return const Center(child: Text("Nhóm chưa có thành viên"));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: danhSachThanhVien.map((member) {
        final name = _memberName(member);
        final role = _memberRole(member);
        final balance = _readMemberBalance(member);

        return _buildMemberItem(
          name,
          role,
          "${balance.toStringAsFixed(0)}đ",
          balance >= 0 ? Colors.green : Colors.red,
        );
      }).toList(),
    );
  }

  Widget _buildLichSuHoatDong() {
    if (lichSuGiaoDich.isEmpty) {
      return const Center(child: Text("Chưa có giao dịch nào"));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Giao dịch gần nhất",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text("Tất cả", style: TextStyle(color: Color(0xFF00A86B))),
          ],
        ),
        const SizedBox(height: 10),
        ...lichSuGiaoDich.map((item) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item['ngay'].toString(), style: const TextStyle(color: Colors.grey)),
              _buildTransactionItem(
                item['ten'].toString(),
                "Trả bởi: ${item['nguoi']}",
                item['tien'].toString(),
                Icons.receipt_long,
                Colors.red,
              ),
              const SizedBox(height: 15),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTransactionItem(
    String title,
    String subtitle,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(amount, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

  String _memberName(Map<String, dynamic> member) {
    return (member['displayName'] ?? member['name'] ?? member['email'] ?? "Không tên")
        .toString();
  }

  String _memberRole(Map<String, dynamic> member) {
    final role = (member['role'] ?? '').toString();
    if (role == 'owner') {
      return "Trưởng nhóm";
    }
    if (role == 'member' || role.isEmpty) {
      return "Thành viên";
    }
    return role;
  }

  double _readMemberBalance(Map<String, dynamic> member) {
    final raw = member['balance'];
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  double _readAmount(Map<String, dynamic> expense) {
    final raw = expense['soTien'] ?? expense['amount'];
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  String _readPayer(Map<String, dynamic> expense) {
    return (expense['nguoiChi'] ?? expense['payer'] ?? "Không rõ").toString();
  }

  bool _isCurrentUser(
    String payer,
    String currentUserId,
    String currentDisplayName,
    String currentEmail,
  ) {
    final normalizedPayer = payer.trim().toLowerCase();
    return normalizedPayer == currentDisplayName ||
        normalizedPayer == currentEmail ||
        normalizedPayer == currentUserId.toLowerCase();
  }

  String _formatExpenseDate(Map<String, dynamic> expense) {
    final timestamp = expense['ngay Tao'] ?? expense['createdAt'] ?? expense['date'];
    return _formatTimestamp(timestamp);
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      final date = value.toDate();
      return "${date.day}/${date.month}/${date.year}";
    }
    if (value is DateTime) {
      return "${value.day}/${value.month}/${value.year}";
    }
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
    return "Hôm nay";
  }
}
