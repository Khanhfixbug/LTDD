import 'package:cloud_firestore/cloud_firestore.dart';

enum CreateAccountResult {
  success,
  phoneAlreadyExists,
}

class LoginRepository {
  LoginRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const rememberLoginKey = 'remember_login';

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
      'emailVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    return CreateAccountResult.success;
  }

  Future<void> markEmailVerified(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'emailVerified': true,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> userDocumentExistsByEmail(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      return false;
    }

    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<int> removeGroupMembershipsByMissingEmail(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      return 0;
    }

    if (await userDocumentExistsByEmail(normalizedEmail)) {
      return 0;
    }

    var deletedCount = 0;
    WriteBatch batch = _firestore.batch();

    final groups = await _firestore.collection('groups').get();
    for (final group in groups.docs) {
      final memberships = await group.reference
          .collection('members')
          .where('email', isEqualTo: normalizedEmail)
          .get();

      for (final membership in memberships.docs) {
        batch.delete(membership.reference);
        deletedCount++;

        if (deletedCount % 450 == 0) {
          await batch.commit();
          batch = _firestore.batch();
        }
      }
    }

    if (deletedCount % 450 != 0) {
      await batch.commit();
    }

    return deletedCount;
  }
}
