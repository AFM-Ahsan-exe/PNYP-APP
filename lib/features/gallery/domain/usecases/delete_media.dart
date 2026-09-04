import '../../domain/repositories/gallery_repository.dart';

class DeleteMedia {
  final GalleryRepository repository;
  DeleteMedia(this.repository);
  Future<void> call(String mediaId) => repository.deleteMedia(mediaId);
}
