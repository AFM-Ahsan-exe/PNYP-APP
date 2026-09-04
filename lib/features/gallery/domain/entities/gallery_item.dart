import 'package:cloud_firestore/cloud_firestore.dart';

class Album {
  final String id;
  final String title;
  final String description;
  final String coverImageUrl;
  final List<String> tags;
  final bool isPublic;
  final int mediaCount;
  final String createdBy;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const Album({
    required this.id,
    required this.title,
    required this.description,
    required this.coverImageUrl,
    required this.tags,
    required this.isPublic,
    required this.mediaCount,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Album.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Album(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Album',
      description: data['description'] as String? ?? '',
      coverImageUrl: data['coverImageUrl'] as String? ?? '',
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      isPublic: data['isPublic'] as bool? ?? true,
      mediaCount: data['mediaCount'] as int? ?? 0,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}

class GalleryMedia {
  final String id;
  final String albumId;
  final String mediaUrl;
  final String mediaType;
  final String thumbnailUrl;
  final String caption;
  final List<String> tags;
  final String uploadedBy;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const GalleryMedia({
    required this.id,
    required this.albumId,
    required this.mediaUrl,
    required this.mediaType,
    required this.thumbnailUrl,
    required this.caption,
    required this.tags,
    required this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GalleryMedia.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return GalleryMedia(
      id: doc.id,
      albumId: data['albumId'] as String? ?? '',
      mediaUrl: data['mediaUrl'] as String? ?? '',
      mediaType: data['mediaType'] as String? ?? 'image',
      thumbnailUrl: data['thumbnailUrl'] as String? ?? '',
      caption: data['caption'] as String? ?? '',
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? const [],
      uploadedBy: data['uploadedBy'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: data['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}
