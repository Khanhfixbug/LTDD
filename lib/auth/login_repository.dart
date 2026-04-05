import 'package:cloud_firestore/cloud_firestore.dart';

enum CreateAccountResult {
  success,
  phoneAlreadyExists,
}

class LoginRepository {
  LoginRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static String normalizePhoneInput(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  Future<CreateAccountResult> createAccount({
    required String uid,
    required String email,
    String displayName = '',
    String phone = '',
    String? avatarBase64,
  }) async {
    final normalizedPhone = normalizePhoneInput(phone);

    if (normalizedPhone.isNotEmpty) {
      final existingPhone = await _firestore
          .collection('users')
          .where('phone', isEqualTo: normalizedPhone)
          .limit(1)
          .get();

      final isPhoneUsedByAnotherUser = existingPhone.docs.any(
        (doc) => doc.id != uid,
      );
      if (isPhoneUsedByAnotherUser) {
        return CreateAccountResult.phoneAlreadyExists;
      }
    }

    await _firestore.collection('users').doc(uid).set({
      'email': email.trim(),
      'displayName': displayName.trim(),
      'phone': normalizedPhone,
      'avatarBase64': (avatarBase64 ?? '').trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    return CreateAccountResult.success;
  }
}
