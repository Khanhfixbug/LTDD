import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class AppLanguage extends ChangeNotifier {
  Locale _locale = const Locale('vi');
  Map<String, String> _data = {};
  String _selectedCurrency = "VND";
  Map<String, double> _exchangeRates = {
    "VND": 1.0,
    "USD": 0.00004, 
    "AUD": 0.00006,
  };

  Locale get locale => _locale;
  String get selectedCurrency => _selectedCurrency;

  AppLanguage() {
    _initData();
  }

  Future<void> _initData() async {
    await loadLanguage();
    await loadCurrency();
    await updateExchangeRates(); 
  }

  // ================= PHẦN NGÔN NGỮ =================

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String lang = prefs.getString('language') ?? 'vi';
    _locale = Locale(lang);
    await _loadJson(lang);
    notifyListeners();
  }

  Future<void> _loadJson(String lang) async {
    try {
      String jsonString = await rootBundle.loadString('assets/lang/$lang.json');
      Map<String, dynamic> jsonMap = json.decode(jsonString);
      _data = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    } catch (e) {
      debugPrint("Lỗi nạp file JSON: $e");
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
    await _loadJson(languageCode);
    notifyListeners();
  }

  String t(String key) => _data[key] ?? key;

  // ================= PHẦN TIỀN TỆ & QUY ĐỔI =================

  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _selectedCurrency = prefs.getString('currency') ?? 'VND';
    notifyListeners();
  }

  Future<void> changeCurrency(String currencyCode) async {
    _selectedCurrency = currencyCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', currencyCode);
    notifyListeners();
  }

  // 2. CẬP NHẬT TỶ GIÁ TỪ API
  Future<void> updateExchangeRates() async {
    try {
      final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/VND'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        _exchangeRates["USD"] = (data['rates']['USD'] as num).toDouble();
        _exchangeRates["AUD"] = (data['rates']['AUD'] as num).toDouble();
        debugPrint("Đã cập nhật tỷ giá mới nhất: USD=${_exchangeRates["USD"]}");
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Không thể cập nhật tỷ giá (Dùng mặc định): $e");
    }
  }

  // 3. HÀM QUY ĐỔI VÀ ĐỊNH DẠNG (QUAN TRỌNG NHẤT)
  String formatMoney(double amountVND) {
    double rate = _exchangeRates[_selectedCurrency] ?? 1.0;
    
    // Tính toán giá trị sau quy đổi
    double convertedAmount = amountVND * rate;

    // Định dạng hiển thị
    switch (_selectedCurrency) {
      case 'USD':
        return NumberFormat.currency(locale: 'en_US', symbol: '\$').format(convertedAmount);
      case 'AUD':
        return NumberFormat.currency(locale: 'en_AU', symbol: 'A\$').format(convertedAmount);
      case 'VND':
      default:
        return NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0).format(convertedAmount);
    }
  }
}