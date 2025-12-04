import 'package:flutter/material.dart';

class GroupFilterModal extends StatefulWidget {
  final Function(String?) onApply;
  final String? initialCategory; // Kategori yang sudah terpilih sebelumnya

  const GroupFilterModal({
    super.key,
    required this.onApply,
    this.initialCategory,
  });

  @override
  State<GroupFilterModal> createState() => _GroupFilterModalState();
}

class _GroupFilterModalState extends State<GroupFilterModal> {
  // Menyimpan filter yang sedang dipilih
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    // Set initial value dari kategori yang sudah dipilih
    _selectedFilter = widget.initialCategory;
  }

  final List<Map<String, dynamic>> _filterOptions = [
    {'label': 'Kontrakan', 'icon': Icons.home_outlined},
    {'label': 'Olahraga', 'icon': Icons.sports_tennis_outlined},
    {'label': 'Liburan', 'icon': Icons.store_outlined}, // Ikon mirip bangunan/toko
    {'label': 'Lainnya', 'icon': Icons.list_alt_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cari Berdasarkan',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF44444C),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Jenis Grup',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 10),
            
            // Grid Pilihan Filter
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _filterOptions.map((option) {
                return _buildFilterOption(option['label'], option['icon']);
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // Tombol Aksi
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_selectedFilter);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0DB662),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Terapkan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: OutlinedButton(
                    onPressed: () {
                      // Reset filter dan terapkan
                      widget.onApply(null);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Reset Filter',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Color(0xFFFF5656),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    
    return InkWell(
      onTap: () {
        setState(() {
          // Toggle selection
          if (_selectedFilter == label) {
            _selectedFilter = null;
          } else {
            _selectedFilter = label;
          }
        });
      },
      child: Container(
        width: 140, // Ukuran lebar fix agar rapi 2 kolom
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0DB662).withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF0DB662) : const Color(0xFFE0E0E0),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF0DB662) : const Color(0xFF0DB662),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF44444C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}