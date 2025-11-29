import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // [PENTING] Untuk fitur Copy Clipboard
import '../models/group_model.dart'; 

class GroupSettingsPage extends StatefulWidget {
  final GroupModel group; 

  const GroupSettingsPage({super.key, required this.group});

  @override
  State<GroupSettingsPage> createState() => _GroupSettingsPageState();
}

class _GroupSettingsPageState extends State<GroupSettingsPage> {
  // --- STATE VARIABLE ---
  String _groupName = "";
  String _description = ""; 
  double _totalExpense = 0; 
  late List<dynamic> _members;
  bool isCurrentUserAdmin = true; // Simulasi Admin

  @override
  void initState() {
    super.initState();
    _groupName = widget.group.name;
    _members = List.from(widget.group.members); 
  }

  // --- 1. FUNGSI EDIT INFO GRUP ---
  void _showEditDialog() {
    TextEditingController nameController = TextEditingController(text: _groupName);
    TextEditingController descController = TextEditingController(text: _description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Info Grup", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nama Grup")),
            const SizedBox(height: 10),
            TextField(controller: descController, decoration: const InputDecoration(labelText: "Info / Deskripsi"), maxLines: 2),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF087B42)),
            onPressed: () {
              setState(() {
                _groupName = nameController.text;
                _description = descController.text;
                if (_totalExpense == 0) _totalExpense = 1250000; 
              });
              Navigator.pop(context);
            }, 
            child: const Text("Simpan", style: TextStyle(color: Colors.white))
          ),
        ],
      ),
    );
  }

  // --- 2. FUNGSI MUNCULKAN POP-UP INVITE LINK (BARU) ---
  void _showInviteDialog() {
    // Link dummy contoh berdasarkan nama grup
    String inviteLink = "https://cekaceka.id/invite/${widget.group.name.replaceAll(' ', '')}";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Sudut bulat
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Link yang dapat dibagikan",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              
              // Container Lonjong (Pill Shape)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 5, 5, 5), // Padding kiri agak besar buat teks
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    // Teks Link
                    Expanded(
                      child: Text(
                        inviteLink,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.black87,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Tombol Salin Link (Hijau)
                    ElevatedButton.icon(
                      onPressed: () {
                        // Logic Copy Clipboard
                        Clipboard.setData(ClipboardData(text: inviteLink));
                        Navigator.pop(context); // Tutup dialog
                        
                        // Tampilkan Notifikasi Kecil
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Link berhasil disalin ke clipboard!"),
                            backgroundColor: Color(0xFF087B42),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF087B42),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.white),
                      label: const Text(
                        "Salin link",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600
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

  // --- 3. FUNGSI LAINNYA ---
  void _removeMember(int index) { /* ... Logic sama seperti sebelumnya ... */ 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Anggota?"),
        content: Text("Yakin ingin menghapus ${_members[index]} dari grup?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () { setState(() { _members.removeAt(index); }); Navigator.pop(context); }, child: const Text("Hapus", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _confirmLeaveGroup() { /* ... Logic sama seperti sebelumnya ... */ 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar Grup?"),
        content: const Text("Kamu tidak akan bisa melihat aktivitas grup ini lagi."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("Keluar", style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _confirmDeleteGroup() { /* ... Logic sama seperti sebelumnya ... */
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Grup Permanen?"),
        content: const Text("Tindakan ini tidak bisa dibatalkan."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: const Text("Hapus Grup", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF087B42)),
        title: const Text("Group settings", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER GRUP
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                      image: const DecorationImage(image: AssetImage('assets/images/design1.png'), fit: BoxFit.cover, opacity: 0.5)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(_groupName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold))),
                          if (isCurrentUserAdmin)
                            InkWell(
                              onTap: _showEditDialog,
                              child: const Padding(padding: EdgeInsets.all(4.0), child: Text("Edit", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF087B42)))),
                            )
                        ],
                      ),
                      if (_description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(_description, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey[600])),
                      ],
                      if (_totalExpense > 0) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(8)),
                          child: Text("Total Expense: Rp ${_totalExpense.toStringAsFixed(0)}", style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD32F2F))),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 10),

            const Text("Group Member", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            
            // --- INVITE LINK (SEKARANG BISA DIKLIK) ---
            InkWell(
              onTap: _showInviteDialog, // <--- Panggil fungsi popup di sini
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Transform.rotate(
                      angle: -0.7,
                      child: const Icon(Icons.link, size: 24, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Invite via link",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey) // Panah kecil di ujung
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // LIST MEMBER
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final memberName = _members[index];
                bool isMemberAdmin = index == 0; 
                return Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: const BoxDecoration(shape: BoxShape.circle, image: DecorationImage(image: AssetImage('assets/images/design1.png'), fit: BoxFit.cover)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(memberName.toString(), style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500)),
                              if (isMemberAdmin) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF087B42), width: 0.5)),
                                  child: const Text("Admin", style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF087B42), fontWeight: FontWeight.bold)),
                                ),
                              ]
                            ],
                          ),
                          Text("member@gmail.com", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey[400])),
                        ],
                      ),
                    ),
                    if (isCurrentUserAdmin && !isMemberAdmin) 
                      IconButton(icon: Icon(Icons.remove_circle_outline, color: Colors.red[300], size: 20), onPressed: () => _removeMember(index)),
                  ],
                );
              },
            ),

            const SizedBox(height: 40),
            
            // FOOTER BUTTONS
            InkWell(
              onTap: _confirmLeaveGroup,
              child: Row(children: const [Icon(Icons.exit_to_app_rounded, color: Colors.grey), SizedBox(width: 12), Text("Leave Group", style: TextStyle(fontFamily: 'Poppins', color: Colors.grey))]),
            ),
            
            if (isCurrentUserAdmin) ...[
              const SizedBox(height: 24),
              InkWell(
                onTap: _confirmDeleteGroup,
                child: Row(children: const [Icon(Icons.delete_outline_rounded, color: Colors.red), SizedBox(width: 12), Text("Delete Group", style: TextStyle(fontFamily: 'Poppins', color: Colors.red))]),
              ),
            ],
            
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
