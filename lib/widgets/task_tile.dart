import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../utils/mood_theme.dart';
import '../utils/task_theme.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final Function(bool?)? onCheckboxChanged;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  const TaskTile({
    super.key,
    required this.task,
    required this.onCheckboxChanged,
    required this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        onDelete();
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          Icons.delete_rounded,
          color: Colors.red.shade400,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: task.mood == 'default' ? null : MoodTheme.gradients[task.mood],
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: task.isCompleted ? Colors.transparent : Colors.grey.withOpacity(0.1),
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onCheckboxChanged?.call(!task.isCompleted),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildCheckbox(context),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: TaskTheme.priorityColors[task.priority],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task.title,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task.isCompleted
                                          ? Colors.grey.withOpacity(0.5)
                                          : MoodTheme.getTextColor(task.mood),
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (task.mood == 'default' 
                                  ? (TaskTheme.categoryColors[task.category] ?? Colors.grey)
                                  : Colors.white).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    TaskTheme.categoryIcons[task.category],
                                    size: 12,
                                    color: task.mood == 'default' 
                                      ? TaskTheme.categoryColors[task.category] 
                                      : Colors.white.withOpacity(0.8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    task.category,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: task.mood == 'default' 
                                        ? TaskTheme.categoryColors[task.category] 
                                        : Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: MoodTheme.getTextColor(task.mood).withOpacity(0.5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('h:mm a').format(task.timestamp),
                              style: TextStyle(
                                fontSize: 11,
                                color: MoodTheme.getTextColor(task.mood).withOpacity(0.5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: MoodTheme.getTextColor(task.mood).withOpacity(0.4),
      ),
      onSelected: (value) {
        if (value == 'edit') {
          onEdit?.call();
        } else if (value == 'delete') {
          onDelete();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 18),
              SizedBox(width: 12),
              Text('Edit'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_rounded, size: 18, color: Colors.red),
              SizedBox(width: 12),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckbox(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 26,
      width: 26,
      decoration: BoxDecoration(
        color: task.isCompleted
            ? Theme.of(context).primaryColor
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: task.isCompleted
              ? Theme.of(context).primaryColor
              : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: task.isCompleted
          ? const Icon(
              Icons.check_rounded,
              size: 18,
              color: Colors.white,
            )
          : null,
    );
  }
}

