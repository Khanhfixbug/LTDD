import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../auth/login_repository.dart';

class GroupDraft {
  const GroupDraft({
    required this.groupName,
    required this.groupType,
    required this.description,
  });

  final String groupName;
  final String groupType;
  final String description;
}

class GroupMemberCandidate {
  const GroupMemberCandidate({
    required this.userId,
    required this.email,
    required this.displayName,
  });

  final String userId;
  final String email;
  final String displayName;
}

class GroupDetails {
  const GroupDetails({
    required this.groupId,
    required this.groupName,
    required this.groupType,
    required this.description,
    required this.groupCode,
    required this.createdBy,
    required this.createdAt,
    required this.memberCount,
    required this.ownerName,
  });

  final String groupId;
  final String groupName;
  final String groupType;
  final String description;
  final String groupCode;
  final String createdBy;
  final Timestamp? createdAt;
  final int memberCount;
  final String ownerName;
}

class GroupInvitation {
  const GroupInvitation({
    required this.invitationId,
    required this.groupId,
    required this.groupName,
    required this.fromUserId,
    required this.fromDisplayName,
    required this.toUserId,
    required this.toEmail,
    required this.toDisplayName,
    required this.status,
    required this.createdAt,
  });

  final String invitationId;
  final String groupId;
  final String groupName;
  final String fromUserId;
  final String fromDisplayName;
  final String toUserId;
  final String toEmail;
  final String toDisplayName;
  final String status;
  final Timestamp? createdAt;
}

class GroupRepository {
  GroupRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _loginRepository = LoginRepository(firestore: firestore);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final LoginRepository _loginRepository;

  static const String _groupCodeChars = 'abcdefghijklmnopqrstuvwxyz0123456789';

  Future<String> getCurrentUserDefaultDisplayName() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return '';
    }

    final ownerProfile =
        await _firestore.collection('users').doc(currentUser.uid).get();
    final ownerData = ownerProfile.data() ?? <String, dynamic>{};

    return (ownerData['displayName'] as String? ??
            currentUser.displayName ??
            currentUser.email ??
            '')
        .trim();
  }

  Future<GroupMemberCandidate?> findUserByEmail(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      return null;
    }

    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      await _loginRepository.removeGroupMembershipsByMissingEmail(
        normalizedEmail,
      );
      return null;
    }

    final doc = snapshot.docs.first;
    final data = doc.data();

    return GroupMemberCandidate(
      userId: doc.id,
      email: (data['email'] as String? ?? normalizedEmail).trim(),
      displayName: (data['displayName'] as String? ?? '').trim(),
    );
  }

  Future<String> createGroup({
    required GroupDraft draft,
    required String ownerDisplayName,
    required List<GroupMemberCandidate> members,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('Người dùng chưa đăng nhập.');
    }

    final ownerProfile =
        await _firestore.collection('users').doc(currentUser.uid).get();
    final ownerData = ownerProfile.data() ?? <String, dynamic>{};
    final ownerEmail =
        (ownerData['email'] as String? ?? currentUser.email ?? '').trim();

    if (ownerEmail.isEmpty) {
      throw StateError('Không tìm thấy email của người tạo nhóm.');
    }

    final normalizedOwnerDisplayName = ownerDisplayName.trim().isNotEmpty
        ? ownerDisplayName.trim()
        : (ownerData['displayName'] as String? ?? currentUser.displayName ?? '')
            .trim();

    final resolvedOwnerDisplayName = normalizedOwnerDisplayName.isNotEmpty
        ? normalizedOwnerDisplayName
        : ownerEmail;

    final groupCode = await _generateUniqueGroupCode();
    final groupRef = _firestore.collection('groups').doc();
    final membersCollection = groupRef.collection('members');
    final batch = _firestore.batch();

    batch.set(groupRef, {
      'groupName': draft.groupName.trim(),
      'groupType': draft.groupType.trim(),
      'description': draft.description.trim(),
      'groupCode': groupCode,
      'createdBy': currentUser.uid,
      'ownerName': resolvedOwnerDisplayName,
      'ownerEmail': ownerEmail,
      'memberIds': [currentUser.uid],
      'createdAt': FieldValue.serverTimestamp(),
      'isArchived': false,
    });

    batch.set(membersCollection.doc(currentUser.uid), {
      'userId': currentUser.uid,
      'email': ownerEmail,
      'displayName': resolvedOwnerDisplayName,
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    final invitedMemberIds = <String>{currentUser.uid};
    for (final member in members) {
      if (!invitedMemberIds.add(member.userId)) {
        continue;
      }

      _queueGroupInvitation(
        batch: batch,
        groupId: groupRef.id,
        groupName: draft.groupName.trim(),
        fromUserId: currentUser.uid,
        fromDisplayName: resolvedOwnerDisplayName,
        member: member,
      );
    }

    await batch.commit();
    return groupRef.id;
  }

  Future<void> inviteMemberToGroup({
    required String groupId,
    required GroupMemberCandidate member,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('Người dùng chưa đăng nhập.');
    }

    final groupDoc = await _firestore.collection('groups').doc(groupId).get();
    if (!groupDoc.exists) {
      throw StateError('Không tìm thấy nhóm.');
    }

    final memberDoc = await groupDoc.reference
        .collection('members')
        .doc(member.userId)
        .get();
    if (memberDoc.exists) {
      throw StateError('Người này đã là thành viên.');
    }

    final userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};
    final fromDisplayName = (userData['displayName'] as String? ??
            currentUser.displayName ??
            currentUser.email ??
            '')
        .trim();
    final groupData = groupDoc.data() ?? <String, dynamic>{};

    final batch = _firestore.batch();
    _queueGroupInvitation(
      batch: batch,
      groupId: groupId,
      groupName: (groupData['groupName'] as String? ?? 'Nhóm').trim(),
      fromUserId: currentUser.uid,
      fromDisplayName: fromDisplayName,
      member: member,
    );
    await batch.commit();
  }

  Stream<List<GroupInvitation>> watchCurrentUserPendingInvitations() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('group_invitations')
        .where('toUserId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      final invitations = snapshot.docs
          .map(_mapInvitation)
          .where((invitation) => invitation.status == 'pending')
          .toList();
      invitations.sort((a, b) {
        final first = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final second = b.createdAt?.millisecondsSinceEpoch ?? 0;
        return second.compareTo(first);
      });
      return invitations;
    });
  }

  Future<void> acceptInvitation(GroupInvitation invitation) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.uid != invitation.toUserId) {
      throw StateError('Người dùng không hợp lệ.');
    }

    final invitationRef =
        _firestore.collection('group_invitations').doc(invitation.invitationId);
    final memberRef = _firestore
        .collection('groups')
        .doc(invitation.groupId)
        .collection('members')
        .doc(invitation.toUserId);

    await _firestore.runTransaction((transaction) async {
      final invitationSnap = await transaction.get(invitationRef);
      final data = invitationSnap.data() ?? <String, dynamic>{};
      if (!invitationSnap.exists || data['status'] != 'pending') {
        throw StateError('Lời mời không còn hiệu lực.');
      }

      final memberSnap = await transaction.get(memberRef);
      if (!memberSnap.exists) {
        transaction.set(memberRef, {
          'userId': invitation.toUserId,
          'email': invitation.toEmail,
          'displayName': invitation.toDisplayName.isEmpty
              ? invitation.toEmail
              : invitation.toDisplayName,
          'role': 'member',
          'joinedAt': FieldValue.serverTimestamp(),
          'balance': 0,
        });
      }

      transaction.update(
        _firestore.collection('groups').doc(invitation.groupId),
        {
          'memberIds': FieldValue.arrayUnion([invitation.toUserId]),
        },
      );

      transaction.update(invitationRef, {
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> declineInvitation(String invitationId) async {
    await _firestore.collection('group_invitations').doc(invitationId).update({
      'status': 'declined',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<GroupDetails?> findGroupByCode(String inputCode) async {
    final normalizedCode = inputCode.trim().toLowerCase();
    if (normalizedCode.isEmpty) {
      return null;
    }

    final snapshot = await _firestore
        .collection('groups')
        .where('groupCode', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return _mapGroupDetails(snapshot.docs.first);
  }

  Future<bool> isCurrentUserMember(String groupId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('Người dùng chưa đăng nhập.');
    }

    final memberDoc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .doc(currentUser.uid)
        .get();

    return memberDoc.exists;
  }

  Future<void> joinGroup(String groupId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw StateError('Người dùng chưa đăng nhập.');
    }

    final userDoc =
        await _firestore.collection('users').doc(currentUser.uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};
    final email = (userData['email'] as String? ?? currentUser.email ?? '').trim();

    if (email.isEmpty) {
      throw StateError('Không tìm thấy email người dùng.');
    }

    final displayName =
        (userData['displayName'] as String? ?? currentUser.displayName ?? email)
            .trim();

    final groupRef = _firestore.collection('groups').doc(groupId);
    final memberRef = groupRef.collection('members').doc(currentUser.uid);

    await _firestore.runTransaction((transaction) async {
      final groupSnap = await transaction.get(groupRef);
      if (!groupSnap.exists) {
        throw StateError('Nhóm không tồn tại.');
      }

      final memberSnap = await transaction.get(memberRef);
      if (memberSnap.exists) {
        throw StateError('Bạn đã ở trong nhóm này rồi.');
      }

      // Add member document
      transaction.set(memberRef, {
        'userId': currentUser.uid,
        'email': email,
        'displayName': displayName.isEmpty ? email : displayName,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Update group memberIds atomically in same transaction
      transaction.update(groupRef, {
        'memberIds': FieldValue.arrayUnion([currentUser.uid]),
      });
    });
  }

  Future<List<GroupDetails>> getCurrentUserGroups() async {
  final currentUser = _auth.currentUser;
  if (currentUser == null) {
    return [];
  }

  final groupDocsById =
      <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

  try {
    final memberIdSnapshot = await _firestore
        .collection('groups')
        .where('memberIds', arrayContains: currentUser.uid)
        .get()
        .timeout(const Duration(seconds: 4));

    for (final doc in memberIdSnapshot.docs) {
      groupDocsById[doc.id] = doc;
    }
  } catch (e) {
    print('Member groups error: $e');
  }

  try {
    final ownerSnapshot = await _firestore
        .collection('groups')
        .where('createdBy', isEqualTo: currentUser.uid)
        .get()
        .timeout(const Duration(seconds: 4));

    for (final doc in ownerSnapshot.docs) {
      groupDocsById[doc.id] = doc;
    }
  } catch (e) {
    print('Owner groups error: $e');
  }

  final groups = <GroupDetails>[];

  for (final groupDoc in groupDocsById.values) {
    try {
      final data = groupDoc.data();

      // Bỏ qua nhóm đã lưu trữ
      final isArchived = data['isArchived'] == true;

      if (isArchived) {
        continue;
      }

      groups.add(await _mapGroupDetails(groupDoc));
    } catch (e) {
      print('Map group error: $e');
    }
  }

  groups.sort((a, b) {
    final first = a.createdAt?.millisecondsSinceEpoch ?? 0;
    final second = b.createdAt?.millisecondsSinceEpoch ?? 0;
    return second.compareTo(first);
  });

  return groups;
}

  Future<int> cleanupMissingUsersInGroup(String groupId) async {
    final normalizedGroupId = groupId.trim();
    if (normalizedGroupId.isEmpty) {
      return 0;
    }

    final membersSnapshot = await _firestore
        .collection('groups')
        .doc(normalizedGroupId)
        .collection('members')
        .get()
        .timeout(const Duration(seconds: 5));

    var deletedCount = 0;
    WriteBatch batch = _firestore.batch();

    for (final memberDoc in membersSnapshot.docs) {
      final data = memberDoc.data();
      final userId = (data['userId'] as String? ?? memberDoc.id).trim();
      if (userId.isEmpty) {
        continue;
      }

      DocumentSnapshot<Map<String, dynamic>> userDoc;
      try {
        userDoc = await _firestore
            .collection('users')
            .doc(userId)
            .get()
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        continue;
      }

      if (userDoc.exists) {
        continue;
      }

      batch.delete(memberDoc.reference);
      deletedCount++;

      if (deletedCount % 450 == 0) {
        await batch.commit();
        batch = _firestore.batch();
      }
    }

    if (deletedCount % 450 != 0) {
      await batch.commit();
    }

    return deletedCount;
  }

  Future<GroupDetails> _mapGroupDetails(
    DocumentSnapshot<Map<String, dynamic>> groupDoc,
  ) async {
    final data = groupDoc.data() ?? <String, dynamic>{};
    final memberIds = data['memberIds'];
    final memberCount = memberIds is List ? memberIds.length : 1;
    final ownerName =
        (data['ownerName'] as String? ?? data['ownerEmail'] as String? ?? '')
            .trim();

    return GroupDetails(
      groupId: groupDoc.id,
      groupName: (data['groupName'] as String? ?? 'Nhóm chưa đặt tên').trim(),
      groupType: (data['groupType'] as String? ?? '').trim(),
      description: (data['description'] as String? ?? '').trim(),
      groupCode: (data['groupCode'] as String? ?? '').trim(),
      createdBy: (data['createdBy'] as String? ?? '').trim(),
      createdAt: data['createdAt'] as Timestamp?,
      memberCount: memberCount,
      ownerName: ownerName,
    );
  }

  Future<String> _generateUniqueGroupCode() async {
    const maxAttempts = 20;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final code = _randomGroupCode();
      final existingGroup = await _firestore
          .collection('groups')
          .where('groupCode', isEqualTo: code)
          .limit(1)
          .get();

      if (existingGroup.docs.isEmpty) {
        return code;
      }
    }

    throw StateError('Không thể tạo groupCode duy nhất. Vui lòng thử lại.');
  }

  String _randomGroupCode() {
    final random = Random.secure();
    return List.generate(
      6,
      (_) => _groupCodeChars[random.nextInt(_groupCodeChars.length)],
    ).join();
  }

  void _queueGroupInvitation({
    required WriteBatch batch,
    required String groupId,
    required String groupName,
    required String fromUserId,
    required String fromDisplayName,
    required GroupMemberCandidate member,
  }) {
    final invitationRef = _firestore.collection('group_invitations').doc();
    batch.set(invitationRef, {
      'groupId': groupId,
      'groupName': groupName,
      'fromUserId': fromUserId,
      'fromDisplayName': fromDisplayName,
      'toUserId': member.userId,
      'toEmail': member.email.trim(),
      'toDisplayName': member.displayName.trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  GroupInvitation _mapInvitation(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return GroupInvitation(
      invitationId: doc.id,
      groupId: (data['groupId'] as String? ?? '').trim(),
      groupName: (data['groupName'] as String? ?? 'Nhóm').trim(),
      fromUserId: (data['fromUserId'] as String? ?? '').trim(),
      fromDisplayName: (data['fromDisplayName'] as String? ?? '').trim(),
      toUserId: (data['toUserId'] as String? ?? '').trim(),
      toEmail: (data['toEmail'] as String? ?? '').trim(),
      toDisplayName: (data['toDisplayName'] as String? ?? '').trim(),
      status: (data['status'] as String? ?? '').trim(),
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}
