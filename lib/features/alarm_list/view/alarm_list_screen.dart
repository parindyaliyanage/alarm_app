import 'package:alarm_app/data/repositories/alarm_repository.dart';
import 'package:alarm_app/features/alarm_setup/bloc/alarm_setup_bloc.dart';
import 'package:alarm_app/features/alarm_setup/bloc/alarm_setup_event.dart';
import 'package:alarm_app/features/alarm_setup/view/alarm_setup_screen.dart';
import 'package:alarm_app/features/alarm_trigger/bloc/alarm_trigger_bloc.dart';
import 'package:alarm_app/features/alarm_trigger/view/alarm_trigger_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../bloc/alarm_list_bloc.dart';
import '../bloc/alarm_list_event.dart';
import '../bloc/alarm_list_state.dart';
import '../../../data/models/alarm_model.dart';
import '../../../core/constants/app_constants.dart';

class AlarmListScreen extends StatefulWidget {
  const AlarmListScreen({super.key});

  @override
  State<AlarmListScreen> createState() => _AlarmListScreenState();
}

class _AlarmListScreenState extends State<AlarmListScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Rebuild when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text(
          'My Alarms',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Active alarm banner ──
          ValueListenableBuilder(
            valueListenable: Hive.box(AppConstants.activeAlarmBox).listenable(),
            builder: (context, box, _) {
              final isRinging = box.get(
                AppConstants.activeAlarmKey,
                defaultValue: false,
              );

              if (!isRinging) return const SizedBox.shrink();

              return GestureDetector(
                onTap: () {
                  final activeBox = Hive.box(AppConstants.activeAlarmBox);
                  final challengeType = activeBox.get(
                    AppConstants.activeChallengeTypeKey,
                    defaultValue: AppConstants.mathChallenge,
                  ) as String;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => AlarmTriggerBloc(),
                        child: AlarmTriggerScreen(challengeType: challengeType), // ← correct
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.alarm, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⏰ Alarm is ringing!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Tap to solve the challenge',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ── Alarm list ──
          Expanded(
            child: BlocBuilder<AlarmListBloc, AlarmListState>(
              builder: (context, state) {
                if (state is AlarmListLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.deepPurple),
                  );
                }
                if (state is AlarmListError) {
                  return Center(
                    child: Text(
                      state.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (state is AlarmListLoaded) {
                  if (state.alarms.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildAlarmList(context, state.alarms);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (_) => AlarmSetupBloc(AlarmRepository()),
                child: const AlarmSetupScreen(),
              ),
            ),
          );
          if (saved == true && context.mounted) {
            context.read<AlarmListBloc>().add(const LoadAlarms());
          }
        },
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Alarm', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm_off, size: 80, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            'No alarms yet',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Tap + to add your first alarm',
            style: TextStyle(color: Colors.white30, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmList(BuildContext context, List<AlarmModel> alarms) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: alarms.length,
      itemBuilder: (context, index) {
        final alarm = alarms[index];
        return _AlarmCard(alarm: alarm);
      },
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  const _AlarmCard({required this.alarm});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openEditScreen(context), // ← tap whole card to edit
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF16213E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alarm.isEnabled
                ? Colors.deepPurple.withValues(alpha: 0.5)
                : Colors.white12,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alarm.formattedTime,
                    style: TextStyle(
                      color: alarm.isEnabled ? Colors.white : Colors.white38,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alarm.label.isEmpty ? 'Alarm' : alarm.label,
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: alarm.challengeType == AppConstants.mathChallenge
                          ? Colors.orange.withValues(alpha: 0.2)
                          : Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      alarm.challengeType == AppConstants.mathChallenge
                          ? '🧮 Math'
                          : '📷 Object',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Switch(
                  value: alarm.isEnabled,
                  activeColor: Colors.deepPurple,
                  onChanged: (value) {
                    context.read<AlarmListBloc>().add(
                      ToggleAlarm(alarm.id, value),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white30),
                  onPressed: () => _confirmDelete(context, alarm.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditScreen(BuildContext context) async {
    final listBloc = context.read<AlarmListBloc>();
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) =>
              AlarmSetupBloc(AlarmRepository())
                ..add(LoadAlarmForEdit(alarm)), // ← pre-fill with alarm data
          child: const AlarmSetupScreen(),
        ),
      ),
    );
    if (saved == true) {
      listBloc.add(const LoadAlarms());
    }
  }

  void _confirmDelete(BuildContext context, String alarmId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Delete alarm?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This alarm will be removed.',
          style: TextStyle(color: Colors.white54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AlarmListBloc>().add(DeleteAlarm(alarmId));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
