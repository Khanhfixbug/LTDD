import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'CREATE_JOIN_GROUP/create_group_sheet.dart';
import 'CREATE_JOIN_GROUP/group_repository.dart';
import 'Manage_Group/group_details_page.dart';
import 'SETTING/screensettings.dart';
import 'SETTING/app_language.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GroupRepository _repository = GroupRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<GroupDetails> _groups = [];
  bool _loadingGroups = true;

  final Map<String, double> _balances = {};
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>> _subs = {};

  double _totalReceive = 0.0;
  double _totalPay = 0.0;

  @override
  void initState() {
    super.initState();
    _loadGroupsAndSubscribe();
  }

  Future<void> _loadGroupsAndSubscribe() async {
    if (!mounted) return;
    setState(() => _loadingGroups = true);

    try {
      final allGroups = await _repository.getCurrentUserGroups();
      final groups = allGroups.where((g) => g.isArchived != true).toList();

      for (final s in _subs.values) { s.cancel(); }
      _subs.clear();
      _balances.clear();

      if (!mounted) return;
      setState(() {
        _groups = groups;
        _loadingGroups = false;
      });

      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      for (final g in groups) {
        final docRef = FirebaseFirestore.instance
            .collection('groups')
            .doc(g.groupId)
            .collection('members')
            .doc(currentUser.uid);

        final sub = docRef.snapshots().listen((snap) {
          if (!mounted) return;
          double bal = 0.0;
          if (snap.exists) {
            final data = snap.data() ?? {};
            final raw = data['balance'];
            bal = (raw is num) ? raw.toDouble() : (double.tryParse(raw?.toString() ?? '') ?? 0.0);
          }
          //Tự động cập nhật số dư khi có bất kỳ ai thêm chi tiêu trong nhóm
          setState(() {
            _balances[g.groupId] = bal;
            _recomputeTotals();// Tính toán lại tổng thu/chi ngay lập tức
          });
        });

        _subs[g.groupId] = sub;
      }
    } catch (e) {
      if (mounted) setState(() => _loadingGroups = false);
    }
  }

  void _recomputeTotals() {
    double recv = 0.0;
    double pay = 0.0;
    for (final bal in _balances.values) {
      if (bal >= 0) recv += bal; 
      else pay += -bal;
    }
    _totalReceive = recv;
    _totalPay = pay;
  }

  @override
  void dispose() {
    for (final s in _subs.values) { s.cancel(); }
    _subs.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    final appLang = context.watch<AppLanguage>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showCreateGroupSheet(),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Column(
        children: [
          _buildHeader(currentUser, appLang),
          Transform.translate(
            offset: const Offset(0, -50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _buildBalanceCard(true, _totalReceive, _loadingGroups, appLang)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildBalanceCard(false, _totalPay, _loadingGroups, appLang)),
                ],
              ),
            ),
          ),
          _buildGroupListHeader(appLang),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadGroupsAndSubscribe,
              child: _loadingGroups 
                ? const Center(child: CircularProgressIndicator())
                : _groups.isEmpty 
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: 400,
                        alignment: Alignment.center,
                        child: Text(appLang.t("Bạn chưa có nhóm nào")),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _groups.length,
                      itemBuilder: (context, index) => _buildGroupCard(context, _groups[index], appLang),
                    ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBottomNav(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home, color: Colors.blue, size: 30),
            onPressed: () {}, // Đang ở Home rồi
          ),
          const SizedBox(width: 60),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 30),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              // Load lại khi từ Setting quay về (lỡ có Unarchive bên trong)
              _loadGroupsAndSubscribe();
            },
          ),
        ],
      ),
    );
  }

  void _showCreateGroupSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (_) => const CreateGroupSheet(),
    ).then((_) => _loadGroupsAndSubscribe());
  }

  Widget _buildHeader(User? currentUser, AppLanguage appLang) {
    final name = currentUser?.displayName ?? currentUser?.email?.split('@')[0] ?? "Bạn";
    //  DANH SÁCH AVATAR CON VẬT DỄ THƯƠNG (Dạng Icon chuyên nghiệp)
    // có thể đổi sang các icon con vật khác tùy ý như: pets, cattery, bird, dove, owl,...
    final List<IconData> animalIcons = [
      Icons.pets,            // Dấu chân thú cưng
      Icons.flutter_dash,    // Chú chim Dash của Flutter (Siêu hợp với dân code Flutter!)
      Icons.cruelty_free,    // Chú thỏ hoạt hình

    ];

    // Chọn ngẫu nhiên hoặc cố định một icon thú cưng thú vị dựa theo độ dài tên
    final IconData randomAnimal = animalIcons[name.length % animalIcons.length];

    return Container(
      // Tăng nhẹ padding bottom để tạo khoảng không gian bo cong mềm mại hơn
      padding: const EdgeInsets.only(top: 65, left: 24, right: 24, bottom: 90),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[800]!, // Xanh đậm hiện đại
            Colors.blue[500]!, // Xanh sáng năng động
            Colors.teal[400]!, // Hòa chút ánh ngọc lục bảo cho bắt mắt
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // KHU VỰC TEXT: Chào mừng và Tên người dùng xếp dọc chuyên nghiệp
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  appLang.t("Chào mừng quay trở lại,"),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24, // Tăng kích thước chữ tên to rõ ràng
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        )
                      ]
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 15),

          // KHU VỰC AVATAR: Con vật thú vị thiết kế nổi khối nổi bật
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.6), width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ],
            ),
            child: CircleAvatar(
              radius: 26, // Tăng kích thước avatar vừa vặn, đẹp mắt
              backgroundColor: Colors.white, // Nền trắng làm nổi bật icon con vật màu sắc
              child: Icon(
                randomAnimal,
                color: Colors.orange[700], // Màu cam rực rỡ mang lại cảm giác vui tươi
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(bool isReceive, double amount, bool loading, AppLanguage appLang) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // TIÊU ĐỀ KÈM ICON MŨI TÊN (Lên cho Nhận, Xuống cho Trả)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isReceive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 25,
                color: isReceive ? Colors.green[600] : Colors.red[600],
              ),
              const SizedBox(width: 4),
              Text(
                appLang.t(isReceive ? "Bạn nhận được" : "Bạn cần trả"),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // KHU VỰC HIỂN THỊ SỐ TIỀN KHỚP VỚI ĐỒNG XU
          loading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🌟 ICON ĐỒNG XU VÀNG (Dùng Icon tiền tệ đồng bộ sắc cam vàng)
              Icon(
                Icons.monetization_on_rounded, // Hoặc dùng Icons.paid_rounded nhìn cũng rất đẹp
                size: 18,
                color: isReceive ? Colors.amber[600] : Colors.orange[400],
              ),
              const SizedBox(width: 4),

              // SỐ TIỀN TÍNH TOÁN
              Flexible(
                child: Text(
                  appLang.formatMoney(amount),
                  style: TextStyle(
                    color: isReceive ? Colors.green[700] : Colors.red[700],
                    fontSize: 17, // Thu nhỏ nhẹ xuống 17 để khi thêm icon không bị tràn dòng trên màn hình nhỏ
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupListHeader(AppLanguage appLang) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(appLang.t("Nhóm của tôi"), 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, GroupDetails group, AppLanguage appLang) {
    final balance = _balances[group.groupId] ?? 0;

    // Giả định đối tượng 'group' (GroupDetails) có chứa biến thời gian.
    // kiểm tra xem model GroupDetails lưu trường này tên là gì nhé (ví dụ: lastActivity, updatedAt hoặc createdAt)
    final dynamic groupTimestamp = group.lastActivity;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell( // Sử dụng InkWell thay ListTile để bắt sự kiện chạm mượt mà trên toàn bộ layout custom
        onTap: () async {
          await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GroupDetailsPage(groupId: group.groupId))
          );
          _loadGroupsAndSubscribe();
        },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 1. Biểu tượng nhóm bên trái
              CircleAvatar(
                backgroundColor: Colors.blue[50],
                child: const Icon(Icons.group, color: Colors.blue),
              ),
              const SizedBox(width: 15),

              // 2. Khu vực hiển thị thông tin TEXT bên trái (Tên nhóm, số thành viên, thời gian)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      group.groupName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${group.memberCount} ${appLang.t("thành viên")}",
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    // THÊM: Dòng thời gian hoạt động gần nhất dịch tự động
                    Text(
                      "${appLang.t("Gần nhất")}: ${_formatTimeAgo(groupTimestamp, appLang)}",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // 3. Khu vực hiển thị Tiền số dư và chữ "Số dư" bên phải
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    appLang.formatMoney(balance),
                    style: TextStyle(
                      color: balance >= 0 ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // THÊM: Chữ "Số dư" ngay dưới số tiền hiển thị
                  Text(
                    appLang.t("Số dư"),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(dynamic timestamp, AppLanguage appLang) {
    if (timestamp == null) return appLang.t("Chưa có hoạt động");

    DateTime lastTime;
    if (timestamp is Timestamp) {
      lastTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      lastTime = timestamp;
    } else {
      return appLang.t("Chưa có hoạt động");
    }

    final now = DateTime.now();
    final difference = now.difference(lastTime);

    if (difference.inSeconds < 60) {
      return "${difference.inSeconds} ${appLang.t("giây trước")}";
    } else if (difference.inMinutes < 60) {
      return "${difference.inMinutes} ${appLang.t("phút trước")}";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} ${appLang.t("giờ trước")}";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} ${appLang.t("ngày trước")}";
    } else if ((difference.inDays / 7).floor() < 4) {
      return "${(difference.inDays / 7).floor()} ${appLang.t("tuần trước")}";
    } else if ((difference.inDays / 30).floor() < 12) {
      return "${(difference.inDays / 30).floor()} ${appLang.t("tháng trước")}";
    } else {
      return "${(difference.inDays / 365).floor()} ${appLang.t("năm trước")}";
    }
  }
}