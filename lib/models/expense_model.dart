import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String groupId;
  final String payerId; // Siapa yang menalangi (biasanya user yang login)
  final Map<String, double> splitDetails; // Key: UserID, Value: Nominal Hutang
  final String splitType; // 'equal', 'percent', atau 'exact'

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.groupId,
    required this.payerId,
    required this.splitDetails,
    required this.splitType,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'groupId': groupId,
      'payerId': payerId,
      'splitDetails': splitDetails,
      'splitType': splitType,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}