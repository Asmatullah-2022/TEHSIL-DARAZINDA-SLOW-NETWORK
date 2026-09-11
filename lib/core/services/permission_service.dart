import 'package:permission_handler/permission_handler.dart';

/// Requests the `READ_PHONE_STATE` runtime permission (maps to
/// `Permission.phone` in permission_handler) needed to read operator
/// name, network type, and signal strength via TelephonyManager.
///
/// This is genuinely required: neither Geolocator (which only requests
/// location permissions) nor any other plugin in this app requests
/// phone-state access, and the native Kotlin telephony reader
/// (`MainActivity.kt`) silently returns null signal/operator fields
/// when the permission is missing rather than crashing — so without an
/// explicit request here, telephony data would permanently show "Not
/// available on this device" on every real install.
class PermissionService {
  /// Returns true if permission is granted (either already, or just
  /// now). Never throws — a denial simply means telephony fields will
  /// read as unavailable, which the rest of the app already handles.
  Future<bool> ensurePhoneStatePermission() async {
    final status = await Permission.phone.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) return false;

    final result = await Permission.phone.request();
    return result.isGranted;
  }

  Future<bool> get isPhoneStatePermanentlyDenied async {
    return (await Permission.phone.status).isPermanentlyDenied;
  }
}
