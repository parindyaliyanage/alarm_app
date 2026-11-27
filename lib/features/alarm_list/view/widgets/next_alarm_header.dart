import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/alarm_model.dart';

/// Top section of the alarm list: streak + theme button, greeting and the
/// "Next wake-up" card.
class NextAlarmHeader extends StatefulWidget {
  final List<AlarmModel> alarms;

  /// Consecutive days the user has beaten their alarm. Hidden when 0.
  final int streakDays;

  /// Tapping the card opens the editor for this alarm.
  final void Function(AlarmModel alarm) onEdit;

  /// Palette button — open the theme picker.
  final VoidCallback onChangeTheme;

  const NextAlarmHeader({
    super.key,
    required this.alarms,
    required this.onEdit,
    required this.onChangeTheme,
    this.streakDays = 0,
  });

  @override
  State<NextAlarmHeader> createState() => _NextAlarmHeaderState();
}

class _NextAlarmHeaderState extends State<NextAlarmHeader> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Refresh the greeting and "Rings in" countdown every 30 seconds.
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    final next = findNextAlarm(widget.alarms, now);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopRow(
            streakDays: widget.streakDays,
            onChangeTheme: widget.onChangeTheme,
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '${_greeting(now)} 👋',
              style: TextStyle(color: p.textMuted, fontSize: 17),
            ),
          ),
          const SizedBox(height: 16),
          _WakeUpCard(
            alarm: next?.alarm,
            at: next?.at,
            now: now,
            onEdit: widget.onEdit,
          ),
        ],
      ),
    );
  }

  static String _greeting(DateTime now) {
    final h = now.hour;
    if (h >= 5 && h < 12) return 'Good morning';
    if (h >= 12 && h < 17) return 'Good afternoon';
    if (h >= 17 && h < 21) return 'Good evening';
    return 'Good night';
  }
}

/// Soonest upcoming ring time across all enabled alarms.
({AlarmModel alarm, DateTime at})? findNextAlarm(
  List<AlarmModel> alarms,
  DateTime now,
) {
  ({AlarmModel alarm, DateTime at})? best;
  for (final alarm in alarms.where((a) => a.isEnabled)) {
    final at = _nextOccurrence(alarm, now);
    if (at == null) continue;
    if (best == null || at.isBefore(best.at)) best = (alarm: alarm, at: at);
  }
  return best;
}

DateTime? _nextOccurrence(AlarmModel alarm, DateTime now) {
  final repeats = alarm.repeatDays.any((d) => d);
  // Check today + the next 7 days
  for (var offset = 0; offset <= 7; offset++) {
    final candidate = DateTime(
      now.year,
      now.month,
      now.day + offset,
      alarm.hour,
      alarm.minute,
    );
    if (!candidate.isAfter(now)) continue;
    // repeatDays index: 0 = Mon ... 6 = Sun; DateTime.weekday: 1 = Mon
    if (!repeats || alarm.repeatDays[candidate.weekday - 1]) return candidate;
  }
  return null;
}

String _formatTime12(int hour, int minute) {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h:${minute.toString().padLeft(2, '0')}';
}

String _period(int hour) => hour < 12 ? 'am' : 'pm';

// ── Top row: streak pill + theme button ──────────────────────────
class _TopRow extends StatelessWidget {
  final int streakDays;
  final VoidCallback onChangeTheme;
  const _TopRow({required this.streakDays, required this.onChangeTheme});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        const Spacer(),
        if (streakDays > 0) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: p.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_fire_department, color: p.primary, size: 20),
                const SizedBox(width: 6),
                Text(
                  '$streakDays',
                  style: TextStyle(
                    color: p.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  ' day streak',
                  style: TextStyle(color: p.textMuted, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
        // Theme picker
        GestureDetector(
          onTap: onChangeTheme,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.surface,
              shape: BoxShape.circle,
              border: Border.all(color: p.border),
            ),
            child: Icon(Icons.palette_outlined, color: p.highlight, size: 22),
          ),
        ),
      ],
    );
  }
}

// ── The "Next wake-up" card ──────────────────────────────────────
class _WakeUpCard extends StatelessWidget {
  final AlarmModel? alarm;
  final DateTime? at;
  final DateTime now;
  final void Function(AlarmModel alarm) onEdit;

  const _WakeUpCard({
    required this.alarm,
    required this.at,
    required this.now,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: alarm == null ? null : () => onEdit(alarm!),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: p.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              const Positioned(top: -70, right: -90, child: _Sun()),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: alarm == null ? const _NoAlarm() : _content(p),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(AppPalette p) {
    final alarm = this.alarm!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NEXT WAKE-UP',
          style: TextStyle(
            color: p.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              _formatTime12(alarm.hour, alarm.minute),
              style: TextStyle(
                color: p.text,
                fontSize: 80,
                height: 1.05,
                fontWeight: FontWeight.w800,
                letterSpacing: -3,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _period(alarm.hour),
              style: TextStyle(
                color: p.textMuted,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            style: TextStyle(color: p.textMuted, fontSize: 16),
            children: [
              const TextSpan(text: 'Rings in '),
              TextSpan(
                text: _countdown(at!.difference(now)),
                style: TextStyle(color: p.text, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _nudge(alarm, at!),
          style: TextStyle(
            color: p.highlight,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  static const _mathNudges = [
    'Warm up that brain: what\'s 17 × 4? 🧮',
    'Practise your times tables before bed. Bedzilla is watching.',
    'Quick, 48 + 76? You\'ll need that speed tomorrow.',
  ];

  static const _objectNudges = [
    'Decide where your object is now, so you\'re not hunting half asleep. 🔎',
    'Hide your target object somewhere far from the bed. Trust us.',
    'Pick a different room for your object. More steps, fewer snoozes.',
  ];

  static const _generalNudges = [
    'Do 10 squats when it rings. Your legs will thank you. 🏋️',
    'Drink a glass of water the moment you get up. 💧',
    'Open the curtains first thing and let the sun in. ☀️',
    'Try 5 jumping jacks before you check your phone.',
    'Think of one thing you\'re looking forward to tomorrow.',
    'Stretch like a dinosaur waking up. Rawr! 🦖',
  ];

  /// A short, playful tip for the next alarm. Picked from the alarm id and
  /// ring day so it stays the same between rebuilds.
  static String _nudge(AlarmModel alarm, DateTime at) {
    final specific = alarm.challengeType == AppConstants.mathChallenge
        ? _mathNudges
        : _objectNudges;
    final pool = [...specific, ..._generalNudges];
    final seed = alarm.id.hashCode ^ (at.year * 400 + at.month * 32 + at.day);
    return pool[seed.abs() % pool.length];
  }

  static String _countdown(Duration d) {
    // Round up so "rings in 0m" never shows while it's still upcoming
    final totalMinutes = (d.inSeconds / 60).ceil();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0) return '${m}m';
    return '${h}h ${m}m';
  }
}

/// Glowing sun in the top-right corner of the card that slowly breathes
/// (expands and contracts), with a halo ring pulsing slightly out of step.
class _Sun extends StatefulWidget {
  const _Sun();

  @override
  State<_Sun> createState() => _SunState();
}

class _SunState extends State<_Sun> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  late final Animation<double> _breath = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      width: 300,
      height: 300,
      child: AnimatedBuilder(
        animation: _breath,
        builder: (context, _) {
          final t = _breath.value; // 0 → 1 → 0 ...
          final sunScale = 0.92 + 0.10 * t; // 0.92 ↔ 1.02
          final haloScale = 0.96 + 0.08 * t; // 0.96 ↔ 1.04
          final glow = 0.20 + 0.20 * t; // glow brightens as it expands

          return Stack(
            alignment: Alignment.center,
            children: [
              // Halo ring
              Transform.scale(
                scale: haloScale,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: p.primary.withValues(alpha: 0.08 + 0.08 * t),
                    ),
                  ),
                ),
              ),
              // Sun
              Transform.scale(
                scale: sunScale,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(0.3, -0.5),
                      radius: 1.0,
                      colors: [
                        p.highlight.withValues(alpha: 0.75),
                        p.primary.withValues(alpha: 0.6),
                        p.accentContainer.withValues(alpha: 0.6),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: p.primary.withValues(alpha: glow),
                        blurRadius: 60,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NoAlarm extends StatelessWidget {
  const _NoAlarm();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NEXT WAKE-UP',
          style: TextStyle(
            color: p.primary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '--:--',
          style: TextStyle(
            color: p.border,
            fontSize: 80,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'No alarm set. Tap + to add one.',
          style: TextStyle(color: p.textMuted, fontSize: 16),
        ),
      ],
    );
  }
}
