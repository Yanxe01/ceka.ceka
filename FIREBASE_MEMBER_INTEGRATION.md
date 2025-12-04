# Firebase Member Integration - Add Expense Page

## Overview
Implementasi Firebase untuk fetch member dari group yang sudah dibuat. Setiap kali halaman Add Expense dibuka, sistem otomatis mengambil data member terbaru dari Firestore.

## Architecture Flow

### 1. Data Flow
```
Home/Groups Page (GroupService)
    ↓ (fetch groups from Firebase)
GroupModel (dengan field members: List<String>)
    ↓ (pass ke GroupDetailPage)
GroupDetailPage
    ↓ (pass ke AddExpensePage)
AddExpensePage._fetchMemberDetails()
    ↓ (iterate widget.group.members UIDs)
UserService.getUserData(uid) → FirestoreService.getUser(uid)
    ↓ (fetch dari /users/{uid} collection)
UserModel (displayName, email, photoURL, dll)
    ↓ (populate _groupMembers list)
UI Display (member list di modal dan split list)
```

### 2. Firebase Collections Used

#### /groups/{groupId}
```json
{
  "name": "Kontrakan Bersama",
  "category": "Kontrakan",
  "adminId": "user123",
  "members": ["user1", "user2", "user3"],
  "inviteCode": "ABC123",
  "createdAt": "2024-12-03T10:00:00Z",
  "image": "url..."
}
```

#### /users/{userId}
```json
{
  "email": "member@example.com",
  "displayName": "John Doe",
  "phoneNumber": "+62812345678",
  "photoURL": "url...",
  "createdAt": "2024-11-01T10:00:00Z"
}
```

### 3. Implementation Details

#### AddExpensePage._fetchMemberDetails()
**Location:** `lib/pages/add_expense_page.dart` (lines 40-75)

**Logic:**
1. Set loading state: `_loadingMembers = true`
2. Initialize `UserService()` dan empty lists
3. Iterate melalui `widget.group.members` (list UIDs dari group)
4. Untuk setiap UID:
   - Call `userService.getUserData(uid)`
   - Firestore query: `/users/{uid}` document
   - Parse ke `UserModel` object
   - Add ke `_groupMembers` list
   - Add uid ke `_selectedMemberIds` (default semua dipilih)
5. Update UI dengan setState
6. Set `_loadingMembers = false`

**Error Handling:**
- Try-catch untuk tiap user fetch
- Try-catch wrapper untuk keseluruhan method
- Print debug logs untuk tracking
- Show SnackBar jika terjadi error

#### UI Indicators
**Member Count Display:**
```dart
InkWell(
  onTap: _loadingMembers ? null : _showChoosePeopleModal,
  child: Container(
    child: _loadingMembers
        ? CircularProgressIndicator() // Loading state
        : Text("${_selectedMemberIds.length}") // Member count
  ),
)
```

**Loading State:**
- Spinner muncul sambil fetch member
- Button "Choose People" di-disable selama loading
- Button "and split" di-disable selama loading

### 4. State Variables

```dart
List<UserModel> _groupMembers = [];           // Member objects dengan detail
List<String> _selectedMemberIds = [];         // UIDs member yang dipilih
Map<String, double> _finalSplitAmounts = {}; // Hasil split calculation
String _splitType = 'equal';                  // Mode split: equal/percent/exact
bool _isLoading = false;                      // Loading untuk save expense
bool _loadingMembers = true;                  // Loading untuk fetch member
```

### 5. UI Components

#### Choose People Modal
**File:** `lib/pages/add_expense_page.dart` - `_showChoosePeopleModal()`

**Features:**
- List semua members dari `_groupMembers`
- Checkbox untuk select/unselect member
- Show member display name dan avatar (first letter)
- Real-time count update: "0 orang dipilih" → "3 orang dipilih"
- OK button untuk confirm

#### Split List Display
**File:** `lib/pages/add_expense_page.dart` - `_buildSplitList()`

**Modes:**
1. **Equal (=)** - Divide total by member count
2. **Percent (%)** - Percentage per member
3. **Exact (Rp)** - Direct nominal input

**For each selected member:**
- Display: Avatar + displayName
- Input field (jika isInput=true)
- Result display (calculated amount)

### 6. Error Scenarios & Handling

| Scenario | Handling |
|----------|----------|
| Member UID tidak ada di /users | Logged, skip member, continue loop |
| Firestore connection error | Catch exception, set _loadingMembers=false, show SnackBar |
| Empty group.members list | No members loaded, default empty |
| User logout mid-fetch | mounted check sebelum setState |
| Multiple fetch requests | Each initState fresh fetch, no caching |

### 7. Debug Logging

All operations logged with "DEBUG:" prefix:

```dart
// Initiation
"DEBUG: Fetching member details from Firebase for 3 members"

// Per member
"DEBUG: Loaded member - John Doe (user123)"
"DEBUG: User not found for uid: user456"
"DEBUG: Error fetching user user456: ..."

// Completion
"DEBUG: Member details loaded - Total: 2 members"

// Errors
"DEBUG: Error in _fetchMemberDetails: ..."
```

### 8. Integration with Expense Save

When saving expense:
1. Use `_selectedMemberIds` untuk tau siapa yg kena tagihan
2. Use `_finalSplitAmounts` (Map<String, double>) untuk store split details
3. Call `ExpenseService().addExpense()` dengan:
   - `groupId`: dari `widget.group.id`
   - `splitDetails`: `_finalSplitAmounts` (uid → amount mapping)
   - `splitType`: 'equal', 'percent', atau 'exact'

### 9. Real-time Sync

**Current Implementation:**
- Member data fetch hanya sekali saat initState
- Static copy dari group.members UIDs
- Tidak ada real-time listener untuk member changes

**Future Improvement:**
```dart
// Bisa ganti dengan Stream untuk real-time sync
Stream<List<UserModel>> _getMembersStream() {
  return FirebaseFirestore.instance
    .collection('users')
    .where(FieldPath.documentId, whereIn: widget.group.members)
    .snapshots()
    .map((snapshot) => snapshot.docs
      .map((doc) => UserModel.fromDocumentSnapshot(doc))
      .toList());
}
```

### 10. Testing Checklist

- [ ] Create group dengan multiple members
- [ ] Open GroupDetailPage
- [ ] Click "Add Expense"
- [ ] Verify loading spinner muncul
- [ ] Verify semua members ter-load dengan nama
- [ ] Click "Choose People" button
- [ ] Verify modal show semua members
- [ ] Select beberapa member
- [ ] Verify split list update dengan selected members
- [ ] Input amount dan split values
- [ ] Click Save
- [ ] Verify expense saved dengan correct split details di Firebase
- [ ] Go back to GroupDetailPage
- [ ] Verify expense muncul di list dengan correct member names

## Firebase Queries

### Get Group Members
```javascript
// GroupService.getUserGroups()
WHERE adminId == currentUserId OR members.contains(currentUserId)
RETURN: List<GroupModel>
```

### Get User Data
```javascript
// UserService.getUserData(uid)
GET /users/{uid}
RETURN: UserModel
```

### Get Group Details
```javascript
// Passed via GroupModel object
RETURN: GroupModel with members list
```

## Validation Rules

| Rule | Check | Error Message |
|------|-------|---------------|
| At least 1 member selected | `_selectedMemberIds.isEmpty` | "Mohon pilih minimal 1 orang" |
| All members must exist | `user != null` | (Skipped, logged) |
| Display name required | Use email if null | Fallback to "Unknown" |
| UID format valid | Passed from group | Assume valid from Firebase |

## Performance Considerations

1. **Member Fetch Latency:**
   - Sequential fetch per member (not parallel)
   - Can be optimized with Future.wait() for parallel fetch
   - Typical: 2-5s untuk 5 members

2. **Memory:**
   - UserModel objects stored in memory (small impact)
   - Split amounts map (minimal)
   - Disposal on page close

3. **Network:**
   - Firestore read ops: 1 per member + initial load
   - Consider caching for frequently accessed groups

## Dependencies

- `firebase_auth`: User authentication
- `cloud_firestore`: Member data fetch
- `models/user_model.dart`: UserModel class
- `services/user_service.dart`: getUserData() method
- `services/firestore_service.dart`: getUser() implementation

## Related Files

- `lib/pages/add_expense_page.dart` - Main implementation
- `lib/pages/group_detail_page.dart` - Caller page
- `lib/models/group_model.dart` - Group data structure
- `lib/models/user_model.dart` - User data structure
- `lib/services/user_service.dart` - User fetch service
- `lib/services/firestore_service.dart` - Firestore operations
