# 🔔 Notification Feature Documentation

## ✅ Fitur yang Sudah Dibuat

Saya telah membuat sistem notifikasi lengkap dengan:

### 1. **NotificationService** ([lib/services/notification_service.dart](lib/services/notification_service.dart))
- ✅ Integrasi Firebase Cloud Messaging (FCM)
- ✅ SharedPreferences untuk menyimpan preferensi notifikasi
- ✅ Subscribe/Unsubscribe ke FCM topics
- ✅ 14 jenis notifikasi yang dapat dikonfigurasi

### 2. **NotificationSettingsPage** ([lib/pages/notification_settings_page.dart](lib/pages/notification_settings_page.dart))
- ✅ UI untuk mengatur preferensi notifikasi
- ✅ Toggle untuk push notifications (icon notifikasi)
- ✅ Toggle untuk email notifications (icon email)
- ✅ Auto-save ke SharedPreferences
- ✅ Loading state saat load/save data

---

## 📱 Cara Menggunakan

### Di Profile Page:

1. User klik menu **"Notifikasi"**
2. Akan masuk ke halaman Notification Settings
3. User bisa toggle icon untuk aktif/non-aktifkan:
   - **Icon Lonceng** = Push Notification
   - **Icon Email** = Email Notification
4. Klik **"Save Changes"** untuk menyimpan
5. Preferensi tersimpan di device menggunakan SharedPreferences

### Jenis Notifikasi yang Tersedia:

#### **Groups and Friends:**
- When someone adds me to a group (Push only)
- When someone adds me as a friend (Push only)

#### **Expenses:**
- When an expense is added (Push + Email)
- When an expense is edited/deleted (Push + Email)
- When an expense is due (Push + Email)
- When someone pays me (Push + Email)

#### **News and Updates:**
- Monthly summary of my activity (Push + Email)
- Major CekaCeka news and updates (Push + Email)

---

## 🔧 Cara Kerja Backend

### Firebase Cloud Messaging Topics:

Ketika user mengaktifkan notifikasi, device akan subscribe ke FCM topic:

```dart
// Contoh: User aktifkan "When an expense is added"
await NotificationService().setExpenseAdd(true);

// Backend akan:
// 1. Save ke SharedPreferences: true
// 2. Subscribe to FCM topic: "expense_add"
```

### Mengirim Notifikasi (Backend/Admin):

Untuk mengirim notifikasi dari backend, gunakan Firebase Admin SDK:

```javascript
// Node.js example
const admin = require('firebase-admin');

// Kirim ke semua user yang subscribe topic "expense_add"
await admin.messaging().send({
  topic: 'expense_add',
  notification: {
    title: 'New Expense Added',
    body: 'Kontrakan A added expense: Listrik Rp150,000'
  },
  data: {
    type: 'expense_add',
    expenseId: 'exp_123',
    groupId: 'grp_456'
  }
});
```

---

## 🎯 Testing Notification

### 1. Test di Device:

```bash
# Run aplikasi
flutter run

# Buka Profile → Notifikasi
# Toggle beberapa notifikasi ON
# Klik Save Changes
```

### 2. Test dengan Firebase Console:

1. Buka Firebase Console → Cloud Messaging
2. Click **"Send test message"**
3. Masukkan FCM token (check console log saat app start)
4. Kirim notification

### 3. Check Apakah Preferensi Tersimpan:

```dart
// Di console akan muncul log saat subscribe/unsubscribe
// Output: "Subscribed to topic: expense_add"
// Output: "Unsubscribed from topic: expense_add"
```

---

## 📋 API Reference

### NotificationService Methods:

```dart
final notificationService = NotificationService();

// Initialize (panggil di main.dart)
await notificationService.initialize();

// GET preferences
bool isEnabled = await notificationService.getExpenseAdd();

// SET preferences (auto subscribe/unsubscribe)
await notificationService.setExpenseAdd(true);

// Topics yang tersedia:
// - group_add
// - friend_add
// - expense_add
// - expense_edit
// - expense_due
// - payment
// - summary
// - updates
```

---

## ⚙️ Setup Required

### 1. Firebase Cloud Messaging sudah configured ✅
   - Sudah ada di `pubspec.yaml`: `firebase_messaging: ^15.1.5`

### 2. Permissions (Android):

Sudah otomatis di handle oleh `firebase_messaging` package.

### 3. Permissions (iOS):

Untuk iOS, tambahkan di `ios/Runner/Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
  <string>remote-notification</string>
</array>
```

---

## 🔍 Troubleshooting

### **Notifikasi tidak muncul:**

1. Check console log untuk FCM token:
   ```
   FCM Token: eABC123...
   ```

2. Pastikan device terconnect ke internet

3. Test dengan Firebase Console manual send

### **Preferensi tidak tersimpan:**

1. Check apakah `Save Changes` sudah diklik
2. Check console log: `Subscribed to topic: ...`
3. Check SharedPreferences dengan:
   ```dart
   final prefs = await SharedPreferences.getInstance();
   print(prefs.getBool('notif_expense_add')); // should print true/false
   ```

### **Permission denied:**

Jika muncul error permission denied:
```dart
// Check permission status
NotificationSettings settings = await FirebaseMessaging.instance.requestPermission();
print('Permission: ${settings.authorizationStatus}');
```

---

## 🚀 Next Steps (Optional Enhancement)

### 1. **In-App Notifications:**
   - Badge count di icon notifikasi
   - Notification center dalam app
   - Mark as read/unread

### 2. **Notification History:**
   - List semua notifikasi yang pernah diterima
   - Filter by type
   - Clear all

### 3. **Advanced Settings:**
   - Notification sound customization
   - Quiet hours (jangan kirim notif jam 10pm - 7am)
   - Group notifications by type

### 4. **Email Integration:**
   - Integration dengan email service (SendGrid, etc.)
   - Email template design
   - Unsubscribe link di email

---

## ✅ Checklist

- [x] NotificationService created
- [x] FCM initialization
- [x] SharedPreferences integration
- [x] Subscribe/Unsubscribe to topics
- [x] Notification Settings UI
- [x] Toggle for push notifications
- [x] Toggle for email notifications
- [x] Save functionality
- [x] Loading states
- [x] Navigation from Profile page
- [x] Documentation

---

## 📞 Support

Untuk pertanyaan atau issue terkait notifikasi:
1. Check Firebase Console → Cloud Messaging
2. Verify FCM token di console log
3. Test manual send dari Firebase Console

**Fitur notifikasi sudah siap digunakan! 🎉**
