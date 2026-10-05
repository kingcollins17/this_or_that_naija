import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  static const String _votedBoxName = 'user_votes_box';
  static const String _settingsBoxName = 'app_settings_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_votedBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  static Box<String> get _votedBox => Hive.box<String>(_votedBoxName);
  static Box get _settingsBox => Hive.box(_settingsBoxName);

  static bool hasVoted(String questionId) => _votedBox.containsKey(questionId);

  static String? getVoteChoice(String questionId) => _votedBox.get(questionId);

  static Future<void> saveVote(String questionId, String option) async {
    await _votedBox.put(questionId, option);
  }

  static String getUserDisplayName() {
    return _settingsBox.get('display_name', defaultValue: 'Naija Citizen');
  }

  static Future<void> setUserDisplayName(String name) async {
    await _settingsBox.put('display_name', name);
  }
}
