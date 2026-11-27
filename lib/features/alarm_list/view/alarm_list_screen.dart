import 'package:alarm_app/data/repositories/alarm_repository.dart';
import 'package:alarm_app/features/alarm_setup/bloc/alarm_setup_bloc.dart';
import 'package:alarm_app/features/alarm_setup/bloc/alarm_setup_event.dart';
import 'package:alarm_app/features/alarm_setup/view/alarm_setup_screen.dart';
import 'package:alarm_app/features/alarm_trigger/bloc/alarm_trigger_bloc.dart';
import 'package:alarm_app/features/alarm_trigger/view/alarm_trigger_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../bloc/alarm_list_bloc.dart';
import '../bloc/alarm_list_event.dart';
import '../bloc/alarm_list_state.dart';
import '../../../data/models/alarm_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../theme_picker/view/theme_picker_screen.dart';
import 'widgets/next_alarm_header.dart';

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
      body: BlocBuilder<AlarmListBloc, AlarmListState>(
        builder: (context, state) {
          final alarms = state is AlarmListLoaded
              ? state.alarms
              : const <AlarmModel>[];

          return CustomScrollView(
            slivers: [
              // ── Top: next alarm hero ──
              SliverToBoxAdapter(
                child: NextAlarmHeader(
                  alarms: alarms,
                  onEdit: (alarm) => openAlarmEditor(context, alarm),
                  onChangeTheme: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const ThemePickerScreen(isChanging: true),
                    ),
                  ),
                ),
              ),

              // ── Active alarm banner ──
              SliverToBoxAdapter(child: _buildRingingBanner(context)),

              // ── Bottom: alarm list ──
              ..._buildListSlivers(context, state),

              // Room for the floating button
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          );
        },
      ),
      // Colors come from floatingActionButtonTheme in app_theme.dart
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
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Alarm',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildRingingBanner(BuildContext context) {
    final p = context.palette;
    return ValueListenableBuilder(
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
                  child: AlarmTriggerScreen(challengeType: challengeType),
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: p.gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: p.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.alarm, color: p.onPrimary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alarm is ringing!',
                        style: TextStyle(
                          color: p.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to solve the challenge',
                        style: TextStyle(color: p.onPrimary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: p.onPrimary, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildListSlivers(BuildContext context, AlarmListState state) {
    final p = context.palette;

    if (state is AlarmListLoading || state is AlarmListInitial) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (state is AlarmListError) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Text(state.message, style: TextStyle(color: p.error)),
          ),
        ),
      ];
    }

    final alarms = (state as AlarmListLoaded).alarms;
    if (alarms.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(context),
        ),
      ];
    }

    final onCount = alarms.where((a) => a.isEnabled).length;

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 14),
        sliver: SliverToBoxAdapter(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'All alarms',
                  style: TextStyle(
                    color: p.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '$onCount of ${alarms.length} on',
                style: TextStyle(color: p.textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.builder(
          itemCount: alarms.length,
          itemBuilder: (context, index) => _AlarmCard(alarm: alarms[index]),
        ),
      ),
    ];
  }

  Widget _buildEmptyState(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.alarm_off, size: 64, color: p.border),
          const SizedBox(height: 16),
          Text('No alarms yet', style: TextStyle(color: p.text, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first alarm',
            style: TextStyle(color: p.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Opens the editor pre-filled with [alarm], and reloads the list if saved.
Future<void> openAlarmEditor(BuildContext context, AlarmModel alarm) async {
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

class _AlarmCard extends StatelessWidget {
  final AlarmModel alarm;
  const _AlarmCard({required this.alarm});

  static const _dayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hour12 = alarm.hour % 12 == 0 ? 12 : alarm.hour % 12;
    final minute = alarm.minute.toString().padLeft(2, '0');
    final period = alarm.hour < 12 ? 'AM' : 'PM';
    final isMath = alarm.challengeType == AppConstants.mathChallenge;
    final on = alarm.isEnabled;

    return GestureDetector(
      onTap: () => openAlarmEditor(context, alarm), // ← tap whole card to edit
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: on ? p.primary.withValues(alpha: 0.35) : p.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$hour12:$minute',
                        style: TextStyle(
                          color: on ? p.text : p.textMuted,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        period,
                        style: TextStyle(
                          color: p.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alarm.label.isEmpty ? 'Alarm' : alarm.label,
                    style: TextStyle(color: p.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: p.accentContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isMath
                                  ? Icons.calculate_outlined
                                  : Icons.camera_alt_outlined,
                              color: p.highlight,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isMath ? 'Math' : 'Object',
                              style: TextStyle(color: p.highlight, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(child: _repeatText(context)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                // Colors come from switchTheme in app_theme.dart
                Switch(
                  value: on,
                  onChanged: (value) {
                    context.read<AlarmListBloc>().add(
                      ToggleAlarm(alarm.id, value),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: p.textMuted),
                  onPressed: () => _confirmDelete(context, alarm.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "Once", "Every day", or the selected day letters e.g. "M W F".
  Widget _repeatText(BuildContext context) {
    final days = alarm.repeatDays;
    final String text;
    if (!days.any((d) => d)) {
      text = 'Once';
    } else if (days.every((d) => d)) {
      text = 'Every day';
    } else {
      text = [
        for (var i = 0; i < 7; i++)
          if (days[i]) _dayLetters[i],
      ].join(' ');
    }
    return Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: context.palette.textMuted, fontSize: 12),
    );
  }

  void _confirmDelete(BuildContext context, String alarmId) {
    final p = context.palette;
    // Dialog colors come from dialogTheme in app_theme.dart
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete alarm?'),
        content: const Text('This alarm will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: p.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AlarmListBloc>().add(DeleteAlarm(alarmId));
            },
            child: Text('Delete', style: TextStyle(color: p.error)),
          ),
        ],
      ),
    );
  }
}
