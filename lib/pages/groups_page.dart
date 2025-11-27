import 'package:flutter/material.dart';
import '../components/group_filter_modal.dart';
import '../models/group_model.dart'; // PENTING: Pakai GroupModel
import '../services/services.dart'; // PENTING: Import Service
import 'add_group_page.dart';
import 'group_detail_page.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  // Variable untuk search (filter lokal sederhana)
  String _searchQuery = "";

  void _showFilterModal() {
    showDialog(
      context: context,
      builder: (context) => GroupFilterModal(
        onApply: (selectedCategory) {
          // Nanti bisa dikembangkan untuk filter query Firestore
          print("Filter diterapkan: $selectedCategory");
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Judul Halaman
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Groups',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
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
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.black54,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Cari',
                          hintStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.grey,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
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

            // LIST GROUPS (REALTIME DARI FIREBASE)
            Expanded(
              child: StreamBuilder<List<GroupModel>>(
                stream: GroupService().getUserGroups(),
                builder: (context, snapshot) {
                  // 1. Loading State
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // 2. Error State
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  // 3. Data Kosong
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_off_outlined, size: 60, color: Colors.grey[400]),
                          const SizedBox(height: 10),
                          Text(
                            "Belum ada grup",
                            style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  // 4. Ada Data -> Tampilkan List
                  final groups = snapshot.data!;
                  
                  // Filter sederhana berdasarkan search query
                  final filteredGroups = groups.where((g) {
                    return g.name.toLowerCase().contains(_searchQuery);
                  }).toList();

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filteredGroups.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final group = filteredGroups[index];
                      return _buildGroupTile(group);
                    },
                  );
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
                    // Cukup push biasa, karena StreamBuilder otomatis refresh kalau ada data baru
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddGroupPage()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Theme.of(context).cardTheme.color,
                    side: const BorderSide(color: Color(0xFF0DB662)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Buat Grup Baru',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
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

  // Widget Tile menerima GroupModel (bukan GroupItem lagi)
  Widget _buildGroupTile(GroupModel group) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            // Data 'group' di sini sudah bertipe GroupModel, jadi cocok dengan detail page
            builder: (context) => GroupDetailPage(group: group), 
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            // Group Image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: const DecorationImage(
                  // Sementara pakai asset default kalau image null
                  image: AssetImage('assets/images/design1.png'), 
                  fit: BoxFit.cover,
                ),
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(width: 16),
            
            // Group Name
            Expanded(
              child: Text(
                group.name,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            
            // Member Count (diambil dari panjang list members)
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Color(0xFF0DB662),
                ),
                const SizedBox(width: 4),
                Text(
                  group.members.length.toString(), // Convert length ke String
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
      ),
    );
  }
}