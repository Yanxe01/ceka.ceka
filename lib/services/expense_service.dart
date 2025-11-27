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

    await _firestore.collection('expenses').add({
      'title': title,
      'amount': amount,
      'date': Timestamp.now(), // Default hari ini
      'groupId': groupId,
      'payerId': user.uid,
      'splitDetails': splitDetails,
      'splitType': splitType,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}