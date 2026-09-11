import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

final _log = Logger();

/// Raw telephony reading straight from the OS. Every field is nullable
/// because not every device/carrier/Android version exposes every
/// metric — callers must render "Not available on this device" for
/// nulls, never invent a value.
class TelephonyReading {
  const TelephonyReading({
    this.operatorName,
    this.networkType,
    this.simCountryIso,
    this.signalDbm,
    this.signalAsu,
    this.hasPhoneStatePermission = false,
    this.hasLocationPermission = false,
  });

  final String? operatorName;
  final String? networkType;
  final String? simCountryIso;
  final int? signalDbm;
  final int? signalAsu;
  final bool hasPhoneStatePermission;
  final bool hasLocationPermission;

  factory TelephonyReading.unavailable() => const TelephonyReading();
}

/// Bridges to native Android code (see `MainActivity.kt`) via a
/// MethodChannel to read TelephonyManager data. On iOS/web this always
/// returns [TelephonyReading.unavailable] since cellular signal APIs
/// are not exposed there — the UI already handles that as "Not
/// available on this device".
class TelephonyDataSource {
  static const MethodChannel _channel =
      MethodChannel('pk.darazindaconnect.app/telephony');

  Future<TelephonyReading> getReading() async {
    try {
      final Map<dynamic, dynamic>? result =
          await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getTelephonyInfo',
      );
      if (result == null) return TelephonyReading.unavailable();

      return TelephonyReading(
        operatorName: result['operatorName'] as String?,
        networkType: result['networkType'] as String?,
        simCountryIso: result['simCountryIso'] as String?,
        signalDbm: result['signalDbm'] as int?,
        signalAsu: result['signalAsu'] as int?,
        hasPhoneStatePermission:
            (result['hasPhoneStatePermission'] as bool?) ?? false,
        hasLocationPermission:
            (result['hasLocationPermission'] as bool?) ?? false,
      );
    } on PlatformException catch (error) {
      _log.w('Telephony channel error: ${error.message}');
      return TelephonyReading.unavailable();
    } catch (error) {
      // Not implemented on this platform (iOS/web) — expected.
      return TelephonyReading.unavailable();
    }
  }
}
