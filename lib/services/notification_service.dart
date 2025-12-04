import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk handle notifikasi menggunakan Firebase Cloud Messaging
class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Keys untuk SharedPreferences
  static const String _keyGroupAdd = 'notif_group_add';
  static const String _keyFriendAdd = 'notif_friend_add';
  static const String _keyExpenseAdd = 'notif_expense_add';
  static const String _keyExpenseAddEmail = 'notif_expense_add_email';
  static const String _keyExpenseEdit = 'notif_expense_edit';
  static const String _keyExpenseEditEmail = 'notif_expense_edit_email';
  static const String _keyExpenseDue = 'notif_expense_due';
  static const String _keyExpenseDueEmail = 'notif_expense_due_email';
  static const String _keyPayment = 'notif_payment';
  static const String _keyPaymentEmail = 'notif_payment_email';
  static const String _keySummary = 'notif_summary';
  static const String _keySummaryEmail = 'notif_summary_email';
  static const String _keyUpdates = 'notif_updates';
  static const String _keyUpdatesEmail = 'notif_updates_email';

  /// Initialize Firebase Messaging
  Future<void> initialize() async {
    // Request permission untuk iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }

  /// Subscribe to topic based on notification preference
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  // ==================== GETTERS ====================

  Future<bool> getGroupAdd() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyGroupAdd) ?? true; // Default: true
  }

  Future<bool> getFriendAdd() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFriendAdd) ?? true;
  }

  Future<bool> getExpenseAdd() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyExpenseAdd) ?? true;
  }

  Future<bool> getExpenseAddEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyExpenseAddEmail) ?? true;
  }

  Future<bool> getExpenseEdit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyExpenseEdit) ?? true;
  }

  Future<bool> getExpenseEditEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyExpenseEditEmail) ?? true;
  }

  Future<bool> getExpenseDue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyExpenseDue) ?? true;
  }

  Future<bool> getExpenseDueEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyExpenseDueEmail) ?? true;
  }

  Future<bool> getPayment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPayment) ?? true;
  }

  Future<bool> getPaymentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPaymentEmail) ?? true;
  }

  Future<bool> getSummary() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySummary) ?? true;
  }

  Future<bool> getSummaryEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySummaryEmail) ?? true;
  }

  Future<bool> getUpdates() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUpdates) ?? true;
  }

  Future<bool> getUpdatesEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUpdatesEmail) ?? true;
  }

  // ==================== SETTERS ====================

  Future<void> setGroupAdd(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGroupAdd, value);
    if (value) {
      await subscribeToTopic('group_add');
    } else {
      await unsubscribeFromTopic('group_add');
    }
  }

  Future<void> setFriendAdd(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFriendAdd, value);
    if (value) {
      await subscribeToTopic('friend_add');
    } else {
      await unsubscribeFromTopic('friend_add');
    }
  }

  Future<void> setExpenseAdd(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyExpenseAdd, value);
    if (value) {
      await subscribeToTopic('expense_add');
    } else {
      await unsubscribeFromTopic('expense_add');
    }
  }

  Future<void> setExpenseAddEmail(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyExpenseAddEmail, value);
  }

  Future<void> setExpenseEdit(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyExpenseEdit, value);
    if (value) {
      await subscribeToTopic('expense_edit');
    } else {
      await unsubscribeFromTopic('expense_edit');
    }
  }

  Future<void> setExpenseEditEmail(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyExpenseEditEmail, value);
  }

  Future<void> setExpenseDue(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyExpenseDue, value);
    if (value) {
      await subscribeToTopic('expense_due');
    } else {
      await unsubscribeFromTopic('expense_due');
    }
  }

  Future<void> setExpenseDueEmail(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyExpenseDueEmail, value);
  }

  Future<void> setPayment(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPayment, value);
    if (value) {
      await subscribeToTopic('payment');
    } else {
      await unsubscribeFromTopic('payment');
    }
  }

  Future<void> setPaymentEmail(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPaymentEmail, value);
  }

  Future<void> setSummary(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySummary, value);
    if (value) {
      await subscribeToTopic('summary');
    } else {
      await unsubscribeFromTopic('summary');
    }
  }

  Future<void> setSummaryEmail(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySummaryEmail, value);
  }

  Future<void> setUpdates(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUpdates, value);
    if (value) {
      await subscribeToTopic('updates');
    } else {
      await unsubscribeFromTopic('updates');
    }
  }

  Future<void> setUpdatesEmail(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUpdatesEmail, value);
  }
}
