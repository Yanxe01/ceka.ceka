import 'package:flutter/material.dart';
import '../models/group_data.dart'; // Import model data
import '../components/invite_member_modal.dart'; // Import modal invite
import 'bills_page.dart'; // Import halaman Bills
import 'add_expense_page.dart'; // Import halaman Add Expense

class GroupDetailPage extends StatelessWidget {
  final GroupItem group; // Menerima data grup yang diklik

  const GroupDetailPage({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Floating Action Button "Add Expense"
      floatingActionButton: SizedBox(
        height: 45,
        child: FloatingActionButton.extended(
          onPressed: () {
            // Navigasi ke AddExpensePage
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddExpensePage(group: group),
              ),
            );
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

          // --- BAGIAN LIST EXPENSE (SCROLLABLE) ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              children: [
                _buildWelcomeMessage(),
                const SizedBox(height: 30),
                
                // Dummy Data List
                _buildMonthSection("August 2025", [
                  _buildExpenseItem(context, "12", "Aug", "Listrik", "You paid for yourself", true),
                  _buildExpenseItem(context, "12", "Aug", "Uang Kontrakan", "You paid for yourself", true),
                ]),
                
                _buildMonthSection("September 2025", [
                  _buildExpenseItem(context, "12", "Sept", "Listrik", "Ikrar paid for you", false),
                ]),

                _buildMonthSection("October 2025", [
                  _buildExpenseItem(context, "12", "Oct", "Listrik", "You haven't paid", false, isAlert: true),
                ]),
                
                // Space untuk FAB agar tidak menutupi list paling bawah
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
        color: Color(0xFF087B42), // Warna Background Hijau Header
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
            group.name, 
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
              // Tombol Add Members (Memicu Modal)
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => InviteMemberModal(groupName: group.name),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0DB662), // Hijau lebih terang
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
                    Text(
                      '${group.memberCount} People', // Menggunakan getter memberCount
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

  Widget _buildWelcomeMessage() {
    return Row(
      children: const [
        Text("👋", style: TextStyle(fontSize: 20)),
        SizedBox(width: 8),
        Text(
          "You're fully set up. Jump right in!",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF44444C),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthSection(String month, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          month,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        ...items,
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildExpenseItem(BuildContext context, String day, String monthShort, String title, String subtitle, bool isPaid, {bool isAlert = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BillsPage(group: group),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Container(
          color: Colors.transparent, 
          child: Row(
            children: [
              // Tanggal
              Column(
                children: [
                  Text(
                    monthShort,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF44444C),
                    ),
                  ),
                  Text(
                    day,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF44444C),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Icon Box
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

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF44444C),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: isAlert ? const Color(0xFFFF5656) : Colors.grey, 
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
}