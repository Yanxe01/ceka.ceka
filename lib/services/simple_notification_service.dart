import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

/// Service sederhana untuk notifikasi yang PASTI BEKERJA
class SimpleNotificationService {
  static final SimpleNotificationService _instance = SimpleNotificationService._internal();
  factory SimpleNotificationService() => _instance;
  SimpleNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _initialized = false;

  /// Initialize notifikasi - WAJIB dipanggil saat app start
  Future<void> initialize() async {
    if (_initialized) return;

    developer.log('🔧 Initializing Simple Notification Service...', name: 'SimpleNotification');

    // Setup Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Setup iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        developer.log('Notification tapped: ${details.payload}', name: 'SimpleNotification');
      },
    );

    // REQUEST PERMISSION untuk Android 13+
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      developer.log('📱 Requesting notification permission...', name: 'SimpleNotification');
      final granted = await androidPlugin.requestNotificationsPermission();
      developer.log('Permission granted: $granted', name: 'SimpleNotification');

      if (granted == false) {
        developer.log('⚠️ Notification permission DENIED by user!', name: 'SimpleNotification');
      }
    }

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'cekaceka_main',
      'CekaCeka Notifications',
      description: 'Notifikasi utama aplikasi CekaCeka',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await androidPlugin?.createNotificationChannel(channel);

    _initialized = true;
    developer.log('✅ Simple Notification Service initialized!', name: 'SimpleNotification');
  }

  /// Tampilkan notifikasi LANGSUNG ke status bar
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      developer.log('❌ Notification service not initialized!', name: 'SimpleNotification');
      await initialize();
    }

    developer.log('📢 SHOWING NOTIFICATION:', name: 'SimpleNotification');
    developer.log('Title: $title', name: 'SimpleNotification');
    developer.log('Body: $body', name: 'SimpleNotification');

    const androidDetails = AndroidNotificationDetails(
      'cekaceka_main',
      'CekaCeka Notifications',
      channelDescription: 'Notifikasi utama aplikasi CekaCeka',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    try {
      await _notifications.show(
        id,
        title,
        body,
        details,
        payload: payload,
      );
      developer.log('✅ Notification shown successfully with ID: $id', name: 'SimpleNotification');
    } catch (e) {
      developer.log('❌ Error showing notification: $e', name: 'SimpleNotification', error: e);
    }
  }

  /// Setup listener untuk expense notifications dari Firestore
  void setupExpenseListener() {
    final user = _auth.currentUser;
    if (user == null) {
      developer.log('❌ User not logged in, cannot setup listener', name: 'SimpleNotification');
      return;
    }

    developer.log('👂 Setting up expense listener for user: ${user.uid}', name: 'SimpleNotification');

    // Listen ke expenses collection dimana user adalah member
    _firestore
        .collection('expenses')
        .snapshots()
        .listen((snapshot) {

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          final splitDetails = data['splitDetails'] as Map<String, dynamic>?;
          final payerId = data['payerId'] as String?;
          final title = data['title'] as String?;
          final amount = data['amount'] as num?;
          final groupId = data['groupId'] as String?;

          // Cek apakah user adalah member (ada di splitDetails)
          // KIRIM NOTIFIKASI KE SEMUA MEMBER TERMASUK ADMIN!
          if (splitDetails != null &&
              splitDetails.containsKey(user.uid) &&
              payerId != null) {

            final userAmount = (splitDetails[user.uid] as num?)?.toDouble() ?? 0;

            developer.log('🆕 NEW EXPENSE DETECTED!', name: 'SimpleNotification');
            developer.log('User is member with amount: Rp$userAmount', name: 'SimpleNotification');

            // Ambil nama group
            if (groupId != null) {
              _firestore.collection('groups').doc(groupId).get().then((groupDoc) {
                final groupName = groupDoc.data()?['name'] ?? 'Unknown Group';

                // Ambil nama payer
                _firestore.collection('users').doc(payerId).get().then((payerDoc) {
                  final payerName = payerDoc.data()?['displayName'] ?? 'Someone';

                  // TAMPILKAN NOTIFIKASI KE SEMUA MEMBER!
                  // Jika user adalah payer, tampilkan notifikasi konfirmasi
                  if (payerId == user.uid) {
                    showNotification(
                      title: '✅ Expense Berhasil Dibuat',
                      body: 'Grup $groupName: Anda menambahkan "$title" - Total: Rp${amount?.toStringAsFixed(0)}',
                      payload: 'expense:${change.doc.id}:$groupId',
                    );
                  } else {
                    // User adalah member lain, tampilkan notifikasi expense baru
                    showNotification(
                      title: '💸 Expense Baru',
                      body: 'Grup $groupName: $payerName menambahkan "$title" - Bagian Anda: Rp${userAmount.toStringAsFixed(0)}',
                      payload: 'expense:${change.doc.id}:$groupId',
                    );
                  }
                });
              });
            }
          }
        }
      }
    }, onError: (error) {
      developer.log('❌ Error in expense listener: $error', name: 'SimpleNotification', error: error);
    });
  }

  /// Setup listener untuk group member join notifications
  void setupGroupListener() {
    final user = _auth.currentUser;
    if (user == null) {
      developer.log('❌ User not logged in, cannot setup group listener', name: 'SimpleNotification');
      return;
    }

    developer.log('👂 Setting up group listener for user: ${user.uid}', name: 'SimpleNotification');

    // Listen ke groups collection dimana user adalah member
    _firestore
        .collection('groups')
        .snapshots()
        .listen((snapshot) {

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data == null) continue;

          final members = data['members'] as List<dynamic>?;
          final groupName = data['name'] as String?;
          final createdBy = data['createdBy'] as String?;

          // Cek apakah user adalah member dari group ini
          if (members != null && members.contains(user.uid)) {
            // Cek apakah ada member baru yang join
            // Kita akan kirim notifikasi ke semua member existing ketika ada member baru
            developer.log('👥 GROUP MEMBER CHANGE DETECTED!', name: 'SimpleNotification');

            // Ambil semua nama member untuk notifikasi
            if (groupName != null && members.length > 1) {
              // Notifikasi untuk admin/creator
              if (createdBy == user.uid && members.length > 1) {
                showNotification(
                  title: '👥 Member Baru Bergabung',
                  body: 'Grup $groupName: Ada member baru yang bergabung! Total member: ${members.length}',
                  payload: 'group:${change.doc.id}',
                );
              }
            }
          }
        }
      }
    }, onError: (error) {
      developer.log('❌ Error in group listener: $error', name: 'SimpleNotification', error: error);
    });
  }

  /// Setup listener untuk payment notifications
  void setupPaymentListener() {
    final user = _auth.currentUser;
    if (user == null) {
      developer.log('❌ User not logged in, cannot setup payment listener', name: 'SimpleNotification');
      return;
    }

    developer.log('👂 Setting up payment listener for user: ${user.uid}', name: 'SimpleNotification');

    // Listen ke payments collection
    _firestore
        .collection('payments')
        .snapshots()
        .listen((snapshot) {

      for (var change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;

        final payerId = data['userId'] as String?;
        final expenseId = data['expenseId'] as String?;
        final amount = data['amount'] as num?;
        final status = data['status'] as String?;

        if (change.type == DocumentChangeType.added) {
          // Notifikasi payment baru disubmit - kirim ke creator expense
          if (expenseId != null) {
            _firestore.collection('expenses').doc(expenseId).get().then((expenseDoc) {
              final expenseData = expenseDoc.data();
              if (expenseData == null) return;

              final expensePayerId = expenseData['payerId'] as String?;
              final expenseTitle = expenseData['title'] as String?;
              final groupId = expenseData['groupId'] as String?;

              // Jika user adalah creator expense, kirim notifikasi ada payment baru
              if (expensePayerId == user.uid && payerId != user.uid) {
                _firestore.collection('users').doc(payerId).get().then((payerDoc) {
                  final payerName = payerDoc.data()?['displayName'] ?? 'Someone';

                  _firestore.collection('groups').doc(groupId).get().then((groupDoc) {
                    final groupName = groupDoc.data()?['name'] ?? 'Unknown Group';

                    showNotification(
                      title: '💳 Pembayaran Baru',
                      body: 'Grup $groupName: $payerName mengajukan pembayaran untuk "$expenseTitle" sebesar Rp${amount?.toStringAsFixed(0)}',
                      payload: 'payment:${change.doc.id}:$expenseId',
                    );
                  });
                });
              }
            });
          }
        } else if (change.type == DocumentChangeType.modified) {
          // Notifikasi payment status change (approved/rejected)
          if (payerId == user.uid && status != null) {
            _firestore.collection('expenses').doc(expenseId).get().then((expenseDoc) {
              final expenseData = expenseDoc.data();
              if (expenseData == null) return;

              final expenseTitle = expenseData['title'] as String?;
              final groupId = expenseData['groupId'] as String?;

              _firestore.collection('groups').doc(groupId).get().then((groupDoc) {
                final groupName = groupDoc.data()?['name'] ?? 'Unknown Group';

                if (status == 'approved') {
                  showNotification(
                    title: '✅ Pembayaran Diterima',
                    body: 'Grup $groupName: Pembayaran Anda untuk "$expenseTitle" telah diterima!',
                    payload: 'payment:${change.doc.id}:$expenseId',
                  );
                } else if (status == 'rejected') {
                  showNotification(
                    title: '❌ Pembayaran Ditolak',
                    body: 'Grup $groupName: Pembayaran Anda untuk "$expenseTitle" ditolak. Silakan periksa kembali.',
                    payload: 'payment:${change.doc.id}:$expenseId',
                  );
                }
              });
            });
          }
        }
      }
    }, onError: (error) {
      developer.log('❌ Error in payment listener: $error', name: 'SimpleNotification', error: error);
    });
  }

  /// Setup listener untuk debt/piutang notifications (payer_covered)
  void setupDebtListener() {
    final user = _auth.currentUser;
    if (user == null) {
      developer.log('❌ User not logged in, cannot setup debt listener', name: 'SimpleNotification');
      return;
    }

    developer.log('👂 Setting up debt listener for user: ${user.uid}', name: 'SimpleNotification');

    // Listen ke expenses collection untuk payer_covered scenario
    _firestore
        .collection('expenses')
        .snapshots()
        .listen((snapshot) {

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;

          final payerCovered = data['payer_covered'] as Map<String, dynamic>?;
          final title = data['title'] as String?;
          final groupId = data['groupId'] as String?;
          final payerId = data['payerId'] as String?;

          // Cek apakah ada member yang menanggung (payer_covered)
          if (payerCovered != null && payerCovered.isNotEmpty) {
            // Notifikasi ke member yang ditanggung
            payerCovered.forEach((memberId, amount) {
              if (memberId == user.uid && payerId != null) {
                final coveredAmount = (amount as num?)?.toDouble() ?? 0;

                _firestore.collection('groups').doc(groupId).get().then((groupDoc) {
                  final groupName = groupDoc.data()?['name'] ?? 'Unknown Group';

                  _firestore.collection('users').doc(payerId).get().then((payerDoc) {
                    final payerName = payerDoc.data()?['displayName'] ?? 'Someone';

                    showNotification(
                      title: '🤝 Ada yang Menanggung Tagihan Anda',
                      body: 'Grup $groupName: $payerName menanggung tagihan Anda untuk "$title" sebesar Rp${coveredAmount.toStringAsFixed(0)}',
                      payload: 'debt:${change.doc.id}:$groupId',
                    );
                  });
                });
              }
            });

            // Notifikasi ke member yang menanggung (payer)
            if (payerId == user.uid) {
              final totalCovered = payerCovered.values.fold<double>(0, (total, val) => total + ((val as num?)?.toDouble() ?? 0));

              _firestore.collection('groups').doc(groupId).get().then((groupDoc) {
                final groupName = groupDoc.data()?['name'] ?? 'Unknown Group';

                showNotification(
                  title: '💰 Piutang Baru',
                  body: 'Grup $groupName: Anda menanggung tagihan member untuk "$title" sebesar Rp${totalCovered.toStringAsFixed(0)}',
                  payload: 'debt:${change.doc.id}:$groupId',
                );
              });
            }
          }
        }
      }
    }, onError: (error) {
      developer.log('❌ Error in debt listener: $error', name: 'SimpleNotification', error: error);
    });
  }

  /// Setup H-1 reminder notifications untuk due dates
  void setupReminderNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      developer.log('❌ User not logged in, cannot setup reminders', name: 'SimpleNotification');
      return;
    }

    developer.log('👂 Setting up reminder notifications for user: ${user.uid}', name: 'SimpleNotification');

    // Check setiap hari untuk due dates yang akan jatuh tempo besok
    // Listen ke expenses yang belum lunas
    _firestore
        .collection('expenses')
        .where('status', isEqualTo: 'unpaid')
        .snapshots()
        .listen((snapshot) {

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final dueDate = data['dueDate'] as Timestamp?;
        final splitDetails = data['splitDetails'] as Map<String, dynamic>?;
        final title = data['title'] as String?;
        final groupId = data['groupId'] as String?;

        if (dueDate != null && splitDetails != null && splitDetails.containsKey(user.uid)) {
          final dueDateValue = dueDate.toDate();
          final now = DateTime.now();
          final tomorrow = DateTime(now.year, now.month, now.day + 1);
          final dueDay = DateTime(dueDateValue.year, dueDateValue.month, dueDateValue.day);

          // Cek apakah due date adalah besok (H-1)
          if (dueDay.year == tomorrow.year &&
              dueDay.month == tomorrow.month &&
              dueDay.day == tomorrow.day) {

            final userAmount = (splitDetails[user.uid] as num?)?.toDouble() ?? 0;

            _firestore.collection('groups').doc(groupId).get().then((groupDoc) {
              final groupName = groupDoc.data()?['name'] ?? 'Unknown Group';

              showNotification(
                title: '⏰ Pengingat Jatuh Tempo',
                body: 'Grup $groupName: Tagihan "$title" akan jatuh tempo besok! Bagian Anda: Rp${userAmount.toStringAsFixed(0)}',
                payload: 'reminder:${doc.id}:$groupId',
              );
            });
          }
        }
      }
    }, onError: (error) {
      developer.log('❌ Error in reminder listener: $error', name: 'SimpleNotification', error: error);
    });
  }

  // /// Kirim notifikasi test
  // Future<void> sendTestNotification() async {
  //   await showNotification(
  //     title: '🧪 Test Notification',
  //     body: 'Ini adalah notifikasi test. Jika Anda melihat ini, notifikasi SUDAH BEKERJA!',
  //     payload: 'test',
  //   );
  // }
}
