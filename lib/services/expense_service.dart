import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<DocumentReference> addExpense({
    required String title,
    required double amount,
    required String groupId,
    required Map<String, double> splitDetails,
    required String splitType,
    DateTime? dueDate, // Tanggal deadline pembayaran (optional)
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    print("DEBUG addExpense: User UID: ${user.uid}");
    print("DEBUG addExpense: Title: $title");
    print("DEBUG addExpense: Amount: $amount");
    print("DEBUG addExpense: GroupId: $groupId");
    print("DEBUG addExpense: SplitType: $splitType");
    print("DEBUG addExpense: SplitDetails: $splitDetails");
    print("DEBUG addExpense: DueDate: $dueDate");

    final expenseData = {
      'title': title,
      'amount': amount,
      'date': Timestamp.now(), // Default hari ini
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
      'groupId': groupId,
      'payerId': user.uid,
      'splitDetails': splitDetails,
      'splitType': splitType,
      'createdAt': FieldValue.serverTimestamp(),
    };

    print("DEBUG addExpense: Full expense data being saved: $expenseData");

    final docRef = await _firestore.collection('expenses').add(expenseData);
    print("DEBUG addExpense: Expense saved successfully with ID: ${docRef.id}");

    // Kirim notifikasi piutang ke user yang membuat expense (karena orang lain berhutang ke dia)
    // Note: Notifikasi piutang dikirim ke user yang memiliki piutang, bukan debtor
    // Dalam kasus ini, user yang membuat expense memiliki piutang dari member lain
    // Tapi notifikasi ini akan dikirim setelah expense dibuat dan member membayar

    // Jika ada due date, schedule reminder H-1
    if (dueDate != null) {
      final reminderService = ReminderService();
      await reminderService.scheduleH1Reminder(
        expenseId: docRef.id,
        groupId: groupId,
        expenseTitle: title,
        dueDate: dueDate,
        splitDetails: splitDetails,
      );
    }

    return docRef;
  }

  /// Get total utang (berapa yang harus user bayar ke orang lain)
  /// Utang = Jumlah yang harus dibayar user dari SEMUA expense (termasuk yang dibuat user sendiri)
  /// DIKURANGI dengan pembayaran yang sudah confirmed
  /// DITAMBAH dengan pembayaran yang ditanggung orang lain untuk user (payer_covered)
  Stream<double> getTotalUtang() {
    final user = _auth.currentUser;
    if (user == null) {
      print("DEBUG getTotalUtang: User not logged in");
      return Stream.value(0);
    }

    print("DEBUG getTotalUtang: Starting stream for user ${user.uid}");

    // Ambil expenses dan groups secara realtime
    return _firestore.collection('expenses').snapshots().asyncMap((expenseSnapshot) async {
      double total = 0;
      print("DEBUG getTotalUtang: Processing ${expenseSnapshot.docs.length} total expenses in database");

      // Ambil semua group IDs yang masih ada
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: user.uid)
          .get();

      final validGroupIds = groupsSnapshot.docs.map((doc) => doc.id).toSet();
      print("DEBUG getTotalUtang: User is member of ${validGroupIds.length} groups: $validGroupIds");

      for (var doc in expenseSnapshot.docs) {
        final data = doc.data();
        final payerId = data['payerId'] as String?;
        final groupId = data['groupId'] as String?;
        final splitDetails = data['splitDetails'] as Map<String, dynamic>?;

        print("DEBUG getTotalUtang: Checking expense ${doc.id} - groupId: $groupId, payerId: $payerId");

        // Skip jika groupId null atau group sudah tidak ada
        if (groupId == null || !validGroupIds.contains(groupId)) {
          print("DEBUG getTotalUtang: ✗ Skipping expense ${doc.id} - group not found or deleted");
          continue;
        }

        // Hitung bagian user di splitDetails, termasuk jika user adalah payer
        // Karena user juga harus bayar bagiannya (walaupun dia yang menalangi)
        if (payerId != null && splitDetails != null && splitDetails.containsKey(user.uid)) {
          final userShare = (splitDetails[user.uid] as num?)?.toDouble() ?? 0;

          if (userShare > 0) {
            // Cek apakah user sudah bayar (confirmed) untuk expense ini
            final paymentSnapshot = await _firestore
                .collection('payments')
                .where('expenseId', isEqualTo: doc.id)
                .where('payerId', isEqualTo: user.uid)
                .where('status', isEqualTo: 'confirmed')
                .get();

            // Jika belum ada payment confirmed, masukkan ke total utang
            if (paymentSnapshot.docs.isEmpty) {
              total += userShare;
              print("DEBUG getTotalUtang: ✓ Added $userShare from expense ${doc.id} (${data['title']}) - NOT PAID YET, new total: $total");
            } else {
              print("DEBUG getTotalUtang: ✗ Skipping expense ${doc.id} - user already paid (confirmed)");
            }
          }
        } else {
          print("DEBUG getTotalUtang: ✗ User ${user.uid} NOT found in splitDetails for expense ${doc.id}");
        }
      }

      // TAMBAHAN: Hitung utang dari pembayaran yang ditanggung orang lain untuk user
      // Query payments where payerId = user (user yang dibantu) dan paymentMethod = payer_covered
      print("DEBUG getTotalUtang: Checking payments covered by others for user...");
      final coveredForUserSnapshot = await _firestore
          .collection('payments')
          .where('payerId', isEqualTo: user.uid)
          .where('paymentMethod', isEqualTo: 'payer_covered')
          .where('status', isEqualTo: 'confirmed')
          .get();

      print("DEBUG getTotalUtang: Found ${coveredForUserSnapshot.docs.length} payments covered by others");

      for (var paymentDoc in coveredForUserSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final amount = (paymentData['amount'] ?? 0).toDouble();
        final receiverId = paymentData['receiverId'] as String?; // Admin yang menalangi

        if (amount > 0 && receiverId != null) {
          // Cek apakah user sudah bayar kembali ke admin
          final repaymentSnapshot = await _firestore
              .collection('payments')
              .where('payerId', isEqualTo: user.uid)
              .where('receiverId', isEqualTo: receiverId)
              .where('relatedCoveredPaymentId', isEqualTo: paymentDoc.id)
              .where('status', isEqualTo: 'confirmed')
              .get();

          // Jika belum bayar kembali, tambahkan ke utang
          if (repaymentSnapshot.docs.isEmpty) {
            total += amount;
            print("DEBUG getTotalUtang: ✓ Added $amount from covered payment by user $receiverId, new total: $total");
          } else {
            print("DEBUG getTotalUtang: ✗ Skipping covered payment - already repaid to user $receiverId");
          }
        }
      }

      print("DEBUG getTotalUtang: ====== Final total utang (including covered debts): Rp $total ======");
      return total;
    });
  }

  /// Get total piutang (berapa yang harus orang lain bayar ke user)
  /// Piutang = Jumlah yang harus dibayar orang lain dari expense yang dibuat user
  /// DIKURANGI dengan pembayaran yang sudah confirmed
  /// DITAMBAH dengan pembayaran yang ditanggung user untuk member lain (payer_covered)
  Stream<double> getTotalPiutang() {
    final user = _auth.currentUser;
    if (user == null) {
      print("DEBUG getTotalPiutang: User not logged in");
      return Stream.value(0);
    }

    print("DEBUG getTotalPiutang: Starting stream for user ${user.uid}");

    // Ambil expenses dan groups secara realtime
    return _firestore.collection('expenses').snapshots().asyncMap((expenseSnapshot) async {
      double total = 0;
      print("DEBUG getTotalPiutang: Processing ${expenseSnapshot.docs.length} total expenses in database");

      // Ambil semua group IDs yang masih ada
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: user.uid)
          .get();

      final validGroupIds = groupsSnapshot.docs.map((doc) => doc.id).toSet();
      print("DEBUG getTotalPiutang: User is member of ${validGroupIds.length} groups: $validGroupIds");

      for (var doc in expenseSnapshot.docs) {
        final data = doc.data();
        final payerId = data['payerId'] as String?;
        final groupId = data['groupId'] as String?;
        final splitDetails = data['splitDetails'] as Map<String, dynamic>?;

        print("DEBUG getTotalPiutang: Checking expense ${doc.id} - groupId: $groupId, payerId: $payerId");

        // Skip jika groupId null atau group sudah tidak ada
        if (groupId == null || !validGroupIds.contains(groupId)) {
          print("DEBUG getTotalPiutang: ✗ Skipping expense ${doc.id} - group not found or deleted");
          continue;
        }

        // Hanya hitung jika user adalah payer (orang lain berutang ke user)
        if (payerId == user.uid && splitDetails != null) {
          // Cek siapa saja yang sudah bayar (confirmed)
          final paymentsSnapshot = await _firestore
              .collection('payments')
              .where('expenseId', isEqualTo: doc.id)
              .where('status', isEqualTo: 'confirmed')
              .get();

          // Buat set berisi UID yang sudah bayar
          final paidUserIds = paymentsSnapshot.docs
              .map((paymentDoc) => paymentDoc.data()['payerId'] as String?)
              .where((uid) => uid != null)
              .toSet();

          print("DEBUG getTotalPiutang: Expense ${doc.id} - Users who already paid: $paidUserIds");

          // Cek apakah SEMUA member sudah bayar
          bool allPaid = true;
          for (var uid in splitDetails.keys) {
            if (uid != user.uid && !paidUserIds.contains(uid)) {
              allPaid = false;
              break;
            }
          }

          // Jika SEMUA sudah bayar, skip dari penghitungan piutang
          // JANGAN HAPUS expense agar payment history tetap ada
          if (allPaid && splitDetails.length > 1) {
            print("DEBUG getTotalPiutang: ✓ ALL members paid for expense ${doc.id} - Skipping from piutang calculation (NOT deleting for history)");
            continue; // Skip penghitungan, tapi expense tetap ada untuk payment history
          }

          // Hitung total yang harus dibayar orang lain (tidak termasuk user sendiri)
          // DAN yang belum melakukan confirmed payment
          splitDetails.forEach((uid, amount) {
            if (uid != user.uid && !paidUserIds.contains(uid)) {
              final amt = (amount as num).toDouble();
              total += amt;
              print("DEBUG getTotalPiutang: ✓ Added $amt from user $uid (expense: ${data['title']}) - NOT PAID YET, new total: $total");
            } else if (uid != user.uid && paidUserIds.contains(uid)) {
              print("DEBUG getTotalPiutang: ✗ Skipping user $uid - already paid");
            }
          });
        } else {
          if (payerId != user.uid) {
            print("DEBUG getTotalPiutang: ✗ Skipping expense ${doc.id} - user is NOT the payer");
          }
        }
      }

      // TAMBAHAN: Hitung piutang dari pembayaran yang user tanggung untuk member lain
      // Query payments where receiverId = user (user yang menalangi) dan paymentMethod = payer_covered
      print("DEBUG getTotalPiutang: Checking covered payments...");
      final coveredPaymentsSnapshot = await _firestore
          .collection('payments')
          .where('receiverId', isEqualTo: user.uid)
          .where('paymentMethod', isEqualTo: 'payer_covered')
          .where('status', isEqualTo: 'confirmed')
          .get();

      print("DEBUG getTotalPiutang: Found ${coveredPaymentsSnapshot.docs.length} covered payments");

      for (var paymentDoc in coveredPaymentsSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final amount = (paymentData['amount'] ?? 0).toDouble();
        final payerId = paymentData['payerId'] as String?; // Member yang dibantu

        if (amount > 0 && payerId != null) {
          // Cek apakah member sudah bayar kembali ke user
          final repaymentSnapshot = await _firestore
              .collection('payments')
              .where('payerId', isEqualTo: payerId)
              .where('receiverId', isEqualTo: user.uid)
              .where('relatedCoveredPaymentId', isEqualTo: paymentDoc.id)
              .where('status', isEqualTo: 'confirmed')
              .get();

          // Jika belum ada pembayaran balik, tambahkan ke piutang
          if (repaymentSnapshot.docs.isEmpty) {
            total += amount;
            print("DEBUG getTotalPiutang: ✓ Added $amount from covered payment for user $payerId, new total: $total");
          } else {
            print("DEBUG getTotalPiutang: ✗ Skipping covered payment - already repaid by user $payerId");
          }
        }
      }

      print("DEBUG getTotalPiutang: ====== Final total piutang (including covered payments): Rp $total ======");
      return total;
    });
  }
}