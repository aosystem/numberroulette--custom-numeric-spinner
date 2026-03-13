import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:numberroulette/l10n/app_localizations.dart';
import 'package:numberroulette/ad_manager.dart';
import 'package:numberroulette/ad_banner_widget.dart';
import 'package:numberroulette/ad_ump_status.dart';
import 'package:numberroulette/model.dart';
import 'package:numberroulette/text_to_speech.dart';
import 'package:numberroulette/theme_color.dart';
import 'package:numberroulette/loading_screen.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});
  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late AdManager _adManager;
  late UmpConsentController _adUmp;
  AdUmpState _adUmpState = AdUmpState.initial;
  int _themeNumber = 0;
  String _languageCode = '';
  late ThemeColor _themeColor;
  final _inAppReview = InAppReview.instance;
  bool _isReady = false;
  bool _isFirst = true;
  //
  final TextEditingController _minController = TextEditingController();
  final TextEditingController _maxController = TextEditingController();
  List<TtsOption> _ttsVoices = const [];
  int _minNumber = 0;
  int _maxNumber = 5;
  int _positionReverse = 0;
  int _positionRandom = 0;
  int _fixBackground = 0;
  int _shortRotation = 0;
  double _maxSpeedDuration = 5.0;
  double _resultTextScale = 1.0;
  double _rouletteTextScale = 1.0;
  bool _ttsEnabled = true;
  String _ttsVoiceId = '';
  double _ttsVolume = 1.0;
  static const List<int> _percentOptions = [
    41,
    51,
    64,
    80,
    100,
    120,
    144,
    173,
    207,
    249,
    299,
    358,
    430,
    516,
    619,
    743,
    892,
    1070
  ];

  int _nearestIndexForScale(double scale) {
    final target = (scale * 100).round();
    int bestIdx = 0;
    int bestDiff = 1 << 30;
    for (int i = 0; i < _percentOptions.length; i++) {
      final d = (target - _percentOptions[i]).abs();
      if (d < bestDiff) {
        bestDiff = d;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  double _scaleForIndex(int index) {
    final i = index.clamp(0, _percentOptions.length - 1).toInt();
    return _percentOptions[i] / 100.0;
  }

  @override
  void initState() {
    super.initState();
    _initState();
  }

  Future<void> _initState() async {
    _adManager = AdManager();
    _themeNumber = Model.themeNumber;
    _languageCode = Model.languageCode;
    //
    _adUmp = UmpConsentController();
    _refreshConsentInfo();
    //
    _minController.text = Model.minNumber.toString();
    _maxController.text = Model.maxNumber.toString();
    //
    _minNumber = Model.minNumber;
    _maxNumber = Model.maxNumber;
    _positionReverse = Model.positionReverse;
    _positionRandom = Model.positionRandom;
    if (_positionReverse == 1 && _positionRandom == 1) {
      _positionRandom = 0;
      await Model.setPositionRandom(_positionRandom);
    }
    _fixBackground = Model.fixBackground;
    _shortRotation = Model.shortRotation;
    _maxSpeedDuration = Model.maxSpeedDuration;
    _resultTextScale = Model.resultTextScale;
    _rouletteTextScale = Model.rouletteTextScale;
    _ttsEnabled = Model.ttsEnabled;
    _ttsVoiceId = Model.ttsVoiceId;
    _ttsVolume = Model.ttsVolume;
    //speech
    await TextToSpeech.getInstance();
    _ttsVoices = TextToSpeech.ttsVoices;
    TextToSpeech.setVolume(_ttsVolume);
    TextToSpeech.setTtsVoiceId(_ttsVoiceId);
    //
    setState(() {
      _isReady = true;
    });
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _adManager.dispose();
    unawaited(TextToSpeech.stop());
    super.dispose();
  }

  Future<void> _refreshConsentInfo() async {
    _adUmpState = await _adUmp.updateConsentInfo(current: _adUmpState);
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _onTapPrivacyOptions() async {
    final err = await _adUmp.showPrivacyOptions();
    await _refreshConsentInfo();
    if (err != null && mounted) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l.cmpErrorOpeningSettings} ${err.message}')),
      );
    }
  }

  void _onApply() async {
    _minNumber = int.tryParse(_minController.text.trim()) ?? 0;
    _maxNumber = int.tryParse(_maxController.text.trim()) ?? (_minNumber + 1);
    if (_minNumber < 0) {
      _minNumber = 0;
    }
    if (_maxNumber <= _minNumber) {
      _maxNumber = _minNumber + 1;
    }
    if (_maxNumber - _minNumber >= 3600) {
      _maxNumber = _minNumber + 3599;
    }
    await Model.setMinNumber(_minNumber);
    await Model.setMaxNumber(_maxNumber);
    if (_positionReverse == 1 && _positionRandom == 1) {
      _positionRandom = 0;
    }
    await Model.setPositionReverse(_positionReverse);
    await Model.setPositionRandom(_positionRandom);
    await Model.setFixBackground(_fixBackground);
    await Model.setShortRotation(_shortRotation);
    await Model.setMaxSpeedDuration(_maxSpeedDuration);
    await Model.setResultTextScale(_resultTextScale);
    await Model.setRouletteTextScale(_rouletteTextScale);
    await Model.setTtsEnabled(_ttsEnabled);
    await Model.setTtsVoiceId(_ttsVoiceId);
    await Model.setTtsVolume(_ttsVolume);
    await TextToSpeech.setVolume(_ttsEnabled ? _ttsVolume : 0.0);
    await Model.setThemeNumber(_themeNumber);
    await Model.setLanguageCode(_languageCode);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const LoadingScreen();
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(themeNumber: _themeNumber, context: context);
    }
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: _themeColor.backColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: _themeColor.appBarForegroundColor,
        leading: IconButton(
          icon: Icon(Icons.close, color: _themeColor.appBarForegroundColor),
          onPressed: () => Navigator.of(context).pop()),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: _themeColor.appBarForegroundColor),
            onPressed: _onApply),
          const SizedBox(width: 24),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildNumberRange(l),
                      _buildTextSize(l),
                      _buildOrder(l),
                      _buildFix(l),
                      _buildRotation(l),
                      _buildSpeechSettings(l),
                      _buildTheme(l),
                      _buildLanguage(l),
                      _buildReview(l),
                      _buildCmpSection(l),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdBannerWidget(adManager: _adManager),
    );
  }

  Widget _buildNumberRange(AppLocalizations l) {
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.numberRange),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    decoration: InputDecoration(
                      labelText: l.min,
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    decoration: InputDecoration(
                      labelText: l.max,
                      border: OutlineInputBorder(),
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSize(AppLocalizations l) {
    return Column(children: [
      Card(
        margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
              child: Text(l.textSizeAdjustResult),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Text('${_percentOptions[_nearestIndexForScale(_resultTextScale)]}%'),
                  Expanded(
                    child: Slider(
                      value: _nearestIndexForScale(_resultTextScale).toDouble(),
                      min: 0,
                      max: (_percentOptions.length - 1).toDouble(),
                      divisions: _percentOptions.length - 1,
                      label: '${_percentOptions[_nearestIndexForScale(_resultTextScale)]}%',
                      onChanged: (double value) {
                        final idx = value.round();
                        setState(() {
                          _resultTextScale = _scaleForIndex(idx);
                        });
                      }
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
      ),
      Card(
        margin: const EdgeInsets.only(left: 0, top: 2, right: 0, bottom: 0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
              child: Text(l.textSizeAdjustRoulette),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  Text('${_percentOptions[_nearestIndexForScale(_rouletteTextScale)]}%'),
                  Expanded(
                    child: Slider(
                      value: _nearestIndexForScale(_rouletteTextScale).toDouble(),
                      min: 0,
                      max: (_percentOptions.length - 1).toDouble(),
                      divisions: _percentOptions.length - 1,
                      label: '${_percentOptions[_nearestIndexForScale(_rouletteTextScale)]}%',
                      onChanged: (double value) {
                        final idx = value.round();
                        setState(() {
                          _rouletteTextScale = _scaleForIndex(idx);
                        });
                      }
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
    ]);
  }

  Widget _buildOrder(AppLocalizations l) {
    return Column(children: [
      Card(
        margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: [
            SwitchListTile(
              contentPadding: const EdgeInsets.all(0),
              title: Text(l.reverseOrder,style: Theme.of(context).textTheme.bodyMedium),
              value: _positionReverse == 1,
              onChanged: (bool v) {
                setState(() {
                  _positionReverse = v ? 1 : 0;
                  if (v) {
                    _positionRandom = 0;
                  }
                });
              },
            ),
          ])
        )
      ),
      Card(
        margin: const EdgeInsets.only(left: 0, top: 2, right: 0, bottom: 0),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(children: [
            SwitchListTile(
              contentPadding: const EdgeInsets.all(0),
              title: Text(l.randomizeOrder,style: Theme.of(context).textTheme.bodyMedium),
              value: _positionRandom == 1,
              onChanged: (bool v) {
                setState(() {
                  _positionRandom = v ? 1 : 0;
                  if (v) {
                    _positionReverse = 0;
                  }
                });
              },
            ),
          ])
        )
      )
    ]);
  }

  Widget _buildFix(AppLocalizations l) {
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.only(left: 0, top: 0, right: 0, bottom: 0),
            title: Text(l.fixBackgroundWhileSpinning,style: Theme.of(context).textTheme.bodyMedium),
            value: _fixBackground == 1,
            onChanged: (bool v) {
              setState(() {
                _fixBackground = v ? 1 : 0;
              });
            },
          ),
        ])
      )
    );
  }

  Widget _buildRotation(AppLocalizations l) {
    return SizedBox(
      width: double.infinity,
      child: Column(children: [
        Card(
          margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
          ),
          color: _themeColor.cardColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
                child: Row(
                  children: [
                    Text(
                      l.rotationTime,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Row(
                  children: <Widget>[
                    Text(_maxSpeedDuration.toStringAsFixed(0)),
                    Expanded(
                      child: Slider(
                        value: _maxSpeedDuration,
                        min: 1,
                        max: 15,
                        divisions: 14,
                        label: _maxSpeedDuration.toStringAsFixed(0),
                        onChanged: (double value) {
                          setState(() {
                            _maxSpeedDuration = value;
                          });
                        }
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        ),
        Card(
          margin: const EdgeInsets.only(left: 0, top: 2, right: 0, bottom: 0),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          color: _themeColor.cardColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.shortenRotation,
                      ),
                    ),
                    Switch(
                      value: _shortRotation == 1,
                      onChanged: (bool value) {
                        setState(() {
                          _shortRotation = value ? 1 : 0;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          )
        ),
      ])
    );
  }

  Widget _buildSpeechSettings(AppLocalizations l) {
    if (_ttsVoices.isEmpty) {
      return SizedBox.shrink();
    }
    final l = AppLocalizations.of(context);
    return Column(children:[
      Card(
          margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
          ),
          color: _themeColor.cardColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.ttsEnabled,
                      ),
                    ),
                    Switch(
                      value: _ttsEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _ttsEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          )
      ),
      Card(
          margin: const EdgeInsets.only(left: 0, top: 2, right: 0, bottom: 0),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
              bottomLeft: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
          ),
          color: _themeColor.cardColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 12),
                child: Row(
                  children: [
                    Text(
                      l.ttsVolume,
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Row(
                  children: <Widget>[
                    Text(_ttsVolume.toStringAsFixed(1)),
                    Expanded(
                      child: Slider(
                        value: _ttsVolume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: _ttsVolume.toStringAsFixed(1),
                        onChanged: _ttsEnabled
                            ? (double value) {
                          setState(() {
                            _ttsVolume = double.parse(
                              value.toStringAsFixed(1),
                            );
                          });
                        }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
      ),
      Card(
          margin: const EdgeInsets.only(left: 0, top: 2, right: 0, bottom: 0),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          color: _themeColor.cardColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 16),
                child: DropdownButtonFormField<String>(
                  initialValue: () {
                    if (_ttsVoiceId.isNotEmpty && _ttsVoices.any((o) => o.id == _ttsVoiceId)) {
                      return _ttsVoiceId;
                    }
                    return _ttsVoices.first.id;
                  }(),
                  items: _ttsVoices
                      .map((o) => DropdownMenuItem<String>(value: o.id, child: Text(o.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) {
                      return;
                    }
                    setState(() => _ttsVoiceId = v);
                  },
                ),
              ),
            ],
          )
      )
    ]);
  }

  Widget _buildTheme(AppLocalizations l) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
        color: _themeColor.cardColor,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 16, top: 0, right: 16, bottom: 0),
          title: Text(l.theme,style: Theme.of(context).textTheme.bodyMedium),
          trailing: DropdownButton<int>(
            value: _themeNumber,
            dropdownColor: _themeColor.dropdownColor,
            items: [
              DropdownMenuItem(value: 0, child: Text(l.systemSetting)),
              DropdownMenuItem(value: 1, child: Text(l.lightTheme)),
              DropdownMenuItem(value: 2, child: Text(l.darkTheme)),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              setState(() {
                _themeNumber = value;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLanguage(AppLocalizations l) {
    final Map<String,String> languageNames = {
      'af': 'af: Afrikaans',
      'ar': 'ar: العربية',
      'bg': 'bg: Български',
      'bn': 'bn: বাংলা',
      'bs': 'bs: Bosanski',
      'ca': 'ca: Català',
      'cs': 'cs: Čeština',
      'da': 'da: Dansk',
      'de': 'de: Deutsch',
      'el': 'el: Ελληνικά',
      'en': 'en: English',
      'es': 'es: Español',
      'et': 'et: Eesti',
      'fa': 'fa: فارسی',
      'fi': 'fi: Suomi',
      'fil': 'fil: Filipino',
      'fr': 'fr: Français',
      'gu': 'gu: ગુજરાતી',
      'he': 'he: עברית',
      'hi': 'hi: हिन्दी',
      'hr': 'hr: Hrvatski',
      'hu': 'hu: Magyar',
      'id': 'id: Bahasa Indonesia',
      'it': 'it: Italiano',
      'ja': 'ja: 日本語',
      'km': 'km: ខ្មែរ',
      'kn': 'kn: ಕನ್ನಡ',
      'ko': 'ko: 한국어',
      'lt': 'lt: Lietuvių',
      'lv': 'lv: Latviešu',
      'ml': 'ml: മലയാളം',
      'mr': 'mr: मराठी',
      'ms': 'ms: Bahasa Melayu',
      'my': 'my: မြန်မာ',
      'ne': 'ne: नेपाली',
      'nl': 'nl: Nederlands',
      'or': 'or: ଓଡ଼ିଆ',
      'pa': 'pa: ਪੰਜਾਬੀ',
      'pl': 'pl: Polski',
      'pt': 'pt: Português',
      'ro': 'ro: Română',
      'ru': 'ru: Русский',
      'si': 'si: සිංහල',
      'sk': 'sk: Slovenčina',
      'sr': 'sr: Српски',
      'sv': 'sv: Svenska',
      'sw': 'sw: Kiswahili',
      'ta': 'ta: தமிழ்',
      'te': 'te: తెలుగు',
      'th': 'th: ไทย',
      'tl': 'tl: Tagalog',
      'tr': 'tr: Türkçe',
      'uk': 'uk: Українська',
      'ur': 'ur: اردو',
      'uz': 'uz: Oʻzbekcha',
      'vi': 'vi: Tiếng Việt',
      'zh': 'zh: 中文',
      'zu': 'zu: isiZulu',
    };
    final TextTheme t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l.language,
                style: t.bodyMedium,
              ),
            ),
            DropdownButton<String?>(
              value: _languageCode,
              items: [
                DropdownMenuItem(value: '', child: Text('Default')),
                ...languageNames.entries.map((entry) => DropdownMenuItem<String?>(
                  value: entry.key,
                  child: Text(entry.value),
                )),
              ],
              onChanged: (String? value) {
                setState(() {
                  _languageCode = value ?? '';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview(AppLocalizations l) {
    final TextTheme t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.reviewApp, style: t.bodyMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.open_in_new, size: 16),
                  label: Text(l.reviewStore, style: t.bodySmall),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 12),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () async {
                    await _inAppReview.openStoreListing(
                      appStoreId: 'YOUR_APP_STORE_ID',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCmpSection(AppLocalizations l) {
    String statusLabel;
    IconData statusIcon;
    final showButton =
        _adUmpState.privacyStatus == PrivacyOptionsRequirementStatus.required;
    statusLabel = l.cmpCheckingRegion;
    statusIcon = Icons.help_outline;
    switch (_adUmpState.privacyStatus) {
      case PrivacyOptionsRequirementStatus.required:
        statusLabel = l.cmpRegionRequiresSettings;
        statusIcon = Icons.privacy_tip;
        break;
      case PrivacyOptionsRequirementStatus.notRequired:
        statusLabel = l.cmpRegionNoSettingsRequired;
        statusIcon = Icons.check_circle_outline;
        break;
      case PrivacyOptionsRequirementStatus.unknown:
        statusLabel = l.cmpRegionCheckFailed;
        statusIcon = Icons.error_outline;
        break;
    }
    return Card(
      margin: const EdgeInsets.only(left: 0, top: 12, right: 0, bottom: 0),
      color: _themeColor.cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Padding(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.cmpSettingsTitle,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(l.cmpConsentDescription,
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Center(
              child: Column(
                children: [
                  Chip(
                    avatar: Icon(statusIcon, size: 18),
                    label: Text(statusLabel),
                    side: BorderSide.none,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${l.cmpConsentStatusLabel} ${_adUmpState.consentStatus.localized(context)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (showButton)
                    Column(children: [
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _adUmpState.isChecking
                            ? null
                            : _onTapPrivacyOptions,
                        icon: const Icon(Icons.settings),
                        label: Text(_adUmpState.isChecking
                            ? l.cmpConsentStatusChecking
                            : l.cmpOpenConsentSettings),
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          side: BorderSide(
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed:
                            _adUmpState.isChecking ? null : _refreshConsentInfo,
                        icon: const Icon(Icons.refresh),
                        label: Text(l.cmpRefreshStatus),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await ConsentInformation.instance.reset();
                          await _refreshConsentInfo();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.cmpResetStatusDone)));
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(l.cmpResetStatus),
                      ),
                    ])
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
