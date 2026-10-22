import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // App Check blocks scripts / modified APKs once enforcement is switched on
  // in the Firebase console (Play Integrity on Android, App Attest on iOS).
  // Debug builds use the debug provider; register the debug token printed in
  // logcat in the console to test against an enforced project.
  await FirebaseAppCheck.instance.activate(
    providerAndroid: kReleaseMode ? const AndroidPlayIntegrityProvider() : const AndroidDebugProvider(),
    providerApple: kReleaseMode ? const AppleAppAttestWithDeviceCheckFallbackProvider() : const AppleDebugProvider(),
  );
  runApp(const App());
}
