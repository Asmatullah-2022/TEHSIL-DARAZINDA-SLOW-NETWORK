import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_localizations_en.dart';
import 'app_localizations_ur.dart';

/// Hand-written localization lookup (English/Urdu). This mirrors the
/// shape Flutter's `flutter gen-l10n` would generate from
/// `lib/core/localization/arb/*.arb`; the ARB files remain the source of
/// truth for translators. Written by hand here only because this
/// environment has no Flutter SDK to run codegen — regenerating with
/// `flutter gen-l10n` (see l10n.yaml) is safe and will replace this file
/// with an equivalent generated one.
abstract class AppLocalizations {
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? result =
        Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(result != null, 'No AppLocalizations found in context');
    return result!;
  }

  String get appName;
  String get appTagline;
  String get onboardingTitle1;
  String get onboardingBody1;
  String get onboardingTitle2;
  String get onboardingBody2;
  String get onboardingTitle3;
  String get onboardingBody3;
  String get onboardingTitle4;
  String get onboardingBody4;
  String get skip;
  String get next;
  String get getStarted;
  String get continueAsGuest;
  String get signIn;
  String get signUp;
  String get email;
  String get password;
  String get home;
  String get quickTest;
  String get signalMap;
  String get reportProblem;
  String get statistics;
  String get myReports;
  String get currentOperator;
  String get networkType;
  String get signalStrength;
  String get gpsStatus;
  String get lastMeasurement;
  String get notAvailableOnDevice;
  String get download;
  String get upload;
  String get ping;
  String get gpsAccuracy;
  String get startTest;
  String get testing;
  String get pendingSync;
  String get synced;
  String get probableConnectivityProblem;
  String get disclaimerNoBoost;
  String get settings;
  String get language;
  String get privacyPolicy;
  String get deleteMyData;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ur'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    final AppLocalizations localizations = switch (locale.languageCode) {
      'ur' => AppLocalizationsUr(),
      _ => AppLocalizationsEn(),
    };
    return SynchronousFuture<AppLocalizations>(localizations);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
