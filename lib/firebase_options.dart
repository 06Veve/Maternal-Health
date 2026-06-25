import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Firebase configuration loaded from the untracked `.env` file.
///
/// Prefer replacing this file with `flutterfire configure` when native Firebase
/// configuration files are available.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return _options('WEB', appIdSuffix: 'WEB');

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _options('ANDROID', appIdSuffix: 'ANDROID');
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _options('IOS', appIdSuffix: 'IOS');
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return _options('WEB', appIdSuffix: 'WEB');
      default:
        throw UnsupportedError('Firebase is not configured for this platform.');
    }
  }

  static FirebaseOptions _options(
    String apiKeySuffix, {
    required String appIdSuffix,
  }) {
    final apiKey = dotenv.env['FIREBASE_API_KEY_$apiKeySuffix'];
    final appId =
        dotenv.env['FIREBASE_APP_ID_$appIdSuffix'] ??
        dotenv.env['FIREBASE_APP_ID_WEB'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];

    if ([
      apiKey,
      appId,
      projectId,
      messagingSenderId,
    ].any((value) => value == null || value.isEmpty)) {
      throw StateError('Firebase configuration is incomplete in .env.');
    }

    return FirebaseOptions(
      apiKey: apiKey!,
      appId: appId!,
      messagingSenderId: messagingSenderId!,
      projectId: projectId!,
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'],
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'],
    );
  }
}
