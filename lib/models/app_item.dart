class AppItem {
  final String name;
  final String description;
  final String iconUrl;
  final String? appCode;
  final String openingStatement;
  final List<String> suggestedQuestions;
  final bool isDefault;

  AppItem({
    required this.name,
    required this.description,
    required this.iconUrl,
    this.appCode,
    required this.openingStatement,
    required this.suggestedQuestions,
    required this.isDefault,
  });

  factory AppItem.fromJson(Map<String, dynamic> json) {
    return AppItem(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['icon_url'] ?? '',
      appCode: json['app_code'],
      openingStatement: json['opening_statement'] ?? '',
      suggestedQuestions: List<String>.from(json['suggested_questions'] ?? []),
      isDefault: json['is_default'] ?? false,
    );
  }
}
