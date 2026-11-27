import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/alarm_setup_bloc.dart';
import '../bloc/alarm_setup_event.dart';
import '../bloc/alarm_setup_state.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

class AlarmSetupScreen extends StatelessWidget {
  const AlarmSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocListener<AlarmSetupBloc, AlarmSetupState>(
      listenWhen: (prev, curr) => curr.isSaved || curr.errorMessage != null,
      listener: (context, state) {
        if (state.isSaved) {
          Navigator.pop(context, true); // true = alarm was saved
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: p.error,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<AlarmSetupBloc, AlarmSetupState>(
            builder: (context, state) {
              return Text(
                state.isEditing ? 'Edit Alarm' : 'New Alarm', // ← dynamic title
                style: TextStyle(color: p.text, fontWeight: FontWeight.bold),
              );
            },
          ),
          actions: [
            BlocBuilder<AlarmSetupBloc, AlarmSetupState>(
              builder: (context, state) {
                return TextButton(
                  onPressed: state.isSaving
                      ? null
                      : () => context.read<AlarmSetupBloc>().add(
                          const SaveAlarm(),
                        ),
                  child: state.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Save',
                          style: TextStyle(
                            color: p.primary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TimePickerSection(),
              const SizedBox(height: 32),
              _LabelSection(),
              const SizedBox(height: 32),
              _RepeatDaysSection(),
              const SizedBox(height: 32),
              _ChallengeTypeSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Time Picker ──────────────────────────────────────
class _TimePickerSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocBuilder<AlarmSetupBloc, AlarmSetupState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () async {
            // Picker colors come from timePickerTheme in app_theme.dart
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: state.hour, minute: state.minute),
            );
            if (picked != null && context.mounted) {
              context.read<AlarmSetupBloc>().add(
                TimeChanged(picked.hour, picked.minute),
              );
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: p.primary.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Text(
                  state.formattedTime,
                  style: TextStyle(
                    color: p.text,
                    fontSize: 64,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to change time',
                  style: TextStyle(color: p.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LabelSection extends StatefulWidget {
  @override
  State<_LabelSection> createState() => _LabelSectionState();
}

class _LabelSectionState extends State<_LabelSection> {
  late TextEditingController _controller;
  bool _initialized = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocBuilder<AlarmSetupBloc, AlarmSetupState>(
      builder: (context, state) {
        // Initialize controller once with existing label
        if (!_initialized) {
          _controller = TextEditingController(text: state.label);
          _initialized = true;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Label', style: TextStyle(color: p.textMuted, fontSize: 14)),
            const SizedBox(height: 8),
            // Field styling comes from inputDecorationTheme in app_theme.dart
            TextField(
              controller: _controller,
              onChanged: (value) =>
                  context.read<AlarmSetupBloc>().add(LabelChanged(value)),
              style: TextStyle(color: p.text),
              decoration: const InputDecoration(hintText: 'e.g. Morning alarm'),
            ),
          ],
        );
      },
    );
  }
}

// Repeat Days
class _RepeatDaysSection extends StatelessWidget {
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocBuilder<AlarmSetupBloc, AlarmSetupState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Repeat', style: TextStyle(color: p.textMuted, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final isSelected = state.repeatDays[index];
                return GestureDetector(
                  onTap: () => context.read<AlarmSetupBloc>().add(
                    RepeatDayToggled(index),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected ? p.primary : p.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? p.primary : p.border,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _days[index],
                        style: TextStyle(
                          color: isSelected ? p.onPrimary : p.textMuted,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

// ── Challenge Type ───────────────────────────────────
class _ChallengeTypeSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BlocBuilder<AlarmSetupBloc, AlarmSetupState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Challenge Type',
              style: TextStyle(color: p.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ChallengeOption(
                  icon: Icons.calculate_outlined,
                  label: 'Math',
                  subtitle: 'Solve 3-digit problems',
                  isSelected: state.challengeType == AppConstants.mathChallenge,
                  onTap: () => context.read<AlarmSetupBloc>().add(
                    const ChallengeTypeChanged(AppConstants.mathChallenge),
                  ),
                ),
                const SizedBox(width: 12),
                _ChallengeOption(
                  icon: Icons.camera_alt_outlined,
                  label: 'Object',
                  subtitle: 'Show a random object',
                  isSelected:
                      state.challengeType == AppConstants.objectChallenge,
                  onTap: () => context.read<AlarmSetupBloc>().add(
                    const ChallengeTypeChanged(AppConstants.objectChallenge),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ChallengeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChallengeOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? p.accentContainer : p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? p.primary : p.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? p.primary : p.surfaceRaised,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? p.onPrimary : p.highlight,
                  size: 26,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: TextStyle(color: p.text, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
