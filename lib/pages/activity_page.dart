import 'package:flutter/material.dart';
import 'bills_page.dart'; // Import halaman Bills
import '../models/group_data.dart'; // Import model untuk passing data

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  // 0 = Bills, 1 = History
  int _selectedTab = 0; 

  // Dummy Data untuk Bills (Tagihan Belum Lunas/Menunggu)
  final List<Map<String, dynamic>> _billsData = [
    {
      'title': 'Badminton DAP',
      'desc': 'Uang Lapangan + uang air',
      'status': 'Waiting for confirmation',
      'amount': 'Rp. 20.000.00',
      'isWarning': true, 
    },
    {
      'title': 'DAP A17',
      'desc': 'Uang Listrik',
      'status': 'Waiting for confirmation',
      'amount': 'Rp. 20.000.00',
      'isWarning': true,
    },
    {
      'title': 'DAP A17',
      'desc': 'Uang Air',
      'status': 'Unpaid',
      'amount': 'Rp. 10.000.00',
      'isWarning': false, 
      'isDanger': true,
    },
  ];

  // Dummy Data untuk History (Sudah Lunas)
  final List<Map<String, dynamic>> _historyData = [
    {
      'title': 'Badminton DAP',
      'desc': 'Uang Lapangan + uang air',
      'status': 'Paid',
      'amount': 'Rp. 20.000.00',
      'date': '04-10-2025',
    },
    {
      'title': 'DAP A17',
      'desc': 'Uang Listrik',
      'status': 'Paid',
      'amount': 'Rp. 20.000.00',
      'date': '04-10-2025',
    },
    {
      'title': 'DAP A17',
      'desc': 'Uang Air',
      'status': 'Paid by Irgi',
      'amount': 'Rp. 10.000.00',
      'date': '04-10-2025',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // HEADER SECTION
          _buildHeader(),

          // LIST CONTENT SECTION
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _selectedTab == 0 ? _billsData.length : _historyData.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final data = _selectedTab == 0 ? _billsData[index] : _historyData[index];
                return _buildActivityCard(data);
              },
            ),
          ),
        ],
      ),
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
                  // LAYER 1: Sliding Indicator
                  AnimatedAlign(
                    alignment: _selectedTab == 0
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    duration: const Duration(milliseconds: 300), 
                    curve: Curves.easeOutCubic, 
                    child: FractionallySizedBox(
                      widthFactor: 0.5, 
                      heightFactor: 1.0, 
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF065F33), // Hijau Gelap (Selected)
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(10), 
                        ),
                      ),
                    ),
                  ),

                  // LAYER 2: Teks Tombol
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

  Widget _buildSlidingTabItem(String title, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          color: Colors.transparent, 
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
            ),
            child: Text(title),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> data) {
    Color statusColor;
    
    if (data['status'].toString().contains('Paid')) {
      statusColor = const Color(0xFF0DB662); 
    } else if (data['isWarning'] == true) {
      statusColor = const Color(0xFFFFA000); 
    } else {
      statusColor = const Color(0xFFFF5656); 
    }

    // UPDATE: Bungkus dengan GestureDetector untuk navigasi ke BillsPage
    return GestureDetector(
      onTap: () {
        // Membuat objek grup sementara berdasarkan judul tagihan
        // Agar BillsPage tahu menampilkan header grup apa
        final dummyGroup = GroupItem(
          name: data['title'], 
          category: 'Lainnya',
          members:['Saya', 'Teman A', 'Teman B'] // Angka dummy
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BillsPage(group: dummyGroup),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFDCF0E9).withOpacity(0.3), 
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
                    data['title'],
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF44444C),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Description: ${data['desc']}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                      children: [
                        const TextSpan(text: 'Status: '),
                        TextSpan(
                          text: data['status'],
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
                    'Total : ${data['amount']}',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF44444C),
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
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: Color(0xFF44444C),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}