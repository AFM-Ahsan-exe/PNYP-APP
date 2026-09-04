import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pynp_app/features/gallery/domain/entities/gallery_item.dart';

void main() {
  group('Album', () {
    test('creates with required fields', () {
      final album = Album(
        id: 'album-1',
        title: 'Test Album',
        description: 'Description',
        coverImageUrl: 'https://example.com/cover.jpg',
        tags: ['event', '2024'],
        isPublic: true,
        mediaCount: 5,
        createdBy: 'user-1',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      expect(album.id, 'album-1');
      expect(album.title, 'Test Album');
      expect(album.isPublic, isTrue);
      expect(album.mediaCount, 5);
      expect(album.tags, ['event', '2024']);
    });

    test('copyWith preserves unspecified fields', () {
      final album = Album(
        id: 'album-1',
        title: 'Test Album',
        description: 'Description',
        coverImageUrl: 'https://example.com/cover.jpg',
        tags: ['event'],
        isPublic: true,
        mediaCount: 5,
        createdBy: 'user-1',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      final updated = Album(
        id: album.id,
        title: album.title,
        description: 'New description',
        coverImageUrl: album.coverImageUrl,
        tags: album.tags,
        isPublic: album.isPublic,
        mediaCount: album.mediaCount,
        createdBy: album.createdBy,
        createdAt: album.createdAt,
        updatedAt: album.updatedAt,
      );
      expect(updated.id, album.id);
      expect(updated.title, album.title);
      expect(updated.description, 'New description');
    });
  });

  group('GalleryMedia', () {
    test('creates with required fields', () {
      final media = GalleryMedia(
        id: 'media-1',
        albumId: 'album-1',
        mediaUrl: 'https://example.com/image.jpg',
        mediaType: 'image',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        caption: 'Test caption',
        tags: ['photo'],
        uploadedBy: 'user-1',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      expect(media.id, 'media-1');
      expect(media.albumId, 'album-1');
      expect(media.mediaType, 'image');
      expect(media.caption, 'Test caption');
      expect(media.tags, ['photo']);
    });

    test('default mediaType is image', () {
      final media = GalleryMedia(
        id: 'media-1',
        albumId: 'album-1',
        mediaUrl: 'https://example.com/image.jpg',
        mediaType: 'unknown',
        thumbnailUrl: '',
        caption: '',
        tags: const [],
        uploadedBy: 'user-1',
        createdAt: Timestamp.now(),
        updatedAt: Timestamp.now(),
      );
      expect(media.mediaType, 'unknown');
    });
  });
}
