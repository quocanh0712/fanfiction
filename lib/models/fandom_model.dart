class FandomModel {
  final String id;
  final String name;
  final String encodedName;
  final String? categoryId;

  FandomModel({
    required this.id,
    required this.name,
    required this.encodedName,
    this.categoryId,
  });

  factory FandomModel.fromJson(Map<String, dynamic> json) {
    return FandomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      encodedName: json['encoded_name'] as String,
      categoryId: json['category_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'encoded_name': encodedName,
      'category_id': categoryId,
    };
  }

  @override
  String toString() {
    return 'FandomModel(id: $id, name: $name, encodedName: $encodedName)';
  }
}

