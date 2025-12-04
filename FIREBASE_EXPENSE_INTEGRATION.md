# Firebase Expense Integration Guide

## Overview
Dokumentasi lengkap untuk mengintegrasikan Add Expense dengan Firebase Firestore dan Split Bill System.

## Fitur yang Sudah Terintegrasi

### 1. **Add Expense** (`add_expense_page.dart`)
- ✅ Input deskripsi pengeluaran dengan UI yang jelas
- ✅ Input nominal dengan format currency (pemisah ribuan)
- ✅ Pilih member yang ingin di-split-bill
- ✅ 3 tipe split: Equal (Sama rata), Percent (Persen), Exact (Nominal pasti)
- ✅ Format tampilan untuk split dengan warna kontras
- ✅ Validasi input sebelum save ke Firebase

### 2. **Group Management** (`group_detail_page.dart`)
- ✅ Invite link untuk menambah member via kode unik
- ✅ Tombol "Add members" di header
- ✅ Floating action button "Add expense"
- ✅ Menampilkan jumlah member di grup

### 3. **Firebase Services**

#### ExpenseService (`expense_service.dart`)
```dart
Future<void> addExpense({
  required String title,           // Deskripsi expense
  required double amount,          // Total nominal
  required String groupId,         // ID grup (dari GroupModel)
  required Map<String, double> splitDetails,  // {userUID: amount}
  required String splitType,       // 'equal', 'percent', 'exact'
})
```

**Struktur data di Firestore:**
```
collections/expenses
├── {docId}
│   ├── title: String
│   ├── amount: double
│   ├── date: Timestamp
│   ├── groupId: String
│   ├── payerId: String (UID siapa yang bayar)
│   ├── splitDetails: Map<String, double>
│   │   └── {memberId}: amountYangHarusDibayar
│   ├── splitType: String
│   └── createdAt: Timestamp
```

#### GroupService (`group_service.dart`)
```dart
// Membuat grup baru
Future<void> createGroup({
  required String name,
  required String category,
})

// Mengambil grup user (realtime)
Stream<List<GroupModel>> getUserGroups()

// Join grup dengan invite code
Future<bool> joinGroup(String inviteCode)
```

## Alur Penggunaan

### Scenario 1: Membuat Expense & Split Bill
```
1. User membuka Group Detail
2. Klik tombol "Add expense"
3. Input deskripsi & nominal
4. Pilih member yang ikut split-bill
5. Pilih tipe split (Equal/Percent/Exact)
6. Klik "Save"
7. Data tersimpan ke Firebase dengan structure:
   - Expense record dibuat di /expenses/{id}
   - Split details mencatat siapa bayar berapa
```

### Scenario 2: Menambah Member via Invite Link
```
1. Admin/Member klik "Add members" di group detail
2. Dialog menampilkan invite link
3. Copy link dan bagikan ke calon member
4. Calon member buka app, input kode dari link
5. Otomatis ditambahkan ke grup
6. Bisa melihat expense dan ikut split-bill
```

## Firestore Database Structure

### Collections:
```
/groups
  {groupId}
    ├── name: String
    ├── category: String
    ├── adminId: String
    ├── members: Array<String> [uid1, uid2, ...]
    ├── inviteCode: String (6 karakter unik)
    ├── createdAt: Timestamp
    └── image: String? (optional)

/expenses
  {expenseId}
    ├── title: String
    ├── amount: Double
    ├── date: Timestamp
    ├── groupId: String (reference ke /groups/{groupId})
    ├── payerId: String (reference ke /users/{payerId})
    ├── splitDetails: Map
    │   └── {userId}: {amount} (jumlah yang harus dibayar user tsb)
    ├── splitType: String ('equal' | 'percent' | 'exact')
    └── createdAt: Timestamp

/users
  {userId}
    ├── displayName: String
    ├── email: String
    ├── photoURL: String? (optional)
    ├── createdAt: Timestamp
    └── ...
```

## Split Type Explanation

### 1. **Equal Split (=)**
- Nominal dibagi sama rata ke semua member
- Contoh: Rp 300.000 ÷ 3 orang = Rp 100.000/orang

### 2. **Percent Split (%)**
- Setiap member ditentukan persennya
- Contoh: User A 50%, User B 30%, User C 20%
- Auto calculate berdasarkan total nominal

### 3. **Exact Split (Rp)**
- Setiap member ditentukan nominal pastinya
- Contoh: User A Rp 150.000, User B Rp 100.000, User C Rp 50.000

## Implementation Details

### Split Amount Calculation

```dart
// Equal Split
double amountPerPerson = totalAmount / selectedMembers.length;
splitDetails[userId] = amountPerPerson;

// Percent Split
double userAmount = (totalAmount * percent) / 100;
splitDetails[userId] = userAmount;

// Exact Split (manual input)
splitDetails[userId] = userInputAmount;
```

### Currency Formatting
```dart
// Format 1000000 → "1.000.000"
String _formatCurrency(String value) {
  if (value.isEmpty) return '';
  final num = int.tryParse(value.replaceAll('.', ''));
  if (num == null) return value;
  return num.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]}.',
  );
}
```

## UI/UX Features Added

### 1. **Color Consistency**
- Text labels: Grey (Colors.grey) untuk kontras
- Input text: White untuk split options modal
- Icons: Teal/Green (Color(0xFF0DB662))

### 2. **Text Input Styling**
- Description field: Grey text with "Enter a description" hint
- Amount field: Format currency with thousands separator
- Split fields: White text on dark background modal

### 3. **Modal Styling**
- Split options modal: Dark background (Color(0xFF2C2C2C))
- All text: White untuk visibility
- Tab navigation: = (Equal), % (Percent), Rp (Exact)

### 4. **Bottom Bar Info**
- Menampilkan tanggal (Today)
- Menampilkan nama grup
- Menampilkan ikon expense dengan warna teal

## How to Use in Your App

### 1. Add Expense Flow
```dart
// Di group_detail_page.dart
FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpensePage(group: widget.group),
      ),
    );
  },
)
```

### 2. Retrieve Expenses
```dart
// Query expenses dari Firebase
Stream<QuerySnapshot> getGroupExpenses(String groupId) {
  return FirebaseFirestore.instance
      .collection('expenses')
      .where('groupId', isEqualTo: groupId)
      .orderBy('createdAt', descending: true)
      .snapshots();
}
```

### 3. Calculate Settlement
```dart
// Hitung siapa hutang siapa
Map<String, double> calculateBalances(List<Expense> expenses) {
  Map<String, double> balances = {}; // userId -> amount
  
  for (var expense in expenses) {
    // Kurangi dari pembayar
    balances[expense.payerId] = 
      (balances[expense.payerId] ?? 0) - expense.amount;
    
    // Tambah ke yang mau split
    expense.splitDetails.forEach((userId, amount) {
      balances[userId] = (balances[userId] ?? 0) + amount;
    });
  }
  
  return balances;
}
```

## Future Enhancements

- [ ] Edit/Delete Expense
- [ ] Expense History dengan filter
- [ ] Payment Settlement Tracking
- [ ] Settlement Suggestions (minimal transactions)
- [ ] Expense Receipt Upload
- [ ] Category-based Analytics
- [ ] Export Expense Report (PDF)

## Testing Checklist

- [x] Add expense dengan deskripsi & nominal
- [x] Format currency dengan titik separator
- [x] Select multiple members untuk split
- [x] Equal split calculation
- [x] Percent split calculation
- [x] Exact split calculation
- [x] Save to Firebase
- [x] Error handling & validation
- [x] UI/UX styling konsisten
- [ ] Retrieve expenses dari Firebase
- [ ] Display expenses di group detail
- [ ] Calculate balances antara members

## Notes

1. **Expense Payer**: Orang yang menginput expense otomatis jadi pembayar (payerId = currentUser.uid)
2. **Split Details**: Menyimpan siapa bayar berapa, bukan track pembayaran
3. **Realtime Updates**: Gunakan StreamBuilder untuk live update expenses
4. **Validation**: Semua input divalidasi sebelum save ke Firebase

---
Dokumentasi dibuat: December 3, 2025
Versi: 1.0
