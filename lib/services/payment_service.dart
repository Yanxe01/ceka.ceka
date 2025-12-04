import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload bukti pembayaran ke Firebase Storage
  Future<String> uploadPaymentProof(File imageFile, String paymentId) async {
    try {
      final ref = _storage.ref().child('payment_proofs/$paymentId.jpg');
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print("ERROR uploadPaymentProof: $e");
      throw Exception("Gagal upload bukti pembayaran");
    }
  }

  /// Buat payment baru
  Future<String> createPayment({
    required String expenseId,
    required String receiverId,
    required double amount,
    required String paymentMethod,
    File? proofImage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    try {
      print("DEBUG createPayment: Creating payment...");
      print("DEBUG createPayment: ExpenseId: $expenseId");
      print("DEBUG createPayment: PayerId: ${user.uid}");
      print("DEBUG createPayment: ReceiverId: $receiverId");
      print("DEBUG createPayment: Amount: $amount");
      print("DEBUG createPayment: PaymentMethod: $paymentMethod");

      // Create payment document first to get ID
      final docRef = await _firestore.collection('payments').add({
        'expenseId': expenseId,
        'payerId': user.uid,
        'receiverId': receiverId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'proofImageUrl': null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'confirmedAt': null,
      });

      print("DEBUG createPayment: Payment created with ID: ${docRef.id}");

      // Upload proof image if provided
      if (proofImage != null) {
        print("DEBUG createPayment: Uploading proof image...");
        final imageUrl = await uploadPaymentProof(proofImage, docRef.id);
        await docRef.update({'proofImageUrl': imageUrl});
        print("DEBUG createPayment: Proof image uploaded: $imageUrl");
      }

      print("DEBUG createPayment: Payment successfully created");
      return docRef.id;
    } catch (e) {
      print("ERROR createPayment: $e");
      rethrow;
    }
  }

  /// Get bills (tagihan yang harus dibayar user)
  /// Bills = Expenses di mana user BUKAN payer DAN belum ada payment dengan status confirmed
  Stream<List<Map<String, dynamic>>> getUserBills() {
    final user = _auth.currentUser;
    if (user == null) {
      print("DEBUG getUserBills: User not logged in");
      return Stream.value([]);
    }

    print("DEBUG getUserBills: Getting bills for user ${user.uid}");

    return _firestore
        .collection('expenses')
        .snapshots()
        .asyncMap((expenseSnapshot) async {
      List<Map<String, dynamic>> bills = [];

      for (var expenseDoc in expenseSnapshot.docs) {
        final expenseData = expenseDoc.data();
        final payerId = expenseData['payerId'] as String?;
        final splitDetails = expenseData['splitDetails'] as Map<String, dynamic>?;

        // Hanya ambil expense di mana user bukan payer DAN user ada di splitDetails
        if (payerId != null && payerId != user.uid && splitDetails != null) {
          if (splitDetails.containsKey(user.uid)) {
            final userAmount = (splitDetails[user.uid] as num?)?.toDouble() ?? 0;

            if (userAmount > 0) {
              // Cek apakah sudah ada payment yang confirmed untuk expense ini
              final paymentSnapshot = await _firestore
                  .collection('payments')
                  .where('expenseId', isEqualTo: expenseDoc.id)
                  .where('payerId', isEqualTo: user.uid)
                  .where('status', isEqualTo: 'confirmed')
                  .get();

              if (paymentSnapshot.docs.isEmpty) {
                // Belum ada payment confirmed, masukkan ke bills
                bills.add({
                  'expenseId': expenseDoc.id,
                  'title': expenseData['title'] ?? 'Untitled',
                  'amount': userAmount,
                  'payerId': payerId,
                  'groupId': expenseData['groupId'] ?? '',
                  'date': expenseData['date'] ?? Timestamp.now(),
                  'status': 'unpaid',
                });
              }
            }
          }
        }
      }

      print("DEBUG getUserBills: Found ${bills.length} bills");
      return bills;
    });
  }

  /// Get payment history (pembayaran yang sudah confirmed)
  Stream<List<Map<String, dynamic>>> getUserPaymentHistory() {
    final user = _auth.currentUser;
    if (user == null) {
      print("DEBUG getUserPaymentHistory: User not logged in");
      return Stream.value([]);
    }

    print("DEBUG getUserPaymentHistory: Getting payment history for user ${user.uid}");

    // Simplified query - hanya where payerId, tanpa orderBy untuk menghindari composite index
    return _firestore
        .collection('payments')
        .where('payerId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .asyncMap((paymentSnapshot) async {
      List<Map<String, dynamic>> history = [];

      for (var paymentDoc in paymentSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final expenseId = paymentData['expenseId'] as String?;

        if (expenseId != null) {
          // Get expense details
          final expenseDoc = await _firestore.collection('expenses').doc(expenseId).get();
          if (expenseDoc.exists) {
            final expenseData = expenseDoc.data();
            history.add({
              'paymentId': paymentDoc.id,
              'expenseId': expenseId,
              'title': expenseData?['title'] ?? 'Untitled',
              'amount': (paymentData['amount'] ?? 0).toDouble(),
              'paymentMethod': paymentData['paymentMethod'] ?? 'cash',
              'status': 'paid',
              'date': paymentData['confirmedAt'] ?? paymentData['createdAt'],
            });
          }
        }
      }

      // Sort di client side instead of server
      history.sort((a, b) {
        final aDate = a['date'];
        final bDate = b['date'];
        if (aDate == null || bDate == null) return 0;

        DateTime aDateTime = aDate is DateTime ? aDate : (aDate as Timestamp).toDate();
        DateTime bDateTime = bDate is DateTime ? bDate : (bDate as Timestamp).toDate();

        return bDateTime.compareTo(aDateTime); // Descending order
      });

      print("DEBUG getUserPaymentHistory: Found ${history.length} payment records");
      return history;
    });
  }

  /// Confirm payment (untuk penerima pembayaran)
  Future<void> confirmPayment(String paymentId) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'confirmed',
        'confirmedAt': FieldValue.serverTimestamp(),
      });
      print("DEBUG confirmPayment: Payment $paymentId confirmed");
    } catch (e) {
      print("ERROR confirmPayment: $e");
      rethrow;
    }
  }

  /// Reject payment (untuk penerima pembayaran)
  Future<void> rejectPayment(String paymentId) async {
    try {
      await _firestore.collection('payments').doc(paymentId).update({
        'status': 'rejected',
      });
      print("DEBUG rejectPayment: Payment $paymentId rejected");
    } catch (e) {
      print("ERROR rejectPayment: $e");
      rethrow;
    }
  }
}
