import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseService._internal() {
    // Ép cấu hình chạy kết nối an toàn cho môi trường Web ngay khi khởi tạo Service
    _db.settings = const Settings(persistenceEnabled: true);
  }


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

  // 1. SỬA HÀM addExpense: Nhận Map người chi và List người hưởng
  Future<void> addExpense({
    required String groupId,
    required String tenChiTieu,
    required Map<String, double> payers,
    required List<String> nguoiHuongIds,
    String? ghiChu,
    DateTime? ngayTao,
    String? attachmentBase64,
  }) async {
    // 1. Tính tổng số tiền từ Map payers gửi lên
    double totalAmount = payers.values.fold(0.0, (sum, item) => sum + item);
    if (totalAmount <= 0) throw Exception("Tổng số tiền phải lớn hơn 0");

    final int totalReceivers = nguoiHuongIds.isEmpty ? 1 : nguoiHuongIds.length;
    final double shareAmount = totalAmount / totalReceivers;

    // 2. Tạo một WriteBatch để gom các lệnh ghi dữ liệu
    final WriteBatch batch = _db.batch();
    final groupRef = _db.collection('groups').doc(groupId);

    // --- BƯỚC A: CẬP NHẬT SỐ DƯ CHO NHỮNG NGƯỜI CHI TIỀN ---
    for (var entry in payers.entries) {
      if (entry.value <= 0) continue;
      final pRef = groupRef.collection('members').doc(entry.key);

      // Sử her dụng FieldValue.increment để Firebase tự động cộng dồn trên Cloud,
      // Không cần phải đọc dữ liệu về trước => Loại bỏ hoàn toàn lỗi bất đồng bộ!
      batch.update(pRef, {
        'balance': FieldValue.increment(entry.value),
      });
    }

    // --- BƯỚC B: CẬP NHẬT SỐ DƯ CHO NHỮNG NGƯỜI HƯỞNG TIỀN ---
    for (String rId in nguoiHuongIds) {
      if (rId.trim().isEmpty) continue;
      final rRef = groupRef.collection('members').doc(rId.trim());

      batch.update(rRef, {
        'balance': FieldValue.increment(-shareAmount),
      });
    }

    // --- BƯỚC C: TẠO BẢN GHI LỊCH SỬ HOẠT ĐỘNG ---
    final activityRef = _db.collection('expenses').doc();

    // Ép kiểu Map tường minh tránh lỗi định dạng JSON trên Web
    final Map<String, dynamic> firestorePayers = {};
    payers.forEach((k, v) => firestorePayers[k] = v);

    batch.set(activityRef, {
      'groupId': groupId,
      'type': 'expense',
      'tenChiTieu': tenChiTieu.trim(),
      'soTien': totalAmount,
      'payers': firestorePayers,
      'nguoiHuongIds': nguoiHuongIds,
      'ghiChu': (ghiChu ?? '').trim(),
      'attachmentBase64': (attachmentBase64 ?? '').trim(),
      'ngayTao': ngayTao == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(ngayTao),
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. Thực thi đồng loạt tất cả các lệnh trên Cloud
    await batch.commit();
  }

  // 2. GIỮ NGUYÊN HÀM addPayment: Tạo một Map giả lập 1 người chi để tái sử dụng hàm _createActivity mới
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
      payers: {nguoiChiId: soTien}, // Chuyển đổi về Map để đồng bộ xử lý
      nguoiHuongIds: [nguoiHuongId], // Chuyển đổi về List để đồng bộ xử lý
      ghiChu: ghiChu,
      ngayTao: ngayTao,
      attachmentBase64: attachmentBase64,
    );
  }

  // 3. NÂNG CẤP HÀM VÀNG _createActivity: Xử lý được cả đơn lẻ lẫn tập thể bằng Transaction
  Future<void> _createActivity({
    required String groupId,
    required String type,
    required String tenChiTieu,
    required double soTien,
    required String nguoiChi,
    required String nguoiHuong,
    required String nguoiChiId,
    required String nguoiHuongId,
    required Map<String, double> payers,
    required List<String> nguoiHuongIds,
    String? ghiChu,
    DateTime? ngayTao,
    String? attachmentBase64,
  }) async {
    final groupRef = _db.collection('groups').doc(groupId);
    final activityRef = _db.collection('expenses').doc();

    // Tính toán số tiền chia đều cho mỗi người hưởng (Tránh chia cho 0)
    final int totalReceivers = nguoiHuongIds.isEmpty ? 1 : nguoiHuongIds.length;
    final double shareAmount = soTien / totalReceivers;

    await _db.runTransaction((transaction) async {
      // --- BƯỚC A: CẬP NHẬT SỐ DƯ CHO NHỮNG NGƯỜI CHI TIỀN ---
      for (var entry in payers.entries) {
        if (entry.value <= 0) continue; // Bỏ qua nếu người này đóng góp bằng 0
        final pRef = groupRef.collection('members').doc(entry.key);
        final pSnap = await transaction.get(pRef);

        double pBalance = 0.0;
        if (pSnap.exists) {
          pBalance = _readBalance(pSnap.data() ?? {});
        }
        transaction.update(pRef, {'balance': pBalance + entry.value});
      }

      // --- BƯỚC B: CẬP NHẬT SỐ DƯ CHO NHỮNG NGƯỜI HƯỞNG TIỀN ---
      for (String rId in nguoiHuongIds) {
        if (rId.trim().isEmpty) continue;
        final rRef = groupRef.collection('members').doc(rId);
        final rSnap = await transaction.get(rRef);

        double rBalance = 0.0;
        if (rSnap.exists) {
          rBalance = _readBalance(rSnap.data() ?? {});
        }
        transaction.update(rRef, {'balance': rBalance - shareAmount});
      }

      // --- BƯỚC C: TẠO BẢN GHI LỊCH SỬ HOẠT ĐỘNG (Ép kiểu Map rõ ràng) ---
      final Map<String, dynamic> firestorePayers = {};
      payers.forEach((k, v) => firestorePayers[k] = v);

      transaction.set(activityRef, {
        'groupId': groupId,
        'type': type,
        'tenChiTieu': tenChiTieu.trim(),
        'soTien': soTien,
        'nguoiChi': nguoiChi.trim(),
        'nguoiHuong': nguoiHuong.trim(),
        'nguoiChiId': nguoiChiId,
        'nguoiHuongId': nguoiHuongId,
        'payers': firestorePayers,
        'nguoiHuongIds': nguoiHuongIds,
        'ghiChu': (ghiChu ?? '').trim(),
        'attachmentBase64': (attachmentBase64 ?? '').trim(),
        'ngay Tao': ngayTao == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(ngayTao),
        'createdAt': FieldValue.serverTimestamp(),
      });
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
