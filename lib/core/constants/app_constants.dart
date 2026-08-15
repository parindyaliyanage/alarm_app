class AppConstants {
  // Hive box names
  static const String alarmBox = 'alarms';

  // Challenge types
  static const String mathChallenge = 'math';
  static const String objectChallenge = 'object';

  // Hive box to track if an alarm is currently ringing
  static const String activeAlarmBox = 'active_alarm';
  static const String activeAlarmKey = 'is_ringing';

  // Fallback timeout in seconds (2 minutes)
  static const int objectChallengTimeoutSeconds = 120;

  static const String activeChallengeTypeKey = 'active_challenge_type';

  // 20 curated objects from COCO dataset
  static const List<String> detectableObjects = [
    'toothbrush',
    'cup',
    'spoon',
    'fork',
    'bottle',
    'bowl',
    'banana',
    'apple',
    'orange',
    'chair',
    'laptop',
    'mouse',
    'remote',
    'keyboard',
    'cell phone',
    'book',
    'scissors',
    'clock',
    'umbrella',
    'backpack',
  ];

}
