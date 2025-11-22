import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk fitur Copy to Clipboard

class InviteMemberModal extends StatelessWidget {
  final String groupName;

  const InviteMemberModal({super.key, required this.groupName});

  @override
  Widget build(BuildContext context) {
    // Link dummy yang unik berdasarkan nama grup
    final String dummyLink = "https://cekaceka.id/invite/${groupName.replaceAll(' ', '')}123";

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Link yang dapat dibagikan',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF44444C),
              ),
            ),
            const SizedBox(height: 20),
            
            // Container Link + Tombol Salin
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  // Text Link (terpotong jika kepanjangan)
                  Expanded(
                    child: Text(
                      dummyLink,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Tombol Salin
                  ElevatedButton.icon(
                    onPressed: () {
                      // Logic Copy to Clipboard
                      Clipboard.setData(ClipboardData(text: dummyLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Link berhasil disalin!")),
                      );
                      Navigator.pop(context); // Tutup modal setelah salin
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0DB662),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.copy, size: 14, color: Colors.white),
                    label: const Text(
                      'Salin link',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
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