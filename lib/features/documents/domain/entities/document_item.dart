import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentItem {
  final String id;
  final String title;
  final String? description;
  final String? category;
  final String? fileType;
  final String? fileUrl;
  final int? downloadCount;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final String? accessLevel;
  final List<String>? tags;
  final String? uploadedBy;
  final String? uploaderName;
  final int? fileSize;

  const DocumentItem({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.fileType,
    this.fileUrl,
    this.downloadCount,
    this.createdAt,
    this.updatedAt,
    this.accessLevel,
    this.tags,
    this.uploadedBy,
    this.uploaderName,
    this.fileSize,
  });

  factory DocumentItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return DocumentItem(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Document',
      description: data['description'] as String?,
      category: data['category'] as String?,
      fileType: data['fileType'] as String?,
      fileUrl: data['fileUrl'] as String?,
      downloadCount: data['downloadCount'] as int? ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
      accessLevel: data['accessLevel'] as String?,
      tags: (data['tags'] as List<dynamic>?)?.cast<String>(),
      uploadedBy: data['uploadedBy'] as String?,
      uploaderName: data['uploaderName'] as String?,
      fileSize: data['fileSize'] as int?,
    );
  }
}
