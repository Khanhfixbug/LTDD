import 'package:flutter/material.dart';
import 'ChiTietNhom.dart';
import 'CREATE_JOIN_GROUP/create_group_sheet.dart';
import 'SETTING/screensettings.dart';
import 'package:provider/provider.dart';
import 'SETTING/app_language.dart';

class TrangChu extends StatelessWidget {
  const TrangChu({super.key});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi ngôn ngữ và tiền tệ từ Provider
    final lang = context.watch<AppLanguage>();

    return Scaffold(
      backgroundColor: Colors.grey[100],

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: const Icon(Icons.home_filled, color: Colors.blue, size: 30),
                onPressed: () {},
              ),
              const SizedBox(width: 60), 
              IconButton(
                icon: const Icon(Icons.manage_accounts_outlined, color: Colors.grey, size: 30),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 35, color: Colors.white),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            builder: (context) => const CreateGroupSheet(),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Gradient
            Container(
              padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 80),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue[800]!, Colors.blue[400]!],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t("Chào buổi sáng,"), 
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                      ),
                      const Text(
                        "Toan",
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Colors.blue, size: 30),
                    ),
                  ),
                ],
              ),
            ),

            // Phần 2 card số dư - ĐÃ CẬP NHẬT ĐỔI TIỀN TỆ
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(child: _buildBalanceCard(
                      context, 
                      lang.t("Bạn nhận được"), 
                      lang.formatMoney(0), // Sử dụng hàm formatMoney
                      Icons.trending_down, 
                      Colors.green
                    )),
                    const SizedBox(width: 15),
                    Expanded(child: _buildBalanceCard(
                      context, 
                      lang.t("Bạn cần trả"), 
                      lang.formatMoney(0), // Sử dụng hàm formatMoney
                      Icons.trending_up, 
                      Colors.red
                    )),
                  ],
                ),
              ),
            ),

            // Tiêu đề Nhóm của tôi
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  lang.t("Nhóm của tôi"),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Danh sách nhóm - ĐÃ CẬP NHẬT ĐỔI TIỀN TỆ TRONG ITEM
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildGroupItem(context, lang,"khanh", "LTDD", "3", 0.0),
            ),
            
            const SizedBox(height: 100), 
          ],
        ),
      ),
    );
  }

  // Widget Card số dư - Dùng FittedBox để tránh tràn chữ khi đổi sang USD/AUD
  Widget _buildBalanceCard(BuildContext context, String title, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              amount,
              style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

  // Widget hiển thị từng nhóm
  Widget _buildGroupItem(BuildContext context, AppLanguage lang, String groupName,String groupId, String members, double balanceValue) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChiTietNhom()),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: const Icon(Icons.group, color: Colors.blue, size: 30),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(groupName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("$members ${lang.t("thành viên")}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(lang.t("Gần nhất 16 ngày trước"), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    lang.formatMoney(balanceValue), // Đã sửa từ "0đ" thành formatMoney
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(lang.t("Số dư"), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}