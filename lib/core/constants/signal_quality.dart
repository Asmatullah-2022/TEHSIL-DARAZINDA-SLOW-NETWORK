/// Normalized signal quality used across the app (map pins, dashboard,
/// dead-zone analysis). Derived from raw dBm/ASU values reported by the
/// OS — never fabricated. When the OS does not expose a value, callers
/// must use [SignalQuality.unknown] and surface "Not available on this
/// device" rather than guessing.
enum SignalQuality {
  unknown(0),
  veryWeak(1),
  weak(2),
  moderate(3),
  good(4);

  const SignalQuality(this.level);
  final int level;

  /// GSM/LTE/NR dBm ranges are broadly similar for a coarse 4-bucket UX
  /// classification. This is an approximation for display purposes only
  /// and is documented as such — it is not used for any official
  /// engineering measurement.
  factory SignalQuality.fromDbm(int? dbm) {
    if (dbm == null) return SignalQuality.unknown;
    if (dbm >= -80) return SignalQuality.good;
    if (dbm >= -95) return SignalQuality.moderate;
    if (dbm >= -110) return SignalQuality.weak;
    return SignalQuality.veryWeak;
  }

  bool get isPoor =>
      this == SignalQuality.veryWeak || this == SignalQuality.weak;
}
