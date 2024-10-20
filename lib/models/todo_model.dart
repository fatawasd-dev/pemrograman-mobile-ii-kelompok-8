class TodoModel {
  final String? id;
  final String title;
  final String description;

  TodoModel({this.id, required this.title, required this.description});

  factory TodoModel.fromMap(Map<String, dynamic> map, String id) {
    return TodoModel(
        id: id,
        title: map['title'] ?? '',
        description: map['description'] ?? '');
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
    };
  }
}
