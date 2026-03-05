import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Thông tin cá nhân"),
        backgroundColor: Colors.blue,
      ),

      body: SingleChildScrollView(  
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [

              CircleAvatar(
                radius: width * 0.15,
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.person,size:80,color:Colors.blue),
              ),

              const SizedBox(height:20),

              TextField(
                decoration: InputDecoration(
                  labelText: "Tên hiển thị",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height:20),

              TextField(
                decoration: InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height:30),

              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),

                  onPressed: () {},

                  child: const Text(
                    "Cập nhật",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
}