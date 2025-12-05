import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/payment_service.dart';
import 'package:intl/intl.dart';

class PaymentRequestsPage extends StatefulWidget {
  const PaymentRequestsPage({super.key});

  @override
  State<PaymentRequestsPage> createState() => _PaymentRequestsPageState();
}

class _PaymentRequestsPageState extends State<PaymentRequestsPage> {
  final PaymentService _paymentService = PaymentService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _formatCurrency(double value) {
    return value.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatDate(dynamic date) {
    try {
      if (date == null) return '';
      DateTime dateTime;
      if (date is DateTime) {
        dateTime = date;
      } else {
        dateTime = date.toDate();
      }
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  Stream<List<Map<String, dynamic>>> _getPendingPayments() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('payments')
        .where('receiverId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> requests = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final expenseId = data['expenseId'] as String?;
        final payerId = data['payerId'] as String?;

        // Get payer info
        String payerName = 'Unknown';
        if (payerId != null) {
          final userDoc = await _firestore.collection('users').doc(payerId).get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            payerName = userData?['displayName'] ?? userData?['email']?.split('@')[0] ?? 'Unknown';
          }
        }

        if (expenseId != null) {
          // Regular payment (dari expense)
          final expenseDoc = await _firestore.collection('expenses').doc(expenseId).get();
          if (expenseDoc.exists) {
            final expenseData = expenseDoc.data();

            requests.add({
              'paymentId': doc.id,
              'expenseId': expenseId,
              'title': expenseData?['title'] ?? 'Untitled',
              'amount': (data['amount'] ?? 0).toDouble(),
              'paymentMethod': data['paymentMethod'] ?? 'cash',
              'proofImageUrl': data['proofImageUrl'],
              'createdAt': data['createdAt'],
              'payerId': payerId,
              'payerName': payerName,
              'isRepayment': false,
            });
          }
        } else {
          // Repayment (pembayaran kembali utang penalangan)
          // expenseId null, ini adalah pembayaran utang pribadi
          final note = data['note'] as String?;
          final relatedCoveredPaymentId = data['relatedCoveredPaymentId'] as String?;

          requests.add({
            'paymentId': doc.id,
            'expenseId': null,
            'title': note ?? 'Pembayaran Utang Penalangan',
            'amount': (data['amount'] ?? 0).toDouble(),
            'paymentMethod': data['paymentMethod'] ?? 'cash',
            'proofImageUrl': data['proofImageUrl'],
            'createdAt': data['createdAt'],
            'payerId': payerId,
            'payerName': payerName,
            'isRepayment': true,
            'relatedCoveredPaymentId': relatedCoveredPaymentId,
          });
        }
      }

      // Sort by date descending
      requests.sort((a, b) {
        final aDate = a['createdAt'];
        final bDate = b['createdAt'];
        if (aDate == null || bDate == null) return 0;

        DateTime aDateTime = aDate is DateTime ? aDate : (aDate as Timestamp).toDate();
        DateTime bDateTime = bDate is DateTime ? bDate : (bDate as Timestamp).toDate();

        return bDateTime.compareTo(aDateTime);
      });

      return requests;
    });
  }

  Future<void> _confirmPayment(String paymentId) async {
    try {
      await _paymentService.confirmPayment(paymentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Pembayaran berhasil dikonfirmasi',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0DB662),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengkonfirmasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectPayment(String paymentId) async {
    try {
      await _paymentService.rejectPayment(paymentId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Pembayaran ditolak'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menolak: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Text(
                      'Gagal memuat gambar',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF087B42),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Requests',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getPendingPayments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payment,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada permintaan pembayaran',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'Permintaan pembayaran akan muncul di sini',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          final requests = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _buildPaymentRequestCard(request);
            },
          );
        },
      ),
    );
  }

  Widget _buildPaymentRequestCard(Map<String, dynamic> request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF0DB662).withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: request['isRepayment'] == true
                      ? Colors.orange.withOpacity(0.1)
                      : const Color(0xFF0DB662).withOpacity(0.1),
                  child: Text(
                    request['payerName'].toString()[0].toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: request['isRepayment'] == true
                          ? Colors.orange
                          : const Color(0xFF0DB662),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            request['payerName'],
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (request['isRepayment'] == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'REPAYMENT',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _formatDate(request['createdAt']),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Expense Info
            Text(
              request['title'] ?? 'Untitled',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF087B42),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Jumlah:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  'Rp ${_formatCurrency(request['amount'])}',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF087B42),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Metode:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  request['paymentMethod'] == 'cash'
                      ? 'Cash'
                      : request['paymentMethod'] == 'bank_transfer'
                          ? 'Bank Transfer'
                          : 'E-Wallet',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            // Proof Image
            if (request['proofImageUrl'] != null) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showImageDialog(request['proofImageUrl']),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      request['proofImageUrl'],
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            'Gagal memuat bukti',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap untuk melihat bukti pembayaran',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectPayment(request['paymentId']),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Tolak',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmPayment(request['paymentId']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0DB662),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Konfirmasi',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
