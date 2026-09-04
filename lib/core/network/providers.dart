import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cloud_functions_client.dart';

final cloudFunctionsClientProvider = Provider<CloudFunctionsClient>((ref) {
  final projectId = Firebase.app().options.projectId;
  return CloudFunctionsClient(projectId: projectId, region: 'us-central1');
});
