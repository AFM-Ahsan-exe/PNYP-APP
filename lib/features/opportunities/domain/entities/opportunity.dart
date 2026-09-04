import 'package:cloud_firestore/cloud_firestore.dart';

class Opportunity {
  final String id;
  final String title;
  final String? description;
  final String? organization;
  final String? location;
  final bool isRemote;
  final String? applyUrl;
  final Timestamp? deadline;
  final Timestamp? startDateTime;
  final Timestamp? endDateTime;
  final int? currentParticipants;
  final int? maxParticipants;
  final String? coverImageUrl;
  final String? status;
  final int? viewCount;
  final int? clickCount;
  final List<String>? tags;
  final List<String>? targetAudience;
  final String? createdBy;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const Opportunity({
    required this.id,
    required this.title,
    this.description,
    this.organization,
    this.location,
    this.isRemote = false,
    this.applyUrl,
    this.deadline,
    this.startDateTime,
    this.endDateTime,
    this.currentParticipants,
    this.maxParticipants,
    this.coverImageUrl,
    this.status,
    this.viewCount,
    this.clickCount,
    this.tags,
    this.targetAudience,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Opportunity.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return Opportunity(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Opportunity',
      description: data['description'] as String?,
      organization: data['organization'] as String?,
      location: data['location'] as String?,
      isRemote: data['isRemote'] as bool? ?? false,
      applyUrl: data['applyUrl'] as String?,
      deadline: data['deadline'] as Timestamp?,
      startDateTime: data['startDateTime'] as Timestamp?,
      endDateTime: data['endDateTime'] as Timestamp?,
      currentParticipants: data['currentParticipants'] as int? ?? 0,
      maxParticipants: data['maxParticipants'] as int?,
      coverImageUrl: data['coverImageUrl'] as String?,
      status: data['status'] as String?,
      viewCount: data['viewCount'] as int? ?? 0,
      clickCount: data['clickCount'] as int? ?? 0,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>(),
      targetAudience: (data['targetAudience'] as List<dynamic>?)
          ?.cast<String>(),
      createdBy: data['createdBy'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }
}
