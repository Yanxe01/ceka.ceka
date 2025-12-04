import 'package:flutter/material.dart';
import 'payment_page.dart';
import '../services/payment_service.dart';
import 'package:intl/intl.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  // 0 = Bills, 1 = History
  int _selectedTab = 0;

  final PaymentService _paymentService = PaymentService();

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
      return DateFormat('dd-MM-yyyy').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // HEADER SECTION
          _buildHeader(),

          // LIST CONTENT SECTION
          Expanded(
            child: _selectedTab == 0
                ? _buildBillsList()
                : _buildHistoryList(),
          ),
        ],
      ),
    );
  }

  // Build Bills List (Tagihan yang belum dibayar)
  Widget _buildBillsList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _paymentService.getUserBills(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "Tidak ada tagihan!",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  "Semua pembayaran sudah lunas",
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

        final bills = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: bills.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildActivityCard(bills[index], isHistory: false);
          },
        );
      },
    );
  }

  // Build History List (Pembayaran yang sudah lunas)
  Widget _buildHistoryList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _paymentService.getUserPaymentHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "Belum ada riwayat",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  "Pembayaran yang sudah lunas akan muncul di sini",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final history = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: history.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return _buildActivityCard(history[index], isHistory: true);
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 0,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF087B42), // Hijau Header Dasar
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. JUDUL ACTIVITY
          const Padding(
            padding: EdgeInsets.only(left: 24.0, bottom: 20),
            child: Text(
              'Activity',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),

          // 2. TAB BAR DENGAN SLIDING EFFECT
          // Kita bungkus dengan ClipRRect agar animasi slide tidak keluar dari border radius bawah
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
            child: Container(
              height: 55, // Tinggi area Tab
              color: const Color(0xFF087B42), // Warna dasar (saat tidak dipilih)
              child: Stack(
                children: [
                  // LAYER 1: Sliding Indicator (Kotak Hijau Gelap yang Bergerak)
                  AnimatedAlign(
                    alignment: _selectedTab == 0
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    duration: const Duration(milliseconds: 300), // Kecepatan slide (halus)
                    curve: Curves.easeOutCubic, // Efek gerak agar terlihat natural
                    child: FractionallySizedBox(
                      widthFactor: 0.5, // Lebar kotak selalu 50% dari layar
                      heightFactor: 1.0, // Tinggi full
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF065F33), // Hijau Gelap (Selected)
                          boxShadow: [
                            // Efek "Shadow dikit bgt"
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          // Opsional: Jika ingin sudut atas sliding box agak rounded
                          borderRadius: BorderRadius.circular(10), 
                        ),
                      ),
                    ),
                  ),

                  // LAYER 2: Teks Tombol (Di atas slider)
                  Row(
                    children: [
                      _buildSlidingTabItem("Bills", 0),
                      _buildSlidingTabItem("History", 1),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper kecil untuk Teks Tab agar kodingan di atas lebih rapi
  Widget _buildSlidingTabItem(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        // Container transparan agar bisa di-klik
        child: Container(
          color: Colors.transparent, 
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              // Teks jadi putih terang jika dipilih, agak pudar jika tidak
              color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
            ),
            child: Text(title),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> data, {required bool isHistory}) {
    final status = data['status'] ?? (isHistory ? 'paid' : 'unpaid');

    Color statusColor;
    String statusText;

    if (isHistory || status == 'paid') {
      statusColor = const Color(0xFF0DB662);
      statusText = 'Paid';
    } else {
      statusColor = const Color(0xFFFF5656);
      statusText = 'Unpaid';
    }

    final amount = data['amount'] is double
        ? data['amount']
        : (data['amount'] is int ? data['amount'].toDouble() : 0.0);

    final formattedAmount = _formatCurrency(amount);

    return GestureDetector(
      onTap: () {
        // Hanya bisa klik jika di tab Bills (belum lunas)
        if (!isHistory) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentPage(bill: data),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF0DB662), width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(
                  image: AssetImage('assets/images/design1.png'),
                  fit: BoxFit.cover,
                ),
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? 'Untitled',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (data['paymentMethod'] != null && isHistory)
                    Text(
                      'Metode: ${data['paymentMethod'] == 'cash' ? 'Cash' : data['paymentMethod'] == 'bank_transfer' ? 'Bank Transfer' : 'E-Wallet'}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey,
                      ),
                    ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey,
                      ),
                      children: [
                        const TextSpan(text: 'Status: '),
                        TextSpan(
                          text: statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: Rp $formattedAmount',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (_selectedTab == 1 && data['date'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Text(
                  data['date'],
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}