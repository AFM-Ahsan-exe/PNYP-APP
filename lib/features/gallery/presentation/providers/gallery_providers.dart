import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/gallery_repository_impl.dart';
import '../../domain/entities/gallery_item.dart';
import '../../domain/repositories/gallery_repository.dart';
import '../../domain/usecases/add_media.dart';
import '../../domain/usecases/create_album.dart';
import '../../domain/usecases/update_album.dart';
import '../../domain/usecases/delete_album.dart';
import '../../domain/usecases/delete_media.dart';
import '../../domain/usecases/get_album_detail.dart';
import '../../domain/usecases/get_album_media.dart';
import '../../domain/usecases/get_albums.dart';
import '../../domain/usecases/get_albums_page.dart';
import '../../domain/usecases/get_media_page.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  return GalleryRepositoryImpl(ref.watch(firestoreProvider));
});

final getAlbumsProvider = Provider<GetAlbums>((ref) {
  return GetAlbums(ref.watch(galleryRepositoryProvider));
});

final getAlbumDetailProvider = Provider<GetAlbumDetail>((ref) {
  return GetAlbumDetail(ref.watch(galleryRepositoryProvider));
});

final getAlbumMediaProvider = Provider<GetAlbumMedia>((ref) {
  return GetAlbumMedia(ref.watch(galleryRepositoryProvider));
});

final createAlbumProvider = Provider<CreateAlbum>((ref) {
  return CreateAlbum(ref.watch(galleryRepositoryProvider));
});

final updateAlbumProvider = Provider<UpdateAlbum>((ref) {
  return UpdateAlbum(ref.watch(galleryRepositoryProvider));
});

final addMediaProvider = Provider<AddMedia>((ref) {
  return AddMedia(ref.watch(galleryRepositoryProvider));
});

final deleteMediaProvider = Provider<DeleteMedia>((ref) {
  return DeleteMedia(ref.watch(galleryRepositoryProvider));
});

final deleteAlbumProvider = Provider<DeleteAlbum>((ref) {
  return DeleteAlbum(ref.watch(galleryRepositoryProvider));
});

final getAlbumsPageProvider = Provider<GetAlbumsPage>((ref) {
  return GetAlbumsPage(ref.watch(galleryRepositoryProvider));
});

final getMediaPageProvider = Provider<GetMediaPage>((ref) {
  return GetMediaPage(ref.watch(galleryRepositoryProvider));
});

final albumsProvider = StreamProvider.autoDispose<List<Album>>((ref) {
  return ref.watch(galleryRepositoryProvider).watchAlbums();
});

final albumDetailProvider = FutureProvider.autoDispose.family<Album?, String>((
  ref,
  albumId,
) async {
  return ref.watch(getAlbumDetailProvider)(albumId);
});

final albumMediaProvider = FutureProvider.autoDispose
    .family<List<GalleryMedia>, String>((ref, albumId) async {
      return ref.watch(getAlbumMediaProvider)(albumId);
    });