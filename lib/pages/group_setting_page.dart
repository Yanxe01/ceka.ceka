import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // [PENTING] Untuk fitur Copy Clipboard
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/services.dart';

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
  List<String> _memberUids = []; // UIDs dari group members
  Map<String, UserModel> _memberDetails = {}; // Cache member details
  bool isCurrentUserAdmin = true; // Simulasi Admin
  bool _loadingMembers = true;
  File? _selectedImage;
  bool _isLoadingImage = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _groupName = widget.group.name;
    _memberUids = List.from(widget.group.members);
    _currentImageUrl = widget.group.image;
    _fetchAllMemberDetails();
  }

  // Fetch semua member details dari Firebase
  Future<void> _fetchAllMemberDetails() async {
    try {
      print("DEBUG: Fetching member details for group settings");
      Map<String, UserModel> members = {};
      UserService userService = UserService();

      for (String uid in _memberUids) {
        try {
          UserModel? user = await userService.getUserData(uid);
          if (user != null) {
            members[uid] = user;
            print("DEBUG: Loaded member - ${user.displayName} ($uid)");
          }
        } catch (e) {
          print("DEBUG: Error fetching member $uid: $e");
        }
      }

      if (mounted) {
        setState(() {
          _memberDetails = members;
          _loadingMembers = false;
        });
      }
    } catch (e) {
      print("DEBUG: Error in _fetchAllMemberDetails: $e");
      if (mounted) {
        setState(() => _loadingMembers = false);
      }
    }
  }

  // --- IMAGE PICKER & UPLOAD ---
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });

        // Upload image immediately after selection
        await _uploadAndUpdateGroupImage();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Gagal memilih gambar: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _uploadAndUpdateGroupImage() async {
    if (_selectedImage == null) return;

    setState(() => _isLoadingImage = true);

    try {
      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('group_pictures')
          .child('${widget.group.id}.jpg');

      final uploadTask = await storageRef.putFile(_selectedImage!);
      final downloadURL = await uploadTask.ref.getDownloadURL();

      // Update Firestore
      await GroupService().updateGroupImage(widget.group.id, downloadURL);

      setState(() {
        _currentImageUrl = downloadURL;
        _selectedImage = null;
      });

      if (mounted) {
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
                    'Gambar grup berhasil diperbarui',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Gagal mengupload gambar: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingImage = false);
      }
    }
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
  void _removeMember(int index) {
    final uid = _memberUids[index];
    final memberName = _memberDetails[uid]?.displayName ?? uid;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Anggota?"),
        content: Text("Yakin ingin menghapus $memberName dari grup?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              try {
                print("DEBUG: Attempting to remove member $uid from group ${widget.group.id}");
                await GroupService().removeMember(widget.group.id, uid);
                
                if (mounted) {
                  setState(() {
                    _memberUids.removeAt(index);
                    _memberDetails.remove(uid);
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Member berhasil dihapus"),
                      backgroundColor: Color(0xFF087B42),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                print("DEBUG: Error removing member: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmLeaveGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Keluar Grup?"),
        content: const Text("Kamu tidak akan bisa melihat aktivitas grup ini lagi."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              // Close dialog first
              Navigator.pop(context);
              
              // Show loading
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Sedang keluar dari grup..."),
                    duration: Duration(seconds: 5),
                  ),
                );
              }
              
              try {
                print("DEBUG: Attempting to leave group ${widget.group.id}");
                await GroupService().leaveGroup(widget.group.id);

                if (mounted) {
                  // Close settings page
                  Navigator.pop(context);
                  // Close group detail page and go back to group list
                  Navigator.pop(context);
                }
              } catch (e) {
                print("DEBUG: Error leaving group: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: ${e.toString()}"),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: const Text("Keluar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Grup Permanen?"),
        content: const Text("Tindakan ini tidak bisa dibatalkan. Semua data expense akan terhapus."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              // Save context before async operations
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              // Close dialog first
              navigator.pop();

              try {
                print("DEBUG: Attempting to delete group ${widget.group.id}");

                await GroupService().deleteGroup(widget.group.id);

                print("DEBUG: Group deleted successfully, navigating back...");

                if (!mounted) return;

                // Navigate back - pop twice to go back to group list
                if (navigator.canPop()) {
                  navigator.pop(); // Close settings page
                }

                // Small delay to ensure first pop completes
                await Future.delayed(const Duration(milliseconds: 100));

                if (!mounted) return;

                if (navigator.canPop()) {
                  navigator.pop(); // Close group detail page
                }

                // Small delay before showing success message
                await Future.delayed(const Duration(milliseconds: 100));

                if (!mounted) return;

                // Show success message after navigation
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Text("Grup berhasil dihapus"),
                      ],
                    ),
                    backgroundColor: const Color(0xFF087B42),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } catch (e) {
                print("DEBUG: Error deleting group: $e");
                if (!mounted) return;

                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text("Error: ${e.toString()}"),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text("Hapus Grup", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
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
                GestureDetector(
                  onTap: isCurrentUserAdmin && !_isLoadingImage ? _pickImage : null,
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _selectedImage != null
                              ? Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                )
                              : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                                  ? Image.network(
                                      _currentImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.asset(
                                          'assets/images/design1.png',
                                          fit: BoxFit.cover,
                                          opacity: const AlwaysStoppedAnimation(0.5),
                                        );
                                      },
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                                : null,
                                            strokeWidth: 2,
                                            valueColor: const AlwaysStoppedAnimation<Color>(
                                              Color(0xFF0DB662),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      'assets/images/design1.png',
                                      fit: BoxFit.cover,
                                      opacity: const AlwaysStoppedAnimation(0.5),
                                    ),
                        ),
                      ),
                      if (_isLoadingImage)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        ),
                      if (isCurrentUserAdmin && !_isLoadingImage)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0DB662),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
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
            if (_loadingMembers)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_memberUids.isEmpty)
              const Center(
                child: Text("No members in this group"),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _memberUids.length,
                separatorBuilder: (context, index) => const SizedBox(height: 20),
                itemBuilder: (context, index) {
                  final uid = _memberUids[index];
                  final member = _memberDetails[uid];
                  bool isMemberAdmin = index == 0;
                  
                  // Get display name (fallback ke email prefix)
                  final displayName = (member?.displayName != null && member!.displayName!.isNotEmpty)
                      ? member.displayName!
                      : member?.email.split('@')[0] ?? uid;
                  
                  return Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: Center(
                          child: Text(
                            displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                                if (isMemberAdmin) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE8F5E9),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFF087B42), width: 0.5),
                                    ),
                                    child: const Text(
                                      "Admin",
                                      style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF087B42), fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                            Text(
                              member?.email ?? "No email",
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                      if (isCurrentUserAdmin && !isMemberAdmin)
                        IconButton(
                          icon: Icon(Icons.remove_circle_outline, color: Colors.red[300], size: 20),
                          onPressed: () => _removeMember(index),
                        ),
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
