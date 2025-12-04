import 'package:cloud_firestore/cloud_firestore.dart';

/// Script untuk migrasi data user lama dari field 'name' ke 'displayName'
/// dan 'phone' ke 'phoneNumber'
class MigrateUserData {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrasi semua user yang masih menggunakan field lama
  static Future<void> migrateAllUsers() async {
    try {
      print("=== STARTING USER MIGRATION ===");

      // Get all users
      QuerySnapshot snapshot = await _firestore.collection('users').get();

      int totalUsers = snapshot.docs.length;
      int migratedCount = 0;

      print("Found $totalUsers users in database");

      for (var doc in snapshot.docs) {
        try {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          bool needsUpdate = false;
          Map<String, dynamic> updates = {};

          // Check if has old 'name' field
          if (data.containsKey('name') && !data.containsKey('displayName')) {
            updates['displayName'] = data['name'];
            needsUpdate = true;
            print("User ${doc.id}: Will migrate 'name' -> 'displayName': ${data['name']}");
          }

          // Check if has old 'phone' field
          if (data.containsKey('phone') && !data.containsKey('phoneNumber')) {
            updates['phoneNumber'] = data['phone'];
            needsUpdate = true;
            print("User ${doc.id}: Will migrate 'phone' -> 'phoneNumber': ${data['phone']}");
          }

          // Update if needed
          if (needsUpdate) {
            updates['updatedAt'] = FieldValue.serverTimestamp();
            await _firestore.collection('users').doc(doc.id).update(updates);
            migratedCount++;
            print("✅ User ${doc.id} migrated successfully");
          } else {
            print("⏭️  User ${doc.id} already up to date");
          }

        } catch (e) {
          print("❌ Error migrating user ${doc.id}: $e");
        }
      }

      print("\n=== MIGRATION COMPLETED ===");
      print("Total users: $totalUsers");
      print("Migrated: $migratedCount");
      print("Already up to date: ${totalUsers - migratedCount}");

    } catch (e) {
      print("❌ Migration failed: $e");
      rethrow;
    }
  }

  /// Migrasi single user berdasarkan UID
  static Future<void> migrateSingleUser(String uid) async {
    try {
      print("=== MIGRATING USER $uid ===");

      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        print("❌ User $uid not found");
        return;
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> updates = {};
      bool needsUpdate = false;

      // Check if has old 'name' field
      if (data.containsKey('name') && !data.containsKey('displayName')) {
        updates['displayName'] = data['name'];
        needsUpdate = true;
        print("Will migrate 'name' -> 'displayName': ${data['name']}");
      }

      // Check if has old 'phone' field
      if (data.containsKey('phone') && !data.containsKey('phoneNumber')) {
        updates['phoneNumber'] = data['phone'];
        needsUpdate = true;
        print("Will migrate 'phone' -> 'phoneNumber': ${data['phone']}");
      }

      if (needsUpdate) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(uid).update(updates);
        print("✅ User $uid migrated successfully");
      } else {
        print("⏭️  User $uid already up to date");
      }

    } catch (e) {
      print("❌ Migration failed for user $uid: $e");
      rethrow;
    }
  }

  /// Cek status migrasi user
  static Future<void> checkUserMigrationStatus(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        print("❌ User $uid not found");
        return;
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      print("\n=== USER $uid MIGRATION STATUS ===");
      print("Has 'name' field: ${data.containsKey('name')}");
      print("Has 'displayName' field: ${data.containsKey('displayName')}");
      print("Has 'phone' field: ${data.containsKey('phone')}");
      print("Has 'phoneNumber' field: ${data.containsKey('phoneNumber')}");

      if (data.containsKey('name')) {
        print("'name' value: ${data['name']}");
      }
      if (data.containsKey('displayName')) {
        print("'displayName' value: ${data['displayName']}");
      }
      if (data.containsKey('phone')) {
        print("'phone' value: ${data['phone']}");
      }
      if (data.containsKey('phoneNumber')) {
        print("'phoneNumber' value: ${data['phoneNumber']}");
      }

      bool needsMigration = (data.containsKey('name') && !data.containsKey('displayName')) ||
                            (data.containsKey('phone') && !data.containsKey('phoneNumber'));

      if (needsMigration) {
        print("\n⚠️  NEEDS MIGRATION");
      } else {
        print("\n✅ UP TO DATE");
      }

    } catch (e) {
      print("❌ Error checking user $uid: $e");
    }
  }
}
