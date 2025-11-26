import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // ✅ Pake intl biar format Rupiah otomatis

// ==============================
// MODAL 1: CHOOSE PEOPLE
// ==============================
class ChoosePeopleModal extends StatefulWidget {
  final List<String> allMembers;
  final List<String> initiallySelected;

  const ChoosePeopleModal({
    super.key,
    required this.allMembers,
    required this.initiallySelected,
  });

  @override
  State<ChoosePeopleModal> createState() => _ChoosePeopleModalState();
}

class _ChoosePeopleModalState extends State<ChoosePeopleModal> {
  late List<String> _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = List.from(widget.initiallySelected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Modal
          Center(
            child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 20),
          const Text("Pilih Orang", style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),

          // List Checkbox Anggota
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.allMembers.length,
              itemBuilder: (context, index) {
                final memberName = widget.allMembers[index];
                final isSelected = _tempSelected.contains(memberName);
                return ListTile(
                  title: Text(memberName, style: const TextStyle(fontFamily: 'Poppins')),
                  trailing: Transform.scale(
                    scale: 1.2,
                    child: Checkbox(
                      value: isSelected,
                      activeColor: const Color(0xFF0DB662),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _tempSelected.add(memberName);
                          } else {
                            _tempSelected.remove(memberName);
                          }
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          
          // Tombol Simpan Pilihan
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, _tempSelected); // Kembalikan list yang dipilih
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0DB662),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text("Simpan Pilihan", style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}


// ==============================
// MODAL 2: SPLIT OPTIONS & PAYMENT (Updated with Intl)
// ==============================
class SplitOptionsModal extends StatefulWidget {
  final double totalAmount;
  final List<String> selectedPeople;

  const SplitOptionsModal({
    super.key,
    required this.totalAmount,
    required this.selectedPeople,
  });

  @override
  State<SplitOptionsModal> createState() => _SplitOptionsModalState();
}

class _SplitOptionsModalState extends State<SplitOptionsModal> {
  int _selectedModeIdx = 0; // 0 = Equal (=), 1 = Percent (%), 2 = Amount (Rp)
  
  // Controllers untuk input manual (% dan Amount)
  final Map<String, TextEditingController> _inputControllers = {};
  
  // State untuk Payment Method
  String _selectedPaymentMethod = 'Cash'; // Default
  final TextEditingController _bankNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller untuk setiap orang
    for (var person in widget.selectedPeople) {
      _inputControllers[person] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var controller in _inputControllers.values) {
      controller.dispose();
    }
    _bankNameController.dispose();
    super.dispose();
  }

  // ✅ Helper format currency MENGGUNAKAN INTL
  String _formatCurrency(double amount) {
    // Otomatis format: Rp 20.000 (tanpa desimal biar rapi)
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(amount);
  }

  // Helper hitung sisa (untuk mode Amount)
  double _calculateRemainingAmount() {
    double currentTotalInput = 0;
    for (var controller in _inputControllers.values) {
      // Hapus karakter non-digit sebelum parsing
      String cleanText = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
      currentTotalInput += double.tryParse(cleanText) ?? 0;
    }
    return widget.totalAmount - currentTotalInput;
  }


  @override
  Widget build(BuildContext context) {
    final double headerHeight = 180;
    final double paymentSectionHeight = _selectedPaymentMethod == 'Transfer' ? 160 : _selectedPaymentMethod == 'QRIS' ? 180 : 100;
    final double availableHeightForList = MediaQuery.of(context).size.height * 0.8 - headerHeight - paymentSectionHeight - 50; 

    return Container(
      height: MediaQuery.of(context).size.height * 0.85, 
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // --- HEADER (Batal, Title, Selesai) ---
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal", style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF0DB662))),
                ),
                const Text("Split Options", style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () {
                    // Validasi sisa harus 0 jika mode Amount
                    if (_selectedModeIdx == 2 && _calculateRemainingAmount() != 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Jumlah pembagian belum sesuai total!")));
                      return;
                    }
                    Navigator.pop(context);
                  },
                  child: const Text("Selesai", style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF0DB662))),
                ),
              ],
            ),
          ),

          // --- TOGGLE BUTTONS (=, %, Rp) ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildToggleBtn(0, "=", Icons.drag_handle),
                _buildToggleBtn(1, "%", Icons.percent),
                _buildToggleBtn(2, "Rp", Icons.monetization_on_outlined), 
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- LIST MEMBER & INPUT ---
          SizedBox(
            height: availableHeightForList > 100 ? availableHeightForList : 200, 
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: widget.selectedPeople.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final person = widget.selectedPeople[index];
                return _buildSplitItem(person);
              },
            ),
          ),

          // --- PAYMENT METHOD SECTION ---
          const Divider(thickness: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text("Payment method:", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                   const SizedBox(height: 12),
                   // Dropdown Payment Method
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12),
                     decoration: BoxDecoration(
                       border: Border.all(color: Colors.grey.shade300),
                       borderRadius: BorderRadius.circular(12)
                     ),
                     child: DropdownButtonHideUnderline(
                       child: DropdownButton<String>(
                         value: _selectedPaymentMethod,
                         isExpanded: true,
                         items: ['Cash', 'Transfer', 'QRIS'].map((String value) {
                           return DropdownMenuItem<String>(
                             value: value,
                             child: Text(value, style: const TextStyle(fontFamily: 'Poppins')),
                           );
                         }).toList(),
                         onChanged: (newValue) {
                           setState(() {
                             _selectedPaymentMethod = newValue!;
                           });
                         },
                       ),
                     ),
                   ),
                   const SizedBox(height: 16),
            
                   // Conditional Input based on Payment Method
                   if (_selectedPaymentMethod == 'Transfer')
                     TextField(
                       controller: _bankNameController,
                       decoration: const InputDecoration(
                         labelText: 'Nama Bank / E-Wallet (e.g., BCA, GoPay)',
                         labelStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12),
                         border: OutlineInputBorder(),
                         contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12)
                       ),
                     ),
            
                   if (_selectedPaymentMethod == 'QRIS')
                     InkWell(
                       onTap: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur Upload QRIS")));
                       },
                       child: Container(
                         height: 100,
                         width: double.infinity,
                         decoration: BoxDecoration(
                           color: Colors.grey[200],
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid)
                         ),
                         child: Column(
                           mainAxisAlignment: MainAxisAlignment.center,
                           children: const [
                             Icon(Icons.add_photo_alternate_outlined, color: Colors.grey),
                             SizedBox(height: 8),
                             Text("Upload Foto QRIS", style: TextStyle(fontFamily: 'Poppins', color: Colors.grey))
                           ],
                         ),
                       ),
                     ),
                ],
              ),
            ),
          ),

          // --- BOTTOM SUMMARY BAR (Khusus mode Amount/Rp) ---
          if (_selectedModeIdx == 2)
          Container(
            padding: const EdgeInsets.all(16),
            color: _calculateRemainingAmount() == 0 ? const Color(0xFFE8F5E9) : Colors.red.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total: ${_formatCurrency(widget.totalAmount)}",
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                ),
                Text(
                  // Menampilkan sisa yang belum dibagi dengan format Intl
                  "Left: ${_formatCurrency(_calculateRemainingAmount())}",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: _calculateRemainingAmount() == 0 ? const Color(0xFF0DB662) : Colors.red,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildToggleBtn(int index, String text, IconData icon) {
    final isSelected = _selectedModeIdx == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedModeIdx = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
          ),
          child: Icon(icon, color: isSelected ? const Color(0xFF0DB662) : Colors.grey),
        ),
      ),
    );
  }

  Widget _buildSplitItem(String personName) {
    Widget trailingWidget;

    if (_selectedModeIdx == 0) {
      // MODE EQUAL (=): Hitung otomatis & Format Intl
      double splitAmount = widget.totalAmount / widget.selectedPeople.length;
      trailingWidget = Text(
        _formatCurrency(splitAmount), // <-- Pake Intl
        style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Color(0xFF44444C)),
      );
    } else if (_selectedModeIdx == 1) {
      // MODE PERCENT (%): Input manual persen
      trailingWidget = SizedBox(
        width: 80,
        child: TextField(
          controller: _inputControllers[personName],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.end,
          decoration: const InputDecoration(
            hintText: "0",
            suffixText: "%",
            border: UnderlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 8)
          ),
        ),
      );
    } else {
      // MODE AMOUNT (Rp): Input manual rupiah (Raw Number)
      trailingWidget = SizedBox(
        width: 120,
        child: TextField(
          controller: _inputControllers[personName],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.end,
          onChanged: (val) => setState(() {}), // Rebuild untuk update sisa di bawah
          decoration: const InputDecoration(
            hintText: "0",
            prefixText: "Rp ",
            border: UnderlineInputBorder(),
             contentPadding: EdgeInsets.symmetric(vertical: 8)
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, color: Colors.grey[600]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              personName,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          trailingWidget,
        ],
      ),
    );
  }
}