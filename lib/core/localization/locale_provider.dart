import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _prefsKeyLocale = 'app_locale_code';

/// Persists the user's language choice (English/Urdu) and exposes it as
/// a [Locale]. Urdu (`ur`) triggers RTL automatically via Flutter's
/// built-in bidi text direction resolution for the locale.
class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _restore();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKeyLocale);
    if (code != null) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyLocale, locale.languageCode);
  }
}

final StateNotifierProvider<LocaleNotifier, Locale> localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

const List<Locale> supportedLocales = <Locale>[
  Locale('en'),
  Locale('ur'),
];
