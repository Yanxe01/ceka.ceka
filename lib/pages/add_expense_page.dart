import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/services.dart';
import '../services/expense_service.dart';

class AddExpensePage extends StatefulWidget {
  final GroupModel group;

  const AddExpensePage({super.key, required this.group});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  
  // State untuk Logic
  List<UserModel> _groupMembers = [];
  List<String> _selectedMemberIds = []; // Siapa saja yang kena tagihan
  Map<String, double> _finalSplitAmounts = {}; // Hasil hitungan akhir
  String _splitType = 'equal'; // equal, percent, exact
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMemberDetails();
  }

  // Ambil detail member (Nama & Avatar) berdasarkan ID member di grup
  Future<void> _fetchMemberDetails() async {
    List<UserModel> members = [];
    UserService userService = UserService();
    
    // Default: Semua member terpilih
    List<String> tempSelected = [];

    for (String uid in widget.group.members) {
      UserModel? user = await userService.getUserData(uid);
      if (user != null) {
        members.add(user);
        tempSelected.add(user.uid);
      }
    }

    if (mounted) {
      setState(() {
        _groupMembers = members;
        _selectedMemberIds = tempSelected;
      });
    }
  }

  // Fungsi Simpan ke Backend
  void _saveExpense() async {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon isi deskripsi dan nominal")));
      }
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon pilih minimal 1 orang")));
      }
      return;
    }

    setState(() => _isLoading = true);
    double totalAmount = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;

    // Hitung ulang split jika tipe 'equal' sebelum save (untuk memastikan data update)
    if (_splitType == 'equal') {
      double splitVal = totalAmount / _selectedMemberIds.length;
      _finalSplitAmounts.clear();
      for (var uid in _selectedMemberIds) {
        _finalSplitAmounts[uid] = splitVal;
      }
    }

    try {
      await ExpenseService().addExpense(
        title: _titleController.text,
        amount: totalAmount,
        groupId: widget.group.id,
        splitDetails: _finalSplitAmounts,
        splitType: _splitType,
      );
      if (mounted) {
        Navigator.pop(context); // Kembali ke halaman sebelumnya
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Expense berhasil ditambahkan!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), // Background abu-abu soft
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF0DB662)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "Add Expense",
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveExpense,
            child: const Text(
              "Save",
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Color(0xFF0DB662)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // --- INPUT FIELDS ---
            _buildInputFields(),

            const SizedBox(height: 24),

            // --- CHOOSE PEOPLE & SPLIT ---
            Row(
              children: [
                const Text("Choose People: ", style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _showChoosePeopleModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0DB662).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0DB662)),
                    ),
                    child: const Icon(Icons.people_outline, color: Color(0xFF0DB662), size: 20),
                  ),
                ),
                const Spacer(),
                const Text("and split", style: TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _showSplitOptionsModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0DB662).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0DB662)),
                    ),
                    child: const Icon(Icons.arrow_forward_ios, color: Color(0xFF0DB662), size: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // --- BOTTOM BAR INFO ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0DB662).withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFF0DB662)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF0DB662), size: 18),
                      const SizedBox(width: 8),
                      const Text("Today", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.group, color: Color(0xFF0DB662), size: 18),
                      const SizedBox(width: 8),
                      Text(widget.group.name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const Icon(Icons.receipt_long, color: Color(0xFF0DB662), size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return Column(
      children: [
        // Description
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0DB662).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0DB662)),
                ),
                child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF0DB662)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: "Enter a description",
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Amount
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade400)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0DB662).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0DB662)),
                ),
                child: const Text("Rp", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0DB662))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: "0",
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- MODAL: CHOOSE PEOPLE ---
  void _showChoosePeopleModal() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Choose People", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 20),
                    Column(
                      children: _groupMembers.map((member) {
                        final isSelected = _selectedMemberIds.contains(member.uid);
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(backgroundColor: Colors.grey[200], child: Text(member.displayName?[0] ?? "U")),
                          title: Text(member.displayName ?? "Unknown", style: const TextStyle(fontFamily: 'Poppins')),
                          trailing: Checkbox(
                            activeColor: const Color(0xFF0DB662),
                            shape: const CircleBorder(),
                            value: isSelected,
                            onChanged: (val) {
                              setModalState(() {
                                if (val == true) {
                                  _selectedMemberIds.add(member.uid);
                                } else {
                                  _selectedMemberIds.remove(member.uid);
                                }
                              });
                              // Update parent state juga agar jumlah orang terupdate
                              setState(() {}); 
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0DB662)),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Done", style: TextStyle(color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- MODAL: SPLIT OPTIONS ---
  void _showSplitOptionsModal() {
    double total = double.tryParse(_amountController.text) ?? 0;
    
    // Inisialisasi controller map untuk input manual
    Map<String, TextEditingController> manualControllers = {};
    for (var member in _groupMembers) {
      if (_selectedMemberIds.contains(member.uid)) {
        manualControllers[member.uid] = TextEditingController();
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return DefaultTabController(
          length: 3, // Sama (=), Persen (%), Nominal (Rp)
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 500, // Fixed height agar muat tab view
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.red))),
                      const Text("Split Options", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                      TextButton(
                        onPressed: () {
                          // Logic Save Split (Disini kita update state _finalSplitAmounts)
                          // Validasi total harus match bisa ditambahkan disini
                          Navigator.pop(context);
                        },
                        child: const Text("Selesai", style: TextStyle(color: Color(0xFF0DB662))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Tab Bar
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TabBar(
                      indicator: BoxDecoration(
                        color: const Color(0xFF0DB662).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF0DB662)),
                      ),
                      labelColor: const Color(0xFF0DB662),
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(text: "="),
                        Tab(text: "%"),
                        Tab(text: "Rp"), // Tab baru Nominal
                      ],
                      onTap: (index) {
                        setState(() {
                          if (index == 0) _splitType = 'equal';
                          if (index == 1) _splitType = 'percent';
                          if (index == 2) _splitType = 'exact';
                        });
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 20),

                  // Tab View Content
                  Expanded(
                    child: TabBarView(
                      children: [
                        // 1. EQUAL SPLIT
                        _buildSplitList(
                          isInput: false,
                          getValue: (uid) => "Rp ${(total / _selectedMemberIds.length).toStringAsFixed(0)}",
                        ),

                        // 2. PERCENT SPLIT (Sederhana: Input manual persen)
                        _buildSplitList(
                          isInput: true,
                          hint: "0",
                          suffix: "%",
                          onChanged: (uid, val) {
                             double percent = double.tryParse(val) ?? 0;
                             _finalSplitAmounts[uid] = (total * percent) / 100;
                          },
                        ),

                        // 3. NOMINAL SPLIT (Exact Amount)
                        _buildSplitList(
                          isInput: true,
                          hint: "0",
                          suffix: "Rp",
                          onChanged: (uid, val) {
                            _finalSplitAmounts[uid] = double.tryParse(val) ?? 0;
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Info sisa
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF0DB662).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      "Total Amount: Rp ${total.toStringAsFixed(0)}",
                      style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Color(0xFF0DB662)),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSplitList({
    required bool isInput,
    String? Function(String uid)? getValue,
    Function(String uid, String val)? onChanged,
    String hint = "",
    String suffix = "",
  }) {
    // Filter hanya member yang dipilih di "Choose People"
    final activeMembers = _groupMembers.where((m) => _selectedMemberIds.contains(m.uid)).toList();

    return ListView.separated(
      itemCount: activeMembers.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final member = activeMembers[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: Colors.grey[200], child: Text(member.displayName?[0] ?? "U")),
              const SizedBox(width: 12),
              Expanded(child: Text(member.displayName ?? "Unknown", style: const TextStyle(fontFamily: 'Poppins'))),
              
              if (isInput)
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.end,
                    decoration: InputDecoration(
                      hintText: hint,
                      suffixText: suffix,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (val) => onChanged!(member.uid, val),
                  ),
                )
              else
                Text(
                  getValue!(member.uid)!,
                  style: const TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                ),
            ],
          ),
        );
      },
    );
  }
}