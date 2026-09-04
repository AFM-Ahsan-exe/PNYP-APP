import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String title;
  final String eventType;
  final String? description;
  final String? location;
  final Timestamp? startDateTime;
  final Timestamp? endDateTime;
  final int? currentParticipants;
  final int? maxParticipants;
  final String? coverImageUrl;
  final String? status;

  // Extended fields written by the createEvent/updateEvent Cloud Functions.
  final bool isOnline;
  final Timestamp? registrationDeadline;
  final int entryFee;
  final List<String> targetAudience;
  final List<String> organizingTeam;
  final List<String> sponsors;
  final List<String> tags;
  final String? createdBy;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const Event({
    required this.id,
    required this.title,
    required this.eventType,
    this.description,
    this.location,
    this.startDateTime,
    this.endDateTime,
    this.currentParticipants,
    this.maxParticipants,
    this.coverImageUrl,
    this.status,
    this.isOnline = false,
    this.registrationDeadline,
    this.entryFee = 0,
    this.targetAudience = const [],
    this.organizingTeam = const [],
    this.sponsors = const [],
    this.tags = const [],
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Event.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Event(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Event',
      eventType: data['eventType'] as String? ?? 'Event',
      description: data['description'] as String?,
      location: data['location'] as String?,
      startDateTime: data['startDateTime'] as Timestamp?,
      endDateTime: data['endDateTime'] as Timestamp?,
      currentParticipants: data['currentParticipants'] as int? ?? 0,
      maxParticipants: data['maxParticipants'] as int?,
      coverImageUrl: (data['coverImageUrl'] ?? data['bannerUrl']) as String?,
      status: data['status'] as String?,
      isOnline: data['isOnline'] as bool? ?? false,
      registrationDeadline: data['registrationDeadline'] as Timestamp?,
      entryFee: data['entryFee'] as int? ?? 0,
      targetAudience:
          (data['targetAudience'] as List<dynamic>?)?.cast<String>() ??
          const [],
      organizingTeam:
          (data['organizingTeam'] as List<dynamic>?)?.cast<String>() ??
          const [],
      sponsors:
          (data['sponsors'] as List<dynamic>?)?.cast<String>() ?? const [],
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      createdBy: data['createdBy'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'eventType': eventType,
      'description': description,
      'location': location,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'currentParticipants': currentParticipants,
      'maxParticipants': maxParticipants,
      'coverImageUrl': coverImageUrl,
      'status': status,
      'isOnline': isOnline,
      'registrationDeadline': registrationDeadline,
      'entryFee': entryFee,
      'targetAudience': targetAudience,
      'organizingTeam': organizingTeam,
      'sponsors': sponsors,
      'tags': tags,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// True when a maximum participant limit exists and has been reached.
  bool get isFull =>
      maxParticipants != null &&
      maxParticipants! > 0 &&
      (currentParticipants ?? 0) >= maxParticipants!;

  /// True when the event accepts registrations right now.
  /// Mirrors the server-side checks in `registerForEvent`.
  bool get isOpenForRegistration {
    if (status == 'cancelled' || status == 'completed') return false;
    if (isFull) return false;
    final deadline = registrationDeadline?.toDate();
    if (deadline != null && deadline.isBefore(DateTime.now())) return false;
    return true;
  }

  /// FR-038: cancellation allowed up to 24 hours before event start.
  bool get canCancelRegistration {
    final start = startDateTime?.toDate();
    if (start == null) return true;
    return DateTime.now().isBefore(start.subtract(const Duration(hours: 24)));
  }
}
