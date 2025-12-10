import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import '../models/payment_model.dart';
import '../services/notification_service.dart';

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
  /// Bills = Expenses di mana user ada di splitDetails DAN belum lunas
  /// TERMASUK expense yang user buat sendiri (admin juga harus bayar bagiannya)
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

      // Ambil semua group IDs yang masih ada dan user masih menjadi member
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: user.uid)
          .get();

      final validGroupIds = groupsSnapshot.docs.map((doc) => doc.id).toSet();
      print("DEBUG getUserBills: Valid groups: $validGroupIds");

      print("DEBUG getUserBills: Total expenses in database: ${expenseSnapshot.docs.length}");

      for (var expenseDoc in expenseSnapshot.docs) {
        final expenseData = expenseDoc.data();
        final payerId = expenseData['payerId'] as String?;
        final splitDetails = expenseData['splitDetails'] as Map<String, dynamic>?;
        final groupId = expenseData['groupId'] as String?;
        final title = expenseData['title'] ?? 'Untitled';

        print("DEBUG getUserBills: ===== Expense ${expenseDoc.id} =====");
        print("DEBUG getUserBills: Title: $title");
        print("DEBUG getUserBills: PayerId: $payerId");
        print("DEBUG getUserBills: GroupId: $groupId");
        print("DEBUG getUserBills: SplitDetails keys: ${splitDetails?.keys.toList()}");
        print("DEBUG getUserBills: User is in splitDetails: ${splitDetails?.containsKey(user.uid)}");

        // Skip jika groupId null atau group sudah tidak ada
        if (groupId == null || !validGroupIds.contains(groupId)) {
          print("DEBUG getUserBills: ✗ SKIPPED - invalid group (groupId: $groupId, valid: ${validGroupIds.contains(groupId)})");
          continue;
        }

        // Cek apakah user ada di splitDetails
        if (splitDetails != null && splitDetails.containsKey(user.uid)) {
          final userAmount = (splitDetails[user.uid] as num?)?.toDouble() ?? 0;
          print("DEBUG getUserBills: User amount in expense ${expenseDoc.id}: $userAmount");

          if (userAmount > 0) {
            // Cek apakah sudah ada payment (pending atau confirmed) untuk expense ini
            final paymentSnapshot = await _firestore
                .collection('payments')
                .where('expenseId', isEqualTo: expenseDoc.id)
                .where('payerId', isEqualTo: user.uid)
                .get();

            // Filter payment yang confirmed atau pending
            final relevantPayments = paymentSnapshot.docs.where((doc) {
              final status = doc.data()['status'] as String?;
              return status == 'confirmed' || status == 'pending';
            }).toList();

            print("DEBUG getUserBills: Payments (confirmed/pending) for expense ${expenseDoc.id}: ${relevantPayments.length}");

            if (relevantPayments.isEmpty) {
              // Belum ada payment (pending atau confirmed), masukkan ke bills
              // Jika user adalah payer, dia bayar ke diri sendiri (kas bersama)
              // Jika user bukan payer, dia bayar ke payer
              bills.add({
                'expenseId': expenseDoc.id,
                'title': expenseData['title'] ?? 'Untitled',
                'amount': userAmount,
                'payerId': payerId ?? user.uid,
                'groupId': groupId,
                'date': expenseData['date'] ?? Timestamp.now(),
                'dueDate': expenseData['dueDate'], // Include due date
                'status': 'unpaid',
              });
              print("DEBUG getUserBills: Added bill for expense ${expenseDoc.id}");
            } else {
              print("DEBUG getUserBills: Skipping expense ${expenseDoc.id} - payment already exists (confirmed/pending)");
            }
          }
        } else {
          print("DEBUG getUserBills: User NOT in splitDetails for expense ${expenseDoc.id}");
        }
      }

      print("DEBUG getUserBills: ===== Found ${bills.length} total bills =====");
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

    // Gabungkan 2 stream: payment yang user bayarkan DAN payment yang user terima
    return _firestore
        .collection('payments')
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .asyncMap((paymentSnapshot) async {
      List<Map<String, dynamic>> history = [];
      Set<String> processedPaymentIds = {}; // Untuk mencegah duplikasi

      // Ambil semua group IDs yang masih ada dan user masih menjadi member
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: user.uid)
          .get();

      final validGroupIds = groupsSnapshot.docs.map((doc) => doc.id).toSet();

      for (var paymentDoc in paymentSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final payerId = paymentData['payerId'] as String?;
        final receiverId = paymentData['receiverId'] as String?;
        final expenseId = paymentData['expenseId'] as String?;
        final relatedCoveredPaymentId = paymentData['relatedCoveredPaymentId'] as String?;
        final paymentMethod = paymentData['paymentMethod'] as String?;

        // Skip jika payment sudah diproses
        if (processedPaymentIds.contains(paymentDoc.id)) {
          continue;
        }

        // Hanya proses payment yang relevan dengan user (sebagai payer ATAU receiver)
        if (payerId != user.uid && receiverId != user.uid) {
          continue;
        }

        // Tandai payment ini sudah diproses
        processedPaymentIds.add(paymentDoc.id);

        if (expenseId != null) {
          // Get expense details
          final expenseDoc = await _firestore.collection('expenses').doc(expenseId).get();

          // Ambil expense data jika ada, atau gunakan default jika tidak ada
          String expenseTitle = 'Untitled';
          String? groupId;

          if (expenseDoc.exists) {
            final expenseData = expenseDoc.data();
            expenseTitle = expenseData?['title'] ?? 'Untitled';
            groupId = expenseData?['groupId'] as String?;

            // Skip jika groupId ada tapi group sudah tidak ada (user sudah leave)
            if (groupId != null && !validGroupIds.contains(groupId)) {
              continue;
            }
          } else {
            // Expense sudah dihapus, tapi tetap tampilkan payment history
            print("DEBUG getUserPaymentHistory: Expense $expenseId not found, but showing payment in history");
          }

          // Format date for display
          final confirmedAt = paymentData['confirmedAt'] ?? paymentData['createdAt'];
          String formattedDate = '';
          if (confirmedAt != null) {
            DateTime dateTime = confirmedAt is DateTime ? confirmedAt : (confirmedAt as Timestamp).toDate();
            formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);
          }

          // Cek apakah ini pembayaran yang ditanggung admin (payer_covered)
          bool isCoveredPayment = paymentMethod == 'payer_covered';

          // Tentukan apakah user adalah payer atau receiver
          bool userIsPayer = payerId == user.uid;
          bool userIsReceiver = receiverId == user.uid;

          // Ambil nama counterpart (lawan transaksi)
          String counterpartName = '';
          String counterpartRole = ''; // 'dari' atau 'ke'

          if (userIsPayer) {
            // User membayar, ambil nama receiver
            if (receiverId != null) {
              final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
              counterpartName = receiverDoc.data()?['name'] ?? receiverDoc.data()?['displayName'] ?? 'Admin';
            }
            counterpartRole = isCoveredPayment ? 'ditanggung oleh' : 'ke';
          } else if (userIsReceiver) {
            // User menerima, ambil nama payer
            if (payerId != null) {
              final payerDoc = await _firestore.collection('users').doc(payerId).get();
              counterpartName = payerDoc.data()?['name'] ?? payerDoc.data()?['displayName'] ?? 'Member';
            }
            counterpartRole = 'dari';
          }

          history.add({
            'paymentId': paymentDoc.id,
            'expenseId': expenseId,
            'title': expenseTitle,
            'amount': (paymentData['amount'] ?? 0).toDouble(),
            'paymentMethod': paymentMethod ?? 'cash',
            'status': userIsReceiver ? 'received' : 'paid',
            'date': formattedDate,
            'rawDate': confirmedAt, // For sorting
            'isCoveredPayment': isCoveredPayment,
            'receiverName': userIsPayer ? counterpartName : '',
            'payerName': userIsReceiver ? counterpartName : '',
            'counterpartName': counterpartName,
            'counterpartRole': counterpartRole,
            'userIsPayer': userIsPayer,
            'userIsReceiver': userIsReceiver,
            'isRepayment': false,
          });
        } else if (relatedCoveredPaymentId != null) {
          // Repayment (pembayaran kembali utang penalangan)
          final confirmedAt = paymentData['confirmedAt'] ?? paymentData['createdAt'];
          String formattedDate = '';
          if (confirmedAt != null) {
            DateTime dateTime = confirmedAt is DateTime ? confirmedAt : (confirmedAt as Timestamp).toDate();
            formattedDate = DateFormat('dd-MM-yyyy').format(dateTime);
          }

          // Tentukan apakah user adalah payer atau receiver
          bool userIsPayer = payerId == user.uid;
          bool userIsReceiver = receiverId == user.uid;

          // Ambil nama counterpart
          String counterpartName = '';
          String counterpartRole = '';

          if (userIsPayer) {
            // User membayar kembali utang, ambil nama admin yang menerima
            if (receiverId != null) {
              final receiverDoc = await _firestore.collection('users').doc(receiverId).get();
              counterpartName = receiverDoc.data()?['name'] ?? receiverDoc.data()?['displayName'] ?? 'Admin';
            }
            counterpartRole = 'ke';
          } else if (userIsReceiver) {
            // User menerima pembayaran kembali, ambil nama member yang bayar
            if (payerId != null) {
              final payerDoc = await _firestore.collection('users').doc(payerId).get();
              counterpartName = payerDoc.data()?['name'] ?? payerDoc.data()?['displayName'] ?? 'Member';
            }
            counterpartRole = 'dari';
          }

          history.add({
            'paymentId': paymentDoc.id,
            'expenseId': null,
            'title': 'Pembayaran Utang Penalangan',
            'amount': (paymentData['amount'] ?? 0).toDouble(),
            'paymentMethod': paymentMethod ?? 'cash',
            'status': userIsReceiver ? 'received' : 'paid',
            'date': formattedDate,
            'rawDate': confirmedAt,
            'isCoveredPayment': false,
            'receiverName': userIsPayer ? counterpartName : '',
            'payerName': userIsReceiver ? counterpartName : '',
            'counterpartName': counterpartName,
            'counterpartRole': counterpartRole,
            'userIsPayer': userIsPayer,
            'userIsReceiver': userIsReceiver,
            'isRepayment': true,
          });
        }
      }

      // Sort di client side instead of server
      history.sort((a, b) {
        final aDate = a['rawDate'];
        final bDate = b['rawDate'];
        if (aDate == null || bDate == null) return 0;

        DateTime aDateTime = aDate is DateTime ? aDate : (aDate as Timestamp).toDate();
        DateTime bDateTime = bDate is DateTime ? bDate : (bDate as Timestamp).toDate();

        return bDateTime.compareTo(aDateTime); // Descending order
      });

      print("DEBUG getUserPaymentHistory: Found ${history.length} total payment records (including covered & repayments)");
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

  /// Payer menalangi pembayaran untuk member tertentu
  /// Langsung create payment dengan status confirmed atas nama member
  Future<void> payForMember({
    required String expenseId,
    required String memberId,
    required double amount,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    try {
      print("DEBUG payForMember: Creating payment on behalf of member...");
      print("DEBUG payForMember: ExpenseId: $expenseId");
      print("DEBUG payForMember: MemberId (payer): $memberId");
      print("DEBUG payForMember: ReceiverId (admin): ${user.uid}");
      print("DEBUG payForMember: Amount: $amount");

      // Create payment document with status confirmed
      // payerId = member yang dibantu, receiverId = admin yang menalangi
      await _firestore.collection('payments').add({
        'expenseId': expenseId,
        'payerId': memberId, // Member yang dibantu
        'receiverId': user.uid, // Admin yang menalangi
        'amount': amount,
        'paymentMethod': 'payer_covered', // Metode khusus untuk penalangan
        'proofImageUrl': null,
        'status': 'confirmed', // Langsung confirmed
        'createdAt': FieldValue.serverTimestamp(),
        'confirmedAt': FieldValue.serverTimestamp(),
        'note': 'Ditanggung oleh payer', // Catatan tambahan
      });

      print("DEBUG payForMember: Payment successfully created and confirmed");
    } catch (e) {
      print("ERROR payForMember: $e");
      rethrow;
    }
  }

  /// Get tagihan member lain yang bisa ditanggung oleh payer
  /// Untuk menampilkan list member yang belum bayar di expense yang dibuat user
  Stream<List<Map<String, dynamic>>> getUnpaidMemberBills() {
    final user = _auth.currentUser;
    if (user == null) {
      print("DEBUG getUnpaidMemberBills: User not logged in");
      return Stream.value([]);
    }

    print("DEBUG getUnpaidMemberBills: Getting unpaid member bills for payer ${user.uid}");

    return _firestore
        .collection('expenses')
        .where('payerId', isEqualTo: user.uid) // Hanya expense yang dibuat user
        .snapshots()
        .asyncMap((expenseSnapshot) async {
      List<Map<String, dynamic>> unpaidBills = [];

      // Ambil semua group IDs yang masih ada
      final groupsSnapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: user.uid)
          .get();

      final validGroupIds = groupsSnapshot.docs.map((doc) => doc.id).toSet();
      print("DEBUG getUnpaidMemberBills: Valid groups: $validGroupIds");

      for (var expenseDoc in expenseSnapshot.docs) {
        final expenseData = expenseDoc.data();
        final splitDetails = expenseData['splitDetails'] as Map<String, dynamic>?;
        final groupId = expenseData['groupId'] as String?;

        // Skip jika groupId null atau group sudah tidak ada
        if (groupId == null || !validGroupIds.contains(groupId)) {
          continue;
        }

        if (splitDetails != null) {
          // Loop setiap member di splitDetails
          for (var entry in splitDetails.entries) {
            final memberId = entry.key;
            final memberAmount = (entry.value as num).toDouble();

            // Skip jika member adalah payer sendiri
            if (memberId == user.uid) continue;

            // Cek apakah member ini sudah bayar
            final paymentSnapshot = await _firestore
                .collection('payments')
                .where('expenseId', isEqualTo: expenseDoc.id)
                .where('payerId', isEqualTo: memberId)
                .where('status', isEqualTo: 'confirmed')
                .get();

            // Jika belum bayar, masukkan ke list
            if (paymentSnapshot.docs.isEmpty) {
              // Ambil info member
              final memberDoc = await _firestore.collection('users').doc(memberId).get();
              String memberName = 'Unknown';
              String memberEmail = '';

              if (memberDoc.exists) {
                final memberData = memberDoc.data();
                memberName = memberData?['displayName'] ?? memberData?['email']?.split('@')[0] ?? 'Unknown';
                memberEmail = memberData?['email'] ?? '';
              }

              unpaidBills.add({
                'expenseId': expenseDoc.id,
                'expenseTitle': expenseData['title'] ?? 'Untitled',
                'memberId': memberId,
                'memberName': memberName,
                'memberEmail': memberEmail,
                'amount': memberAmount,
                'groupId': groupId,
                'dueDate': expenseData['dueDate'],
              });

              print("DEBUG getUnpaidMemberBills: Added unpaid bill - Member: $memberName, Amount: $memberAmount");
            }
          }
        }
      }

      print("DEBUG getUnpaidMemberBills: ===== Found ${unpaidBills.length} unpaid member bills =====");
      return unpaidBills;
    });
  }

  /// Get utang penalangan (covered debts) yang harus dibayar kembali ke admin
  /// Untuk menampilkan list utang yang ditanggung admin untuk user
  Stream<List<Map<String, dynamic>>> getCoveredDebts() {
    final user = _auth.currentUser;
    if (user == null) {
      print("DEBUG getCoveredDebts: User not logged in");
      return Stream.value([]);
    }

    print("DEBUG getCoveredDebts: Getting covered debts for user ${user.uid}");

    return _firestore
        .collection('payments')
        .where('payerId', isEqualTo: user.uid)
        .where('paymentMethod', isEqualTo: 'payer_covered')
        .where('status', isEqualTo: 'confirmed')
        .snapshots()
        .asyncMap((paymentSnapshot) async {
      List<Map<String, dynamic>> coveredDebts = [];

      for (var paymentDoc in paymentSnapshot.docs) {
        final paymentData = paymentDoc.data();
        final receiverId = paymentData['receiverId'] as String?; // Admin yang menalangi
        final amount = (paymentData['amount'] ?? 0).toDouble();
        final expenseId = paymentData['expenseId'] as String?;

        if (receiverId != null && amount > 0) {
          // Cek apakah sudah dibayar kembali
          final repaymentSnapshot = await _firestore
              .collection('payments')
              .where('payerId', isEqualTo: user.uid)
              .where('receiverId', isEqualTo: receiverId)
              .where('relatedCoveredPaymentId', isEqualTo: paymentDoc.id)
              .where('status', isEqualTo: 'confirmed')
              .get();

          // Jika belum bayar kembali, masukkan ke list
          if (repaymentSnapshot.docs.isEmpty) {
            // Ambil info admin
            final adminDoc = await _firestore.collection('users').doc(receiverId).get();
            String adminName = 'Unknown';
            String adminEmail = '';

            if (adminDoc.exists) {
              final adminData = adminDoc.data();
              adminName = adminData?['displayName'] ?? adminData?['email']?.split('@')[0] ?? 'Unknown';
              adminEmail = adminData?['email'] ?? '';
            }

            // Ambil info expense
            String expenseTitle = 'Unknown';
            if (expenseId != null) {
              final expenseDoc = await _firestore.collection('expenses').doc(expenseId).get();
              if (expenseDoc.exists) {
                expenseTitle = expenseDoc.data()?['title'] ?? 'Unknown';
              }
            }

            coveredDebts.add({
              'coveredPaymentId': paymentDoc.id,
              'adminId': receiverId,
              'adminName': adminName,
              'adminEmail': adminEmail,
              'amount': amount,
              'expenseTitle': expenseTitle,
              'expenseId': expenseId,
              'coveredAt': paymentData['confirmedAt'] ?? paymentData['createdAt'],
            });

            print("DEBUG getCoveredDebts: Added covered debt - Admin: $adminName, Amount: $amount");
          }
        }
      }

      print("DEBUG getCoveredDebts: ===== Found ${coveredDebts.length} covered debts =====");
      return coveredDebts;
    });
  }

  /// Bayar kembali utang penalangan ke admin
  /// Member membayar kembali ke admin yang sudah menalangi pembayarannya
  Future<void> repayForCoveredDebt({
    required String coveredPaymentId,
    required String adminId,
    required double amount,
    required String paymentMethod,
    File? proofImage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    try {
      print("DEBUG repayForCoveredDebt: Creating repayment...");
      print("DEBUG repayForCoveredDebt: CoveredPaymentId: $coveredPaymentId");
      print("DEBUG repayForCoveredDebt: AdminId (receiver): $adminId");
      print("DEBUG repayForCoveredDebt: Amount: $amount");
      print("DEBUG repayForCoveredDebt: PaymentMethod: $paymentMethod");

      // Create payment document first to get ID
      final docRef = await _firestore.collection('payments').add({
        'expenseId': null, // Tidak terkait expense tertentu, ini pembayaran utang pribadi
        'payerId': user.uid, // User yang bayar kembali
        'receiverId': adminId, // Admin yang menerima pembayaran
        'amount': amount,
        'paymentMethod': paymentMethod,
        'proofImageUrl': null,
        'status': 'pending', // Pending sampai admin konfirmasi
        'createdAt': FieldValue.serverTimestamp(),
        'confirmedAt': null,
        'relatedCoveredPaymentId': coveredPaymentId, // Link ke payment yang ditanggung admin
        'note': 'Pembayaran kembali utang penalangan',
      });

      print("DEBUG repayForCoveredDebt: Repayment created with ID: ${docRef.id}");

      // Upload proof image if provided
      if (proofImage != null) {
        print("DEBUG repayForCoveredDebt: Uploading proof image...");
        final imageUrl = await uploadPaymentProof(proofImage, docRef.id);
        await docRef.update({'proofImageUrl': imageUrl});
        print("DEBUG repayForCoveredDebt: Proof image uploaded: $imageUrl");
      }

      print("DEBUG repayForCoveredDebt: Repayment successfully created");
    } catch (e) {
      print("ERROR repayForCoveredDebt: $e");
      rethrow;
    }
  }

  /// Helper method untuk kirim notifikasi konfirmasi pembayaran
  Future<void> _sendPaymentConfirmedNotification(String paymentId) async {
    try {
      // Ambil data payment
      final paymentDoc = await _firestore.collection('payments').doc(paymentId).get();
      if (!paymentDoc.exists) return;

      final paymentData = paymentDoc.data()!;
      final expenseId = paymentData['expenseId'] as String?;
      final payerId = paymentData['payerId'] as String?;
      final amount = (paymentData['amount'] ?? 0).toDouble();

      if (expenseId == null || payerId == null) return;

      // Ambil data expense
      final expenseDoc = await _firestore.collection('expenses').doc(expenseId).get();
      if (!expenseDoc.exists) return;

      final expenseData = expenseDoc.data()!;
      final groupId = expenseData['groupId'] as String?;
      final expenseTitle = expenseData['title'] ?? 'Unknown Expense';

      if (groupId == null) return;

      // Kirim notifikasi menggunakan NotificationService
      final notificationService = NotificationService();
      await notificationService.sendPaymentConfirmedNotification(
        paymentId: paymentId,
        expenseId: expenseId,
        groupId: groupId,
        expenseTitle: expenseTitle,
        payerId: payerId,
        amount: amount,
      );

    } catch (e) {
      print("ERROR _sendPaymentConfirmedNotification: $e");
    }
  }
}
