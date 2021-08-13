library openprojectapp.globals;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences prefs;
final FlutterSecureStorage storage = FlutterSecureStorage();
final LocalAuthentication authentication = LocalAuthentication();
final DateFormat dateFormat = DateFormat.yMd();
