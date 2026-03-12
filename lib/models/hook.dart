class Hook {
  final String id;
  final String content;
  final String category;
  final String? description;

  const Hook({
    required this.id,
    required this.content,
    required this.category,
    this.description,
  });

  factory Hook.fromJson(Map<String, dynamic> json) {
    return Hook(
      id: json['id'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
    );
  }
}
