import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';

/// First-launch theme picker, hosted by Bedzilla.
///
/// The whole screen previews the selected theme live and Bedzilla swaps to
/// the matching colors.
class ThemePickerScreen extends StatefulWidget {
  /// True when opened from the home screen to change an existing choice.
  final bool isChanging;

  const ThemePickerScreen({super.key, this.isChanging = false});

  @override
  State<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends State<ThemePickerScreen> {
  late AppThemeChoice _selected =
      ThemeController.instance.value ?? AppThemeChoice.teal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode both mascots up front so switching themes is instant.
    for (final choice in AppThemeChoice.values) {
      precacheImage(AssetImage(choice.mascot), context);
    }
  }

  void _pick(AppThemeChoice choice) {
    setState(() => _selected = choice);
  }

  Future<void> _confirm() async {
    await ThemeController.instance.select(_selected);
    if (widget.isChanging && mounted) Navigator.of(context).pop();
    // On first launch, AlarmApp swaps to the alarm list automatically.
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      data: _selected.themeData,
      duration: const Duration(milliseconds: 400),
      child: Builder(
        builder: (context) {
          final p = context.palette;

          return Scaffold(
            backgroundColor: p.background,
            appBar: widget.isChanging
                ? AppBar(backgroundColor: Colors.transparent)
                : null,
            body: Stack(
              children: [
                // Soft background blobs for a friendly, bubbly feel
                Positioned(
                  top: -80,
                  left: -60,
                  child: _Blob(size: 220, color: p.accentContainer),
                ),
                Positioned(
                  bottom: 140,
                  right: -70,
                  child: _Blob(size: 180, color: p.accentContainer),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Column(
                      children: [
                        // ── Greeting ──
                        Text(
                          widget.isChanging
                              ? 'New look, who dis?'
                              : "Hi, I'm Bedzilla!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: p.text,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Your sleepy little wake-up buddy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.textMuted, fontSize: 16),
                        ),
                        const SizedBox(height: 20),

                        // ── Bedzilla ──
                        Expanded(
                          child: _FloatingMascot(asset: _selected.mascot),
                        ),
                        const SizedBox(height: 16),

                        // ── Theme options ──
                        Row(
                          children: [
                            for (final choice in AppThemeChoice.values) ...[
                              if (choice != AppThemeChoice.values.first)
                                const SizedBox(width: 14),
                              Expanded(
                                child: _ThemeOption(
                                  choice: choice,
                                  selected: choice == _selected,
                                  onTap: () => _pick(choice),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),

                        // ── Confirm ──
                        _ChunkyButton(
                          label: widget.isChanging ? 'Looks good!' : "Let's go!",
                          onTap: _confirm,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Bedzilla ──────────────────────────────────────────────────────

/// Bedzilla standing still with a shadow underneath.
/// Pops in with a bounce when the theme changes; hops when tapped.
class _FloatingMascot extends StatefulWidget {
  final String asset;
  const _FloatingMascot({required this.asset});

  @override
  State<_FloatingMascot> createState() => _FloatingMascotState();
}

class _FloatingMascotState extends State<_FloatingMascot>
    with SingleTickerProviderStateMixin {
  // Tap hop
  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void dispose() {
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return GestureDetector(
      onTap: () => _hop.forward(from: 0),
      child: AnimatedBuilder(
        animation: _hop,
        builder: (context, child) {
          // Hop: up then down, one arc
          final hop = math.sin(_hop.value * math.pi);
          final dy = -40 * hop;
          final shadowScale = 1 - 0.35 * hop;

          return LayoutBuilder(
            builder: (context, box) {
              final size = math.min(box.maxWidth, box.maxHeight) * 0.92;
              return Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Shadow
                  Positioned(
                    bottom: 4,
                    child: Transform.scale(
                      scale: shadowScale,
                      child: Container(
                        width: size * 0.6,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, dy),
                    child: SizedBox(
                      width: size,
                      height: size,
                      child: child,
                    ),
                  ),
                ],
              );
            },
          );
        },
        // Swaps mascot with a springy pop when the theme changes
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          switchInCurve: Curves.elasticOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: child,
          ),
          child: Container(
            key: ValueKey(widget.asset),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: p.primary.withValues(alpha: 0.18),
                  blurRadius: 60,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Image.asset(widget.asset, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

// ── Theme options ─────────────────────────────────────────────────

/// A chunky, tappable card with a mini Bedzilla in that theme's colors.
class _ThemeOption extends StatelessWidget {
  final AppThemeChoice choice;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Each card uses its own palette so both themes are visible side by side.
    final AppPalette p = choice.palette;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.0 : 0.94,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 16),
          decoration: BoxDecoration(
            color: selected ? p.accentContainer : p.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: selected ? p.primary : p.border,
              width: selected ? 3 : 2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: p.primary.withValues(alpha: 0.3),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 72,
                    child: Image.asset(choice.mascot, fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    choice.label,
                    style: TextStyle(
                      color: p.text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    choice.description,
                    style: TextStyle(color: p.highlight, fontSize: 13),
                  ),
                ],
              ),
              // Check badge
              Positioned(
                top: -6,
                right: -2,
                child: AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: p.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, size: 17, color: p.onPrimary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Confirm button ────────────────────────────────────────────────

/// Big "3D" button: a darker base sits under the face, and the face sinks
/// into it while pressed.
class _ChunkyButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _ChunkyButton({required this.label, required this.onTap});

  @override
  State<_ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<_ChunkyButton> {
  static const _depth = 6.0;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final base = Color.lerp(p.primary, Colors.black, 0.4)!;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      child: SizedBox(
        height: 60 + _depth,
        child: Stack(
          children: [
            // Base
            Positioned.fill(
              top: _depth,
              child: Container(
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
            // Face
            AnimatedPositioned(
              duration: const Duration(milliseconds: 80),
              left: 0,
              right: 0,
              top: _pressed ? _depth : 0,
              height: 60,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.primary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: p.onPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;
  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.6),
        shape: BoxShape.circle,
      ),
    );
  }
}
