import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/alarm_trigger_bloc.dart';
import '../bloc/alarm_trigger_event.dart';
import '../bloc/alarm_trigger_state.dart';
import '../bloc/object_challenge_bloc.dart';
import 'object_challenge_screen.dart';
import '../../../core/constants/app_constants.dart';

class AlarmTriggerScreen extends StatefulWidget {
  final String challengeType;
  const AlarmTriggerScreen({
    super.key,
    this.challengeType = AppConstants.mathChallenge,
  });

  @override
  State<AlarmTriggerScreen> createState() => _AlarmTriggerScreenState();
}

class _AlarmTriggerScreenState extends State<AlarmTriggerScreen> {
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AlarmTriggerBloc>().add(const AlarmStarted());

    // Route to object challenge if needed
    if (widget.challengeType == AppConstants.objectChallenge) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MultiBlocProvider(
              providers: [
                BlocProvider.value(
                  value: context.read<AlarmTriggerBloc>(),
                ),
                BlocProvider(
                  create: (_) => ObjectChallengeBloc(),
                ),
              ],
              child: const ObjectChallengeScreen(),
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AlarmTriggerBloc, AlarmTriggerState>(
      listenWhen: (prev, curr) => curr.status == AlarmStatus.solved,
      listener: (context, state) {
        Navigator.of(context).pop();
      },
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color(0xFF1A1A2E),
          body: BlocBuilder<AlarmTriggerBloc, AlarmTriggerState>(
            builder: (context, state) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: state.isWrong
                    ? Colors.red.withValues(alpha: 0.3)
                    : const Color(0xFF1A1A2E),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Spacer(),
                        const Icon(
                          Icons.alarm,
                          size: 64,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Wake Up!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Solve all 3 problems to stop the alarm',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        _buildProgressDots(state.questionsLeft),
                        const SizedBox(height: 40),
                        Text(
                          state.question,
                          style: TextStyle(
                            color: state.isWrong ? Colors.red : Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 40),
                        TextField(
                          controller: _answerController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.center,
                          autofocus: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '?',
                            hintStyle: const TextStyle(
                              color: Colors.white24,
                              fontSize: 32,
                            ),
                            filled: true,
                            fillColor: const Color(0xFF16213E),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: state.isWrong
                                    ? Colors.red
                                    : Colors.deepPurple,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              context.read<AlarmTriggerBloc>().add(
                                    AnswerSubmitted(_answerController.text),
                                  );
                              _answerController.clear();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDots(int questionsLeft) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final isCompleted = index < (3 - questionsLeft);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: isCompleted ? 32 : 16,
          height: 16,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.deepPurple : Colors.white24,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}