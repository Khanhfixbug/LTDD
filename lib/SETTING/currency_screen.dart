import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_language.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  late String _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = context.read<AppLanguage>().selectedCurrency;
  }

  @override
  Widget build(BuildContext context) {
    final appLanguage = context.watch<AppLanguage>();
    final bool isVN = appLanguage.locale.languageCode == 'vi';

    return Scaffold(
      appBar: AppBar(
        title: Text(isVN ? "Đơn vị tiền tệ" : "Currency"),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      body: ListView(
        children: [
          _buildRadio(isVN ? "Đô la Úc (A\$)" : "Australian Dollar (A\$)", "AUD", appLanguage),
          _buildRadio(isVN ? "Đô la Mỹ (\$)" : "US Dollar (\$)", "USD", appLanguage),
          _buildRadio(isVN ? "Việt Nam Đồng (₫)" : "Vietnam Dong (₫)", "VND", appLanguage),
        ],
      ),
    );
  }

  Widget _buildRadio(String title, String value, AppLanguage provider) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: _selectedCurrency,
      onChanged: (newValue) {
        setState(() {
          _selectedCurrency = newValue!;
        });
        provider.changeCurrency(newValue!);
      },
    );
  }
}