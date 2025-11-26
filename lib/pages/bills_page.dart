import 'package:flutter/material.dart';
import '../models/group_data.dart'; // Import model GroupItem
import 'payment_details_page.dart'; // Import halaman Payment Details

class BillsPage extends StatefulWidget {
  final GroupItem group; // Data grup (Nama, dll)

  const BillsPage({super.key, required this.group});

  @override
  State<BillsPage> createState() => _BillsPageState();
}

class _BillsPageState extends State<BillsPage> {
  // Dummy Data: Tagihan Saya
  final List<Map<String, dynamic>> _myBills = [
    {'title': 'Uang Listrik', 'amount': 'Rp. 20.000,00', 'isChecked': true},
    {'title': 'Uang Air', 'amount': 'Rp. 10.000,00', 'isChecked': true},
    {'title': 'Uang beli dispenser', 'amount': 'Rp. 60.000,00', 'isChecked': false},
  ];

  // Dummy Data: Tagihan Teman
  final List<Map<String, dynamic>> _friendsBills = [
    {
      'friend': 'Ikrar',
      'title': 'Uang Listrik',
      'amount': 'Rp. 20.000,00',
      'isChecked': true
    },
    {
      'friend': 'Ikrar',
      'title': 'Uang Air',
      'amount': 'Rp. 10.000,00',
      'isChecked': true
    },
  ];

  void _showAddBillModal() {
    showDialog(
      context: context,
      builder: (context) => AddBillModal(
        groupName: widget.group.name,
        onAdd: (selectedBills) {
          setState(() {
            _friendsBills.addAll(selectedBills);
          });
        },
      ),
    );
  }

  // Helper untuk mengumpulkan semua item yang dicentang
  List<Map<String, dynamic>> _getSelectedBills() {
    List<Map<String, dynamic>> selected = [];
    selected.addAll(_myBills.where((b) => b['isChecked'] == true));
    selected.addAll(_friendsBills.where((b) => b['isChecked'] == true));
    return selected;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF0DB662)),
              ),
              child: const Icon(Icons.receipt_long, color: Color(0xFF0DB662)),
            ),
            const SizedBox(width: 12),
            Text(
              widget.group.name,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0DB662),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Divider(thickness: 1, color: Colors.grey),
                const SizedBox(height: 20),

                // --- MY BILLS SECTION ---
                const Text(
                  "My Bills",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF44444C),
                  ),
                ),
                const SizedBox(height: 12),
                ..._myBills.map((bill) => _buildBillItem(bill)).toList(),

                const SizedBox(height: 30),

                // --- FRIENDS BILLS HEADER ---
                const Text(
                  "Friends Bill's",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF44444C),
                  ),
                ),
                const SizedBox(height: 12),

                if (_friendsBills.isEmpty)
                  const Text(
                    "Belum ada tagihan teman yang ditalangi.",
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey),
                  )
                else
                  ..._friendsBills.map((bill) => _buildBillItem(bill, isFriend: true)).toList(),

                const SizedBox(height: 20),

                // --- BUTTON ADD ANOTHER BILL ---
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _showAddBillModal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF087B42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text(
                      'Add another bill',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- BOTTOM PAYMENT BUTTON ---
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 160,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    // LOGIKA VALIDASI
                    final selectedBills = _getSelectedBills();

                    if (selectedBills.isEmpty) {
                      // Tampilkan Error jika tidak ada yang dicentang
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Pilih minimal satu tagihan untuk dibayar!"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else {
                      // Lanjut ke Payment Details Page membawa data
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentDetailsPage(
                            groupName: widget.group.name,
                            selectedItems: selectedBills,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF087B42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Go to payment',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillItem(Map<String, dynamic> bill, {bool isFriend = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isFriend && bill['friend'] != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              bill['friend'],
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0DB662),
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            color: isFriend ? Colors.grey[100] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    bill['isChecked'] = !bill['isChecked'];
                  });
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: bill['isChecked'] ? const Color(0xFF0DB662) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: bill['isChecked'] ? const Color(0xFF0DB662) : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: bill['isChecked']
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  bill['title'],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Color(0xFF44444C),
                  ),
                ),
              ),
              Text(
                bill['amount'],
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xFF44444C),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AddBillModal extends StatefulWidget {
  final String groupName;
  final Function(List<Map<String, dynamic>>) onAdd;

  const AddBillModal({super.key, required this.groupName, required this.onAdd});

  @override
  State<AddBillModal> createState() => _AddBillModalState();
}

class _AddBillModalState extends State<AddBillModal> {
  final List<String> _members = ['Ikrar', 'Balanza', 'Dylan', 'Evita', 'Deryl', 'Rafqy'];
  String? _expandedMember;
  final Map<String, List<Map<String, dynamic>>> _availableBills = {
    'Ikrar': [
      {'title': 'Uang Listrik', 'amount': 'Rp. 20.000,00', 'isChecked': true},
      {'title': 'Uang Air', 'amount': 'Rp. 10.000,00', 'isChecked': true},
      {'title': 'Uang beli dispenser', 'amount': 'Rp. 60.000,00', 'isChecked': false},
    ]
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        height: 500,
        child: Column(
          children: [
            Text(
              widget.groupName,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0DB662),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: _members.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final member = _members[index];
                  return _buildMemberTile(member);
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 120,
              height: 40,
              child: ElevatedButton(
                onPressed: () {
                  List<Map<String, dynamic>> toAdd = [];
                  if (_expandedMember != null && _availableBills.containsKey(_expandedMember)) {
                     final bills = _availableBills[_expandedMember]!;
                     for (var b in bills) {
                       if (b['isChecked']) {
                         toAdd.add({
                           'friend': _expandedMember,
                           'title': b['title'],
                           'amount': b['amount'],
                           'isChecked': true,
                         });
                       }
                     }
                  }
                  widget.onAdd(toAdd);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF087B42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Add', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(String name) {
    final isExpanded = _expandedMember == name;
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(name, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, color: Color(0xFF44444C))),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedMember = null;
              } else {
                _expandedMember = name;
                if (!_availableBills.containsKey(name)) {
                  _availableBills[name] = [
                    {'title': 'Uang Listrik', 'amount': 'Rp. 20.000,00', 'isChecked': false},
                    {'title': 'Uang Kebersihan', 'amount': 'Rp. 5.000,00', 'isChecked': false},
                  ];
                }
              }
            });
          },
        ),
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 0, bottom: 10),
            child: Column(
              children: _availableBills[name]!.map((bill) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 24, width: 24,
                        child: Checkbox(
                          value: bill['isChecked'],
                          activeColor: const Color(0xFF0DB662),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) {
                            setState(() {
                              bill['isChecked'] = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(bill['title'], style: const TextStyle(fontFamily: 'Poppins', fontSize: 12))),
                      Text(bill['amount'], style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}