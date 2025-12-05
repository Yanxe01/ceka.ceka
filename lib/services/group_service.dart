import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math'; // Untuk generate random code
import '../models/group_model.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  CollectionReference get _groups => _firestore.collection('groups');

  // Generate kode unik 6 karakter (Contoh: K3J9L1)
  String _generateInviteCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // --- 1. CREATE GROUP ---
  Future<String> createGroup({
    required String name,
    required String category,
    String? imageUrl,
  }) async {
    final user = _auth.currentUser;

    print("DEBUG GroupService: Current user: ${user?.uid ?? 'NULL'}");
    print("DEBUG GroupService: Current user email: ${user?.email ?? 'NULL'}");

    if (user == null) throw Exception("User belum login");

    String code = _generateInviteCode();

    // Data yang akan dikirim
    Map<String, dynamic> groupData = {
      'name': name,
      'category': category,
      'adminId': user.uid,
      'members': [user.uid], // Pembuat otomatis jadi member
      'inviteCode': code,
      'createdAt': FieldValue.serverTimestamp(),
      'image': imageUrl,
    };

    print("DEBUG GroupService: Group data to save: $groupData");
    print("DEBUG GroupService: Attempting to save to Firestore...");

    try {
      final docRef = await _groups.add(groupData);
      print("DEBUG GroupService: Group saved with ID: ${docRef.id}");
      return docRef.id; // Return group ID for image upload
    } catch (e) {
      print("DEBUG GroupService: Error saving to Firestore: $e");
      rethrow;
    }
  }

  // --- UPDATE GROUP IMAGE ---
  Future<void> updateGroupImage(String groupId, String imageUrl) async {
    try {
      await _groups.doc(groupId).update({
        'image': imageUrl,
      });
      print("DEBUG GroupService: Group image updated for: $groupId");
    } catch (e) {
      print("DEBUG GroupService: Error updating group image: $e");
      rethrow;
    }
  }

  // --- 2. GET USER GROUPS (REALTIME) ---
  // Mengambil daftar grup di mana user tersebut menjadi member
  Stream<List<GroupModel>> getUserGroups() {
    final user = _auth.currentUser;

    print("DEBUG getUserGroups: Current user: ${user?.uid ?? 'NULL'}");

    if (user == null) {
      print("DEBUG getUserGroups: User is null, returning empty stream");
      return Stream.value([]);
    }

    print("DEBUG getUserGroups: Listening to groups for user: ${user.uid}");

    return _groups
        .where('members', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) {
      print("DEBUG getUserGroups: Received ${snapshot.docs.length} groups");

      // Sort di client side untuk menghindari composite index
      final groups = snapshot.docs
          .map((doc) {
            print("DEBUG getUserGroups: Processing group doc: ${doc.id}");
            return GroupModel.fromDocumentSnapshot(doc);
          })
          .toList();

      // Sort berdasarkan createdAt descending (terbaru di atas)
      groups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      print("DEBUG getUserGroups: Returning ${groups.length} groups");
      return groups;
    });
  }

  // --- 3. JOIN GROUP BY CODE ---
  Future<bool> joinGroup(String inviteCode) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    // Cari grup berdasarkan kode
    final querySnapshot = await _groups
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception("Kode undangan tidak valid");
    }

    final doc = querySnapshot.docs.first;
    final List members = doc['members'];

    // Cek apakah sudah join
    if (members.contains(user.uid)) {
      return false; // Sudah join
    }

    // Tambahkan user ke array members
    await _groups.doc(doc.id).update({
      'members': FieldValue.arrayUnion([user.uid])
    });

    return true; // Berhasil join
  }

  // --- 3B. JOIN GROUP BY CODE (WITH GROUP MODEL RETURN) ---
  Future<GroupModel> joinGroupWithCode(String inviteCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print("DEBUG: JoinGroupWithCode - User is null");
        throw Exception("User belum login");
      }

      print("DEBUG: JoinGroupWithCode - User ${user.uid} trying to join with code: $inviteCode");

      // Cari grup berdasarkan kode
      print("DEBUG: JoinGroupWithCode - Querying Firestore for invite code...");
      final querySnapshot = await _groups
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .limit(1)
          .get();

      print("DEBUG: JoinGroupWithCode - Query completed. Found ${querySnapshot.docs.length} groups");

      if (querySnapshot.docs.isEmpty) {
        print("DEBUG: JoinGroupWithCode - Group not found");
        throw Exception("Group not found");
      }

      final doc = querySnapshot.docs.first;
      print("DEBUG: JoinGroupWithCode - Found group: ${doc.id}");

      final List members = doc['members'];
      print("DEBUG: JoinGroupWithCode - Current members: $members");

      // Cek apakah sudah join
      if (members.contains(user.uid)) {
        print("DEBUG: JoinGroupWithCode - User already a member");
        throw Exception("User already a member");
      }

      // Tambahkan user ke array members
      print("DEBUG: JoinGroupWithCode - Attempting to add user to members...");
      await _groups.doc(doc.id).update({
        'members': FieldValue.arrayUnion([user.uid])
      });

      print("DEBUG: JoinGroupWithCode - Successfully updated members");

      // Ambil data group yang sudah diupdate
      print("DEBUG: JoinGroupWithCode - Fetching updated group data...");
      final updatedDoc = await _groups.doc(doc.id).get();

      print("DEBUG: JoinGroupWithCode - Successfully joined group");
      return GroupModel.fromDocumentSnapshot(updatedDoc);
    } catch (e) {
      print("DEBUG: JoinGroupWithCode - Error caught: $e");
      print("DEBUG: JoinGroupWithCode - Error type: ${e.runtimeType}");
      rethrow;
    }
  }

  // --- 4. LEAVE GROUP ---
  /// User meninggalkan grup
  Future<void> leaveGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    try {
      print("DEBUG: LeaveGroup - User ${user.uid} leaving group $groupId");
      
      // Remove user dari members array
      await _groups.doc(groupId).update({
        'members': FieldValue.arrayRemove([user.uid])
      });
      
      print("DEBUG: LeaveGroup - Successfully removed user from group");
    } catch (e) {
      print("DEBUG: LeaveGroup - Error: $e");
      rethrow;
    }
  }

  // --- 5. DELETE GROUP ---
  /// Admin menghapus grup (hanya untuk admin)
  Future<void> deleteGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    try {
      print("DEBUG: DeleteGroup - User ${user.uid} attempting to delete group $groupId");
      
      // Cek apakah user adalah admin
      final doc = await _groups.doc(groupId).get();
      if (!doc.exists) throw Exception("Group tidak ditemukan");
      
      final data = doc.data() as Map<String, dynamic>;
      final adminId = data['adminId'] as String?;
      
      if (adminId != user.uid) {
        throw Exception("Hanya admin yang bisa menghapus grup");
      }
      
      // Delete group document
      await _groups.doc(groupId).delete();
      
      // Delete semua expenses untuk group ini
      final expensesQuery = await _firestore
          .collection('expenses')
          .where('groupId', isEqualTo: groupId)
          .get();
      
      for (var expenseDoc in expensesQuery.docs) {
        await expenseDoc.reference.delete();
      }
      
      print("DEBUG: DeleteGroup - Successfully deleted group and all expenses");
    } catch (e) {
      print("DEBUG: DeleteGroup - Error: $e");
      rethrow;
    }
  }

  // --- 6. REMOVE MEMBER FROM GROUP ---
  /// Admin menghapus member dari grup
  Future<void> removeMember(String groupId, String memberId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User belum login");

    try {
      print("DEBUG: RemoveMember - User ${user.uid} removing $memberId from group $groupId");
      
      // Cek apakah user adalah admin
      final doc = await _groups.doc(groupId).get();
      if (!doc.exists) throw Exception("Group tidak ditemukan");
      
      final data = doc.data() as Map<String, dynamic>;
      final adminId = data['adminId'] as String?;
      
      if (adminId != user.uid) {
        throw Exception("Hanya admin yang bisa menghapus member");
      }
      
      // Remove member dari array
      await _groups.doc(groupId).update({
        'members': FieldValue.arrayRemove([memberId])
      });
      
      print("DEBUG: RemoveMember - Successfully removed member from group");
    } catch (e) {
      print("DEBUG: RemoveMember - Error: $e");
      rethrow;
    }
  }
}