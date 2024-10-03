class GraphData {
  final List<dynamic> hourly;
  final List<dynamic> hourly8;
  final List<dynamic> yearly;
  final List<dynamic> daily;

  GraphData({
    required this.hourly,
    required this.hourly8,
    required this.yearly,
    required this.daily,
  });

  factory GraphData.fromJson(Map<String, dynamic> json) {
    return GraphData(
      hourly: json['hourly'] ?? [],
      hourly8: json['hourly_8'] ?? [],
      yearly: json['yearly'] ?? [],
      daily: json['daily'] ?? [],
    );
  }
}
