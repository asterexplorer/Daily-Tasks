import 'dart:convert';

class Task {
  final String id;
  String title;
  bool isCompleted;
  final DateTime timestamp;
  String mood; // 'default', 'creative', 'focus', 'chill', 'energy'
  String priority; // 'Low', 'Medium', 'High'
  String category; // 'Personal', 'Work', 'Health', 'Study', 'Other'

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    required this.timestamp,
    this.mood = 'default',
    this.priority = 'Medium',
    this.category = 'Personal',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'mood': mood,
      'priority': priority,
      'category': category,
    };
  }

  @override
  String toString() {
    return 'Task{id: $id, title: $title, isCompleted: $isCompleted, timestamp: $timestamp, mood: $mood, priority: $priority, category: $category}';
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      title: map['title'],
      isCompleted: (map['isCompleted'] as int) == 1,
      timestamp: DateTime.parse(map['timestamp']),
      mood: map['mood'] ?? 'default',
      priority: map['priority'] ?? 'Medium',
      category: map['category'] ?? 'Personal',
    );
  }

  String toJson() => json.encode(toMap());

  factory Task.fromJson(String source) => Task.fromMap(json.decode(source));
}

