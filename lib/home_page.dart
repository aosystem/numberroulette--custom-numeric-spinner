import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


import 'package:numberroulette/l10n/app_localizations.dart';
import 'package:numberroulette/ad_manager.dart';
import 'package:numberroulette/ad_banner_widget.dart';
import 'package:numberroulette/parse_locale_tag.dart';
import 'package:numberroulette/roulette_painter.dart';
import 'package:numberroulette/setting_page.dart';
import 'package:numberroulette/text_to_speech.dart';
import 'package:numberroulette/model.dart';
import 'package:numberroulette/const_value.dart';
import 'package:numberroulette/theme_color.dart';
import 'package:numberroulette/theme_mode_number.dart';
import 'package:numberroulette/loading_screen.dart';
import 'package:numberroulette/main.dart';
import 'package:numberroulette/three_phase_roulette_curve.dart';

class MainHomePage extends StatefulWidget {
  const MainHomePage({super.key});
  @override
  State<MainHomePage> createState() => _MainHomePageState();
}

class _MainHomePageState extends State<MainHomePage> with SingleTickerProviderStateMixin {
  late AdManager _adManager;
  late ThemeColor _themeColor;
  bool _isReady = false;
  bool _isFirst = true;
  //
  late AnimationController _animationController;
  late Animation<double> _animation;
  int? _currentNumber;
  String? _resultText;
  Color? _currentBackgroundColor;
  final _random = Random();
  List<int> _orderedNumbers = [];

  @override
  void initState() {
    super.initState();
    _initState();
  }

  Future<void> _initState() async {
    _adManager = AdManager();
    await TextToSpeech.applyPreferences(Model.ttsVoiceId,Model.ttsVolume);
    _rebuildOrderedNumbers();
    _updateVisualForAngle(0);
    _animationController =
    AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _determineWinner();
        }
      });
    _animation = Tween<double>(begin: 0, end: 360 * 20).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
    if (mounted) {
      setState(() {
        _isReady = true;
      });
    }
  }

  void _rebuildOrderedNumbers() {
    final minN = Model.minNumber;
    final maxN = Model.maxNumber;
    var list = List<int>.generate(maxN - minN + 1, (i) => minN + i);
    if (Model.positionRandom == 1) {
      list.shuffle(_random);
    } else if (Model.positionReverse == 1) {
      list = list.reversed.toList();
    }
    _orderedNumbers = list;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _adManager.dispose();
    TextToSpeech.stop();
    super.dispose();
  }

  void _onClickStart() {
    setState(() {
      _resultText = null;
    });
    final double scale = (Model.shortRotation == 1) ? 0.1 : 1.0;
    final double easeInDuration = 1.0 * scale;
    final double linearDuration = Model.maxSpeedDuration * scale;
    final double easeOutDuration = 8.0 * scale;
    final double totalDuration = easeInDuration + linearDuration + easeOutDuration;
    _animationController.duration = Duration(milliseconds: (totalDuration * 1000).round());
    const double baseEaseIn = 1.0;
    const double baseLinearDuration = 5.0;
    const double baseEaseOut = 8.0;
    const double baseTotalDuration = baseEaseIn + baseLinearDuration + baseEaseOut;
    const double baseRotationAmount = 360 * 28;
    final double targetRotationAmount = baseRotationAmount * (totalDuration / baseTotalDuration);
    final double randomExtraRotation = 360 * (_random.nextDouble() - 0.5);
    final double beginAngle = _animation.value;
    final double endAngle = beginAngle + targetRotationAmount + randomExtraRotation;
    _animation = Tween<double>(begin: beginAngle, end: endAngle).animate(CurvedAnimation(
      parent: _animationController,
      curve: ThreePhaseRouletteCurve(
        easeInDuration: easeInDuration,
        linearDuration: linearDuration,
        easeOutDuration: easeOutDuration,
      ),
    ));
    _animationController.forward(from: 0.0);
  }

  void _updateCurrentNumber() {
    if (_orderedNumbers.isEmpty) return;
    final double currentAngle = _animation.value;
    final double effectiveAngle = (360 - (currentAngle % 360) + 270) % 360;

    final int count = _orderedNumbers.length;
    final double sweep = 360.0 / count;
    int index = (effectiveAngle / sweep).floor();
    if (index < 0 || index >= count) index = index % count;
    final number = _orderedNumbers[index];
    _currentNumber = number;
    final colorIdx = index % ConstValue.colorLight.length;
    final Color segColor = ConstValue.colorLight[colorIdx];
    if (_animationController.isAnimating && Model.fixBackground == 1) {
      _currentBackgroundColor = ConstValue.fixedBgColor;
    } else {
      _currentBackgroundColor = segColor;
    }
  }

  void _determineWinner() {
    _updateCurrentNumber();
    final result = _currentNumber?.toString();
    setState(() {
      _resultText = result;
    });
    if (result != null && Model.ttsEnabled && Model.ttsVolume > 0.0) {
      unawaited(TextToSpeech.speak(result));
    }
  }

  void _updateVisualForAngle(double angle) {
    if (_orderedNumbers.isEmpty) return;
    final double effectiveAngle = (360 - (angle % 360) + 270) % 360;
    final int count = _orderedNumbers.length;
    final double sweep = 360.0 / count;
    int index = (effectiveAngle / sweep).floor();
    if (index < 0 || index >= count) {
      index = index % count;
    }
    final number = _orderedNumbers[index];
    setState(() {
      _currentNumber = number;
      final Color segColor =
      ConstValue.colorLight[index % ConstValue.colorLight.length];
      _currentBackgroundColor = segColor;
      _resultText ??= number.toString();
    });
  }

  Future<void> _openSetting() async {
    final updated = await Navigator.push<bool>(context,MaterialPageRoute(builder: (_) => const SettingPage()));
    if (!mounted) {
      return;
    }
    if (updated == true) {
      final mainState = context.findAncestorStateOfType<MainAppState>();
      if (mainState != null) {
        mainState
          ..themeMode = ThemeModeNumber.numberToThemeMode(Model.themeNumber)
          ..locale = parseLocaleTag(Model.languageCode)
          ..setState(() {});
      }
      await TextToSpeech.applyPreferences(Model.ttsVoiceId,Model.ttsVolume);
      _rebuildOrderedNumbers();
      _updateVisualForAngle(_animation.value);
      _isFirst = true;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady == false) {
      return const LoadingScreen();
    }
    if (_isFirst) {
      _isFirst = false;
      _themeColor = ThemeColor(themeNumber: Model.themeNumber, context: context);
    }
    final l = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        _updateCurrentNumber();
        return Scaffold(
          backgroundColor: _currentBackgroundColor,
          appBar: AppBar(
            backgroundColor: _currentBackgroundColor,
            elevation: 0,
            actions: [
              IconButton(
                  icon: Icon(Icons.settings, color: _themeColor.mainForeColor),
                  onPressed: _openSetting
              ),
              const SizedBox(width: 10),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Column(children: [
                  Visibility(
                    visible: _animationController.isAnimating || _resultText != null,
                    maintainState: true,
                    maintainAnimation: true,
                    maintainSize: true,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 10),
                      child: Text(
                        _animationController.isAnimating
                            ? '${_currentNumber ?? ''}'
                            : (_resultText ?? ''),
                        style: GoogleFonts.outfit(
                          fontSize: 50.0 * Model.resultTextScale,
                          height: 1.0,
                          color: _themeColor.mainResultForeColor,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: RoulettePainter(
                              animationValue: _animation.value,
                              numbers: _orderedNumbers,
                              colorLight: ConstValue.colorLight,
                              colorDark: ConstValue.colorDark,
                              boardFontScale: Model.rouletteTextScale,
                              progress: _animationController.value,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: AnimatedOpacity(
                              opacity: _animationController.isAnimating ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 600),
                              child: GestureDetector(
                                onTap: _onClickStart,
                                child: Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF000000)
                                        .withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    l.rouletteStart,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                ]),
              ],
            ),
          ),
          bottomNavigationBar: AdBannerWidget(adManager: _adManager),
        );
      },
    );
  }
}
