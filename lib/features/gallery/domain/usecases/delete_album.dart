import '../../domain/repositories/gallery_repository.dart';

class DeleteAlbum {
  final GalleryRepository repository;
  DeleteAlbum(this.repository);
  Future<void> call(String albumId) => repository.deleteAlbum(albumId);
}
