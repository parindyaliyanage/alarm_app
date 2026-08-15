import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import '../bloc/object_challenge_bloc.dart';
import '../bloc/object_challenge_event.dart';
import '../bloc/object_challenge_state.dart';
import '../bloc/alarm_trigger_bloc.dart';
import '../bloc/alarm_trigger_event.dart';

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
        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [

              // ── Camera preview ──
              if (state.status == ObjectChallengeStatus.scanning ||
                  state.status == ObjectChallengeStatus.detected)
                _buildCameraPreview(context),

              // ── Loading overlay ──
              if (state.status == ObjectChallengeStatus.loading)
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.deepPurple),
                      SizedBox(height: 16),
                      Text(
                        'Starting camera...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
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
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Show this object to the camera',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.targetObject.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
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
                                color: state.secondsRemaining < 30
                                    ? Colors.red
                                    : Colors.white54,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                state.formattedTime,
                                style: TextStyle(
                                  color: state.secondsRemaining < 30
                                      ? Colors.red
                                      : Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                '→ math fallback',
                                style: TextStyle(
                                  color: Colors.white30,
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
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.deepPurple,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Scanning...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Success overlay ──
              if (state.status == ObjectChallengeStatus.detected)
                Container(
                  color: Colors.green.withValues(alpha: 0.7),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 80),
                        SizedBox(height: 16),
                        Text(
                          'Object Detected!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Dismissing alarm...',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
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
    final controller =
        context.read<ObjectChallengeBloc>().cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return SizedBox.expand(
      child: CameraPreview(controller),
    );
  }
}