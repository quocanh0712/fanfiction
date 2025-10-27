class FandomModel {
  final String id;
  final String name;
  final int? count;

  FandomModel({required this.id, required this.name, this.count});

  factory FandomModel.fromJson(Map<String, dynamic> json) {
    return FandomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      count: json['count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'count': count};
  }

  @override
  String toString() {
    return 'FandomModel(id: $id, name: $name, count: $count)';
  }
}
