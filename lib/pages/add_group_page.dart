import 'package:flutter/material.dart';
import '../services/services.dart';

class AddGroupPage extends StatefulWidget {
  const AddGroupPage({super.key});

  @override
  State<AddGroupPage> createState() => _AddGroupPageState();
}

class _AddGroupPageState extends State<AddGroupPage> {
  final _nameController = TextEditingController();
  String _selectedCategory = 'Kontrakan'; // Default
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Kontrakan', 'icon': Icons.home_outlined},
    {'name': 'Olahraga', 'icon': Icons.sports_tennis_outlined},
    {'name': 'Liburan', 'icon': Icons.store_outlined},
    {'name': 'Lainnya', 'icon': Icons.list_alt_outlined},
  ];

  void _saveGroup() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mohon isi nama grup")),
      );
      return;
    }

    print("DEBUG: Saving group...");
    print("DEBUG: Group name: ${_nameController.text}");
    print("DEBUG: Category: $_selectedCategory");

    setState(() => _isLoading = true);

    try {
      // Simpan ke Firebase
      await GroupService().createGroup(
        name: _nameController.text,
        category: _selectedCategory,
      );

      print("DEBUG: Group saved successfully!");

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Grup berhasil dibuat!")),
        );
      }
    } catch (e) {
      print("DEBUG: Error saving group: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                    onPressed: _isLoading ? null : _saveGroup,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0DB662)),
                            ),
                          )
                        : const Text(
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