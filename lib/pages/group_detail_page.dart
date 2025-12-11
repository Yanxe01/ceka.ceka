import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_model.dart';
import 'group_setting_page.dart'; 
import 'add_expense_page.dart'; // [BARU] Import halaman Add Expense temanmu

class GroupDetailPage extends StatefulWidget {
  final GroupModel group; 

  const GroupDetailPage({super.key, required this.group});

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  late Stream<QuerySnapshot> _expensesStream;

  // Format angka dengan pemisah ribuan
  String _formatCurrency(String value) {
    if (value.isEmpty || value == '0') return '0';
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
    // Initialize stream untuk mengambil expenses dari Firebase
    print("DEBUG: GroupDetailPage initState - Group ID: ${widget.group.id}");
    _expensesStream = FirebaseFirestore.instance
        .collection('expenses')
        .where('groupId', isEqualTo: widget.group.id)
        .snapshots();

    // Debug: Listen ke stream
    _expensesStream.listen((snapshot) {
      print("DEBUG: Expenses snapshot received - ${snapshot.docs.length} docs");
      for (var doc in snapshot.docs) {
        print("DEBUG: Expense data: ${doc.data()}");
      }
    });
  }

  // Fungsi Pop-up Invite Code (sama seperti di group_setting_page.dart)
  void _showInviteDialog() {
    // Ambil invite code dari group
    String inviteCode = widget.group.inviteCode;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF0DB662).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_rounded,
                  size: 32,
                  color: Color(0xFF0DB662),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Kode Invite Grup",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Bagikan kode ini untuk mengundang anggota baru",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),

              // Container untuk Kode Invite
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF0DB662).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF0DB662), width: 2),
                ),
                child: Column(
                  children: [
                    // Kode Invite (Besar dan Bold)
                    Text(
                      inviteCode,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4,
                        color: Color(0xFF0DB662),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tombol Salin Kode
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Logic Copy Clipboard
                          Clipboard.setData(ClipboardData(text: inviteCode));
                          Navigator.pop(context); // Tutup dialog

                          // Tampilkan Notifikasi
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Kode berhasil disalin!',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF0DB662),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0DB662),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: const Text(
                          "Salin Kode",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // HEADER HIJAU
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 20, right: 20, bottom: 30),
            decoration: const BoxDecoration(
              color: Color(0xFF087B42),
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              image: DecorationImage(image: AssetImage('assets/images/design1.png'), opacity: 0.1, fit: BoxFit.cover)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.arrow_back, color: Color(0xFF087B42), size: 20))),
                    InkWell(
                      onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => GroupSettingsPage(group: widget.group))); },
                      child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: const Icon(Icons.settings, color: Color(0xFF087B42), size: 20)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(widget.group.name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    InkWell(
                      onTap: _showInviteDialog, 
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: const Row(children: [Icon(Icons.person_add_alt_1, color: Colors.white, size: 16), SizedBox(width: 6), Text("Add members", style: TextStyle(color: Colors.white, fontSize: 12))]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [const Icon(Icons.people, color: Colors.white, size: 16), const SizedBox(width: 6), Text("${widget.group.members.length} People", style: const TextStyle(color: Colors.white, fontSize: 12))]),
                    ),
                  ],
                )
              ],
            ),
          ),

          // ISI KONTEN - AMBIL DARI FIREBASE REALTIME
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _expensesStream,
              builder: (context, snapshot) {
                print("DEBUG: StreamBuilder state - ${snapshot.connectionState}");
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print("DEBUG: Waiting for data...");
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  print("DEBUG: Stream error: ${snapshot.error}");
                  print("DEBUG: Stack trace: ${snapshot.stackTrace}");
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                print("DEBUG: Has data: ${snapshot.hasData}, Docs: ${snapshot.data?.docs.length}");
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  print("DEBUG: No expenses found");
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle), child: const Icon(Icons.receipt_long_outlined, size: 50, color: Color(0xFF087B42))),
                        const SizedBox(height: 20),
                        Text("Belum ada pengeluaran", style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                        const SizedBox(height: 8),
                        Text("Mulai catat pengeluaran grupmu di sini!", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                // Tampilkan expenses dari Firebase
                final expenses = snapshot.data!.docs;
                print("DEBUG: Building ${expenses.length} expenses");
                
                // Sort by createdAt (newest first) di client side
                expenses.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['createdAt'] as Timestamp?;
                  final bTime = bData['createdAt'] as Timestamp?;
                  return (bTime?.toDate() ?? DateTime.now()).compareTo(aTime?.toDate() ?? DateTime.now());
                });
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [const Icon(Icons.waving_hand, color: Colors.orange), const SizedBox(width: 8), Text("You're fully set up. Jump right in!", style: TextStyle(fontFamily: 'Poppins', color: Colors.grey[700]))]),
                      const SizedBox(height: 30),
                      ...expenses.map((doc) {
                        try {
                          final data = doc.data() as Map<String, dynamic>;
                          print("DEBUG: Processing expense: ${data['title']}");
                          
                          DateTime date;
                          if (data['date'] != null && data['date'] is Timestamp) {
                            date = (data['date'] as Timestamp).toDate();
                          } else if (data['createdAt'] != null && data['createdAt'] is Timestamp) {
                            date = (data['createdAt'] as Timestamp).toDate();
                          } else {
                            date = DateTime.now();
                            print("DEBUG: No date found, using now()");
                          }
                          
                          final amount = (data['amount'] ?? 0).toDouble();
                          final formattedAmount = _formatCurrency(amount.toStringAsFixed(0));

                          return _buildExpenseItem(
                            data['title'] ?? 'Untitled',
                            'Rp $formattedAmount',
                            false,
                            date.day.toString().padLeft(2, '0'),
                            _getMonthAbbr(date.month),
                          );
                        } catch (e) {
                          print("DEBUG: Error processing expense: $e");
                          return Container();
                        }
                      }).toList(),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      
      // FLOATING ACTION BUTTON (ADD EXPENSE)
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20),
        child: ElevatedButton.icon(
          onPressed: () {
            // [LOGIC NAVIGASI KE HALAMAN ADD EXPENSE TEMANMU]
            Navigator.push(
              context,
              MaterialPageRoute(
                // Kita kirim data 'group' ke halaman AddExpensePage agar dia tahu ini expense buat grup mana
                builder: (context) => AddExpensePage(group: widget.group),
              ),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF087B42), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
          icon: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
          label: const Text("Add expense", style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildExpenseItem(String title, String subtitle, bool isPaid, String date, String month) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Column(children: [Text(month, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), Text(date, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))]),
          const SizedBox(width: 16),
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF0DB662), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.receipt, color: Colors.white, size: 20)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)), Text(subtitle, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey[500]))]),
        ],
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
