import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addExpense({
    required String title,
    required double amount,
    required String groupId,
    required Map<String, double> splitDetails,
    required String splitType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    print("DEBUG addExpense: User UID: ${user.uid}");
    print("DEBUG addExpense: Title: $title");
    print("DEBUG addExpense: Amount: $amount");
    print("DEBUG addExpense: GroupId: $groupId");
    print("DEBUG addExpense: SplitType: $splitType");
    print("DEBUG addExpense: SplitDetails: $splitDetails");

    final expenseData = {
      'title': title,
      'amount': amount,
      'date': Timestamp.now(), // Default hari ini
      'groupId': groupId,
      'payerId': user.uid,
      'splitDetails': splitDetails,
      'splitType': splitType,
      'createdAt': FieldValue.serverTimestamp(),
    };

    print("DEBUG addExpense: Full expense data being saved: $expenseData");

    await _firestore.collection('expenses').add(expenseData);
    print("DEBUG addExpense: Expense saved successfully");
  }

  /// Get total utang (berapa yang harus user bayar ke orang lain)
  /// Utang = Jumlah yang harus dibayar user dari expense yang dibuat orang lain
  Stream<double> getTotalUtang() {
    final user = _auth.currentUser;
    if (user == null) {
      print("DEBUG getTotalUtang: User not logged in");
      return Stream.value(0);
    }

    print("DEBUG getTotalUtang: Starting stream for user ${user.uid}");

    // Ambil SEMUA expenses, lalu filter di client side
    // Karena Firestore query dengan map key bisa bermasalah
    return _firestore
        .collection('expenses')
        .snapshots()
        .map((snapshot) {
      double total = 0;
      print("DEBUG getTotalUtang: Processing ${snapshot.docs.length} total expenses in database");

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final payerId = data['payerId'] as String?;
        final splitDetails = data['splitDetails'] as Map<String, dynamic>?;

        print("DEBUG getTotalUtang: Checking expense ${doc.id} - payerId: $payerId, splitDetails: $splitDetails");

        // Hanya hitung jika:
        // 1. User bukan payer (user berutang ke payer)
        // 2. User ada di splitDetails
        if (payerId != null && payerId != user.uid && splitDetails != null) {
          if (splitDetails.containsKey(user.uid)) {
            final userShare = (splitDetails[user.uid] as num?)?.toDouble() ?? 0;
            if (userShare > 0) {
              total += userShare;
              print("DEBUG getTotalUtang: ✓ Added $userShare from expense ${doc.id} (${data['title']}), new total: $total");
            }
          } else {
            print("DEBUG getTotalUtang: ✗ User ${user.uid} NOT found in splitDetails");
          }
        } else {
          if (payerId == user.uid) {
            print("DEBUG getTotalUtang: ✗ Skipping expense ${doc.id} - user is the payer");
          }
        }
      }

      print("DEBUG getTotalUtang: ====== Final total utang: Rp $total ======");
      return total;
    });
  }

  /// Get total piutang (berapa yang harus orang lain bayar ke user)
  /// Piutang = Jumlah yang harus dibayar orang lain dari expense yang dibuat user
  Stream<double> getTotalPiutang() {
    final user = _auth.currentUser;
    if (user == null) {
      print("DEBUG getTotalPiutang: User not logged in");
      return Stream.value(0);
    }

    print("DEBUG getTotalPiutang: Starting stream for user ${user.uid}");

    // Ambil SEMUA expenses, lalu filter yang payerId = user.uid di client side
    return _firestore
        .collection('expenses')
        .snapshots()
        .map((snapshot) {
      double total = 0;
      print("DEBUG getTotalPiutang: Processing ${snapshot.docs.length} total expenses in database");

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final payerId = data['payerId'] as String?;
        final splitDetails = data['splitDetails'] as Map<String, dynamic>?;

        print("DEBUG getTotalPiutang: Checking expense ${doc.id} - payerId: $payerId, splitDetails: $splitDetails");

        // Hanya hitung jika user adalah payer (orang lain berutang ke user)
        if (payerId == user.uid && splitDetails != null) {
          // Hitung total yang harus dibayar orang lain (tidak termasuk user sendiri)
          splitDetails.forEach((uid, amount) {
            if (uid != user.uid) {
              final amt = (amount as num).toDouble();
              total += amt;
              print("DEBUG getTotalPiutang: ✓ Added $amt from user $uid (expense: ${data['title']}), new total: $total");
            }
          });
        } else {
          if (payerId != user.uid) {
            print("DEBUG getTotalPiutang: ✗ Skipping expense ${doc.id} - user is NOT the payer");
          }
        }
      }

      print("DEBUG getTotalPiutang: ====== Final total piutang: Rp $total ======");
      return total;
    });
  }
}