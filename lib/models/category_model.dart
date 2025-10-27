class CategoryModel {
  final String id;
  final String name;
  final String encodedName;

  CategoryModel({
    required this.id,
    required this.name,
    required this.encodedName,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      encodedName: json['encoded_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'encoded_name': encodedName};
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, encodedName: $encodedName)';
  }
}
