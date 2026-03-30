import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'match_models.dart';
import 'match_time.dart';

class MatchPersistedState {
  const MatchPersistedState({
    required this.session,
    required this.role,
    required this.hostAddress,
    required this.hostPort,
    required this.joinAddress,
    required this.joinPort,
    required this.careerXp,
    required this.selectedThemeId,
    required this.whiteAtBottom,
    required this.awaitingHandOff,
    required this.clockPreset,
    required this.analyticsSinkUrl,
    required this.turnStartedAtUtc,
  });

  final MatchSession session;
  final MatchRole role;
  final String? hostAddress;
  final int? hostPort;
  final String? joinAddress;
  final int? joinPort;
  final int careerXp;
  final String selectedThemeId;
  final bool whiteAtBottom;
  final bool awaitingHandOff;
  final MatchTimerPreset clockPreset;
  final String? analyticsSinkUrl;
  final DateTime? turnStartedAtUtc;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'session': session.toJson(),
      'role': role.name,
      'hostAddress': hostAddress,
      'hostPort': hostPort,
      'joinAddress': joinAddress,
      'joinPort': joinPort,
      'careerXp': careerXp,
      'selectedThemeId': selectedThemeId,
      'whiteAtBottom': whiteAtBottom,
      'awaitingHandOff': awaitingHandOff,
      'clockPreset': clockPreset.name,
      'analyticsSinkUrl': analyticsSinkUrl,
      'turnStartedAtUtc': turnStartedAtUtc?.toIso8601String(),
    };
  }

  factory MatchPersistedState.fromJson(Map<String, dynamic> json) {
    final rawSession = json['session'];
    return MatchPersistedState(
      session: rawSession is Map<String, dynamic>
          ? MatchSession.fromJson(rawSession)
          : MatchSession.initial(),
      role: MatchRole.values.byName(
        (json['role'] as String?) ?? MatchRole.local.name,
      ),
      hostAddress: json['hostAddress'] as String?,
      hostPort: (json['hostPort'] as num?)?.toInt(),
      joinAddress: json['joinAddress'] as String?,
      joinPort: (json['joinPort'] as num?)?.toInt(),
      careerXp: (json['careerXp'] as num?)?.toInt() ?? 0,
      selectedThemeId:
          (json['selectedThemeId'] as String?) ?? 'chrome',
      whiteAtBottom: json['whiteAtBottom'] as bool? ?? true,
      awaitingHandOff: json['awaitingHandOff'] as bool? ?? false,
      clockPreset: matchTimerPresetFromName(json['clockPreset'] as String?),
      analyticsSinkUrl: json['analyticsSinkUrl'] as String?,
      turnStartedAtUtc: (json['turnStartedAtUtc'] as String?) == null
          ? null
          : DateTime.parse(json['turnStartedAtUtc'] as String).toUtc(),
    );
  }
}

class MatchStorage {
  static const String _storageKey = 'checkmate.match.state';

  Future<MatchPersistedState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return MatchPersistedState.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  Future<void> save(MatchPersistedState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(state.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
