import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'match_models.dart';

class MatchPersistedState {
  const MatchPersistedState({
    required this.session,
    required this.role,
    required this.hostAddress,
    required this.hostPort,
    required this.joinAddress,
    required this.joinPort,
  });

  final MatchSession session;
  final MatchRole role;
  final String? hostAddress;
  final int? hostPort;
  final String? joinAddress;
  final int? joinPort;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'session': session.toJson(),
      'role': role.name,
      'hostAddress': hostAddress,
      'hostPort': hostPort,
      'joinAddress': joinAddress,
      'joinPort': joinPort,
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
