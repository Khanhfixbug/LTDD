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
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue[700]!, Colors.blue[400]!]),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("${appLang.t("Chào")}, $name", 
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
          const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text(appLang.t(isReceive ? "Bạn nhận được" : "Bạn cần trả"), 
            style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(height: 8),
          loading
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(
                  appLang.formatMoney(amount),
                  style: TextStyle(
                    color: isReceive ? Colors.green : Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        onTap: () async {
          await Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => GroupDetailsPage(groupId: group.groupId))
          );
          _loadGroupsAndSubscribe();
        },
        leading: CircleAvatar(
          backgroundColor: Colors.blue[50],
          child: const Icon(Icons.group, color: Colors.blue),
        ),
        title: Text(group.groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${group.memberCount} ${appLang.t("thành viên")}"),
        trailing: Text(
          appLang.formatMoney(balance),
          style: TextStyle(
            color: balance >= 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 15
          ),
        ),
      ),
    );
  }
}