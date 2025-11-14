class ChapterModel {
  final String title;
  final String content;

  ChapterModel({required this.title, required this.content});

  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      title: json['title'] as String,
      content: json['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'content': content};
  }
}

class WorkContentModel {
  final String title;
  final String author;
  final String summary;
  final List<ChapterModel> chapters;
  final String? content;
  final WorkContentMetadata metadata;

  WorkContentModel({
    required this.title,
    required this.author,
    required this.summary,
    required this.chapters,
    required this.metadata,
    this.content,
  });

  factory WorkContentModel.fromJson(Map<String, dynamic> json) {
    return WorkContentModel(
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      chapters: (json['chapters'] as List<dynamic>? ?? [])
          .map(
            (chapter) => ChapterModel.fromJson(chapter as Map<String, dynamic>),
          )
          .toList(),
      metadata: WorkContentMetadata.fromJson(
        json['metadata'] as Map<String, dynamic>? ?? <String, dynamic>{},
      ),
      content: json['content'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'author': author,
      'summary': summary,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
      if (content != null) 'content': content,
      'metadata': metadata.toJson(),
    };
  }
}

class WorkContentMetadata {
  final Map<String, String> _stringValues;
  final Map<String, List<String>> _listValues;

  WorkContentMetadata({
    Map<String, String>? stringValues,
    Map<String, List<String>>? listValues,
  }) : _stringValues = stringValues ?? <String, String>{},
       _listValues = listValues ?? <String, List<String>>{};

  factory WorkContentMetadata.fromJson(Map<String, dynamic> json) {
    final Map<String, String> stringValues = {};
    final Map<String, List<String>> listValues = {};

    json.forEach((key, value) {
      if (value == null) return;

      if (value is List) {
        final list = value.map((item) => item.toString()).toList();
        listValues[key] = list;
        stringValues[key] = list.join(', ');
      } else {
        stringValues[key] = value.toString();
      }
    });

    // Normalise singular/plural keys to keep backward compatibility
    void ensureAlias(String primary, String alias) {
      if (listValues.containsKey(primary) && !listValues.containsKey(alias)) {
        listValues[alias] = List<String>.from(listValues[primary]!);
        stringValues[alias] = stringValues[primary]!;
      } else if (stringValues.containsKey(primary) &&
          !stringValues.containsKey(alias)) {
        stringValues[alias] = stringValues[primary]!;
      }
    }

    ensureAlias('Relationship', 'Relationships');
    ensureAlias('Relationships', 'Relationship');

    return WorkContentMetadata(
      stringValues: stringValues,
      listValues: listValues,
    );
  }

  String? getString(String key) => _stringValues[key];

  List<String> getList(String key) {
    if (_listValues.containsKey(key)) {
      return _listValues[key]!;
    }
    final value = _stringValues[key];
    if (value == null || value.isEmpty) return [];
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  bool containsKey(String key) => _stringValues.containsKey(key);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    _stringValues.forEach((key, value) {
      if (_listValues.containsKey(key)) {
        json[key] = _listValues[key];
      } else {
        json[key] = value;
      }
    });
    return json;
  }

  Map<String, String> toSimpleMap() => Map<String, String>.from(_stringValues);
}
