import 'package:flutter/material.dart';
import '../models/group_model.dart'; // GANTI: Pakai GroupModel (Data Asli)
import '../components/invite_member_modal.dart';
import 'add_expense_page.dart'; // PENTING: Import halaman AddExpense

class GroupDetailPage extends StatelessWidget {
  final GroupModel group; // GANTI: Menerima GroupModel

  const GroupDetailPage({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // FAB "Add Expense"
      floatingActionButton: SizedBox(
        height: 45,
        child: FloatingActionButton.extended(
          onPressed: () {
            print("DEBUG: Add Expense button clicked!");
            print("DEBUG: Group ID: ${group.id}");
            print("DEBUG: Group Name: ${group.name}");
            print("DEBUG: Group Members: ${group.members.length}");

            try {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddExpensePage(group: group),
                ),
              );
            } catch (e) {
              print("DEBUG: Navigation Error: $e");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error navigasi: $e")),
              );
            }
          },
          backgroundColor: const Color(0xFF087B42),
          icon: const Icon(Icons.receipt_long, color: Colors.white),
          label: const Text(
            'Add expense',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // --- BAGIAN HEADER HIJAU ---
          _buildHeader(context),

          // --- BAGIAN LIST EXPENSE (Masih Dummy dulu untuk tampilan) ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                _buildWelcomeMessage(),
                const SizedBox(height: 30),
                
                // Nanti bagian ini kita ganti dengan StreamBuilder dari Firebase
                _buildMonthSection("August 2025", [
                  _buildExpenseItem("12", "Aug", "Listrik", "You paid for yourself", true),
                  _buildExpenseItem("12", "Aug", "Uang Kontrakan", "You paid for yourself", true),
                ]),
                
                // Space agar tidak ketutup FAB
                const SizedBox(height: 80), 
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 24,
        right: 24,
        bottom: 30,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF087B42),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Tombol Back & Settings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 20,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF087B42)),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 20,
                child: IconButton(
                  icon: const Icon(Icons.settings, color: Color(0xFF087B42)),
                  onPressed: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Nama Grup
          Text(
            group.name, // Mengambil nama dari GroupModel
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Tombol Add Members & Info Member
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => InviteMemberModal(groupName: group.name),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0DB662),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                ),
                icon: const Icon(Icons.person_add, size: 18, color: Colors.white),
                label: const Text(
                  'Add members',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Badge Jumlah Member
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0DB662),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.people, size: 18, color: Colors.white),
                    const SizedBox(width: 4),
                    // UPDATE: Hitung jumlah member dari List
                    Text(
                      '${group.members.length} People', 
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Widget helper di bawah tetap sama (hanya styling) ---

  Widget _buildWelcomeMessage() {
    return Builder(
      builder: (context) => Row(
        children: [
          const Text("👋", style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            "You're fully set up. Jump right in!",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSection(String month, List<Widget> items) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            month,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          ...items,
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildExpenseItem(String day, String monthShort, String title, String subtitle, bool isPaid, {bool isAlert = false}) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  monthShort,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  day,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0DB662),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.receipt_long, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isAlert
                          ? const Color(0xFFFF5656)
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}