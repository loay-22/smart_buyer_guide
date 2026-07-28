class SearchHistoryEntry {
  SearchHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.productName,
    required this.imagePath,
    required this.budget,
    required this.analysisJson,
  });

  final String id;
  final DateTime timestamp;
  final String productName;
  final String? imagePath;
  final double? budget;
  final Map<String, dynamic> analysisJson;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'productName': productName,
      'imagePath': imagePath,
      'budget': budget,
      'analysisJson': analysisJson,
    };
  }

  factory SearchHistoryEntry.fromJson(Map<dynamic, dynamic> json) {
    return SearchHistoryEntry(
      id: json['id']?.toString() ?? '',
      timestamp: DateTime.parse(json['timestamp']?.toString() ?? DateTime.now().toIso8601String()),
      productName: json['productName']?.toString() ?? '',
      imagePath: json['imagePath']?.toString(),
      budget: (json['budget'] as num?)?.toDouble(),
      analysisJson: Map<String, dynamic>.from(json['analysisJson'] as Map? ?? {}),
    );
  }
}
