import 'package:cloud_firestore/cloud_firestore.dart';

class LoginAccount {
  const LoginAccount({
    required this.phone,
    required this.password,
    required this.email,
  });

  final String phone;
  final String password;
  final String email;

  factory LoginAccount.fromMap(Map<String, dynamic> map) {
    final phone = (map['phone'] ?? '').toString().trim();
    final password = (map['password'] ?? '').toString().trim();
    final email = (map['email'] ?? '').toString().trim();

    if (phone.isEmpty || password.isEmpty || email.isEmpty) {
      throw const FormatException('Invalid login account data');
    }

    return LoginAccount(
      phone: phone,
      password: password,
      email: email,
    );
  }
}

class LoginRepository {
  LoginRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<bool> authenticate({
    required String phone,
    required String password,
  }) async {
    final normalizedPhone = _normalizePhone(phone);

    final snapshot = await _firestore
        .collection('login_accounts')
        .where('phone', isEqualTo: normalizedPhone)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return false;
    }

    try {
      final account = LoginAccount.fromMap(snapshot.docs.first.data());
      return account.password == password;
    } on FormatException {
      return false;
    }
  }

  String _normalizePhone(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }



  
//test account: 0912345678 - 123456 -
  Future<void> seedTestAccount({
    String phone = '0912345678',
    String password = '123456',
    String email = 'test1@gmail.com',
  }) async {
    final normalizedPhone = _normalizePhone(phone);

    await _firestore.collection('login_accounts').doc(normalizedPhone).set({
      'phone': normalizedPhone,
      'password': password,
      'email': email,
    });
  }
}
