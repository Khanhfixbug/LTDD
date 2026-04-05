import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> getMembers(String groupId) {
    return _db
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            final name =
                (data['displayName'] ?? data['name'] ?? data['email'] ?? '')
                    .toString()
                    .trim();

            return {
              'id': doc.id,
              ...data,
              'name': name.isEmpty ? 'Nguoi dung' : name,
            };
          }).toList();
        });
  }

  Future<void> addExpense({
    required String groupId,
    required String tenChiTieu,
    required double soTien,
    required String nguoiChi,
    required String nguoiHuong,
    required String nguoiChiId,
    required String nguoiHuongId,
    String? ghiChu,
    DateTime? ngayTao,
    String? attachmentBase64,
  }) async {
    await _createActivity(
      groupId: groupId,
      type: 'expense',
      tenChiTieu: tenChiTieu,
      soTien: soTien,
      nguoiChi: nguoiChi,
      nguoiHuong: nguoiHuong,
      nguoiChiId: nguoiChiId,
      nguoiHuongId: nguoiHuongId,
      ghiChu: ghiChu,
      ngayTao: ngayTao,
      attachmentBase64: attachmentBase64,
    );
  }

  Future<void> addPayment({
    required String groupId,
    required double soTien,
    required String nguoiChi,
    required String nguoiHuong,
    required String nguoiChiId,
    required String nguoiHuongId,
    String? ghiChu,
    DateTime? ngayTao,
    String? attachmentBase64,
  }) async {
    await _createActivity(
      groupId: groupId,
      type: 'payment',
      tenChiTieu: 'Thanh toán',
      soTien: soTien,
      nguoiChi: nguoiChi,
      nguoiHuong: nguoiHuong,
      nguoiChiId: nguoiChiId,
      nguoiHuongId: nguoiHuongId,
      ghiChu: ghiChu,
      ngayTao: ngayTao,
      attachmentBase64: attachmentBase64,
    );
  }

  Future<void> _createActivity({
    required String groupId,
    required String type,
    required String tenChiTieu,
    required double soTien,
    required String nguoiChi,
    required String nguoiHuong,
    required String nguoiChiId,
    required String nguoiHuongId,
    String? ghiChu,
    DateTime? ngayTao,
    String? attachmentBase64,
  }) async {
    final groupRef = _db.collection('groups').doc(groupId);
    final payerRef = groupRef.collection('members').doc(nguoiChiId);
    final receiverRef = groupRef.collection('members').doc(nguoiHuongId);
    final activityRef = _db.collection('expenses').doc();

    await _db.runTransaction((transaction) async {
      final payerSnap = await transaction.get(payerRef);
      final receiverSnap = await transaction.get(receiverRef);

      if (!payerSnap.exists || !receiverSnap.exists) {
        throw StateError('Khong tim thay thanh vien de cap nhat so du.');
      }

      final payerData = payerSnap.data() ?? <String, dynamic>{};
      final receiverData = receiverSnap.data() ?? <String, dynamic>{};
      final payerBalance = _readBalance(payerData);
      final receiverBalance = _readBalance(receiverData);

      // Create activity record
      transaction.set(activityRef, {
        'groupId': groupId,
        'type': type,
        'tenChiTieu': tenChiTieu.trim(),
        'soTien': soTien,
        'nguoiChi': nguoiChi.trim(),
        'nguoiHuong': nguoiHuong.trim(),
        'nguoiChiId': nguoiChiId,
        'nguoiHuongId': nguoiHuongId,
        'ghiChu': (ghiChu ?? '').trim(),
        'attachmentBase64': (attachmentBase64 ?? '').trim(),
        'ngay Tao': ngayTao == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(ngayTao),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update balances: payer decreases, receiver increases
      transaction.update(payerRef, {'balance': payerBalance - soTien});
      transaction.update(receiverRef, {'balance': receiverBalance + soTien});
    });
  }

  Future<String> getCurrentUserName() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return 'Nguoi dung';
    }

    final userDoc = await _db.collection('users').doc(currentUser.uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};

    final name =
        (userData['displayName'] ??
                userData['name'] ??
                currentUser.displayName ??
                userData['email'] ??
                currentUser.email ??
                '')
            .toString()
            .trim();

    return name.isEmpty ? 'Nguoi dung' : name;
  }

  double _readBalance(Map<String, dynamic> data) {
    final raw = data['balance'];
    if (raw is num) {
      return raw.toDouble();
    }
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }
}
