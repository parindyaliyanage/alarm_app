import 'package:alarm_app/data/repositories/alarm_repository.dart';
import 'package:alarm_app/features/alarm_list/bloc/alarm_list_bloc.dart';
import 'package:alarm_app/features/alarm_list/bloc/alarm_list_event.dart';
import 'package:alarm_app/features/alarm_list/view/alarm_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AlarmApp extends StatelessWidget {
  const AlarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alarm App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: BlocProvider(
        create: (_) => AlarmListBloc(AlarmRepository())..add(const LoadAlarms()),
        child: const AlarmListScreen(),
      ),

    );
  }
}