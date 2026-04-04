import 'package:cloud_firestore/cloud_firestore.dart';

class LoginAccount {
  const LoginAccount({
    required this.phone,
    required this.password,
    required this.email,
    required this.fullName,
    this.avatarBase64,
  });

  final String phone;
  final String password;
  final String email;
  final String fullName;
  final String? avatarBase64;

  factory LoginAccount.fromMap(Map<String, dynamic> map) {
    final phone = LoginRepository.normalizePhoneInput(
      (map['phone'] ?? '').toString(),
    );
    final password = (map['password'] ?? '').toString().trim();
    final email = (map['email'] ?? '').toString().trim();
    final fullName = (map['fullName'] ?? '').toString().trim();
    final avatarBase64 = (map['avatarBase64'] ?? '').toString().trim();

    if (phone.isEmpty || password.isEmpty) {
      throw const FormatException('Invalid login account data');
    }

    return LoginAccount(
      phone: phone,
      password: password,
      email: email,
      fullName: fullName,
      avatarBase64: avatarBase64.isEmpty ? null : avatarBase64,
    );
  }
}

enum CreateAccountResult {
  success,
  phoneAlreadyExists,
}

class LoginRepository {
  LoginRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<bool> authenticate({
    required String phone,
    required String password,
  }) async {
    final normalizedPhone = normalizePhoneInput(phone);
    if (normalizedPhone.isEmpty) {
      return false;
    }

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

  static String normalizePhoneInput(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  Future<CreateAccountResult> createAccount({
    required String phone,
    required String password,
    String fullName = '',
    String email = '',
    String? avatarBase64,
  }) async {
    final normalizedPhone = normalizePhoneInput(phone);
    if (normalizedPhone.isEmpty) {
      return CreateAccountResult.phoneAlreadyExists;
    }

    final accountRef = _firestore.collection('login_accounts').doc(
          normalizedPhone,
        );
    final existingAccount = await accountRef.get();

    if (existingAccount.exists) {
      return CreateAccountResult.phoneAlreadyExists;
    }

    await accountRef.set({
      'phone': normalizedPhone,
      'password': password,
      'email': email.trim(),
      'fullName': fullName.trim(),
      'avatarBase64': (avatarBase64 ?? '').trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return CreateAccountResult.success;
  }
}
