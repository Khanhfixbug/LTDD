import 'package:flutter/material.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {

  String currency = "VND";

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Đơn vị tiền tệ"),
        backgroundColor: Colors.blue,
      ),

      body: RadioGroup<String>(
        groupValue: currency,
        onChanged: (value) {
          setState(() {
            currency = value!;
          });
        },

        child: ListView(
          children: const [

            RadioListTile<String>(
              title: Text("Đô la Úc (A\$)"),
              value: "AUD",
            ),

            RadioListTile<String>(
              title: Text("Đô la Mỹ (\$)"),
              value: "USD",
            ),

            RadioListTile<String>(
              title: Text("Việt Nam Đồng (đ)"),
              value: "VND",
            ),

          ],
        ),
      ),
    );
  }
}