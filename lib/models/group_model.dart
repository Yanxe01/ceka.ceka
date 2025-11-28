import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String category; // Kontrakan, Olahraga, dll
  final String adminId; // UID pembuat grup
  final List<String> members; // List UID member
  final String inviteCode; // Kode unik buat join
  final DateTime createdAt;
  final String? image; 

  GroupModel({
    required this.id,
    required this.name,
    required this.category,
    required this.adminId,
    required this.members,
    required this.inviteCode,
    required this.createdAt,
    this.image,
  });

  // Dari Firestore ke Object
  factory GroupModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Handle createdAt yang bisa null atau belum tersedia
    DateTime parsedDate;
    try {
      if (data['createdAt'] != null) {
        parsedDate = (data['createdAt'] as Timestamp).toDate();
      } else {
        parsedDate = DateTime.now(); // Default ke sekarang jika null
      }
    } catch (e) {
      print("Error parsing createdAt: $e");
      parsedDate = DateTime.now();
    }

    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      category: data['category'] ?? 'Lainnya',
      adminId: data['adminId'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      inviteCode: data['inviteCode'] ?? '',
      createdAt: parsedDate,
      image: data['image'],
    );
  }

  // Dari Object ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'adminId': adminId,
      'members': members,
      'inviteCode': inviteCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'image': image,
    };
  }
}