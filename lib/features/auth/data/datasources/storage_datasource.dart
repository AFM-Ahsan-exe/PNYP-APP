import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageDataSource {
  final FirebaseStorage _storage;

  StorageDataSource(this._storage);

  Future<String> uploadFile({
    required String path,
    required File file,
    required String contentType,
  }) async {
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: contentType);
    final uploadTask = ref.putFile(file, metadata);
    final snapshot = await uploadTask;
    return snapshot.ref.fullPath;
  }

  Future<String> getDownloadUrl(String path) async {
    final ref = _storage.ref().child(path);
    return ref.getDownloadURL();
  }
}
