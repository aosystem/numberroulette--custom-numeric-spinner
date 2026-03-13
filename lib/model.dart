import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:numberroulette/l10n/app_localizations.dart';

class Model {
  Model._();

  static const String _prefMinNumber = 'minNumber';
  static const String _prefMaxNumber = 'maxNumber';
  static const String _prefPositionReverse = 'positionReverse';
  static const String _prefPositionRandom = 'positionRandom';
  static const String _prefFixBackground = 'fixBackground';
  static const String _prefShortRotation = 'shortRotation';
  static const String _prefMaxSpeedDuration = 'maxSpeedDuration';
  static const String _prefResultTextScale = 'resultTextScale';
  static const String _prefRouletteTextScale = 'rouletteTextScale';
  static const String _prefTtsEnabled = 'ttsEnabled';
  static const String _prefTtsVoiceId = 'ttsVoiceId';
  static const String _prefTtsVolume = 'ttsVolume';
  static const String _prefThemeNumber = 'themeNumber';
  static const String _prefLanguageCode = 'languageCode';

  static bool _ready = false;
  static int _minNumber = 0;
  static int _maxNumber = 5;
  static int _positionReverse = 0;
  static int _positionRandom = 0;
  static int _fixBackground = 0;
  static int _shortRotation = 0;
  static double _maxSpeedDuration = 5.0;
  static double _resultTextScale = 1.0;
  static double _rouletteTextScale = 1.0;
  static bool _ttsEnabled = true;
  static String _ttsVoiceId = '';
  static double _ttsVolume = 1.0;
  static int _themeNumber = 0;
  static String _languageCode = '';

  static int get minNumber => _minNumber;
  static int get maxNumber => _maxNumber;
  static int get positionReverse => _positionReverse;
  static int get positionRandom => _positionRandom;
  static int get fixBackground => _fixBackground;
  static int get shortRotation => _shortRotation;
  static double get maxSpeedDuration => _maxSpeedDuration;
  static double get resultTextScale => _resultTextScale;
  static double get rouletteTextScale => _rouletteTextScale;
  static bool get ttsEnabled => _ttsEnabled;
  static String get ttsVoiceId => _ttsVoiceId;
  static double get ttsVolume => _ttsVolume;
  static int get themeNumber => _themeNumber;
  static String get languageCode => _languageCode;

  static Future<void> ensureReady() async {
    if (_ready) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _minNumber = prefs.getInt(_prefMinNumber) ?? 0;
    _maxNumber = prefs.getInt(_prefMaxNumber) ?? 5;
    _positionReverse = (prefs.getInt(_prefPositionReverse) ?? 0).clamp(0, 1);
    _positionRandom = (prefs.getInt(_prefPositionRandom) ?? 0).clamp(0, 1);
    if (_positionReverse == 1 && _positionRandom == 1) {
      _positionRandom = 0;
      await prefs.setInt(_prefPositionRandom, _positionRandom);
    }
    _fixBackground = (prefs.getInt(_prefFixBackground) ?? 0).clamp(0, 1);
    _shortRotation = (prefs.getInt(_prefShortRotation) ?? 0).clamp(0, 1);
    _maxSpeedDuration = prefs.getDouble(_prefMaxSpeedDuration) ?? 5.0;
    _resultTextScale = prefs.getDouble(_prefResultTextScale) ?? 1.0;
    _rouletteTextScale = prefs.getDouble(_prefRouletteTextScale) ?? 1.0;
    _ttsEnabled = prefs.getBool(_prefTtsEnabled) ?? true;
    _ttsVoiceId = prefs.getString(_prefTtsVoiceId) ?? '';
    _ttsVolume = (prefs.getDouble(_prefTtsVolume) ?? 1.0).clamp(0, 1);
    _themeNumber = (prefs.getInt(_prefThemeNumber) ?? 0).clamp(0, 2);
    _languageCode = prefs.getString(_prefLanguageCode) ?? ui.PlatformDispatcher.instance.locale.languageCode;
    _languageCode = _resolveLanguageCode(_languageCode);
    _ready = true;
  }

  static String _resolveLanguageCode(String code) {
    final supported = AppLocalizations.supportedLocales;
    if (supported.any((l) => l.languageCode == code)) {
      return code;
    } else {
      return '';
    }
  }

  static Future<void> setMinNumber(int value) async {
    _minNumber = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefMinNumber, value);
  }

  static Future<void> setMaxNumber(int value) async {
    _maxNumber = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefMaxNumber, value);
  }

  static Future<void> setPositionReverse(int value) async {
    _positionReverse = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefPositionReverse, value);
  }

  static Future<void> setPositionRandom(int value) async {
    _positionRandom = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefPositionRandom, value);
  }

  static Future<void> setFixBackground(int value) async {
    _fixBackground = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefFixBackground, value);
  }

  static Future<void> setShortRotation(int value) async {
    _shortRotation = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefShortRotation, value);
  }

  static Future<void> setMaxSpeedDuration(double value) async {
    _maxSpeedDuration = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefMaxSpeedDuration, value);
  }

  static Future<void> setResultTextScale(double value) async {
    _resultTextScale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefResultTextScale, value);
  }

  static Future<void> setRouletteTextScale(double value) async {
    _rouletteTextScale = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefRouletteTextScale, value);
  }

  static Future<void> setTtsEnabled(bool value) async {
    _ttsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefTtsEnabled, value);
  }

  static Future<void> setTtsVoiceId(String value) async {
    _ttsVoiceId = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefTtsVoiceId, value);
  }

  static Future<void> setTtsVolume(double value) async {
    _ttsVolume = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefTtsVolume, value);
  }

  static Future<void> setThemeNumber(int value) async {
    _themeNumber = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefThemeNumber, value);
  }

  static Future<void> setLanguageCode(String value) async {
    _languageCode = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefLanguageCode, value);
  }

}
