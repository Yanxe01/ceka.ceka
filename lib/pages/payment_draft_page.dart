import 'package:flutter/material.dart';
import 'payment_detail_page.dart';

// Model simpel untuk item tagihan
class BillItem {
  String name;
  double price;
  bool isSelected;
  String owner; // 'Me' atau nama teman

  BillItem({required this.name, required this.price, this.isSelected = false, required this.owner});
}

class PaymentDraftPage extends StatefulWidget {
  final String billTitle; // Menerima Judul dari halaman sebelumnya
  const PaymentDraftPage({super.key, required this.billTitle});

  @override
  State<PaymentDraftPage> createState() => _PaymentDraftPageState();
}

class _PaymentDraftPageState extends State<PaymentDraftPage> {
  // Data Dummy Item Tagihan Sendiri
  List<BillItem> currentItems = [
    BillItem(name: "Uang Listrik", price: 20000, owner: "Me", isSelected: false),
    BillItem(name: "Uang Air", price: 10000, owner: "Me", isSelected: false),
    BillItem(name: "Uang beli dispenser", price: 60000, owner: "Me", isSelected: false),
  ];

  // Logic Modal Pilih Teman (Nalangin)
  void _showAddFriendBillDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            height: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Text(widget.billTitle, style: const TextStyle(color: Color(0xFF087B42), fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Poppins'))),
                const Divider(),
                const Text("Tagihan Ikrar", style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')), 
                
                // List Hutang Teman (Dummy)
                ListTile(
                  leading: const Icon(Icons.add_circle_outline, color: Color(0xFF087B42)),
                  title: const Text("Uang Listrik", style: TextStyle(fontFamily: 'Poppins')),
                  trailing: const Text("Rp. 20.000", style: TextStyle(fontFamily: 'Poppins')),
                  onTap: () {
                    setState(() {
                      currentItems.add(BillItem(name: "Uang Listrik", price: 20000, owner: "Ikrar", isSelected: true));
                    });
                    Navigator.pop(context);
                  },
                ),
                 ListTile(
                  leading: const Icon(Icons.add_circle_outline, color: Color(0xFF087B42)),
                  title: const Text("Uang Air", style: TextStyle(fontFamily: 'Poppins')),
                  trailing: const Text("Rp. 10.000", style: TextStyle(fontFamily: 'Poppins')),
                  onTap: () {
                    setState(() {
                      currentItems.add(BillItem(name: "Uang Air", price: 10000, owner: "Ikrar", isSelected: true));
                    });
                    Navigator.pop(context);
                  },
                ),
                
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Sesuaikan tema jika perlu
      appBar: AppBar(
        title: Text(widget.billTitle, style: const TextStyle(color: Color(0xFF087B42), fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Looping List Item
            ...currentItems.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CheckboxListTile(
                  activeColor: const Color(0xFF087B42),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(item.name, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w500)),
                  subtitle: item.owner != "Me" 
                      ? Text("Dibayarkan untuk: ${item.owner}", style: const TextStyle(fontFamily: 'Poppins', color: Colors.orange, fontSize: 12)) 
                      : null,
                  secondary: Text("Rp. ${item.price.toStringAsFixed(0)}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 12)),
                  value: item.isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      item.isSelected = value!;
                    });
                  },
                ),
              );
            }).toList(),

            const SizedBox(height: 20),

            // Tombol Add Another Bill (Nalangin)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF087B42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _showAddFriendBillDialog,
                icon: const Icon(Icons.person_add_alt_1, size: 16, color: Colors.white,),
                label: const Text("Add another bill", style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
              ),
            ),

            const SizedBox(height: 80), 
            
            // Tombol Lanjut Payment
            SizedBox(
              width: 150,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF087B42),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(vertical: 12)
                ),
                onPressed: () {
                  // Ambil item yang dicentang saja
                  final selectedItems = currentItems.where((i) => i.isSelected).toList();
                  
                  if (selectedItems.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Pilih minimal satu tagihan")));
                    return;
                  }

                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => PaymentDetailPage(
                        itemsToPay: selectedItems, 
                        billTitle: widget.billTitle
                      )
                    )
                  );
                },
                child: const Text("Payment", style: TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
              ),
            )
          ],
        ),
      ),
    );
  }
}