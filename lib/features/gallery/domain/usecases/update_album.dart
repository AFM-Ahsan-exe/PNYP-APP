import '../repositories/gallery_repository.dart';

class UpdateAlbum {
  final GalleryRepository repository;
  UpdateAlbum(this.repository);
  Future<void> call(String albumId, Map<String, dynamic> data) =>
      repository.updateAlbum(albumId, data);
}
