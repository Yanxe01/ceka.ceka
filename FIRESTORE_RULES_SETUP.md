# Firestore Security Rules Setup

## Error yang Muncul
```
Error: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

## Penyebab
Activity Page mencoba mengakses collections `expenses` dan `payments` dari Firestore, tetapi Security Rules belum dikonfigurasi untuk mengizinkan akses tersebut.

## Solusi: Update Firestore Security Rules

Buka Firebase Console dan update Firestore Security Rules dengan konfigurasi berikut:

### Langkah-langkah:
1. Buka [Firebase Console](https://console.firebase.google.com)
2. Pilih project Anda
3. Klik **Firestore Database** di menu sebelah kiri
4. Klik tab **Rules**
5. Ganti rules yang ada dengan rules di bawah ini
6. Klik **Publish**

### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper function untuk cek apakah user sudah login
    function isSignedIn() {
      return request.auth != null;
    }

    // Helper function untuk cek apakah user adalah owner
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }

    // Users collection - user hanya bisa read/write data mereka sendiri
    match /users/{userId} {
      allow read: if isSignedIn();
      allow write: if isOwner(userId);
    }

    // Groups collection - member bisa read, creator bisa write
    match /groups/{groupId} {
      allow read: if isSignedIn() &&
                     request.auth.uid in resource.data.members;
      allow create: if isSignedIn();
      allow update, delete: if isSignedIn() &&
                               request.auth.uid == resource.data.createdBy;
    }

    // Expenses collection - member group bisa read/write
    match /expenses/{expenseId} {
      allow read: if isSignedIn();
      allow create: if isSignedIn();
      allow update, delete: if isSignedIn() &&
                               request.auth.uid == resource.data.payerId;
    }

    // Payments collection - payer dan receiver bisa read/write
    match /payments/{paymentId} {
      allow read: if isSignedIn() &&
                     (request.auth.uid == resource.data.payerId ||
                      request.auth.uid == resource.data.receiverId);
      allow create: if isSignedIn();
      allow update: if isSignedIn() &&
                       (request.auth.uid == resource.data.payerId ||
                        request.auth.uid == resource.data.receiverId);
      allow delete: if isSignedIn() &&
                       request.auth.uid == resource.data.payerId;
    }
  }
}
```

## Penjelasan Rules

### Users Collection
- **Read**: Semua user yang login bisa membaca data user lain (untuk menampilkan nama member di group)
- **Write**: User hanya bisa menulis/update data mereka sendiri

### Groups Collection
- **Read**: Hanya member group yang bisa membaca data group tersebut
- **Create**: Semua user yang login bisa membuat group baru
- **Update/Delete**: Hanya creator group yang bisa update/delete

### Expenses Collection
- **Read**: Semua user yang login bisa membaca expenses (untuk menghitung utang/piutang)
- **Create**: Semua user yang login bisa membuat expense baru
- **Update/Delete**: Hanya payer (yang membuat expense) yang bisa update/delete

### Payments Collection
- **Read**: Hanya payer (yang bayar) dan receiver (yang menerima) bisa membaca
- **Create**: Semua user yang login bisa membuat payment
- **Update**: Payer dan receiver bisa update (untuk konfirmasi pembayaran)
- **Delete**: Hanya payer yang bisa delete payment mereka

## Testing Setelah Update Rules

Setelah rules di-publish:
1. Restart aplikasi Flutter
2. Coba buka Activity page
3. Error "permission-denied" seharusnya sudah hilang
4. Bills dan History akan muncul sesuai data di Firestore

## Alternative: Development Mode (TIDAK DISARANKAN UNTUK PRODUCTION)

Jika ingin testing cepat (HANYA untuk development), bisa gunakan rules ini sementara:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**PERINGATAN**: Rules ini mengizinkan semua user yang login untuk read/write semua data. Hanya gunakan untuk testing, dan WAJIB diganti dengan rules yang proper sebelum production!
