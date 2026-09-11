import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const String _prefsKeyAnonymousId = 'anonymous_device_id';

/// A random, locally-generated identifier used to tag public/anonymous
/// measurements (guest mode) without collecting any personally
/// identifying information. It is NOT a hardware ID (IMEI/Android ID)
/// and is reset if the app is reinstalled — by design, for privacy.
class DeviceIdentity {
  DeviceIdentity._();

  static Future<String> getOrCreateAnonymousId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_prefsKeyAnonymousId);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_prefsKeyAnonymousId, id);
    }
    return id;
  }
}
