import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String LANGUAGE_CODE = 'languageCode';

// Language codes
const String ENGLISH = 'en';
const String SPANISH = 'es';

Future<Locale> setLocale(String languageCode) async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  await _prefs.setString(LANGUAGE_CODE, languageCode);
  return _locale(languageCode);
}

Future<Locale> getLocale() async {
  SharedPreferences _prefs = await SharedPreferences.getInstance();
  String languageCode = _prefs.getString(LANGUAGE_CODE) ?? ENGLISH;
  return _locale(languageCode);
}

Locale _locale(String languageCode) {
  switch (languageCode) {
    case ENGLISH:
      return const Locale(ENGLISH, '');
    case SPANISH:
      return const Locale(SPANISH, "");
    default:
      return const Locale(ENGLISH, '');
  }
}

AppLocalizations translation(BuildContext context) {
  return AppLocalizations.of(context)!;
}

String getPreference(AppLocalizations localization, String preferenceKey) {
  switch (preferenceKey) {
    case 'canNotTravelWithPets':
      return localization.noPets;
    case 'listenToMusic':
      return localization.listenToMusic;
    case 'noSmoking':
      return localization.noSmoking;
    case 'talkTooMuch':
      return localization.talkTooMuch;
    default:
      return preferenceKey;
  }
}
