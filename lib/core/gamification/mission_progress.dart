
class MissionProgress {
  final int current;
  final int total;

  const MissionProgress({
    required this.current,
    required this.total,
  });

  bool get completed => current >= total;
}
