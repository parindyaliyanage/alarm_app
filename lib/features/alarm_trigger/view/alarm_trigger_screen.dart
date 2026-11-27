import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/alarm_trigger_bloc.dart';
import '../bloc/alarm_trigger_event.dart';
import '../bloc/alarm_trigger_state.dart';
import '../bloc/object_challenge_bloc.dart';
import 'object_challenge_screen.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';

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
    final p = context.palette;
    return BlocListener<AlarmTriggerBloc, AlarmTriggerState>(
      listenWhen: (prev, curr) => curr.status == AlarmStatus.solved,
      listener: (context, state) {
        Navigator.of(context).pop();
      },
      child: PopScope(
        canPop: false,
        child: Scaffold(
          body: BlocBuilder<AlarmTriggerBloc, AlarmTriggerState>(
            builder: (context, state) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: state.isWrong
                    ? Color.alphaBlend(
                        p.error.withValues(alpha: 0.25),
                        p.background,
                      )
                    : p.background,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Spacer(),
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: p.gradient,
                            boxShadow: [
                              BoxShadow(
                                color: p.primary.withValues(alpha: 0.4),
                                blurRadius: 24,
                              ),
                            ],
                          ),
                          child: Icon(Icons.alarm, size: 44, color: p.onPrimary),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Wake Up!',
                          style: TextStyle(
                            color: p.text,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Solve all 3 problems to stop the alarm',
                          style: TextStyle(color: p.textMuted, fontSize: 14),
                        ),
                        const Spacer(),
                        _buildProgressDots(context, state.questionsLeft),
                        const SizedBox(height: 40),
                        Text(
                          state.question,
                          style: TextStyle(
                            color: state.isWrong ? p.error : p.text,
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
                          style: TextStyle(
                            color: p.text,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '?',
                            hintStyle: TextStyle(
                              color: p.textMuted.withValues(alpha: 0.4),
                              fontSize: 32,
                            ),
                            fillColor: p.surfaceRaised,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: state.isWrong ? p.error : p.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () {
                            context.read<AlarmTriggerBloc>().add(
                                  AnswerSubmitted(_answerController.text),
                                );
                            _answerController.clear();
                          },
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                colors: [p.highlight, p.primary],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: p.primary.withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Text(
                              'Submit',
                              style: TextStyle(
                                color: p.onPrimary,
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

  Widget _buildProgressDots(BuildContext context, int questionsLeft) {
    final p = context.palette;
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
            color: isCompleted ? p.primary : p.surfaceRaised,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
