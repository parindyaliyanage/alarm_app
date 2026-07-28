import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/alarm_setup_bloc.dart';
import '../bloc/alarm_setup_event.dart';
import '../bloc/alarm_setup_state.dart';
import '../../../core/constants/app_constants.dart';

class AlarmSetupScreen extends StatelessWidget {
  const AlarmSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A2E),
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'New Alarm',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            BlocBuilder<AlarmSetupBloc, AlarmSetupState>(
              builder: (context, state) {
                return TextButton(
                  onPressed: state.isSaving
                      ? null
                      : () => context.read<AlarmSetupBloc>().add(const SaveAlarm()),
                  child: state.isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.deepPurple,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.deepPurple,
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
    return BlocBuilder<AlarmSetupBloc, AlarmSetupState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: state.hour, minute: state.minute),
              builder: (context, child) {
                return Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Colors.deepPurple,
                    ),
                  ),
                  child: child!,
                );
              },
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
              color: const Color(0xFF16213E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Text(
                  state.formattedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.w200,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tap to change time',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Label 
class _LabelSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Label',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: (value) =>
              context.read<AlarmSetupBloc>().add(LabelChanged(value)),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. Morning alarm',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF16213E),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.deepPurple, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// Repeat Days 
class _RepeatDaysSection extends StatelessWidget {
  static const _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlarmSetupBloc, AlarmSetupState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Repeat',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final isSelected = state.repeatDays[index];
                return GestureDetector(
                  onTap: () => context
                      .read<AlarmSetupBloc>()
                      .add(RepeatDayToggled(index)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepPurple
                          : const Color(0xFF16213E),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepPurple
                            : Colors.white24,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _days[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white38,
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
    return BlocBuilder<AlarmSetupBloc, AlarmSetupState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Challenge Type',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ChallengeOption(
                  icon: '🧮',
                  label: 'Math',
                  subtitle: 'Solve 3-digit problems',
                  isSelected:
                      state.challengeType == AppConstants.mathChallenge,
                  onTap: () => context.read<AlarmSetupBloc>().add(
                        const ChallengeTypeChanged(AppConstants.mathChallenge),
                      ),
                ),
                const SizedBox(width: 12),
                _ChallengeOption(
                  icon: '📷',
                  label: 'Object',
                  subtitle: 'Show a random object',
                  isSelected:
                      state.challengeType == AppConstants.objectChallenge,
                  onTap: () => context.read<AlarmSetupBloc>().add(
                        const ChallengeTypeChanged(
                            AppConstants.objectChallenge),
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
  final String icon;
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.deepPurple.withOpacity(0.2)
                : const Color(0xFF16213E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? Colors.deepPurple : Colors.white12,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}