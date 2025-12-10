import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'notification_service.dart';

/// Service untuk handle reminder dan scheduled notifications
class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  /// Schedule reminder untuk expense yang akan jatuh tempo
  Future<void> scheduleReminderForExpense(
    String reminderId,
    DateTime dueDate,
    {
      required String title,
      required String body,
      required String payload,
    }
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Hitung waktu H-1 (sehari sebelum due date)
      final reminderDate = dueDate.subtract(const Duration(days: 1));

      // Simpan reminder ke Firestore untuk dijadwalkan
      await _firestore.collection('reminders').doc(reminderId).set({
        'userId': user.uid,
        'dueDate': Timestamp.fromDate(dueDate),
        'reminderDate': Timestamp.fromDate(reminderDate),
        'title': title,
        'body': body,
        'payload': payload,
        'isExecuted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'Reminder scheduled: $reminderId for ${reminderDate.toString()}',
        name: 'ReminderService',
      );
    } catch (e) {
      developer.log(
        'Error scheduling reminder: $e',
        name: 'ReminderService',
        error: e,
      );
    }
  }

  /// Schedule reminder H-1 untuk expense
  Future<void> scheduleH1Reminder(
    String expenseId,
    String groupId,
    String expenseTitle,
    DateTime dueDate,
    Map<String, double> splitDetails,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Hitung waktu H-1
      final reminderDate = dueDate.subtract(const Duration(days: 1));

      // Simpan reminder ke Firestore
      final reminderId = '${expenseId}_h1_reminder';
      await _firestore.collection('reminders').doc(reminderId).set({
        'userId': user.uid,
        'expenseId': expenseId,
        'groupId': groupId,
        'expenseTitle': expenseTitle,
        'dueDate': Timestamp.fromDate(dueDate),
        'reminderDate': Timestamp.fromDate(reminderDate),
        'splitDetails': splitDetails,
        'type': 'h1_reminder',
        'isExecuted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      developer.log(
        'H-1 Reminder scheduled for expense $expenseId',
        name: 'ReminderService',
      );
    } catch (e) {
      developer.log(
        'Error scheduling H-1 reminder: $e',
        name: 'ReminderService',
        error: e,
      );
    }
  }

  /// Check dan execute reminders yang sudah waktunya
  Future<void> checkAndExecuteReminders() async {
    try {
      final now = DateTime.now();

      // Query reminders yang belum dieksekusi dan sudah waktunya
      final remindersSnapshot = await _firestore
          .collection('reminders')
          .where('isExecuted', isEqualTo: false)
          .where('reminderDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      for (final doc in remindersSnapshot.docs) {
        final data = doc.data();
        final type = data['type'] as String?;

        if (type == 'h1_reminder') {
          // Execute H-1 reminder
          await _notificationService.sendDueDateH1ReminderNotification(
            expenseId: data['expenseId'] as String,
            groupId: data['groupId'] as String,
            expenseTitle: data['expenseTitle'] as String,
            splitDetails: Map<String, double>.from(data['splitDetails'] as Map),
          );
        }

        // Mark reminder as executed
        await doc.reference.update({'isExecuted': true});

        developer.log(
          'Reminder executed: ${doc.id}',
          name: 'ReminderService',
        );
      }
    } catch (e) {
      developer.log(
        'Error checking reminders: $e',
        name: 'ReminderService',
        error: e,
      );
    }
  }

  /// Cancel reminder
  Future<void> cancelReminder(String reminderId) async {
    try {
      await _firestore.collection('reminders').doc(reminderId).delete();

      developer.log(
        'Reminder cancelled: $reminderId',
        name: 'ReminderService',
      );
    } catch (e) {
      developer.log(
        'Error cancelling reminder: $e',
        name: 'ReminderService',
        error: e,
      );
    }
  }

  /// Get all active reminders for current user
  Future<List<Map<String, dynamic>>> getActiveReminders() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('reminders')
          .where('userId', isEqualTo: user.uid)
          .where('isExecuted', isEqualTo: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      developer.log(
        'Error getting active reminders: $e',
        name: 'ReminderService',
        error: e,
      );
      return [];
    }
  }
}
