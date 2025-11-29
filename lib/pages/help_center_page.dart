import 'package:flutter/material.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  // Data Dummy Pertanyaan
  final List<Map<String, String>> _faqList = [
    {
      "question": "What is Viral Pitch?",
      "answer": "Viral Pitch is an influencer marketing platform..."
    },
    {
      "question": "How to apply for a campaign?",
      "answer": "You can apply by clicking the apply button on the dashboard."
    },
    {
      "question": "How to know status of a campaign?",
      "answer": "Check the 'My Campaigns' tab to see the status."
    },
    {
      "question": "How to withdraw money?",
      "answer": "Go to wallet settings and choose withdraw method."
    },
    {
      "question": "How to contact support?",
      "answer": "You can email us at support@cekaceka.com."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Warna background belakang (Kecoklatan sesuai gambar)
      backgroundColor: const Color(0xFFBCAAA4), 
      body: Column(
        children: [
          // Header Kecil "Help Desk" di area atas
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                "Help Desk",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.black.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          // Container Putih Utama
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // --- Header Dalam (Tombol Back & Judul) ---
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Tombol Kembali
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF087B42)),
                            onPressed: () => Navigator.pop(context), // Logic KEMBALI
                          ),
                        ),
                        // Judul
                        const Text(
                          "Pusat Bantuan",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- Konten Scrollable ---
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Judul Besar
                          const Text(
                            "Kami siap membantu Anda dengan segala hal dan segala sesuatu di KosPay",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E1E1E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Deskripsi
                          Text(
                            "Di Kospay, kami berharap di awal hari ini Anda lebih baik dan lebih bahagia daripada kemarin.",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Colors.grey[500],
                              height: 1.5,
                            ),
                          ),
                          
                          const SizedBox(height: 20),

                          // Search Bar
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                )
                              ],
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: "Cari",
                                hintStyle: TextStyle(color: Colors.grey[400], fontFamily: 'Poppins'),
                                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 15),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Label "DAFTAR PERTANYAAN"
                          const Text(
                            "DAFTAR PERTANYAAN",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              letterSpacing: 0.5,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // List Pertanyaan (ExpansionTile)
                          ..._faqList.map((item) {
                            return Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
                                ),
                                child: ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: Text(
                                    item['question']!,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.add, color: Colors.grey), // Icon Plus sesuai gambar
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: Text(
                                        item['answer']!,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),

                          const SizedBox(height: 20),

                          // Tombol Save Changes (Sesuai Gambar)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                // Aksi dummy
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE57373), // Warna Merah Salmon
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Save Changes",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}