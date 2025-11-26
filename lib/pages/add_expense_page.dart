import 'package:flutter/material.dart';
import '../models/group_data.dart';
import '../components/split_modals.dart'; // Import komponen modal yang akan kita buat

class AddExpensePage extends StatefulWidget {
  final GroupItem group; // Butuh data grup untuk tahu anggotanya

  const AddExpensePage({super.key, required this.group});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  // State untuk menyimpan siapa saja yang dipilih
  List<String> _selectedPeople = [];

  @override
  void initState() {
    super.initState();
    // Default: SEMUA anggota grup terpilih di awal
    _selectedPeople = List.from(widget.group.members);
  }

  // Fungsi untuk memanggil Modal Choose People
  void _showChoosePeopleModal() async {
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChoosePeopleModal(
        allMembers: widget.group.members,
        initiallySelected: _selectedPeople,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedPeople = result;
      });
    }
  }

  // Fungsi untuk memanggil Modal Split Options
  void _showSplitOptionsModal() {
    // Validasi input harga dulu
    String amountText = _amountController.text.replaceAll('.', '').replaceAll(',', '.');
    double totalAmount = double.tryParse(amountText) ?? 0;

    if (totalAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan nominal pengeluaran terlebih dahulu.")),
      );
      return;
    }

    if (_selectedPeople.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih setidaknya satu orang untuk membagi tagihan.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SplitOptionsModal(
        totalAmount: totalAmount,
        selectedPeople: _selectedPeople,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Logic untuk label tombol "Choose People"
    String chooseBtnLabel = "Choose People";
    if (_selectedPeople.length == widget.group.memberCount) {
      chooseBtnLabel = "All Members";
    } else if (_selectedPeople.isNotEmpty) {
      chooseBtnLabel = "${_selectedPeople.length} Choosed";
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF0DB662)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Expense',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF44444C),
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // Logic simpan expense final
              Navigator.pop(context);
            },
            child: const Text(
              'Save',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0DB662),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- INPUT DESKRIPSI ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0DB662)),
                  ),
                  child: const Icon(Icons.receipt_long, color: Color(0xFF0DB662)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      hintText: "Enter a description",
                      hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF0DB662))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- INPUT NOMINAL (Rp) ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0DB662)),
                  ),
                  child: const Text(
                    "Rp",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0DB662),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF44444C),
                    ),
                    decoration: const InputDecoration(
                      hintText: "0",
                      hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.grey, fontSize: 24),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF0DB662))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // --- CHOOSE PEOPLE & SPLIT BUTTONS ---
            Row(
              children: [
                const Text(
                  "Choose People:",
                  style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF44444C)),
                ),
                const SizedBox(width: 12),
                // Tombol Choose People
                InkWell(
                  onTap: _showChoosePeopleModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF0DB662)),
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFFE8F5E9),
                    ),
                    child: Text(
                      chooseBtnLabel, // Label dinamis
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0DB662),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "and split",
                  style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF44444C)),
                ),
                const SizedBox(width: 12),
                // Tombol Panah Split Options
                InkWell(
                  onTap: _showSplitOptionsModal,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF0DB662)),
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFFE8F5E9),
                    ),
                    child: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF0DB662)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // --- FOOTER INFO (Date, Group, Camera, Note) ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFF0DB662).withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Kiri: Tanggal & Nama Grup
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: Color(0xFF0DB662), size: 20),
                      const SizedBox(width: 8),
                      const Text("Today", style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF44444C))),
                      const SizedBox(width: 24),
                      const Icon(Icons.group_outlined, color: Color(0xFF0DB662), size: 20),
                      const SizedBox(width: 8),
                      Text(widget.group.name, style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF44444C))),
                    ],
                  ),
                  // Kanan: Kamera & Note
                  Row(
                    children: [
                      InkWell(
                        onTap: () {}, // Logic kamera
                        child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0DB662), size: 22),
                      ),
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: () {}, // Logic note
                        child: const Icon(Icons.note_add_outlined, color: Color(0xFF0DB662), size: 22),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}