import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;

/// Service untuk handle notifikasi menggunakan Firebase Cloud Messaging
class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Global key untuk navigasi dan menampilkan dialog
  static GlobalKey<NavigatorState>? navigatorKey;

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

  /// Initialize Firebase Messaging dan Local Notifications
  Future<void> initialize() async {
    // Initialize Local Notifications
    await _initializeLocalNotifications();

    // Request permission untuk iOS
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    developer.log('User granted permission: ${settings.authorizationStatus}', name: 'NotificationService');

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    developer.log('FCM Token: $token', name: 'NotificationService');

    // Save FCM token to Firestore
    if (token != null) {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
      }
    }

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Got a message whilst in the foreground!', name: 'NotificationService');
      developer.log('Message data: ${message.data}', name: 'NotificationService');

      if (message.notification != null) {
        developer.log('Message also contained a notification: ${message.notification}', name: 'NotificationService');

        // Show local notification
        _showLocalNotification(
          title: message.notification!.title ?? 'Notification',
          body: message.notification!.body ?? '',
          payload: message.data.toString(),
        );
      }
    });
  }

  /// Setup listener untuk notifikasi realtime - dipanggil setelah user login
  Future<void> setupNotificationListener() async {
    final user = _auth.currentUser;
    if (user == null) {
      developer.log('Cannot setup listener: user not logged in', name: 'NotificationService');
      return;
    }

    developer.log('Setting up notification listener for user: ${user.uid}', name: 'NotificationService');

    // PENTING: Save/Update FCM token setelah user login
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        developer.log('Saving FCM token for user ${user.uid}: $token', name: 'NotificationService');
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
        });
        developer.log('✓ FCM token saved successfully', name: 'NotificationService');
      } else {
        developer.log('✗ No FCM token available', name: 'NotificationService');
      }
    } catch (e) {
      developer.log('Error saving FCM token: $e', name: 'NotificationService', error: e);
    }

    // Listen to notifications collection - HANYA userId, tidak pakai read filter
    developer.log('Starting listener for notifications...', name: 'NotificationService');
    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
      developer.log('📬 Notification snapshot received: ${snapshot.docs.length} total docs', name: 'NotificationService');

      for (var change in snapshot.docChanges) {
        developer.log('Document change type: ${change.type}', name: 'NotificationService');

        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final isRead = data['read'] == true;
            developer.log('Notification data: title="${data['title']}", read=$isRead', name: 'NotificationService');

            // Hanya tampilkan jika belum di-read
            if (!isRead) {
              developer.log('🔔 NEW NOTIFICATION DETECTED: ${data['title']}', name: 'NotificationService');

              // Tampilkan notifikasi lokal
              _showLocalNotification(
                title: data['title'] ?? 'Notification',
                body: data['body'] ?? '',
                payload: data['payload'] ?? '',
              );

              // Mark as read
              change.doc.reference.update({'read': true}).then((_) {
                developer.log('✅ Notification marked as read: ${change.doc.id}', name: 'NotificationService');
              }).catchError((error) {
                developer.log('❌ Error marking as read: $error', name: 'NotificationService');
              });
            } else {
              developer.log('⏭️  Notification already read, skipping', name: 'NotificationService');
            }
          }
        }
      }
    }, onError: (error) {
      developer.log('❌ ERROR in notification listener: $error', name: 'NotificationService', error: error);
    });
  }

  /// Initialize Local Notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        developer.log('Notification tapped: ${response.payload}', name: 'NotificationService');
      },
    );

    // Create notification channel untuk Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'cekaceka_channel',
      'CekaCeka Notifications',
      description: 'Notification channel for CekaCeka app',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Tampilkan notifikasi lokal ke status bar
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'cekaceka_channel',
      'CekaCeka Notifications',
      channelDescription: 'Notification channel for CekaCeka app',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
      payload: payload,
    );

    developer.log('Local notification shown: $title', name: 'NotificationService');
  }

  /// Subscribe to topic based on notification preference
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      developer.log('Subscribed to topic: $topic', name: 'NotificationService');
    } catch (e) {
      developer.log('Error subscribing to topic: $e', name: 'NotificationService', error: e);
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      developer.log('Unsubscribed from topic: $topic', name: 'NotificationService');
    } catch (e) {
      developer.log('Error unsubscribing from topic: $e', name: 'NotificationService', error: e);
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

  // ==================== GROUP NOTIFICATIONS ====================

  /// Kirim notifikasi ketika group baru dibuat
  Future<void> sendGroupCreatedNotification({
    required String groupId,
    required String groupName,
    required List<String> memberIds,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Ambil data user yang membuat group
      final creatorDoc = await _firestore.collection('users').doc(user.uid).get();
      final creatorName = creatorDoc.data()?['name'] ?? 'Someone';

      // Kirim notifikasi ke semua member kecuali yang membuat group
      for (final memberId in memberIds) {
        if (memberId == user.uid) continue; // Skip creator

        final isEnabled = await getGroupAdd();
        if (!isEnabled) continue;

        // Ambil FCM token member
        final userDoc = await _firestore.collection('users').doc(memberId).get();
        final fcmToken = userDoc.data()?['fcmToken'] as String?;

        if (fcmToken != null && fcmToken.isNotEmpty) {
          await _sendFCMNotification(
            token: fcmToken,
            title: 'Ditambahkan ke Group Baru',
            body: '$creatorName menambahkan Anda ke group "$groupName"',
            data: {
              'type': 'group_created',
              'groupId': groupId,
              'creatorId': user.uid,
            },
          );
        }
      }
    } catch (e) {
      developer.log('Error sending group created notification: $e', name: 'NotificationService', error: e);
    }
  }

  // ==================== EXPENSE NOTIFICATIONS ====================

  /// Kirim notifikasi ketika expense baru ditambahkan
  Future<void> sendExpenseAddedNotification({
    required String expenseId,
    required String groupId,
    required String expenseTitle,
    required double amount,
    required Map<String, double> splitDetails,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        developer.log('❌ Cannot send expense notification: user not logged in', name: 'NotificationService');
        return;
      }

      developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'NotificationService');
      developer.log('📤 SENDING EXPENSE NOTIFICATION', name: 'NotificationService');
      developer.log('Expense: $expenseTitle', name: 'NotificationService');
      developer.log('Group ID: $groupId', name: 'NotificationService');
      developer.log('Amount: Rp$amount', name: 'NotificationService');
      developer.log('Split details: $splitDetails', name: 'NotificationService');

      // Ambil data group untuk nama group
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) {
        developer.log('❌ Group not found: $groupId', name: 'NotificationService');
        return;
      }

      final groupName = groupDoc.data()?['name'] ?? 'Unknown Group';
      developer.log('Group name: $groupName', name: 'NotificationService');

      // Ambil data pembuat expense
      final payerDoc = await _firestore.collection('users').doc(user.uid).get();
      final payerName = payerDoc.data()?['displayName'] ?? 'Someone';
      developer.log('Payer: $payerName (${user.uid})', name: 'NotificationService');

      // Kirim notifikasi ke semua member kecuali yang membuat expense
      int sentCount = 0;
      int totalMembers = splitDetails.length - 1; // Exclude payer

      for (final memberId in splitDetails.keys) {
        developer.log('─────────────────────────────────────', name: 'NotificationService');
        developer.log('Processing member: $memberId', name: 'NotificationService');

        if (memberId == user.uid) {
          developer.log('⏭️  Skipping payer (self)', name: 'NotificationService');
          continue; // Skip yang membuat expense
        }

        final isEnabled = await getExpenseAdd();
        if (!isEnabled) {
          developer.log('⏭️  Notification disabled for this member', name: 'NotificationService');
          continue;
        }

        // Ambil FCM token member
        final userDoc = await _firestore.collection('users').doc(memberId).get();
        if (!userDoc.exists) {
          developer.log('❌ User document not found for: $memberId', name: 'NotificationService');
          continue;
        }

        final fcmToken = userDoc.data()?['fcmToken'] as String?;
        developer.log('FCM Token: ${fcmToken?.substring(0, 20)}...', name: 'NotificationService');

        if (fcmToken != null && fcmToken.isNotEmpty) {
          final memberAmount = splitDetails[memberId] ?? 0;
          developer.log('💰 Member amount: Rp${memberAmount.toStringAsFixed(0)}', name: 'NotificationService');

          // Kirim push notification via FCM
          developer.log('📨 Sending notification...', name: 'NotificationService');
          await _sendFCMNotification(
            token: fcmToken,
            title: 'Expense Baru Ditambahkan',
            body: 'Grup $groupName: $payerName menambahkan "$expenseTitle" - Bagian Anda Rp${memberAmount.toStringAsFixed(0)}',
            data: {
              'type': 'expense_added',
              'expenseId': expenseId,
              'groupId': groupId,
              'amount': memberAmount.toString(),
            },
          );
          sentCount++;
          developer.log('✅ Notification sent successfully!', name: 'NotificationService');
        } else {
          developer.log('❌ No FCM token - notification skipped', name: 'NotificationService');
        }
      }

      developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'NotificationService');
      developer.log('✨ NOTIFICATION SUMMARY', name: 'NotificationService');
      developer.log('Total members: $totalMembers', name: 'NotificationService');
      developer.log('Notifications sent: $sentCount', name: 'NotificationService');
      developer.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', name: 'NotificationService');
    } catch (e) {
      developer.log('❌ Error sending expense added notification: $e', name: 'NotificationService', error: e);
    }
  }

  /// Kirim notifikasi reminder untuk due date (hari jatuh tempo)
  Future<void> sendDueDateReminderNotification({
    required String expenseId,
    required String groupId,
    required String expenseTitle,
    required Map<String, double> splitDetails,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Ambil data group untuk nama group
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return;

      final groupName = groupDoc.data()?['name'] ?? 'Unknown Group';

      // Kirim notifikasi ke semua member yang belum bayar
      for (final memberId in splitDetails.keys) {
        final isEnabled = await getExpenseDue();
        if (!isEnabled) continue;

        // Cek apakah member sudah bayar
        final paymentSnapshot = await _firestore
            .collection('payments')
            .where('expenseId', isEqualTo: expenseId)
            .where('payerId', isEqualTo: memberId)
            .where('status', isEqualTo: 'confirmed')
            .get();

        if (paymentSnapshot.docs.isNotEmpty) continue; // Sudah bayar, skip

        // Ambil FCM token member
        final userDoc = await _firestore.collection('users').doc(memberId).get();
        final fcmToken = userDoc.data()?['fcmToken'] as String?;

        if (fcmToken != null && fcmToken.isNotEmpty) {
          final memberAmount = splitDetails[memberId] ?? 0;

          // Kirim push notification via FCM
          await _sendFCMNotification(
            token: fcmToken,
            title: 'Pengingat Pembayaran',
            body: 'Grup $groupName: $expenseTitle - Jatuh tempo hari ini! Rp${memberAmount.toStringAsFixed(0)}',
            data: {
              'type': 'due_date_reminder',
              'expenseId': expenseId,
              'groupId': groupId,
              'amount': memberAmount.toString(),
            },
          );
        }
      }
    } catch (e) {
      developer.log('Error sending due date reminder notification: $e', name: 'NotificationService', error: e);
    }
  }

  /// Kirim notifikasi reminder H-1 sebelum jatuh tempo
  Future<void> sendDueDateH1ReminderNotification({
    required String expenseId,
    required String groupId,
    required String expenseTitle,
    required Map<String, double> splitDetails,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Ambil data group untuk nama group
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return;

      final groupName = groupDoc.data()?['name'] ?? 'Unknown Group';

      // Kirim notifikasi ke semua member yang belum bayar
      for (final memberId in splitDetails.keys) {
        final isEnabled = await getExpenseDue();
        if (!isEnabled) continue;

        // Cek apakah member sudah bayar
        final paymentSnapshot = await _firestore
            .collection('payments')
            .where('expenseId', isEqualTo: expenseId)
            .where('payerId', isEqualTo: memberId)
            .where('status', isEqualTo: 'confirmed')
            .get();

        if (paymentSnapshot.docs.isNotEmpty) continue; // Sudah bayar, skip

        // Ambil FCM token member
        final userDoc = await _firestore.collection('users').doc(memberId).get();
        final fcmToken = userDoc.data()?['fcmToken'] as String?;

        if (fcmToken != null && fcmToken.isNotEmpty) {
          final memberAmount = splitDetails[memberId] ?? 0;

          // Kirim push notification via FCM
          await _sendFCMNotification(
            token: fcmToken,
            title: 'Pengingat Pembayaran - Besok Jatuh Tempo!',
            body: 'Grup $groupName: $expenseTitle - Jatuh tempo besok! Rp${memberAmount.toStringAsFixed(0)}',
            data: {
              'type': 'due_date_h1_reminder',
              'expenseId': expenseId,
              'groupId': groupId,
              'amount': memberAmount.toString(),
            },
          );
        }
      }
    } catch (e) {
      developer.log('Error sending H-1 due date reminder notification: $e', name: 'NotificationService', error: e);
    }
  }

  /// Kirim notifikasi piutang (ketika ada yang harus bayar ke user)
  Future<void> sendDebtNotification({
    required String expenseId,
    required String groupId,
    required String expenseTitle,
    required String debtorId,
    required double amount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Ambil data group
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return;
      final groupName = groupDoc.data()?['name'] ?? 'Unknown Group';

      // Ambil data debtor (yang berhutang)
      final debtorDoc = await _firestore.collection('users').doc(debtorId).get();
      final debtorName = debtorDoc.data()?['name'] ?? 'Someone';

      // Kirim notifikasi ke user yang memiliki piutang (current user)
      final isEnabled = await getExpenseAdd();
      if (!isEnabled) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final fcmToken = userDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _sendFCMNotification(
          token: fcmToken,
          title: 'Piutang Baru',
          body: 'Grup $groupName: $debtorName berhutang Rp${amount.toStringAsFixed(0)} untuk "$expenseTitle"',
          data: {
            'type': 'debt_notification',
            'expenseId': expenseId,
            'groupId': groupId,
            'debtorId': debtorId,
            'amount': amount.toString(),
          },
        );
      }
    } catch (e) {
      developer.log('Error sending debt notification: $e', name: 'NotificationService', error: e);
    }
  }

  // ==================== PAYMENT NOTIFICATIONS ====================

  /// Kirim notifikasi ketika user sudah bayar utang
  Future<void> sendDebtPaidNotification({
    required String expenseId,
    required String groupId,
    required String expenseTitle,
    required String creditorId,
    required double amount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Ambil data group
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return;
      final groupName = groupDoc.data()?['name'] ?? 'Unknown Group';

      // Ambil data payer (yang bayar)
      final payerDoc = await _firestore.collection('users').doc(user.uid).get();
      final payerName = payerDoc.data()?['name'] ?? 'Someone';

      // Kirim notifikasi ke creditor (yang menerima pembayaran)
      final isEnabled = await getPayment();
      if (!isEnabled) return;

      final creditorDoc = await _firestore.collection('users').doc(creditorId).get();
      final fcmToken = creditorDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _sendFCMNotification(
          token: fcmToken,
          title: 'Pembayaran Diterima',
          body: 'Grup $groupName: $payerName telah membayar Rp${amount.toStringAsFixed(0)} untuk "$expenseTitle"',
          data: {
            'type': 'debt_paid',
            'expenseId': expenseId,
            'groupId': groupId,
            'payerId': user.uid,
            'amount': amount.toString(),
          },
        );
      }
    } catch (e) {
      developer.log('Error sending debt paid notification: $e', name: 'NotificationService', error: e);
    }
  }

  /// Kirim notifikasi konfirmasi pembayaran diterima
  Future<void> sendPaymentConfirmedNotification({
    required String paymentId,
    required String expenseId,
    required String groupId,
    required String expenseTitle,
    required String payerId,
    required double amount,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Ambil data group
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return;
      final groupName = groupDoc.data()?['name'] ?? 'Unknown Group';

      // Ambil data yang mengkonfirmasi
      final confirmerDoc = await _firestore.collection('users').doc(user.uid).get();
      final confirmerName = confirmerDoc.data()?['name'] ?? 'Someone';

      // Kirim notifikasi ke payer (yang membayar)
      final isEnabled = await getPayment();
      if (!isEnabled) return;

      final payerDoc = await _firestore.collection('users').doc(payerId).get();
      final fcmToken = payerDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _sendFCMNotification(
          token: fcmToken,
          title: 'Pembayaran Dikonfirmasi',
          body: 'Grup $groupName: $confirmerName telah mengkonfirmasi pembayaran Anda sebesar Rp${amount.toStringAsFixed(0)} untuk "$expenseTitle"',
          data: {
            'type': 'payment_confirmed',
            'paymentId': paymentId,
            'expenseId': expenseId,
            'groupId': groupId,
            'amount': amount.toString(),
          },
        );
      }
    } catch (e) {
      developer.log('Error sending payment confirmed notification: $e', name: 'NotificationService', error: e);
    }
  }

  /// Kirim notifikasi ketika pembayaran ditolak
  Future<void> sendPaymentRejectedNotification({
    required String paymentId,
    required String expenseId,
    required String groupId,
    required String expenseTitle,
    required String payerId,
    required double amount,
    String? reason,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Ambil data group
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return;
      final groupName = groupDoc.data()?['name'] ?? 'Unknown Group';

      // Kirim notifikasi ke payer (yang membayar)
      final isEnabled = await getPayment();
      if (!isEnabled) return;

      final payerDoc = await _firestore.collection('users').doc(payerId).get();
      final fcmToken = payerDoc.data()?['fcmToken'] as String?;

      if (fcmToken != null && fcmToken.isNotEmpty) {
        final bodyText = reason != null && reason.isNotEmpty
            ? 'Grup $groupName: Pembayaran Anda sebesar Rp${amount.toStringAsFixed(0)} untuk "$expenseTitle" ditolak. Alasan: $reason'
            : 'Grup $groupName: Pembayaran Anda sebesar Rp${amount.toStringAsFixed(0)} untuk "$expenseTitle" ditolak.';

        await _sendFCMNotification(
          token: fcmToken,
          title: 'Pembayaran Ditolak',
          body: bodyText,
          data: {
            'type': 'payment_rejected',
            'paymentId': paymentId,
            'expenseId': expenseId,
            'groupId': groupId,
            'amount': amount.toString(),
            if (reason != null) 'reason': reason,
          },
        );
      }
    } catch (e) {
      developer.log('Error sending payment rejected notification: $e', name: 'NotificationService', error: e);
    }
  }

  // ==================== HELPER METHODS ====================

  /// Helper method untuk mengirim FCM notification
  Future<void> _sendFCMNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      // Log untuk debugging
      developer.log('Sending notification to token: $token', name: 'NotificationService');
      developer.log('Title: $title', name: 'NotificationService');
      developer.log('Body: $body', name: 'NotificationService');
      developer.log('Data: $data', name: 'NotificationService');

      // Cari user berdasarkan FCM token
      final userQuery = await _firestore
          .collection('users')
          .where('fcmToken', isEqualTo: token)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        developer.log('No user found with token: $token', name: 'NotificationService');
        return;
      }

      final userId = userQuery.docs.first.id;
      developer.log('Found user: $userId for token', name: 'NotificationService');

      // Simpan notifikasi ke Firestore - akan trigger listener di device member
      final notifData = {
        'userId': userId,
        'title': title,
        'body': body,
        'payload': data.toString(),
        'data': data,
        'read': false,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      developer.log('Saving notification data: $notifData', name: 'NotificationService');

      final notifRef = await _firestore.collection('notifications').add(notifData);

      developer.log('✅ Notification saved successfully with ID: ${notifRef.id} for user: $userId', name: 'NotificationService');

    } catch (e) {
      developer.log('Error sending notification: $e', name: 'NotificationService', error: e);
    }
  }

}
