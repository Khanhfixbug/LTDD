import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'CREATE_JOIN_GROUP/create_group_sheet.dart';
import 'CREATE_JOIN_GROUP/create_group_screen.dart';
import 'CREATE_JOIN_GROUP/group_repository.dart';
import 'CREATE_JOIN_GROUP/join_group_screen.dart';
import 'Manage_Group/group_details_page.dart';
import 'notifications/notifications_screen.dart';
import 'SETTING/screensettings.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GroupRepository _repository = GroupRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final Stream<List<GroupInvitation>> _pendingInvitationsStream;

  List<GroupDetails> _groups = [];
  bool _loadingGroups = true;
  bool _hasLoadedGroupsOnce = false;
  bool _isRefreshingGroups = false;

  final Map<String, double> _balances = {};

  double _totalReceive = 0.0;
  double _totalPay = 0.0;

  @override
  void initState() {
    super.initState();
    _pendingInvitationsStream = _repository.watchCurrentUserPendingInvitations();
   
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _loadGroupsAndSubscribe();
      }
    });
  }

  Future<void> _loadGroupsAndSubscribe() async {
    if (_isRefreshingGroups) {
      return;
    }
    _isRefreshingGroups = true;

    if (!_hasLoadedGroupsOnce) {
      setState(() {
        _loadingGroups = true;
      });
    }

    try {
      final groups = await _repository
          .getCurrentUserGroups()
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () {
              print('getCurrentUserGroups timeout');
              return [];
            },
          );
      if (!mounted) return;

      setState(() {
        _groups = groups;
        _loadingGroups = false;
        _hasLoadedGroupsOnce = true;
      });

      if (groups.isNotEmpty) {
        await _loadBalancesOnce(groups);
      }
    } catch (e) {
      print('Error loading groups: $e');
      if (!mounted) return;
      setState(() {
        _loadingGroups = false;
        _hasLoadedGroupsOnce = true;
      });
    } finally {
      _isRefreshingGroups = false;
    }
  }

  Future<void> _loadBalancesOnce(List<GroupDetails> groups) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || groups.isEmpty) {
      if (!mounted) return;
      setState(() {
        _balances.clear();
        _recomputeTotals();
      });
      return;
    }

    try {
      final db = FirebaseFirestore.instance;
      final futures = groups
          .map(
            (g) => db
                .collection('groups')
                .doc(g.groupId)
                .collection('members')
                .doc(currentUser.uid)
                .get()
                .timeout(const Duration(seconds: 5), onTimeout: () {
                  print('Balance query timeout for group ${g.groupId}');
                  throw TimeoutException('Balance query timeout', const Duration(seconds: 5));
                }),
          )
          .toList();

      final docs = await Future.wait(futures, eagerError: false).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('Balance queries timeout overall');
          return [];
        },
      );
      
      if (!mounted) return;

      final nextBalances = <String, double>{};
      for (var i = 0; i < groups.length; i++) {
        if (i < docs.length) {
          final doc = docs[i];
          double bal = 0.0;
          if (doc != null && doc.exists) {
            final data = doc.data() ?? {};
            final raw = data['balance'];
            if (raw is num) {
              bal = raw.toDouble();
            } else {
              bal = double.tryParse(raw?.toString() ?? '') ?? 0.0;
            }
          }
          nextBalances[groups[i].groupId] = bal;
        } else {
          nextBalances[groups[i].groupId] = 0.0;
        }
      }

      setState(() {
        _balances
          ..clear()
          ..addAll(nextBalances);
        _recomputeTotals();
      });
    } catch (e) {
      print('Error loading balances: $e');
      if (!mounted) return;
      // Set default balances to 0 if loading fails
      final nextBalances = <String, double>{};
      for (final group in groups) {
        nextBalances[group.groupId] = 0.0;
      }
      setState(() {
        _balances
          ..clear()
          ..addAll(nextBalances);
        _recomputeTotals();
      });
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
    _isRefreshingGroups = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 10,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StreamBuilder<List<GroupInvitation>>(
                stream: _pendingInvitationsStream,
                builder: (context, snapshot) {
                  final hasUnread = (snapshot.data ?? []).isNotEmpty;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.blue,
                          size: 30,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          ).then((_) => _loadGroupsAndSubscribe());
                        },
                      ),
                      if (hasUnread)
                        Positioned(
                          right: 10,
                          top: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 60),
              IconButton(
                icon: const Icon(
                  Icons.manage_accounts_outlined,
                  color: Colors.grey,
                  size: 30,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 30),
        onPressed: () async {
          final action = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            builder: (context) => const CreateGroupSheet(),
          );

          if (!mounted || action == null) return;

          if (action == createGroupAction) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreateGroupScreen(),
              ),
            );
          } else if (action == joinGroupAction) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const JoinGroupScreen(),
              ),
            );
          }

          if (mounted) {
            _loadGroupsAndSubscribe();
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Column(
        children: [
          _buildHeader(currentUser),
          Transform.translate(
            offset: const Offset(0, -50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: _buildBalanceCard(true, _totalReceive, _loadingGroups)),
                  const SizedBox(width: 15),
                  Expanded(child: _buildBalanceCard(false, _totalPay, _loadingGroups)),
                ],
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Nhóm của tôi",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Builder(
                builder: (context) {
                  if (_loadingGroups) return const Center(child: CircularProgressIndicator());
                  if (_groups.isEmpty) return const Center(child: Text("Bạn chưa có nhóm nào"));

                  return ListView.separated(
                    itemCount: _groups.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      return _buildGroupCard(context, group);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(User? currentUser) {
    final displayName = (currentUser?.displayName ?? '').trim();
    final email = (currentUser?.email ?? '').trim();
    final title = displayName.isNotEmpty
        ? displayName
        : (email.isNotEmpty ? email : 'Bạn');

    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 76),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade800, Colors.blue.shade500],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Chào bạn,",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white,
            child: Icon(Icons.person),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(bool isReceive, double amount, bool loading) {
    final color = isReceive ? Colors.green : Colors.red;
    final icon = isReceive ? Icons.trending_down : Icons.trending_up;
    final title = isReceive ? "Bạn nhận được" : "Bạn cần trả";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(title),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Text(
              "${amount.toStringAsFixed(0)}đ",
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Future<Map<String, double>> _computeTotals(List<GroupDetails> groups) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || groups.isEmpty)
      return {'receive': 0.0, 'pay': 0.0};

    final db = FirebaseFirestore.instance;
    final futures = groups
        .map(
          (g) => db
              .collection('groups')
              .doc(g.groupId)
              .collection('members')
              .doc(currentUser.uid)
              .get(),
        )
        .toList();
    final docs = await Future.wait(futures);

    double totalReceive = 0.0;
    double totalPay = 0.0;

    for (final doc in docs) {
      if (!doc.exists) continue;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      double bal = 0.0;
      final raw = data['balance'];
      if (raw is num)
        bal = raw.toDouble();
      else
        bal = double.tryParse(raw?.toString() ?? '') ?? 0.0;

      if (bal >= 0) {
        totalReceive += bal;
      } else {
        totalPay += -bal;
      }
    }

    return {'receive': totalReceive, 'pay': totalPay};
  }

  Widget _buildGroupCard(BuildContext context, GroupDetails group) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailsPage(groupId: group.groupId),
          ),
        );
      },
        borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EEF7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(radius: 25, child: Icon(Icons.group)),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.groupName, style: const TextStyle(fontSize: 18)),
                  Text("${group.memberCount} thành viên"),
                  Text(_buildGroupSubtitle(group)),
                ],
              ),
            ),
            Column(
              children: const [
                Text(
                  "0đ",
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text("Số dư"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildGroupSubtitle(GroupDetails group) {
    if (group.groupType.isNotEmpty) {
      return group.groupType;
    }
    if (group.groupCode.isNotEmpty) {
      return "Mã nhóm: ${group.groupCode}";
    }
    return "Nhóm đã tạo";
  }
}
