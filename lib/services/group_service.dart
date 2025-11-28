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
  Future<void> createGroup({
    required String name,
    required String category,
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
      'image': null, // Nanti bisa diupdate fitur upload gambar
    };

    print("DEBUG GroupService: Group data to save: $groupData");
    print("DEBUG GroupService: Attempting to save to Firestore...");

    try {
      final docRef = await _groups.add(groupData);
      print("DEBUG GroupService: Group saved with ID: ${docRef.id}");
    } catch (e) {
      print("DEBUG GroupService: Error saving to Firestore: $e");
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
}