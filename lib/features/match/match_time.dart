enum MatchTimerPreset {
  infinity,
  fiveMinutes,
  tenMinutes,
  fifteenMinutes,
  thirtyMinutes,
}

extension MatchTimerPresetX on MatchTimerPreset {
  String get label => switch (this) {
        MatchTimerPreset.infinity => 'Infinity',
        MatchTimerPreset.fiveMinutes => '5 min',
        MatchTimerPreset.tenMinutes => '10 min',
        MatchTimerPreset.fifteenMinutes => '15 min',
        MatchTimerPreset.thirtyMinutes => '30 min',
      };

  String get longLabel => switch (this) {
        MatchTimerPreset.infinity => 'No timer',
        MatchTimerPreset.fiveMinutes => '5 minutes',
        MatchTimerPreset.tenMinutes => '10 minutes',
        MatchTimerPreset.fifteenMinutes => '15 minutes',
        MatchTimerPreset.thirtyMinutes => '30 minutes',
      };

  Duration? get duration => switch (this) {
        MatchTimerPreset.infinity => null,
        MatchTimerPreset.fiveMinutes => const Duration(minutes: 5),
        MatchTimerPreset.tenMinutes => const Duration(minutes: 10),
        MatchTimerPreset.fifteenMinutes => const Duration(minutes: 15),
        MatchTimerPreset.thirtyMinutes => const Duration(minutes: 30),
      };

}

String formatClock(Duration? duration) {
  if (duration == null) {
    return '∞';
  }

  final resolved = duration.isNegative ? Duration.zero : duration;
  final minutes = resolved.inMinutes;
  final seconds = resolved.inSeconds.remainder(60);
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

MatchTimerPreset matchTimerPresetFromName(String? raw) {
  if (raw == null) {
    return MatchTimerPreset.infinity;
  }

  return MatchTimerPreset.values.firstWhere(
    (preset) => preset.name == raw,
    orElse: () => MatchTimerPreset.infinity,
  );
}
