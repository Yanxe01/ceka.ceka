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
  bool _loadingMembers = true; // Loading state untuk fetch members

  // Format angka dengan pemisah ribuan
  String _formatCurrency(String value) {
    if (value.isEmpty) return '';
    final num = int.tryParse(value.replaceAll('.', ''));
    if (num == null) return value;
    return num.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchMemberDetails();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // Ambil detail member (Nama & Avatar) berdasarkan ID member di grup dari Firebase
  Future<void> _fetchMemberDetails() async {
    setState(() => _loadingMembers = true);
    try {
      print("DEBUG: Fetching member details from Firebase for ${widget.group.members.length} members");
      print("DEBUG: Member UIDs: ${widget.group.members}");
      List<UserModel> members = [];
      UserService userService = UserService();
      
      // Default: Semua member terpilih
      List<String> tempSelected = [];

      for (String uid in widget.group.members) {
        try {
          print("DEBUG: Fetching user data for uid: $uid");
          UserModel? user = await userService.getUserData(uid);
          
          if (user != null) {
            print("DEBUG: User data received - uid: ${user.uid}, displayName: '${user.displayName}', email: '${user.email}'");
            
            // Validasi displayName tidak kosong
            if (user.displayName == null || user.displayName!.isEmpty) {
              print("DEBUG: WARNING - User displayName is null/empty, using email instead");
              // Buat UserModel baru dengan displayName dari email
              final updatedUser = UserModel(
                uid: user.uid,
                email: user.email,
                displayName: user.email.split('@')[0], // Ambil bagian sebelum @
                phoneNumber: user.phoneNumber,
                photoURL: user.photoURL,
                createdAt: user.createdAt,
              );
              members.add(updatedUser);
              tempSelected.add(updatedUser.uid);
              print("DEBUG: Added user with fallback displayName: ${updatedUser.displayName}");
            } else {
              members.add(user);
              tempSelected.add(user.uid);
              print("DEBUG: Loaded member - ${user.displayName} ($uid)");
            }
          } else {
            print("DEBUG: User not found for uid: $uid - Firebase query returned null");
          }
        } catch (e) {
          print("DEBUG: Error fetching user $uid: $e");
          print("DEBUG: Stack trace: ${StackTrace.current}");
        }
      }

      if (mounted) {
        setState(() {
          _groupMembers = members;
          _selectedMemberIds = tempSelected;
          _loadingMembers = false;
        });
        print("DEBUG: Member details loaded - Total: ${members.length} members");
        print("DEBUG: Loaded members: ${members.map((m) => '${m.displayName}(${m.uid})').join(', ')}");
      }
    } catch (e) {
      print("DEBUG: Error in _fetchMemberDetails: $e");
      print("DEBUG: Stack trace: $e");
      if (mounted) {
        setState(() => _loadingMembers = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading members: $e")),
        );
      }
    }
  }

  // Fungsi Simpan ke Backend
  void _saveExpense() async {
    print("DEBUG: _saveExpense called");
    print("DEBUG: Title: ${_titleController.text}");
    print("DEBUG: Amount: ${_amountController.text}");
    print("DEBUG: Selected Members: $_selectedMemberIds");
    print("DEBUG: Split Type: $_splitType");

    if (_titleController.text.trim().isEmpty || _amountController.text.trim().isEmpty) {
      print("DEBUG: Input validation failed - empty fields");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon isi deskripsi dan nominal")));
      }
      return;
    }

    if (_selectedMemberIds.isEmpty) {
      print("DEBUG: No members selected");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mohon pilih minimal 1 orang")));
      }
      return;
    }

    setState(() => _isLoading = true);
    double totalAmount = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
    print("DEBUG: Total Amount Parsed: $totalAmount");

    if (totalAmount <= 0) {
      print("DEBUG: Invalid amount - must be greater than 0");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Nominal harus lebih besar dari 0")));
      }
      return;
    }

    // Hitung ulang split jika tipe 'equal' sebelum save (untuk memastikan data update)
    if (_splitType == 'equal') {
      double splitVal = totalAmount / _selectedMemberIds.length;
      _finalSplitAmounts.clear();
      for (var uid in _selectedMemberIds) {
        _finalSplitAmounts[uid] = splitVal;
      }
      print("DEBUG: Equal split calculated: $_finalSplitAmounts");
    } else {
      print("DEBUG: Using existing split amounts: $_finalSplitAmounts");
    }

    try {
      print("DEBUG: ===== SAVING EXPENSE =====");
      print("DEBUG: Calling ExpenseService.addExpense");
      print("DEBUG: Title: ${_titleController.text.trim()}");
      print("DEBUG: Amount: $totalAmount");
      print("DEBUG: GroupId: ${widget.group.id}");
      print("DEBUG: SplitType: $_splitType");
      print("DEBUG: SplitDetails MAP: $_finalSplitAmounts");
      print("DEBUG: Number of people in split: ${_finalSplitAmounts.length}");

      // Validate: Must have at least 2 people (payer + at least 1 other)
      if (_finalSplitAmounts.length < 2) {
        print("DEBUG: ERROR - Must have at least 2 people!");
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Expense harus minimal 2 orang (termasuk kamu)"),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      await ExpenseService().addExpense(
        title: _titleController.text.trim(),
        amount: totalAmount,
        groupId: widget.group.id,
        splitDetails: _finalSplitAmounts,
        splitType: _splitType,
      );
      print("DEBUG: Expense saved successfully");
      if (mounted) {
        Navigator.pop(context); // Kembali ke halaman sebelumnya
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Expense berhasil ditambahkan!")));
      }
    } catch (e) {
      print("DEBUG: Error saving expense: $e");
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
            onPressed: _isLoading ? null : () {
              print("DEBUG: Save button pressed");
              print("DEBUG: Title controller text: '${_titleController.text}'");
              print("DEBUG: Amount controller text: '${_amountController.text}'");
              print("DEBUG: Selected members: $_selectedMemberIds");
              _saveExpense();
            },
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Choose People: ", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey)),
                InkWell(
                  onTap: _loadingMembers ? null : _showChoosePeopleModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedMemberIds.length < 2
                          ? Colors.orange.withValues(alpha: 0.1)
                          : const Color(0xFF0DB662).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _selectedMemberIds.length < 2
                            ? Colors.orange
                            : const Color(0xFF0DB662)
                      ),
                    ),
                    child: _loadingMembers
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0DB662))),
                          )
                        : Text(
                            "${_selectedMemberIds.length}",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              color: _selectedMemberIds.length < 2
                                  ? Colors.orange
                                  : const Color(0xFF0DB662)
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text("and split ", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey)),
                InkWell(
                  onTap: _loadingMembers ? null : _showSplitOptionsModal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0DB662).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF0DB662)),
                    ),
                    child: const Icon(Icons.arrow_forward_ios, color: Color(0xFF0DB662), size: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Warning jika kurang dari 2 orang
            if (_selectedMemberIds.length < 2)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Pilih minimal 2 orang (termasuk kamu) untuk membagi expense",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // --- BOTTOM BAR INFO ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0DB662).withValues(alpha: 0.1),
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
                      const Text("Today", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Colors.grey)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.group, color: Color(0xFF0DB662), size: 18),
                      const SizedBox(width: 8),
                      Text(widget.group.name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500, color: Colors.grey)),
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
                  color: const Color(0xFF0DB662).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF0DB662)),
                ),
                child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF0DB662)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(fontFamily: 'Poppins', color: Colors.grey),
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
                  color: const Color(0xFF0DB662).withValues(alpha: 0.1),
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black87),
                  decoration: const InputDecoration(
                    hintText: "0",
                    border: InputBorder.none,
                    hintStyle: TextStyle(fontFamily: 'Poppins', color: Colors.grey, fontSize: 20),
                  ),
                  onChanged: (value) {
                    // Hilangkan semua titik dari input
                    String cleanValue = value.replaceAll('.', '');

                    if (cleanValue.isEmpty) {
                      return;
                    }

                    // Format dengan titik pemisah ribuan
                    final formatted = _formatCurrency(cleanValue);

                    // Update text field dengan format baru
                    _amountController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  },
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
                    if (_groupMembers.isEmpty)
                      const Center(
                        child: Text(
                          "No members loaded from Firebase",
                          style: TextStyle(fontFamily: 'Poppins', color: Colors.red, fontSize: 12),
                        ),
                      )
                    else
                      Column(
                        children: _groupMembers.map((member) {
                          final isSelected = _selectedMemberIds.contains(member.uid);
                          final displayName = (member.displayName != null && member.displayName!.isNotEmpty)
                              ? member.displayName! 
                              : member.email.split('@')[0]; // Fallback ke email prefix
                          
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[200], 
                              child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : "?")
                            ),
                            title: Text(
                              displayName,
                              style: const TextStyle(fontFamily: 'Poppins'),
                            ),
                            subtitle: Text(
                              member.email,
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey),
                            ),
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
    // Parse nominal dengan menghapus titik format currency
    double total = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
    
    print("DEBUG: _showSplitOptionsModal - Total Amount: $total");
    
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
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DefaultTabController(
              length: 3, // Sama (=), Persen (%), Nominal (Rp)
              child: Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                backgroundColor: Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  height: 550, // Sedikit lebih tinggi untuk spacing yang lebih baik
                  child: Column(
                    children: [
                      // Header dengan shadow subtle
                      Container(
                        padding: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Batal",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const Text(
                              "Split Options",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 18,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Logic Save Split
                                setState(() {}); // Update parent state
                                Navigator.pop(context);
                              },
                              child: const Text(
                                "Selesai",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF0DB662),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Tab Bar dengan desain modern
                      Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: TabBar(
                          indicator: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          labelColor: const Color(0xFF0DB662),
                          unselectedLabelColor: Colors.grey,
                          labelStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          tabs: const [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.pie_chart_outline, size: 18),
                                  SizedBox(width: 4),
                                  Text("="),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.percent, size: 18),
                                  SizedBox(width: 4),
                                  Text("%"),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.payments_outlined, size: 18),
                                  SizedBox(width: 4),
                                  Text("Rp"),
                                ],
                              ),
                            ),
                          ],
                          onTap: (index) {
                            setModalState(() {
                              if (index == 0) {
                                _splitType = 'equal';
                                // Auto-calculate equal split
                                if (_selectedMemberIds.isNotEmpty) {
                                  double splitVal = total / _selectedMemberIds.length;
                                  _finalSplitAmounts.clear();
                                  for (var uid in _selectedMemberIds) {
                                    _finalSplitAmounts[uid] = splitVal;
                                  }
                                  print("DEBUG: Switched to EQUAL - Calculated splits: $_finalSplitAmounts");
                                }
                              }
                              if (index == 1) {
                                _splitType = 'percent';
                                _finalSplitAmounts.clear(); // Clear untuk percent input
                              }
                              if (index == 2) {
                                _splitType = 'exact';
                                _finalSplitAmounts.clear(); // Clear untuk exact input
                              }
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Tab View Content
                      Expanded(
                        child: TabBarView(
                          children: [
                            // 1. EQUAL SPLIT - Pembayaran dibagi rata
                            _buildSplitList(
                              isInput: false,
                              getValue: (uid) {
                                if (_selectedMemberIds.isEmpty) return "Rp 0";
                                final amountPerPerson = total / _selectedMemberIds.length;
                                final amount = amountPerPerson.toStringAsFixed(0);
                                final formatted = _formatCurrency(amount);
                                print("DEBUG: Equal split - Total: $total, Members: ${_selectedMemberIds.length}, Per person: $amountPerPerson");
                                return "Rp $formatted";
                              },
                            ),

                            // 2. PERCENT SPLIT - Tampilkan hasil nominal berdasarkan persen
                            _buildSplitList(
                              isInput: true,
                              hint: "0",
                              suffix: "%",
                              getValue: (uid) {
                                // Tampilkan hasil nominal dari persen yang diinput
                                final amount = _finalSplitAmounts[uid] ?? 0;
                                final formatted = _formatCurrency(amount.toStringAsFixed(0));
                                return "Rp $formatted";
                              },
                              onChanged: (uid, val) {
                                double percent = double.tryParse(val) ?? 0;
                                setModalState(() {
                                  _finalSplitAmounts[uid] = (total * percent) / 100;
                                });
                                print("DEBUG: Percent split - $uid: $percent% = Rp ${_finalSplitAmounts[uid]}");
                              },
                            ),

                            // 3. NOMINAL SPLIT (Exact Amount)
                            _buildSplitList(
                              isInput: true,
                              hint: "0",
                              suffix: "Rp",
                              getValue: (uid) {
                                // Tampilkan nominal yang sudah diinput
                                final amount = _finalSplitAmounts[uid] ?? 0;
                                if (amount == 0) return "";
                                final formatted = _formatCurrency(amount.toStringAsFixed(0));
                                return formatted;
                              },
                              onChanged: (uid, val) {
                                // Parse nominal dengan menghapus titik separator
                                double nominal = double.tryParse(val.replaceAll('.', '')) ?? 0;
                                setModalState(() {
                                  _finalSplitAmounts[uid] = nominal;
                                });
                                print("DEBUG: Exact split - $uid: Rp $nominal");
                              },
                            ),
                          ],
                        ),
                      ),

                      // Info total dengan desain card modern
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF0DB662).withValues(alpha: 0.1),
                              const Color(0xFF0DB662).withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF0DB662).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.account_balance_wallet,
                                      color: Color(0xFF0DB662),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Total Amount:",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0DB662),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "Rp ${_formatCurrency(total.toStringAsFixed(0))}",
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0DB662),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            if (_splitType == 'exact')
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Total Split:",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black87,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        "Rp ${_formatCurrency(_finalSplitAmounts.values.fold(0.0, (a, b) => a + b).toStringAsFixed(0))}",
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
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

    if (activeMembers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            "Tidak ada member dipilih",
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: activeMembers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final member = activeMembers[index];
        final displayName = (member.displayName != null && member.displayName!.isNotEmpty)
            ? member.displayName!
            : member.email.split('@')[0]; // Fallback ke email prefix

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F8F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Avatar dengan gradient
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF0DB662).withValues(alpha: 0.7),
                      const Color(0xFF0DB662).withValues(alpha: 0.4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),

              if (isInput)
                SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF0DB662).withValues(alpha: 0.3)),
                        ),
                        child: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.end,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: hint,
                            suffixText: suffix,
                            suffixStyle: const TextStyle(
                              color: Color(0xFF0DB662),
                              fontWeight: FontWeight.w600,
                            ),
                            hintStyle: const TextStyle(color: Colors.grey),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            border: InputBorder.none,
                          ),
                          onChanged: (val) {
                            if (onChanged != null) {
                              onChanged(member.uid, val);
                            }
                          },
                        ),
                      ),
                      // Tampilkan hasil nominal jika ada getValue untuk tab "%" dan "Rp"
                      if (getValue != null && (suffix == "%" || suffix == "Rp"))
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            getValue(member.uid) ?? "",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0DB662).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF0DB662).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    getValue!(member.uid)!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0DB662),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}