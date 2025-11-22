import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF0DB662), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF44444C),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("GROUPS AND FRIENDS"),
            _buildNotificationItem("When someone adds me to a group", hasEmail: false),
            _buildNotificationItem("When someone adds me as a friend", hasEmail: false),
            
            const SizedBox(height: 24),
            _buildSectionHeader("EXPENSES"),
            _buildNotificationItem("When an expense is added"),
            _buildNotificationItem("When an expense is edited/deleted"),
            _buildNotificationItem("When an expense is due"),
            _buildNotificationItem("When someone pays me"),

            const SizedBox(height: 24),
            _buildSectionHeader("NEWS AND UPDATES"),
            _buildNotificationItem("Monthly summary of my activity"),
            _buildNotificationItem("Major Splitwise news and updates"),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0DB662),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  "Save Changes",
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
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(String title, {bool hasEmail = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xFF44444C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.notifications_active, size: 24, color: Colors.black87),
          if (hasEmail) ...[
            const SizedBox(width: 12),
            const Icon(Icons.email_outlined, size: 24, color: Colors.black54),
          ],
        ],
      ),
    );
  }
}