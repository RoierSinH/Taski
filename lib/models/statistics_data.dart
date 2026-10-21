class StatisticsData {
  const StatisticsData({
    required this.total,
    required this.completed,
    required this.pending,
    required this.byPriority,
  });

  final int total;
  final int completed;
  final int pending;
  final Map<int, int> byPriority;

  double get completionRate {
    if (total == 0) return 0;
    return completed / total;
  }
}
