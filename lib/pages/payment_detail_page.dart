import 'package:flutter/material.dart';
import 'payment_draft_page.dart'; 

class PaymentDetailPage extends StatefulWidget {
  final List<BillItem> itemsToPay;
  final String billTitle;

  const PaymentDetailPage({super.key, required this.itemsToPay, required this.billTitle});

  @override
  State<PaymentDetailPage> createState() => _PaymentDetailPageState();
}

class _PaymentDetailPageState extends State<PaymentDetailPage> {
  String? _selectedMethod;
  
  // Menghitung Total Harga
  double get _totalAmount {
    double total = 0;
    for (var item in widget.itemsToPay) {
      total += item.price;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), 
      appBar: AppBar(
        title: const Text("Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF087B42)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.black), onPressed: (){}),
          IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.black), onPressed: (){}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          children: [
            // --- HEADER TOTAL ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    border: Border.all(color: const Color(0xFF087B42)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF087B42), size: 32),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.billTitle, style: const TextStyle(color: Color(0xFF087B42), fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
                    Text("Rp ${_totalAmount.toStringAsFixed(0)}", 
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Poppins')),
                  ],
                )
              ],
            ),
            
            const SizedBox(height: 24),
            
            // --- LIST STRUK ---
            Container(
              padding: const EdgeInsets.only(left: 12),
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey, width: 1)),
              ),
              child: Column(
                children: widget.itemsToPay.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(width: 12, height: 1, color: Colors.grey),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: TextStyle(color: Colors.grey[800], fontSize: 14, fontFamily: 'Poppins')),
                                if(item.owner != "Me")
                                  Text("(Titipan ${item.owner})", style: const TextStyle(color: Colors.orange, fontSize: 10, fontFamily: 'Poppins')),
                              ],
                            ),
                          ],
                        ),
                        Text("Rp. ${item.price.toStringAsFixed(0)}", style: TextStyle(color: Colors.grey[700], fontSize: 14, fontFamily: 'Poppins')),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(height: 40),

            // --- DROPDOWN METODE BAYAR ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Metode Pembayaran", style: TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8E6C9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedMethod,
                      hint: const Text("Select", style: TextStyle(fontSize: 14, fontFamily: 'Poppins')),
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                      style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
                      items: <String>['Cash', 'Transfer', 'Qris'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedMethod = newValue;
                        });

                        // POPUP DIALOG TRANSFER
                        if (newValue == 'Transfer') {
                          showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.account_balance_rounded, size: 50, color: Color(0xFF087B42)),
                                    const SizedBox(height: 16),
                                    const Text("Info Transfer", style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Column(
                                        children: [
                                          Text("Bank Mandiri", style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
                                          SizedBox(height: 4),
                                          Text("174-00-0000000-0", style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                          SizedBox(height: 4),
                                          Text("a.n Bu Haji Hebat", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF087B42),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Oke, Saya Mengerti", style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- LOGIKA HILANGKAN UPLOAD BUKTI JIKA CASH ---
            // Simbol '...' di Flutter artinya kita menyisipkan list widget secara kondisional
            if (_selectedMethod != 'Cash') ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Upload Bukti", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {},
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 40, color: Color(0xFF087B42)),
                      SizedBox(height: 8),
                      Text("Tap to upload", style: TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'Poppins'))
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ] else ...[
              // Jika Cash, kita kasih jarak sedikit saja biar tombol send gak nempel dropdown
              const SizedBox(height: 40),
            ],

            // --- BUTTON SEND PAYMENT ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF087B42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                  shadowColor: const Color(0xFF087B42).withOpacity(0.4)
                ),
                onPressed: () {
                   // Logic tambahan: Cek metode bayar sudah dipilih apa belum
                   if (_selectedMethod == null) {
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih Metode Pembayaran dulu!")));
                     return;
                   }

                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pembayaran Terkirim!")));
                   Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Send Payment", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Poppins', fontSize: 16)),
                    SizedBox(width: 10),
                    Icon(Icons.send_rounded, color: Colors.white, size: 20)
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}