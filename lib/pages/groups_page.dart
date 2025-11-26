import 'package:flutter/material.dart';
import '../components/group_filter_modal.dart'; 
import '../models/group_data.dart'; 
import 'add_group_page.dart'; 
import 'group_detail_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  
  void _showFilterModal() {
    showDialog(
      context: context,
      builder: (context) => GroupFilterModal(
        onApply: (selectedCategory) {
          // Logika filtering
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
                    fontWeight: FontWeight.w600,
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
                        borderRadius: BorderRadius.circular(25),
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
                  
                  // Tombol Filter
                  InkWell(
                    onTap: _showFilterModal,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9747FF).withOpacity(0.1), 
                        border: Border.all(color: const Color(0xFF9747FF), width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tune,
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
                itemCount: globalGroupList.length,
                separatorBuilder: (context, index) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final group = globalGroupList[index];
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
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddGroupPage()),
                    );

                    if (result == true) {
                      setState(() {});
                    }
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
    );
  }

  // --- WIDGET GROUP TILE YANG SUDAH DIPERBAIKI ---
  Widget _buildGroupTile(GroupItem group) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GroupDetailPage(group: group),
          ),
        );
      },
      child: Container(
        color: Colors.transparent, 
        child: Row(
          children: [
            // 1. Group Image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: AssetImage(group.image), 
                  fit: BoxFit.cover,
                ),
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(width: 16),
            
            // 2. Nama Grup (Expanded agar mendorong member count ke kanan)
            Expanded(
              child: Text(
                group.name,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF44444C),
                ),
                overflow: TextOverflow.ellipsis, // Agar teks panjang tidak error
              ),
            ),
            
            const SizedBox(width: 8),

            // 3. Jumlah Member (Di sebelah kanan)
            Row(
              mainAxisSize: MainAxisSize.min, // Agar row ini hanya selebar isinya
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Color(0xFF0DB662),
                ),
                const SizedBox(width: 4),
                Text(
                  '${group.members.length} People', // Menggunakan .length
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0DB662),
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