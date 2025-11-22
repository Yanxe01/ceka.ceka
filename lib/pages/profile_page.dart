import 'package:flutter/material.dart';
import 'notification_settings_page.dart';
import 'login_page.dart'; // Import login page untuk navigasi logout

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isDarkTheme = false; // Dummy state untuk switch

  // --- MODAL LOGOUT ---
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Kamu akan keluar dari akun kamu",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF44444C),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Terima kasih telah menggunakan CekaCeka.\nSampai jumpa lagi ya!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () {
                    // Logika Logout: Kembali ke Login Page dan hapus stack history
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE57373), // Merah soft
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Keluar",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 45,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Kembali",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- MODAL HUBUNGI KAMI ---
  void _showContactSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEAEAEA), // Warna abu-abu seperti di gambar
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      "Hubungi kami",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.grey),
                  _buildContactAction("Gmail"),
                  const Divider(height: 1, color: Colors.grey),
                  _buildContactAction("Contact Person"),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEAEAEA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF5656),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactAction(String title) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Color(0xFF44444C),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER HIJAU ---
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 20,
                bottom: 30,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF087B42),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      image: const DecorationImage(
                        // Ganti dengan asset kucing kamu
                        image: AssetImage('assets/images/design1.png'), 
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Nama
                  const Text(
                    "Ian",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  // Email
                  const Text(
                    "ianapalah@dap.apalah",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Edit Profil Link
                  const Text(
                    "Edit Profil",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.white,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // --- MENU CONTENT ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SECTION 1
                  _buildSectionTitle("Akun & Keamanan"),
                  _buildMenuItem(Icons.lock_outline_rounded, "Ubah Password"),
                  _buildMenuItem(Icons.g_mobiledata_rounded, "Akun Terkait", isGoogleIcon: true),

                  const SizedBox(height: 24),

                  // SECTION 2
                  _buildSectionTitle("Pengaturan Aplikasi"),
                  _buildMenuItem(
                    Icons.notifications_none_rounded, 
                    "Notifikasi", 
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const NotificationSettingsPage())
                      );
                    }
                  ),
                  _buildMenuItem(
                    Icons.wb_sunny_outlined, 
                    "Tampilan", 
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: _isDarkTheme,
                        activeColor: Colors.white,
                        activeTrackColor: Colors.black,
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: Colors.grey.shade300,
                        onChanged: (value) {
                          setState(() {
                            _isDarkTheme = value; // Dummy change state
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // SECTION 3
                  _buildSectionTitle("Bantuan"),
                  _buildMenuItem(Icons.help_outline_rounded, "Pusat Bantuan (FAQ)"),
                  _buildMenuItem(
                    Icons.headset_mic_outlined, 
                    "Hubungi Kami",
                    onTap: _showContactSheet,
                  ),
                  _buildMenuItem(Icons.description_outlined, "Syarat & ketentuan"),

                  const SizedBox(height: 40),

                  // TOMBOL LOGOUT (Icon Pintu Keluar)
                  Center(
                    child: IconButton(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout_rounded),
                      color: const Color(0xFFFF5656), // Merah
                      iconSize: 28,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5656).withOpacity(0.1),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                   const SizedBox(height: 80), // Extra space for navbar
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF44444C),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {Widget? trailing, VoidCallback? onTap, bool isGoogleIcon = false}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // Icon
            isGoogleIcon 
            ? const Icon(Icons.g_mobiledata, size: 28, color: Colors.blue) // Placeholder google icon
            : Icon(icon, size: 22, color: const Color(0xFF44444C)),
            
            const SizedBox(width: 16),
            
            // Text
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            // Trailing (Switch atau Arrow jika diperlukan, default kosong)
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}