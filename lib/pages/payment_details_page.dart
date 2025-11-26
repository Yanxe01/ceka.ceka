import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Jika kamu pakai intl, jika tidak saya pakai format manual di bawah

class PaymentDetailsPage extends StatefulWidget {
  final String groupName;
  final List<Map<String, dynamic>> selectedItems;

  const PaymentDetailsPage({
    super.key,
    required this.groupName,
    required this.selectedItems,
  });

  @override
  State<PaymentDetailsPage> createState() => _PaymentDetailsPageState();
}

class _PaymentDetailsPageState extends State<PaymentDetailsPage> {
  // Fungsi menghitung total secara manual dari string "Rp. 20.000,00"
  String _calculateTotal() {
    double total = 0;
    for (var item in widget.selectedItems) {
      String amountStr = item['amount'];
      // Bersihkan string agar jadi angka (hapus Rp, titik, dan koma)
      // Format asumsi: Rp. 20.000,00 -> jadi 20000
      String clean = amountStr
          .replaceAll('Rp.', '')
          .replaceAll('Rp', '')
          .replaceAll('.', '') // Hapus pemisah ribuan
          .replaceAll(',', '.') // Ubah koma desimal jadi titik
          .trim();
      
      total += double.tryParse(clean) ?? 0;
    }

    // Format balik ke Rupiah (Manual format sederhana)
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 2);
    return currencyFormatter.format(total);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0DB662)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Details',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF44444C),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.delete_outline, color: Colors.black54),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, color: Colors.black54),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER INFO (Grup & Total) ---
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF0DB662).withOpacity(0.5)),
                          color: const Color(0xFFE8F5E9),
                        ),
                        child: const Icon(Icons.receipt_long, color: Color(0xFF0DB662), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.groupName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0DB662),
                            ),
                          ),
                          Text(
                            _calculateTotal(),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF44444C),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(thickness: 1, color: Colors.grey),
                  const SizedBox(height: 20),

                  // --- LIST TREE STRUCTURE ---
                  // Kita pakai Stack untuk menggambar garis vertikal panjang
                  Stack(
                    children: [
                      // Garis Vertikal Panjang di kiri
                      Positioned(
                        left: 20, 
                        top: 10,
                        bottom: 25, // Agar tidak lewat dari item terakhir
                        child: Container(
                          width: 1,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      // List Item
                      Column(
                        children: widget.selectedItems.map((item) {
                          // Tentukan nama yang ditampilkan (Judul + Nama Teman jika ada)
                          String displayName = item['title'];
                          if (item['friend'] != null) {
                            displayName += " ${item['friend']}";
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: Row(
                              children: [
                                // Spacer untuk indentasi garis mendatar
                                const SizedBox(width: 20), 
                                // Garis mendatar kecil
                                Container(
                                  width: 30,
                                  height: 1,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(width: 10),
                                // Nama Item
                                Expanded(
                                  child: Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: Color(0xFF696974),
                                    ),
                                  ),
                                ),
                                // Harga
                                Text(
                                  item['amount'],
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Color(0xFF696974),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // --- METODE PEMBAYARAN ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Metode Pembayaran",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Color(0xFF44444C),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCF0E9), // Hijau muda background
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: const [
                            Text(
                              "Select",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Color(0xFF44444C),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_drop_down, size: 18, color: Colors.black54)
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- CATATAN ---
                  const TextField(
                    decoration: InputDecoration(
                      hintText: "Tambahkan catatan",
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF0DB662)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // --- UPLOAD BUKTI ---
                  const Center(
                    child: Text(
                      "Upload Bukti",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF44444C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: InkWell(
                      onTap: () {
                        // Logika buka kamera/galeri
                      },
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: Color(0xFF0DB662),
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // --- TOMBOL SEND PAYMENT ---
          // Kita letakkan di luar scrollview tapi di dalam column (sticky bottom like)
          // Atau mengambang seperti FAB. Sesuai desain, ini di kanan bawah.
          Padding(
            padding: const EdgeInsets.only(right: 24, bottom: 24),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Kirim Pembayaran Action
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Payment Sent!")),
                  );
                  Navigator.pop(context); // Balik ke halaman sebelumnya atau home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF087B42),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                label: const Text(
                  "Send Payment",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ),
          
          // --- BOTTOM NAV BAR (DUMMY VISUAL) ---
          // Agar mirip desain, saya buatkan dummy nav bar statis
          Container(
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFF087B42),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(23),
                topRight: Radius.circular(23),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDummyNavItem(Icons.home_rounded, 'Home'),
                _buildDummyNavItem(Icons.group_rounded, 'Group'),
                _buildDummyNavItem(Icons.receipt_long_rounded, 'History'),
                _buildDummyNavItem(Icons.person_rounded, 'Profile'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDummyNavItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 25),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}