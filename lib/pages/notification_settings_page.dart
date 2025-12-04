import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = true;

  // Notification preferences
  bool _groupAdd = true;
  bool _friendAdd = true;
  bool _expenseAdd = true;
  bool _expenseAddEmail = true;
  bool _expenseEdit = true;
  bool _expenseEditEmail = true;
  bool _expenseDue = true;
  bool _expenseDueEmail = true;
  bool _payment = true;
  bool _paymentEmail = true;
  bool _summary = true;
  bool _summaryEmail = true;
  bool _updates = true;
  bool _updatesEmail = true;

  @override
  void initState() {
    super.initState();
    print('🔔 NotificationSettingsPage: initState called');
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    print('🔔 _loadPreferences: Starting to load preferences');
    setState(() => _isLoading = true);

    _groupAdd = await _notificationService.getGroupAdd();
    _friendAdd = await _notificationService.getFriendAdd();
    _expenseAdd = await _notificationService.getExpenseAdd();
    _expenseAddEmail = await _notificationService.getExpenseAddEmail();
    _expenseEdit = await _notificationService.getExpenseEdit();
    _expenseEditEmail = await _notificationService.getExpenseEditEmail();
    _expenseDue = await _notificationService.getExpenseDue();
    _expenseDueEmail = await _notificationService.getExpenseDueEmail();
    _payment = await _notificationService.getPayment();
    _paymentEmail = await _notificationService.getPaymentEmail();
    _summary = await _notificationService.getSummary();
    _summaryEmail = await _notificationService.getSummaryEmail();
    _updates = await _notificationService.getUpdates();
    _updatesEmail = await _notificationService.getUpdatesEmail();

    print('🔔 _loadPreferences: Loaded - groupAdd=$_groupAdd, expenseAdd=$_expenseAdd');
    setState(() => _isLoading = false);
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);

    await _notificationService.setGroupAdd(_groupAdd);
    await _notificationService.setFriendAdd(_friendAdd);
    await _notificationService.setExpenseAdd(_expenseAdd);
    await _notificationService.setExpenseAddEmail(_expenseAddEmail);
    await _notificationService.setExpenseEdit(_expenseEdit);
    await _notificationService.setExpenseEditEmail(_expenseEditEmail);
    await _notificationService.setExpenseDue(_expenseDue);
    await _notificationService.setExpenseDueEmail(_expenseDueEmail);
    await _notificationService.setPayment(_payment);
    await _notificationService.setPaymentEmail(_paymentEmail);
    await _notificationService.setSummary(_summary);
    await _notificationService.setSummaryEmail(_summaryEmail);
    await _notificationService.setUpdates(_updates);
    await _notificationService.setUpdatesEmail(_updatesEmail);

    setState(() => _isLoading = false);

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
                  'Pengaturan notifikasi berhasil disimpan',
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
      Navigator.pop(context);
    }
  }
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF0DB662)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("GROUPS AND FRIENDS"),
                  _buildNotificationItem(
                    "When someone adds me to a group",
                    pushValue: _groupAdd,
                    onPushChanged: (val) {
                      print('🔔 onPushChanged callback: _groupAdd changing from $_groupAdd to $val');
                      setState(() {
                        print('🔔 setState: Setting _groupAdd = $val');
                        _groupAdd = val;
                      });
                      print('🔔 setState complete: _groupAdd is now $_groupAdd');
                    },
                    hasEmail: false,
                  ),
                  _buildNotificationItem(
                    "When someone adds me as a friend",
                    pushValue: _friendAdd,
                    onPushChanged: (val) => setState(() => _friendAdd = val),
                    hasEmail: false,
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader("EXPENSES"),
                  _buildNotificationItem(
                    "When an expense is added",
                    pushValue: _expenseAdd,
                    onPushChanged: (val) => setState(() => _expenseAdd = val),
                    emailValue: _expenseAddEmail,
                    onEmailChanged: (val) => setState(() => _expenseAddEmail = val),
                  ),
                  _buildNotificationItem(
                    "When an expense is edited/deleted",
                    pushValue: _expenseEdit,
                    onPushChanged: (val) => setState(() => _expenseEdit = val),
                    emailValue: _expenseEditEmail,
                    onEmailChanged: (val) => setState(() => _expenseEditEmail = val),
                  ),
                  _buildNotificationItem(
                    "When an expense is due",
                    pushValue: _expenseDue,
                    onPushChanged: (val) => setState(() => _expenseDue = val),
                    emailValue: _expenseDueEmail,
                    onEmailChanged: (val) => setState(() => _expenseDueEmail = val),
                  ),
                  _buildNotificationItem(
                    "When someone pays me",
                    pushValue: _payment,
                    onPushChanged: (val) => setState(() => _payment = val),
                    emailValue: _paymentEmail,
                    onEmailChanged: (val) => setState(() => _paymentEmail = val),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionHeader("NEWS AND UPDATES"),
                  _buildNotificationItem(
                    "Monthly summary of my activity",
                    pushValue: _summary,
                    onPushChanged: (val) => setState(() => _summary = val),
                    emailValue: _summaryEmail,
                    onEmailChanged: (val) => setState(() => _summaryEmail = val),
                  ),
                  _buildNotificationItem(
                    "Major CekaCeka news and updates",
                    pushValue: _updates,
                    onPushChanged: (val) => setState(() => _updates = val),
                    emailValue: _updatesEmail,
                    onEmailChanged: (val) => setState(() => _updatesEmail = val),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePreferences,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0DB662),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
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

  Widget _buildNotificationItem(
    String title, {
    required bool pushValue,
    required Function(bool) onPushChanged,
    bool? emailValue,
    Function(bool)? onEmailChanged,
    bool hasEmail = true,
  }) {
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
          // Push notification toggle
          InkWell(
            onTap: () {
              print('🔔 InkWell: Push notification tapped for $title - current value=$pushValue');
              onPushChanged(!pushValue);
              print('🔔 InkWell: After onPushChanged called');
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                pushValue ? Icons.notifications_active : Icons.notifications_off_outlined,
                size: 24,
                color: pushValue ? const Color(0xFF0DB662) : Colors.grey,
              ),
            ),
          ),
          // Email notification toggle
          if (hasEmail && emailValue != null && onEmailChanged != null) ...[
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                print('🔔 GestureDetector: Email notification tapped for $title - current value=$emailValue');
                onEmailChanged(!emailValue);
                print('🔔 GestureDetector: After email onChanged called');
              },
              child: Icon(
                emailValue ? Icons.email : Icons.email_outlined,
                size: 24,
                color: emailValue ? const Color(0xFF0DB662) : Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
}