class MatchAnalyticsSink {
  Future<void> appendRow(Uri endpoint, Map<String, Object?> row) async {
    throw UnsupportedError('Analytics export is not supported on this platform.');
  }
}
