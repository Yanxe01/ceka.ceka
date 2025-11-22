import 'package:flutter/material.dart';
import '../models/group_data.dart'; // Pastikan import file data yang baru dibuat

class AddGroupPage extends StatefulWidget {
  const AddGroupPage({super.key});

  @override
  State<AddGroupPage> createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final _nameController = TextEditingController();
  String _selectedCategory = 'Kontrakan'; // Default

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Kontrakan', 'icon': Icons.home_outlined},
    {'name': 'Olahraga', 'icon': Icons.sports_tennis_outlined},
    {'name': 'Liburan', 'icon': Icons.store_outlined},
    {'name': 'Lainnya', 'icon': Icons.list_alt_outlined},
  ];

  void _saveGroup() {
    if (_nameController.text.isEmpty) return;

    // 1. Buat object grup baru
    final newGroup = GroupItem(
      name: _nameController.text,
      category: _selectedCategory,
      members: 1, // Default member 1 (kamu sendiri)
      image: 'assets/images/design1.png', // Placeholder
    );

    // 2. Masukkan ke Global List
    setState(() {
      globalGroupList.add(newGroup);
    });

    // 3. Kembali ke halaman sebelumnya dgn pesan sukses
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER (Batal - Title - Selesai) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Color(0xFFFF5656), // Merah
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Text(
                    'Buat Grup Baru',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF44444C),
                    ),
                  ),
                  TextButton(
                    onPressed: _saveGroup,
                    child: const Text(
                      'Selesai',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Color(0xFF0DB662), // Hijau
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // --- INPUT IMAGE & NAME ---
              Row(
                children: [
                  // Image Placeholder
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      image: const DecorationImage(
                         // Ganti placeholder sesuai assetmu
                        image: AssetImage('assets/images/design1.png'),
                        fit: BoxFit.cover,
                        opacity: 0.6
                      ),
                    ),
                    child: const Icon(Icons.camera_alt_outlined, color: Colors.black54),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text Field Nama Grup
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Nama Grup',
                          hintStyle: TextStyle(
                            fontFamily: 'Poppins',
                            color: Colors.grey,
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // --- JENIS GRUP (Grid) ---
              const Text(
                'Jenis Grup',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF44444C),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _categories.map((cat) {
                  return _buildCategoryItem(cat['name'], cat['icon']);
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String name, IconData icon) {
    final isSelected = _selectedCategory == name;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = name;
        });
      },
      child: Container(
        width: 75,
        height: 75,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0DB662) : Colors.grey.shade400,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0DB662) : const Color(0xFF0DB662),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Color(0xFF44444C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}