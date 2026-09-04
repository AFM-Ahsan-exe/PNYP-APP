import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logLogin({String? method}) async {
    await _analytics.logLogin(loginMethod: method ?? 'email');
  }

  static Future<void> logSignUp({String? method}) async {
    await _analytics.logSignUp(signUpMethod: method ?? 'email');
  }

  static Future<void> logEventRegistration(String eventId) async {
    await _analytics.logEvent(
      name: 'event_registration',
      parameters: {'event_id': eventId},
    );
  }

  static Future<void> logEventCancellation(String eventId) async {
    await _analytics.logEvent(
      name: 'event_cancellation',
      parameters: {'event_id': eventId},
    );
  }

  static Future<void> logVolunteerApplication(String opportunityId) async {
    await _analytics.logEvent(
      name: 'volunteer_application',
      parameters: {'opportunity_id': opportunityId},
    );
  }

  static Future<void> logNewsView(String articleId) async {
    await _analytics.logEvent(
      name: 'news_view',
      parameters: {'article_id': articleId},
    );
  }

  static Future<void> logDocumentDownload(String documentId) async {
    await _analytics.logEvent(
      name: 'document_download',
      parameters: {'document_id': documentId},
    );
  }

  static Future<void> logGalleryView(String albumId) async {
    await _analytics.logEvent(
      name: 'gallery_view',
      parameters: {'album_id': albumId},
    );
  }

  static Future<void> logProfileUpdate() async {
    await _analytics.logEvent(name: 'profile_update');
  }

  static Future<void> logSearch(String query) async {
    await _analytics.logEvent(
      name: 'search',
      parameters: {'search_term': query},
    );
  }
}
