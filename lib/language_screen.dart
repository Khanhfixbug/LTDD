import 'package:flutter/material.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}
class _LanguageScreenState extends State<LanguageScreen> {

  String language = "vi";

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ngôn ngữ"),
        backgroundColor: Colors.blue,
      ),

      body: RadioGroup<String>(
        groupValue: language,
        onChanged: (value) {
          setState(() {
            language = value!;
          });
        },

        child: ListView(
          children: const [

            RadioListTile<String>(
              title: Text("Tiếng Việt"),
              value: "vi",
            ),

            RadioListTile<String>(
              title: Text("English"),
              value: "en",
            ),

          ],
        ),
      ),
    );
  }
}