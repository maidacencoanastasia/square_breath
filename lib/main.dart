import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  runApp(const SquareBreathApp());
}

enum SessionMode { rounds, timer }

enum BreathPhase {
  inhale('Inhale'),
  holdTop('Hold'),
  exhale('Exhale'),
  holdBottom('Hold');

  const BreathPhase(this.label);
  final String label;
}

class SquareBreathApp extends StatelessWidget {
  const SquareBreathApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF171A1F),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFB5C9FF),
        secondary: Color(0xFF9CB8FF),
        surface: Color(0xFF20242B),
      ),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Square Breath',
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.montserratTextTheme(baseTheme.textTheme),
      ),
      home: const SquareBreathingPage(),
    );
  }
}

class SquareBreathingPage extends StatefulWidget {
  const SquareBreathingPage({super.key});

  @override
  State<SquareBreathingPage> createState() => _SquareBreathingPageState();
}

class _SquareBreathingPageState extends State<SquareBreathingPage>
    with SingleTickerProviderStateMixin {
  static const int _phaseSeconds = 4;
  static const int _defaultTimerMinutes = 5;
  static const int _defaultRounds = 10;

  late final AnimationController _pulseController;

  SessionMode _mode = SessionMode.timer;
  BreathPhase _phase = BreathPhase.inhale;
  Timer? _sessionTicker;
  bool _running = false;

  int _phaseSecondsRemaining = _phaseSeconds;
  int _selectedRounds = _defaultRounds;
  int _selectedTimerMinutes = _defaultTimerMinutes;
  int _roundsCompleted = 0;
  int _totalSecondsRemaining = _defaultTimerMinutes * 60;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _phaseSeconds),
      value: 0,
    );
  }

  @override
  void dispose() {
    _stopSession();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startSession() async {
    if (_running) {
      return;
    }

    setState(() {
      _running = true;
      _phase = BreathPhase.inhale;
      _phaseSecondsRemaining = _phaseSeconds;
      _roundsCompleted = 0;
      _totalSecondsRemaining = _selectedTimerMinutes * 60;
      _pulseController.value = 0;
    });

    await WakelockPlus.enable();
    await _triggerHaptic();
    _runPhaseAnimation();

    _sessionTicker?.cancel();
    _sessionTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_running) {
        return;
      }

      setState(() {
        _phaseSecondsRemaining -= 1;
        if (_mode == SessionMode.timer) {
          _totalSecondsRemaining = (_totalSecondsRemaining - 1).clamp(0, 36000);
        }
      });

      final timerEnded =
          _mode == SessionMode.timer && _totalSecondsRemaining <= 0;
      if (timerEnded) {
        _stopSession();
        return;
      }

      if (_phaseSecondsRemaining <= 0) {
        _advancePhase();
      }
    });
  }

  Future<void> _stopSession() async {
    _sessionTicker?.cancel();
    _sessionTicker = null;

    await WakelockPlus.disable();

    if (!mounted) {
      return;
    }

    setState(() {
      _running = false;
      _phase = BreathPhase.inhale;
      _phaseSecondsRemaining = _phaseSeconds;
      _pulseController.value = 0;
    });
  }

  void _advancePhase() {
    final next = switch (_phase) {
      BreathPhase.inhale => BreathPhase.holdTop,
      BreathPhase.holdTop => BreathPhase.exhale,
      BreathPhase.exhale => BreathPhase.holdBottom,
      BreathPhase.holdBottom => BreathPhase.inhale,
    };

    if (next == BreathPhase.inhale && _mode == SessionMode.rounds) {
      _roundsCompleted += 1;
      if (_roundsCompleted >= _selectedRounds) {
        _stopSession();
        return;
      }
    }

    setState(() {
      _phase = next;
      _phaseSecondsRemaining = _phaseSeconds;
    });

    _triggerHaptic();
    _runPhaseAnimation();
  }

  void _runPhaseAnimation() {
    switch (_phase) {
      case BreathPhase.inhale:
        _pulseController.animateTo(
          1,
          duration: const Duration(seconds: _phaseSeconds),
          curve: Curves.easeInOut,
        );
      case BreathPhase.exhale:
        _pulseController.animateTo(
          0,
          duration: const Duration(seconds: _phaseSeconds),
          curve: Curves.easeInOut,
        );
      case BreathPhase.holdTop:
        _pulseController.value = 1;
      case BreathPhase.holdBottom:
        _pulseController.value = 0;
    }
  }

  Future<void> _triggerHaptic() async {
    try {
      final canVibrate = await Haptics.canVibrate();
      if (canVibrate) {
        await Haptics.vibrate(HapticsType.selection);
      }
    } catch (_) {
      // Ignore haptic exceptions to keep the breathing session uninterrupted.
    }
  }

  String _formatClock(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1E24), Color(0xFF111318)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  'Square Breathing',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 20),
                _buildModePicker(),
                const SizedBox(height: 14),
                _buildModeControl(),
                const SizedBox(height: 10),
                Text(
                  _mode == SessionMode.timer
                      ? 'Session ${_formatClock(_totalSecondsRemaining)}'
                      : 'Round ${_roundsCompleted + (_running ? 1 : 0)} of $_selectedRounds',
                  style: textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFA8B3C9),
                  ),
                ),
                const Spacer(),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final side = 120 + (120 * _pulseController.value);
                    return Container(
                      width: side,
                      height: side,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6ECFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          width: 2,
                          color: const Color(
                            0xFFE6ECFF,
                          ).withValues(alpha: 0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 40,
                            spreadRadius: 2,
                            color: const Color(0xFF9CB8FF).withValues(
                              alpha: 0.12 + (_pulseController.value * 0.14),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),
                Text(
                  _running ? _phase.label : 'Ready',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _running
                      ? '$_phaseSecondsRemaining s'
                      : 'Inhale 4s • Hold 4s • Exhale 4s • Hold 4s',
                  style: textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFFD2D8E6),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _running ? _stopSession : _startSession,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFFDEE6FF),
                      foregroundColor: const Color(0xFF161A22),
                      textStyle: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    child: Text(_running ? 'Stop Session' : 'Start Session'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModePicker() {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<SessionMode>(
        segments: const [
          ButtonSegment(value: SessionMode.timer, label: Text('Fixed Timer')),
          ButtonSegment(value: SessionMode.rounds, label: Text('Rounds')),
        ],
        selected: {_mode},
        expandedInsets: EdgeInsets.zero,
        onSelectionChanged: _running
            ? null
            : (selection) {
                setState(() {
                  _mode = selection.first;
                  if (_mode == SessionMode.timer) {
                    _totalSecondsRemaining = _selectedTimerMinutes * 60;
                  }
                });
              },
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(
            Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  Widget _buildModeControl() {
    if (_mode == SessionMode.timer) {
      return _buildControlCard(
        label: 'Minutes',
        value: _selectedTimerMinutes,
        minValue: 1,
        maxValue: 60,
        onChanged: (value) {
          setState(() {
            _selectedTimerMinutes = value;
            _totalSecondsRemaining = value * 60;
          });
        },
      );
    }

    return _buildControlCard(
      label: 'Rounds',
      value: _selectedRounds,
      minValue: 1,
      maxValue: 50,
      onChanged: (value) {
        setState(() {
          _selectedRounds = value;
        });
      },
    );
  }

  Widget _buildControlCard({
    required String label,
    required int value,
    required int minValue,
    required int maxValue,
    required ValueChanged<int> onChanged,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF222731).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFBFC9DE).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _running || value <= minValue
                    ? null
                    : () => onChanged(value - 1),
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 36,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: _running || value >= maxValue
                    ? null
                    : () => onChanged(value + 1),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
