import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String id;
  final String expenseId;
  final String payerId; // User yang bayar
  final String receiverId; // User yang terima bayar
  final double amount;
  final String paymentMethod; // 'cash', 'bank_transfer', 'e-wallet'
  final String? proofImageUrl; // URL bukti pembayaran
  final String status; // 'pending', 'confirmed', 'rejected'
  final DateTime createdAt;
  final DateTime? confirmedAt;

  PaymentModel({
    required this.id,
    required this.expenseId,
    required this.payerId,
    required this.receiverId,
    required this.amount,
    required this.paymentMethod,
    this.proofImageUrl,
    required this.status,
    required this.createdAt,
    this.confirmedAt,
  });

  factory PaymentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentModel(
      id: doc.id,
      expenseId: data['expenseId'] ?? '',
      payerId: data['payerId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentMethod: data['paymentMethod'] ?? 'cash',
      proofImageUrl: data['proofImageUrl'],
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'expenseId': expenseId,
      'payerId': payerId,
      'receiverId': receiverId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'proofImageUrl': proofImageUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
    };
  }
}
