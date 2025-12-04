import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk data User
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    required this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor untuk membuat UserModel dari Map
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    // Handle createdAt yang mungkin null atau tidak ada
    DateTime parsedCreatedAt;
    try {
      if (map['createdAt'] != null) {
        parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
      } else {
        parsedCreatedAt = DateTime.now();
        print("DEBUG: createdAt is null for user $uid, using DateTime.now()");
      }
    } catch (e) {
      parsedCreatedAt = DateTime.now();
      print("DEBUG: Error parsing createdAt for user $uid: $e, using DateTime.now()");
    }

    // Handle updatedAt
    DateTime? parsedUpdatedAt;
    try {
      if (map['updatedAt'] != null) {
        parsedUpdatedAt = (map['updatedAt'] as Timestamp).toDate();
      }
    } catch (e) {
      print("DEBUG: Error parsing updatedAt for user $uid: $e");
    }

    // BACKWARD COMPATIBILITY: Handle old field names
    // Old: 'name' -> New: 'displayName'
    // Old: 'phone' -> New: 'phoneNumber'
    String? displayName = map['displayName'] as String?;
    String? phoneNumber = map['phoneNumber'] as String?;

    // Fallback ke field lama jika field baru tidak ada
    if (displayName == null && map.containsKey('name')) {
      displayName = map['name'] as String?;
      print("DEBUG UserModel: Using legacy 'name' field for user $uid: '$displayName'");
    }

    if (phoneNumber == null && map.containsKey('phone')) {
      phoneNumber = map['phone'] as String?;
      print("DEBUG UserModel: Using legacy 'phone' field for user $uid: '$phoneNumber'");
    }

    return UserModel(
      uid: uid,
      email: map['email'] as String? ?? 'unknown@example.com',
      displayName: displayName,
      phoneNumber: phoneNumber,
      photoURL: map['photoURL'] as String?,
      createdAt: parsedCreatedAt,
      updatedAt: parsedUpdatedAt,
    );
  }

  /// Factory constructor untuk membuat UserModel dari DocumentSnapshot
  factory UserModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap(data, doc.id);
  }

  /// Mengkonversi UserModel ke Map untuk disimpan di Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// CopyWith method untuk membuat copy dengan perubahan tertentu
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, phoneNumber: $phoneNumber, photoURL: $photoURL, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.phoneNumber == phoneNumber &&
        other.photoURL == photoURL &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        phoneNumber.hashCode ^
        photoURL.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}
