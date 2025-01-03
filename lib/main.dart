import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_try_thesis/firebase_options.dart';
import 'package:flutter_try_thesis/models/cache_manager/sqlite_operations/sqliteOperations.dart';
import 'package:flutter_try_thesis/routing/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");
  final sql = SqliteOperations();
  await sql.initDatabase();

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
  );

  runApp(MyRouter());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}
