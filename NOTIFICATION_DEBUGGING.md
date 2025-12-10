# 🔍 DEBUGGING NOTIFIKASI - TIDAK MUNCUL

## ❌ MASALAH:
Notifikasi tidak muncul sama sekali setelah login.

## 🔧 PERBAIKAN YANG SUDAH DILAKUKAN:

### 1. **Menambahkan Explicit Permission Request**

File: `lib/services/simple_notification_service.dart:46-56`

```dart
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
```

**Apa yang dilakukan**:
- Request permission notification secara eksplisit untuk Android 13+
- Log permission status untuk debugging
- Peringatan jika user menolak permission

### 2. **Rebuild dan Reinstall**

```bash
flutter clean
flutter pub get
flutter build apk --debug
flutter run -d emulator-5554
```

---

## 📋 CHECKLIST DEBUGGING:

### **STEP 1: Cek Permission Dialog**
Saat app pertama kali dibuka setelah install ulang, **HARUS MUNCUL dialog**:

```
"Allow CekaCeka to send you notifications?"
[Allow] [Don't allow]
```

✅ **KLIK "ALLOW"!**

### **STEP 2: Cek Logs**

Jalankan:
```bash
flutter logs -d emulator-5554 | grep SimpleNotification
```

**Harus muncul log berikut**:
```
[SimpleNotification] 🔧 Initializing Simple Notification Service...
[SimpleNotification] 📱 Requesting notification permission...
[SimpleNotification] Permission granted: true
[SimpleNotification] ✅ Simple Notification Service initialized!
[SimpleNotification] 👂 Setting up expense listener...
[SimpleNotification] 👂 Setting up group listener...
[SimpleNotification] 👂 Setting up payment listener...
[SimpleNotification] 👂 Setting up debt listener...
[SimpleNotification] 👂 Setting up reminder notifications...
[SimpleNotification] 📢 SHOWING NOTIFICATION:
[SimpleNotification] Title: 🧪 Test Notification
[SimpleNotification] ✅ Notification shown successfully
```

### **STEP 3: Cek Permission di Settings**

Manual check di Android Settings:
1. Buka **Settings** → **Apps** → **CekaCeka**
2. Tap **Notifications**
3. Pastikan **Allow notifications** = **ON**
4. Pastikan **CekaCeka Notifications** channel = **ON**
5. Pastikan Importance = **High** atau **Urgent**

### **STEP 4: Test Notification**

Setelah login:
1. **Swipe down** dari atas layar
2. Lihat notification drawer
3. **HARUS ADA** notifikasi test:
   - Title: "🧪 Test Notification"
   - Body: "Ini adalah notifikasi test..."

---

## 🐛 KEMUNGKINAN MASALAH:

### **MASALAH 1: Permission Denied**

**Gejala**: Log menunjukkan `Permission granted: false`

**Solusi**:
1. Uninstall app sepenuhnya
2. Reinstall
3. Klik "Allow" saat dialog permission muncul

### **MASALAH 2: Channel Tidak Terdaftar**

**Gejala**: No error tapi notifikasi tidak muncul

**Solusi**:
1. Check Settings → Apps → CekaCeka → Notifications
2. Pastikan ada channel "CekaCeka Notifications"
3. Jika tidak ada, reinstall app

### **MASALAH 3: Do Not Disturb Mode**

**Gejala**: Notifikasi tidak muncul tapi tidak ada error

**Solusi**:
1. Swipe down dari atas
2. Pastikan **Do Not Disturb** = OFF
3. Pastikan ringer tidak silent

### **MASALAH 4: Listener Tidak Jalan**

**Gejala**: Init berhasil tapi tidak ada log "Setting up ... listener"

**Solusi**:
1. Pastikan user sudah login (FirebaseAuth.currentUser != null)
2. Check `home_page.dart:70-84` dipanggil
3. Restart app

---

## 📱 CARA TESTING SETELAH FIX:

### **TEST 1: Permission Dialog**
- [ ] Install app
- [ ] Buka app
- [ ] Dialog permission muncul
- [ ] Klik "Allow"
- [ ] Log: "Permission granted: true"

### **TEST 2: Test Notification**
- [ ] Login ke app
- [ ] Masuk HomePage
- [ ] Tunggu 2-3 detik
- [ ] Swipe down notification drawer
- [ ] **Test notification MUNCUL** ✓

### **TEST 3: Real Expense Notification**
- [ ] Buat expense baru
- [ ] Log: "NEW EXPENSE DETECTED!"
- [ ] Log: "SHOWING NOTIFICATION"
- [ ] **Expense notification MUNCUL** ✓

---

## 🔍 LOGS YANG HARUS DICARI:

### **Saat Init**:
```
[SimpleNotification] 🔧 Initializing Simple Notification Service...
[SimpleNotification] 📱 Requesting notification permission...
[SimpleNotification] Permission granted: true  ← HARUS TRUE!
[SimpleNotification] ✅ Simple Notification Service initialized!
```

### **Saat Setup Listeners**:
```
[SimpleNotification] 👂 Setting up expense listener for user: [UID]
[SimpleNotification] 👂 Setting up group listener for user: [UID]
[SimpleNotification] 👂 Setting up payment listener for user: [UID]
[SimpleNotification] 👂 Setting up debt listener for user: [UID]
[SimpleNotification] 👂 Setting up reminder notifications for user: [UID]
```

### **Saat Test Notification**:
```
[SimpleNotification] 📢 SHOWING NOTIFICATION:
[SimpleNotification] Title: 🧪 Test Notification
[SimpleNotification] Body: Ini adalah notifikasi test...
[SimpleNotification] ✅ Notification shown successfully with ID: [ID]
```

### **Jika Ada Error**:
```
[SimpleNotification] ❌ Error showing notification: [ERROR MESSAGE]
[SimpleNotification] ⚠️ Notification permission DENIED by user!
```

---

## ✅ EXPECTED RESULT SETELAH FIX:

1. **Dialog permission muncul** saat pertama kali buka app
2. **Test notification muncul** saat login
3. **All listeners running** (terlihat di logs)
4. **Expense notification muncul** saat ada expense baru

---

## 🚀 NEXT STEPS:

1. Tunggu build selesai
2. App otomatis install ke emulator
3. **PERHATIKAN dialog permission** saat app terbuka
4. **KLIK "ALLOW"**
5. Login ke app
6. Check notification drawer (swipe down)
7. Report hasil!

---

## 📞 JIKA MASIH TIDAK BEKERJA:

Jalankan command ini untuk full debugging:

```bash
# 1. Check logs
flutter logs -d emulator-5554 | grep SimpleNotification

# 2. Check semua logs (tanpa filter)
flutter logs -d emulator-5554

# 3. Screenshot dan kirim:
#    - Notification drawer (swipe down)
#    - Settings → Apps → CekaCeka → Notifications
#    - Full logs dari terminal
```

**PENTING**: Permission dialog adalah kunci! Jika tidak muncul atau di-reject, notifikasi TIDAK AKAN BEKERJA!
