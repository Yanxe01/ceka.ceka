import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
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
  File? _selectedImage;
  bool _isLoadingImage = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Kontrakan', 'icon': Icons.home_outlined},
    {'name': 'Olahraga', 'icon': Icons.sports_tennis_outlined},
    {'name': 'Liburan', 'icon': Icons.store_outlined},
    {'name': 'Lainnya', 'icon': Icons.list_alt_outlined},
  ];

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Gagal memilih gambar: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<String?> _uploadImage(File imageFile, String groupId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('group_pictures')
          .child('$groupId.jpg');

      final uploadTask = await storageRef.putFile(imageFile);
      final downloadURL = await uploadTask.ref.getDownloadURL();

      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  void _saveGroup() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text("Mohon isi nama grup"),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    print("DEBUG: Saving group...");
    print("DEBUG: Group name: ${_nameController.text}");
    print("DEBUG: Category: $_selectedCategory");

    setState(() => _isLoading = true);

    try {
      // Simpan grup terlebih dahulu
      final groupId = await GroupService().createGroup(
        name: _nameController.text,
        category: _selectedCategory,
      );

      print("DEBUG: Group saved with ID: $groupId");

      // Upload image jika ada
      if (_selectedImage != null) {
        print("DEBUG: Uploading group image...");
        setState(() => _isLoadingImage = true);

        final imageUrl = await _uploadImage(_selectedImage!, groupId);

        if (imageUrl != null) {
          // Update group dengan URL gambar
          await GroupService().updateGroupImage(groupId, imageUrl);
          print("DEBUG: Group image uploaded successfully");
        }

        setState(() => _isLoadingImage = false);
      }

      print("DEBUG: Group saved successfully!");

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text("Grup berhasil dibuat!"),
              ],
            ),
            backgroundColor: const Color(0xFF087B42),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print("DEBUG: Error saving group: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text("Error: $e"),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
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
                  GestureDetector(
                    onTap: _isLoadingImage ? null : _pickImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.grey.shade100,
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : _isLoadingImage
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF0DB662),
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Colors.black54,
                                  size: 32,
                                ),
                    ),
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