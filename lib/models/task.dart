import 'dart:convert';

class Task {
  final String id;
  String title;
  bool isCompleted;
  final DateTime timestamp;
  String mood; // 'default', 'creative', 'focus', 'chill'

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.timestamp,
    this.mood = 'default',
  });

  // Convert a Task into a Map. The keys must correspond to the names of the
  // columns in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'mood': mood,
    };
  }

  // Implement toString to make it easier to see information about
  // each dog when using the print statement.
  @override
  String toString() {
    return 'Task{id: $id, title: $title, isCompleted: $isCompleted, timestamp: $timestamp, mood: $mood}';
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      isCompleted: (map['isCompleted'] as int) == 1,
      timestamp: DateTime.parse(map['timestamp']),
      mood: map['mood'] ?? 'default',
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));
}
