import 'package:flutter/material.dart';
import 'CapNhatNhom.dart';
import 'ThemChiTieu.dart';
import 'package:provider/provider.dart';
import 'SETTING/app_language.dart';

class ChiTietNhom extends StatefulWidget {
  const ChiTietNhom({super.key});

  @override
  State<ChiTietNhom> createState() => _ChiTietNhomState();
}

class _ChiTietNhomState extends State<ChiTietNhom> {
  bool isDuNoSelected = true;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppLanguage>();

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Column(
        children: [
          // Header
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
                      lang.t("ltdd"),
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "3 ${lang.t("thành viên")}",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () => _showMenu(context, lang),
                ),
              ],
            ),
          ),

          // Card thông tin tổng quát
          Transform.translate(
            offset: const Offset(0, -40),
            child: _buildSummaryCard(lang),
          ),

          // Nút chuyển đổi dư nợ / hoạt động
          _buildToggleButtons(lang),

          const SizedBox(height: 20),

          Expanded(
            child: isDuNoSelected
                ? _buildDanhSachThanhVien(lang)
                : _buildLichSuHoatDong(lang),
          ),
        ],
      ),
    );
  }

  void _showMenu(BuildContext context, AppLanguage lang) {
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
                    Text(
                      lang.t("Tùy chỉnh"),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                _buildMenuItem(Icons.edit, lang.t("Chỉnh sửa"), () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const CapNhatNhom()));
                }),
                _buildMenuItem(Icons.archive_outlined, lang.t("Lưu trữ"), () => Navigator.pop(context)),
                _buildMenuItem(Icons.share_outlined, lang.t("Chia sẻ"), () => Navigator.pop(context)),
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

  Widget _buildSummaryCard(AppLanguage lang) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          _rowInfo(lang.t("Tổng chi của nhóm"), lang.formatMoney(17000)),
          _rowInfo(lang.t("Tổng chi của tôi"), lang.formatMoney(10000)),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _quickAction(Icons.post_add, lang.t("Thêm chi tiêu")),
              _quickAction(Icons.swap_horiz, lang.t("Thêm thanh toán")),
              _quickAction(Icons.lightbulb_outline, lang.t("Gợi ý")),
              _quickAction(Icons.person_add_alt, lang.t("Thêm bạn")),
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
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, color: Colors.black87))),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _quickAction(IconData icon, String title) {
    return GestureDetector(
      onTap: () {
        if (title == Provider.of<AppLanguage>(context, listen: false).t("Thêm chi tiêu")) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ThemChiTieu()));
        }
      },
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF1976D2)),
          const SizedBox(height: 5),
          Text(title, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildToggleButtons(AppLanguage lang) {
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
                  color: isDuNoSelected ? const Color(0xFF1976D2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.money, color: isDuNoSelected ? Colors.white : const Color(0xFF1976D2), size: 18),
                    const SizedBox(width: 5),
                    Text(lang.t("Dư nợ"), style: TextStyle(color: isDuNoSelected ? Colors.white : const Color(0xFF1976D2), fontWeight: FontWeight.bold)),
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
                  color: !isDuNoSelected ? const Color(0xFF1976D2) : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, color: !isDuNoSelected ? Colors.white : const Color(0xFF1976D2), size: 18),
                    const SizedBox(width: 5),
                    Text(lang.t("Hoạt động"), style: TextStyle(color: !isDuNoSelected ? Colors.white : const Color(0xFF1976D2), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberItem(AppLanguage lang, String name, String role, double balanceValue, Color amountColor) {
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
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(lang.t(role), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                lang.formatMoney(balanceValue),
                style: TextStyle(color: amountColor, fontWeight: FontWeight.bold)
              ),
              Text(lang.t("Số dư"), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDanhSachThanhVien(AppLanguage lang) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _buildMemberItem(lang, "toan", "Trưởng nhóm", 0.0, Colors.grey),
        _buildMemberItem(lang, "a", "Thành viên", 7000.0, Colors.green),
        _buildMemberItem(lang, "bc", "Thành viên", -7000.0, Colors.red),
      ],
    );
  }

  Widget _buildLichSuHoatDong(AppLanguage lang) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(lang.t("Giao dịch gần nhất"), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(lang.t("Tất cả"), style: const TextStyle(color: Color(0xFF1976D2))),
          ],
        ),
        const SizedBox(height: 10),
        Text("03/03/2026", style: TextStyle(color: Colors.grey[600])),
        _buildTransactionItem(
          lang,
          "${lang.t("Trả tiền cho")}: a",
          "${lang.t("Từ")}: bc",
          7000.0,
          Icons.swap_horiz,
          Colors.green
        ),
        const SizedBox(height: 15),
        Text("11/02/2026", style: TextStyle(color: Colors.grey[600])),
        _buildTransactionItem(
          lang,
          lang.t("mua bún"),
          "${lang.t("Trả bởi")}: a",
          7000.0,
          Icons.receipt_long,
          Colors.red
        ),
        _buildTransactionItem(
          lang,
          lang.t("mua rau"),
          "${lang.t("Trả bởi")}: toan",
          10000.0,
          Icons.receipt_long,
          Colors.red
        ),
      ],
    );
  }

  Widget _buildTransactionItem(AppLanguage lang, String title, String subtitle, double amount, IconData icon, Color color) {
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
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            lang.formatMoney(amount),
            style: TextStyle(color: color, fontWeight: FontWeight.bold)
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}