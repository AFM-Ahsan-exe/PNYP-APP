import 'package:cloud_firestore/cloud_firestore.dart';

class Volunteer {
  final String id;
  final String userId;
  final String opportunityId;
  final String motivation;
  final String availability;
  final List<String> skills;
  final String status;
  final Timestamp? appliedAt;
  final Timestamp? reviewedAt;
  final String? reviewedBy;
  final String? reviewNotes;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const Volunteer({
    required this.id,
    required this.userId,
    required this.opportunityId,
    required this.motivation,
    required this.availability,
    required this.skills,
    required this.status,
    this.appliedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNotes,
    this.createdAt,
    this.updatedAt,
  });

  factory Volunteer.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Volunteer(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      opportunityId: data['opportunityId'] as String? ?? '',
      motivation: data['motivation'] as String? ?? '',
      availability: data['availability'] as String? ?? '',
      skills:
          (data['skills'] as List<dynamic>?)?.cast<String>() ??
          const <String>[],
      status: data['status'] as String? ?? 'pending',
      appliedAt: data['appliedAt'] as Timestamp?,
      reviewedAt: data['reviewedAt'] as Timestamp?,
      reviewedBy: data['reviewedBy'] as String?,
      reviewNotes: data['reviewNotes'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'opportunityId': opportunityId,
      'motivation': motivation,
      'availability': availability,
      'skills': skills,
      'status': status,
      'appliedAt': appliedAt,
      'reviewedAt': reviewedAt,
      'reviewedBy': reviewedBy,
      'reviewNotes': reviewNotes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
