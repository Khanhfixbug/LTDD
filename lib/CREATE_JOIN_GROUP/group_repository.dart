import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    this.isArchived = false, // Mặc định là false
    this.lastActivity, //
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
  final bool isArchived; // Thuộc tính để kiểm tra nhóm đã lưu trữ chưa
  final Timestamp? lastActivity; //
}

class GroupRepository {
  GroupRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const String _groupCodeChars = 'abcdefghijklmnopqrstuvwxyz0123456789';

  Future<String> getCurrentUserDefaultDisplayName() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return '';

    final ownerProfile = await _firestore.collection('users').doc(currentUser.uid).get();
    final ownerData = ownerProfile.data() ?? <String, dynamic>{};

    return (ownerData['displayName'] as String? ??
            currentUser.displayName ??
            currentUser.email ??
            '')
        .trim();
  }

  Future<GroupMemberCandidate?> findUserByEmail(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) return null;

    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

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
    if (currentUser == null) throw StateError('Người dùng chưa đăng nhập.');

    final ownerProfile = await _firestore.collection('users').doc(currentUser.uid).get();
    final ownerData = ownerProfile.data() ?? <String, dynamic>{};
    final ownerEmail = (ownerData['email'] as String? ?? currentUser.email ?? '').trim();

    final normalizedOwnerDisplayName = ownerDisplayName.trim().isNotEmpty
        ? ownerDisplayName.trim()
        : (ownerData['displayName'] as String? ?? currentUser.displayName ?? '').trim();

    final resolvedOwnerDisplayName = normalizedOwnerDisplayName.isNotEmpty ? normalizedOwnerDisplayName : ownerEmail;

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
      'createdAt': FieldValue.serverTimestamp(),
      'isArchived': false, // Khởi tạo nhóm mới với trạng thái chưa lưu trữ
    });

    batch.set(membersCollection.doc(currentUser.uid), {
      'userId': currentUser.uid,
      'email': ownerEmail,
      'displayName': resolvedOwnerDisplayName,
      'role': 'owner',
      'joinedAt': FieldValue.serverTimestamp(),
    });

    final addedMemberIds = <String>{currentUser.uid};
    for (final member in members) {
      if (!addedMemberIds.add(member.userId)) continue;

      batch.set(membersCollection.doc(member.userId), {
        'userId': member.userId,
        'email': member.email.trim(),
        'displayName': member.displayName.trim(),
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
    return groupRef.id;
  }

  Future<GroupDetails?> findGroupByCode(String inputCode) async {
    final normalizedCode = inputCode.trim().toLowerCase();
    if (normalizedCode.isEmpty) return null;

    final snapshot = await _firestore
        .collection('groups')
        .where('groupCode', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    return _mapGroupDetails(snapshot.docs.first);
  }

  // Hàm kiểm tra thành viên (Sửa lỗi undefined_method ở JoinGroupSummaryScreen)
  Future<bool> isCurrentUserMember(String groupId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

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
    if (currentUser == null) throw StateError('Người dùng chưa đăng nhập.');

    final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};
    final email = (userData['email'] as String? ?? currentUser.email ?? '').trim();

    final displayName = (userData['displayName'] as String? ?? currentUser.displayName ?? email).trim();

    final memberRef = _firestore.collection('groups').doc(groupId).collection('members').doc(currentUser.uid);

    if ((await memberRef.get()).exists) throw StateError('Bạn đã ở trong nhóm này rồi.');

    await memberRef.set({
      'userId': currentUser.uid,
      'email': email,
      'displayName': displayName.isEmpty ? email : displayName,
      'role': 'member',
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<GroupDetails>> getCurrentUserGroups() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    final groupsSnapshot = await _firestore.collection('groups').get();
    final groups = <GroupDetails>[];

    for (final groupDoc in groupsSnapshot.docs) {
      final memberDoc = await groupDoc.reference.collection('members').doc(currentUser.uid).get();
      if (!memberDoc.exists) continue;

      groups.add(await _mapGroupDetails(groupDoc));
    }

    groups.sort((a, b) {
      final first = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final second = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return second.compareTo(first);
    });

    return groups;
  }

  Future<GroupDetails> _mapGroupDetails(DocumentSnapshot<Map<String, dynamic>> groupDoc) async {
    final data = groupDoc.data() ?? <String, dynamic>{};
    final membersSnapshot = await groupDoc.reference.collection('members').get();

    String ownerName = '';
    final createdBy = (data['createdBy'] as String? ?? '').trim();

    for (final memberDoc in membersSnapshot.docs) {
      final memberData = memberDoc.data();
      if (memberData['role'] == 'owner' || memberData['userId'] == createdBy) {
        ownerName = (memberData['displayName'] as String? ?? '').trim();
        break;
      }
    }

    if (ownerName.isEmpty && createdBy.isNotEmpty) {
      final ownerUserDoc = await _firestore.collection('users').doc(createdBy).get();
      final ownerData = ownerUserDoc.data() ?? <String, dynamic>{};
      ownerName = (ownerData['displayName'] as String? ?? ownerData['email'] as String? ?? '').trim();
    }

    return GroupDetails(
      groupId: groupDoc.id,
      groupName: (data['groupName'] as String? ?? 'Nhóm chưa đặt tên').trim(),
      groupType: (data['groupType'] as String? ?? '').trim(),
      description: (data['description'] as String? ?? '').trim(),
      groupCode: (data['groupCode'] as String? ?? '').trim(),
      createdBy: createdBy,
      createdAt: data['createdAt'] as Timestamp?,
      memberCount: membersSnapshot.docs.length,
      ownerName: ownerName,
      isArchived: data['isArchived'] ?? false, // Đọc field isArchived từ Firestore
      lastActivity: data['lastActivity'] as Timestamp? ?? data['createdAt'] as Timestamp?,//

    );
  }

  Future<String> _generateUniqueGroupCode() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final code = _randomGroupCode();//Sinh mã ngẫu nhiên
      //Kiểm tra mã này đã tồn tại trong Database chưa
      final existingGroup = await _firestore.collection('groups').where('groupCode', isEqualTo: code).limit(1).get();
      if (existingGroup.docs.isEmpty) return code;
    }
    throw StateError('Không thể tạo mã nhóm duy nhất.');
  }

  String _randomGroupCode() {
    final random = Random.secure();
    return List.generate(6, (_) => _groupCodeChars[random.nextInt(_groupCodeChars.length)]).join();
  }
}