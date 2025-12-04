import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/migrate_user_data.dart';

/// Temporary page untuk migrasi data user
/// Halaman ini bisa dihapus setelah semua user berhasil di-migrate
class MigrationPage extends StatefulWidget {
  const MigrationPage({super.key});

  @override
  State<MigrationPage> createState() => _MigrationPageState();
}

class _MigrationPageState extends State<MigrationPage> {
  bool _isMigrating = false;
  String _migrationStatus = "Belum dimulai";
  final List<String> _logs = [];

  Future<void> _migrateCurrentUser() async {
    setState(() {
      _isMigrating = true;
      _migrationStatus = "Sedang migrasi...";
      _logs.clear();
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _addLog("❌ Tidak ada user yang login");
        setState(() {
          _migrationStatus = "Gagal: Tidak ada user yang login";
          _isMigrating = false;
        });
        return;
      }

      _addLog("🔍 Checking user ${user.uid}...");

      // Check status first
      await MigrateUserData.checkUserMigrationStatus(user.uid);

      _addLog("🔄 Starting migration...");

      // Migrate
      await MigrateUserData.migrateSingleUser(user.uid);

      _addLog("✅ Migration completed!");

      setState(() {
        _migrationStatus = "Berhasil! Silakan restart aplikasi";
      });

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("Migration Berhasil!"),
            content: const Text(
              "Data user Anda sudah di-update.\n\n"
              "Silakan restart aplikasi untuk melihat perubahan."
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context); // Kembali ke page sebelumnya
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      _addLog("❌ Error: $e");
      setState(() {
        _migrationStatus = "Gagal: $e";
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  Future<void> _migrateAllUsers() async {
    setState(() {
      _isMigrating = true;
      _migrationStatus = "Sedang migrasi semua user...";
      _logs.clear();
    });

    try {
      _addLog("🔄 Starting migration for all users...");

      await MigrateUserData.migrateAllUsers();

      _addLog("✅ All users migrated!");

      setState(() {
        _migrationStatus = "Berhasil migrasi semua user!";
      });

    } catch (e) {
      _addLog("❌ Error: $e");
      setState(() {
        _migrationStatus = "Gagal: $e";
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  void _addLog(String message) {
    print(message); // Print to console
    setState(() {
      _logs.add(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF087B42),
        elevation: 0,
        title: const Text(
          "User Data Migration",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Halaman ini untuk migrasi data user lama dari field 'name' ke 'displayName'",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Status
            Text(
              "Status: $_migrationStatus",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isMigrating ? null : _migrateCurrentUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0DB662),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isMigrating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text(
                        "Migrate Current User",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isMigrating ? null : _migrateAllUsers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Migrate All Users (Admin)",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Logs
            const Text(
              "Logs:",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _logs.isEmpty ? "No logs yet..." : _logs.join("\n"),
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      fontSize: 12,
                      color: Colors.greenAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
