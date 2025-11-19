import 'package:flutter/material.dart';
import '../components/group_filter_modal.dart'; 

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  // Dummy Data Grup
  final List<Map<String, dynamic>> _allGroups = [
    {
      'name': 'DAP A17',
      'members': 11,
      'image': 'assets/images/group_placeholder.png', // Ganti dengan asset Anda
    },
    {
      'name': 'Badminton DAP A17',
      'members': 9,
      'image': 'assets/images/group_placeholder.png',
    },
    {
      'name': 'Rumah Angkatan',
      'members': 112,
      'image': 'assets/images/group_placeholder.png',
    },
  ];

  void _showFilterModal() {
    showDialog(
      context: context,
      builder: (context) => GroupFilterModal(
        onApply: (selectedCategory) {
          // Disini logika filtering data nanti diterapkan
          print("Filter diterapkan: $selectedCategory");
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Judul Halaman
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Groups',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w600, // Agak tipis sesuai gambar
                    color: Color(0xFF44444C),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Search Bar & Filter Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // Input Pencarian
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25), // Rounded pill shape
                        border: Border.all(color: Colors.black54, width: 1),
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Cari',
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.grey,
                          ),
                          prefixIcon: Icon(Icons.search, color: Colors.black87),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 13),
                        ),
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Tombol Filter (Kotak Ungu di Gambar 1)
                  InkWell(
                    onTap: _showFilterModal,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        // Menggunakan warna ungu sesuai screenshot pertama
                        // Jika ingin konsisten hijau, ganti ke Color(0xFF0DB662)
                        color: const Color(0xFF9747FF).withOpacity(0.1), 
                        border: Border.all(color: const Color(0xFF9747FF), width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tune, // Icon slider/filter
                        color: Color(0xFF9747FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // List Groups
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _allGroups.length,
                separatorBuilder: (context, index) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final group = _allGroups[index];
                  return _buildGroupTile(group);
                },
              ),
            ),

            // Tombol Buat Grup Baru
            Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: SizedBox(
                width: 200,
                height: 45,
                child: OutlinedButton(
                  onPressed: () {
                    // Navigasi ke buat grup
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF0DB662)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Buat Grup Baru',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF44444C),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom Nav Bar di-handle oleh HomePage (Parent), 
      // tapi jika ini page mandiri, Anda bisa copy BottomNavBar dari home_page.dart
    );
  }

  Widget _buildGroupTile(Map<String, dynamic> group) {
    return Container(
      color: Colors.transparent, // Agar area tap luas
      child: Row(
        children: [
          // Group Image
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: const DecorationImage(
                // Menggunakan placeholder icon jika gambar tidak ada
                image: AssetImage('assets/images/design1.png'), 
                fit: BoxFit.cover,
              ),
              color: Colors.grey[300],
            ),
            // Fallback jika asset tidak ditemukan
            child: const Icon(Icons.group, color: Colors.white), 
          ),
          const SizedBox(width: 16),
          
          // Group Name
          Expanded(
            child: Text(
              group['name'],
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF44444C),
              ),
            ),
          ),
          
          // Member Count
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 16,
                color: Color(0xFF0DB662),
              ),
              const SizedBox(width: 4),
              Text(
                group['members'].toString(),
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF0DB662),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}