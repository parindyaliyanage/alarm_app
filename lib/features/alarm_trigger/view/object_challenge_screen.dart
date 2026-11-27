import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../bloc/object_challenge_bloc.dart';
import '../bloc/object_challenge_event.dart';
import '../bloc/object_challenge_state.dart';
import '../bloc/alarm_trigger_bloc.dart';
import '../bloc/alarm_trigger_event.dart';
import '../../../core/theme/app_theme.dart';

class ObjectChallengeScreen extends StatefulWidget {
  const ObjectChallengeScreen({super.key});

  @override
  State<ObjectChallengeScreen> createState() => _ObjectChallengeScreenState();
}

class _ObjectChallengeScreenState extends State<ObjectChallengeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ObjectChallengeBloc>().add(const ObjectChallengeStarted());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Translucent panel color for overlays on top of the camera feed
    final overlay = p.background.withValues(alpha: 0.75);

    return BlocConsumer<ObjectChallengeBloc, ObjectChallengeState>(
      listener: (context, state) {
        if (state.status == ObjectChallengeStatus.detected) {
          // Object found — dismiss alarm
          context.read<AlarmTriggerBloc>().add(const AlarmDismissed());
        }
        if (state.status == ObjectChallengeStatus.timedOut) {
          // 2 minutes passed — pop back to math challenge screen
          // AlarmTriggerScreen is already underneath showing math
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final lowTime = state.secondsRemaining < 30;

        return Scaffold(
          backgroundColor: p.background,
          body: Stack(
            children: [
              // ── Camera preview ──
              if (state.status == ObjectChallengeStatus.scanning ||
                  state.status == ObjectChallengeStatus.detected)
                _buildCameraPreview(context),

              // ── Loading overlay ──
              if (state.status == ObjectChallengeStatus.loading)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Starting camera...',
                        style: TextStyle(color: p.text, fontSize: 16),
                      ),
                    ],
                  ),
                ),

              // ── Top overlay — target object + timer ──
              if (state.status == ObjectChallengeStatus.scanning)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: overlay,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: p.border),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Show this object to the camera',
                            style: TextStyle(
                              color: p.textMuted,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.targetObject.toUpperCase(),
                            style: TextStyle(
                              color: p.highlight,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Countdown timer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.timer,
                                color: lowTime ? p.error : p.textMuted,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                state.formattedTime,
                                style: TextStyle(
                                  color: lowTime ? p.error : p.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '→ math fallback',
                                style: TextStyle(
                                  color: p.textMuted.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Scanning indicator at bottom ──
              if (state.status == ObjectChallengeStatus.scanning)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: overlay,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Scanning...',
                            style: TextStyle(color: p.textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Success overlay ──
              if (state.status == ObjectChallengeStatus.detected)
                Container(
                  color: p.background.withValues(alpha: 0.8),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: p.gradient,
                          ),
                          child: Icon(
                            Icons.check,
                            color: p.onPrimary,
                            size: 56,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Object Detected!',
                          style: TextStyle(
                            color: p.text,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dismissing alarm...',
                          style: TextStyle(color: p.textMuted, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCameraPreview(BuildContext context) {
    final controller = context.read<ObjectChallengeBloc>().cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return SizedBox.expand(child: CameraPreview(controller));
  }
}
