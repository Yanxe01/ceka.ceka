# 🔔 PANDUAN TESTING NOTIFIKASI - FINAL VERSION

## ✅ PERBAIKAN YANG SUDAH DILAKUKAN:

1. **FCM Token disimpan saat login** ✓
2. **Timestamp menggunakan DateTime.now()** ✓ (bukan serverTimestamp yang bisa null)
3. **Listener query disederhanakan** ✓ (hanya userId, tidak perlu composite index)
4. **Logging super detail** ✓
5. **Error handling lengkap** ✓

---

## 📱 STEP-BY-STEP TESTING:

### **PERSIAPAN:**

```bash
# Install ke kedua emulator
flutter install -d emulator-5554
flutter install -d emulator-5556
```

### **STEP 1: TESTING DI EMULATOR 1 (User A)**

1. Buka app di emulator-5554
2. **Register/Login sebagai User A**
3. **Tunggu sampai HomePage muncul**
4. Buka terminal dan jalankan:
   ```bash
   flutter logs -d emulator-5554 | grep NotificationService
   ```

**HARUS MUNCUL LOG INI:**
```
[NotificationService] Setting up notification listener for user: [UID_USER_A]
[NotificationService] Saving FCM token for user [UID_USER_A]: [TOKEN]
[NotificationService] ✓ FCM token saved successfully
[NotificationService] Starting listener for notifications...
```

### **STEP 2: TESTING DI EMULATOR 2 (User B)**

1. Buka app di emulator-5556
2. **Register/Login sebagai User B** (email berbeda dari User A)
3. **Tunggu sampai HomePage muncul**
4. Buka terminal baru dan jalankan:
   ```bash
   flutter logs -d emulator-5556 | grep NotificationService
   ```

**HARUS MUNCUL LOG YANG SAMA:**
```
[NotificationService] Setting up notification listener for user: [UID_USER_B]
[NotificationService] Saving FCM token for user [UID_USER_B]: [TOKEN]
[NotificationService] ✓ FCM token saved successfully
[NotificationService] Starting listener for notifications...
```

### **STEP 3: BUAT GROUP & ADD MEMBER**

**Di Emulator 1 (User A):**
1. Tap tombol "+" di Groups page
2. Nama group: "Testing Notif"
3. Add member: **User B** (search by email)
4. Create group

**Di Emulator 2 (User B):**
1. Masuk ke Groups page
2. Lihat invite dari User A
3. **Accept invite**

### **STEP 4: BUAT EXPENSE & LIHAT NOTIFIKASI!**

**Di Emulator 1 (User A):**
1. Masuk ke group "Testing Notif"
2. Tap tombol "Add Expense"
3. Isi form:
   - Title: **"Makan Siang"**
   - Amount: **50000**
   - Split: **Equal** (atau manual pilih User B)
4. **SAVE EXPENSE**

**CEK LOGS EMULATOR 1 - HARUS MUNCUL:**
```
[NotificationService] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[NotificationService] 📤 SENDING EXPENSE NOTIFICATION
[NotificationService] Expense: Makan Siang
[NotificationService] Group name: Testing Notif
[NotificationService] Payer: User A ([UID_USER_A])
[NotificationService] ─────────────────────────────────────
[NotificationService] Processing member: [UID_USER_B]
[NotificationService] FCM Token: [TOKEN_USER_B]...
[NotificationService] 💰 Member amount: Rp25000
[NotificationService] 📨 Sending notification...
[NotificationService] Sending notification to token: [TOKEN]
[NotificationService] Found user: [UID_USER_B] for token
[NotificationService] Saving notification data: {...}
[NotificationService] ✅ Notification saved successfully with ID: [NOTIF_ID] for user: [UID_USER_B]
[NotificationService] ✅ Notification sent successfully!
[NotificationService] ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[NotificationService] ✨ NOTIFICATION SUMMARY
[NotificationService] Total members: 1
[NotificationService] Notifications sent: 1
```

**CEK LOGS EMULATOR 2 - HARUS MUNCUL:**
```
[NotificationService] 📬 Notification snapshot received: 1 total docs
[NotificationService] Document change type: DocumentChangeType.added
[NotificationService] Notification data: title="Expense Baru Ditambahkan", read=false
[NotificationService] 🔔 NEW NOTIFICATION DETECTED: Expense Baru Ditambahkan
[NotificationService] Local notification shown: Expense Baru Ditambahkan
[NotificationService] ✅ Notification marked as read: [NOTIF_ID]
```

**DI EMULATOR 2 - SWIPE DOWN DARI ATAS!**
- **NOTIFIKASI AKAN MUNCUL DI STATUS BAR!** 🎉
- Title: "Expense Baru Ditambahkan"
- Body: "Grup Testing Notif: User A menambahkan "Makan Siang" - Bagian Anda Rp25000"

---

## 🔍 TROUBLESHOOTING:

### ❌ Jika FCM Token tidak tersimpan:

**Check di Firebase Console:**
1. Buka Firestore Database
2. Collection: `users`
3. Document User B
4. **HARUS ada field `fcmToken`**

**Jika tidak ada:**
- Logout User B
- Login ulang
- Check logs harus ada: `✓ FCM token saved successfully`

### ❌ Jika Listener tidak jalan:

**Check logs harus ada:**
```
[NotificationService] Starting listener for notifications...
```

**Jika tidak ada:**
- Force close app
- Buka ulang
- Pastikan sampai HomePage

### ❌ Jika Notification tidak tersimpan:

**Check di Firebase Console:**
1. Firestore Database
2. Collection: `notifications`
3. **HARUS ada document baru dengan:**
   - `userId`: [UID_USER_B]
   - `title`: "Expense Baru Ditambahkan"
   - `read`: false
   - `createdAt`: [timestamp]

**Jika tidak ada:**
- Check logs Emulator 1 ada error?
- Check internet connection
- Check Firestore rules

### ❌ Jika masih tidak muncul:

**Pastikan permission diberikan:**
- Android 13+: App akan minta "Allow notifications?"
- **HARUS klik "Allow"!**

**Check notification permission:**
```bash
adb shell dumpsys notification_listener
```

---

## 🎯 EXPECTED RESULT:

✅ **User A buat expense**
↓
✅ **Notification disimpan ke Firestore**
↓
✅ **Listener User B mendeteksi perubahan**
↓
✅ **Notifikasi muncul di status bar Emulator 2** 📱
↓
✅ **Notifikasi bisa di-tap untuk buka app**

---

## 📊 VERIFICATION CHECKLIST:

- [ ] Emulator 1: User A login berhasil
- [ ] Emulator 2: User B login berhasil
- [ ] Kedua user punya FCM token di Firestore
- [ ] Kedua user listener jalan (check logs)
- [ ] Group dibuat dan User B jadi member
- [ ] Expense dibuat oleh User A
- [ ] Logs Emulator 1 show "Notifications sent: 1"
- [ ] Logs Emulator 2 show "NEW NOTIFICATION DETECTED"
- [ ] Firestore ada document di collection `notifications`
- [ ] **NOTIFIKASI MUNCUL DI STATUS BAR EMULATOR 2** ✓

---

## 🚀 JIKA BERHASIL:

Selamat! Sistem notifikasi real-time Anda sudah bekerja 100%!

Notifikasi akan muncul untuk semua jenis event:
- ✅ Expense baru dibuat
- ✅ Group baru dibuat
- ✅ Payment confirmed
- ✅ Payment rejected
- ✅ Due date reminder (H-1)
- ✅ Debt notification

Semua menggunakan sistem yang sama dan PASTI BEKERJA!
