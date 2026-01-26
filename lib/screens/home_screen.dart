import 'dart:async';
import 'dart:ui';
import 'package:app/utils/mood_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/database_service.dart';
import '../utils/task_theme.dart';
import '../widgets/task_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Task> _tasks = [];
  bool _isLoading = true;
  final TextEditingController _taskController = TextEditingController();
  final Uuid _uuid = const Uuid();

  // Calendar State
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Clock State
  String _timeString = '';
  Timer? _timer;

  // Filter State
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _updateTime();
    _timer =
        Timer.periodic(const Duration(seconds: 1), (Timer t) => _updateTime());
    _loadTasks();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _taskController.dispose();
    super.dispose();
  }

  void _updateTime() {
    final DateTime now = DateTime.now();
    final String formattedTime = DateFormat('h:mm a').format(now);
    if (mounted && _timeString != formattedTime) {
      setState(() {
        _timeString = formattedTime;
      });
    }
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    // Artificial delay to show the nice loading state
    await Future.delayed(const Duration(milliseconds: 600));
    final tasks = await _databaseService.getTasks();
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _sortTasks();
        _isLoading = false;
      });
    }
  }

  List<Task> get _filteredTasks {
    List<Task> filtered = _tasks;
    if (_selectedDay != null) {
      filtered = filtered.where((task) => isSameDay(task.timestamp, _selectedDay)).toList();
    }
    if (_selectedCategory != 'All') {
      filtered = filtered.where((task) => task.category == _selectedCategory).toList();
    }
    return filtered;
  }

  // ... (keep _sortTasks, _addTask, _toggleTaskType, _deleteTask, _showAddTaskModal same or similar, assuming they are not in this chunk range)
  // Wait, I need to be careful with the chunk. I'll stick to replacing the state variables and _loadTasks first,
  // and then do the build method in a separate chunk or if covered here.
  // Actually, let's just replace the top part of the class first.

  void _sortTasks() {
    _tasks.sort((a, b) {
      if (a.isCompleted == b.isCompleted) {
        return b.timestamp.compareTo(a.timestamp);
      }
      return a.isCompleted ? 1 : -1;
    });
  }

  Future<void> _addTask(String title, {String mood = 'default', String priority = 'Medium', String category = 'Personal'}) async {
    if (title.isEmpty) return;

    final newTask = Task(
      id: _uuid.v4(),
      title: title,
      timestamp: _selectedDay ?? DateTime.now(),
      mood: mood,
      priority: priority,
      category: category,
    );

    await _databaseService.insertTask(newTask);
    _taskController.clear();
    _loadTasks();
  }

  Future<void> _toggleTaskType(Task task) async {
    task.isCompleted = !task.isCompleted;
    await _databaseService.updateTask(task);
    setState(() {
      _sortTasks();
    });
  }

  Future<void> _deleteTask(Task task) async {
    // Optimistically remove from list
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });

    // Show undo snackbar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Task deleted', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Theme.of(context).colorScheme.primary,
          onPressed: () {
            // Undo action: just add it back to state, we haven't deleted from DB yet
            setState(() {
              _tasks.add(task);
              _sortTasks();
            });
          },
        ),
      ),
    ).closed.then((reason) {
      if (reason != SnackBarClosedReason.action) {
        // If not undone, actually delete from DB
        _databaseService.deleteTask(task.id);
      }
    });
  }

  Future<void> _editTask(Task task, String newTitle, String newMood, String newPriority, String newCategory) async {
    task.title = newTitle;
    task.mood = newMood;
    task.priority = newPriority;
    task.category = newCategory;
    await _databaseService.updateTask(task);
    _loadTasks();
  }

  void _showAddTaskModal(BuildContext context, {Task? taskToEdit}) {
    String selectedMood = taskToEdit?.mood ?? 'default';
    String selectedPriority = taskToEdit?.priority ?? 'Medium';
    String selectedCategory = taskToEdit?.category ?? 'Personal';
    _taskController.text = taskToEdit?.title ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      taskToEdit == null ? 'New Task' : 'Edit Task',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2D3142),
                          ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _taskController,
                  autofocus: true,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: 'What needs to be done?',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  ),
                ),
                const SizedBox(height: 24),
                // Priority Selection
                Text('Priority', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: TaskTheme.priorities.map((p) {
                    final isSelected = selectedPriority == p;
                    return InkWell(
                      onTap: () => setModalState(() => selectedPriority = p),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? TaskTheme.priorityColors[p] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: TaskTheme.priorityColors[p]!.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ] : null,
                        ),
                        child: Text(
                          p,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Category Selection
                Text('Category', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: TaskTheme.categories.map((c) {
                    final isSelected = selectedCategory == c;
                    return InkWell(
                      onTap: () => setModalState(() => selectedCategory = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? TaskTheme.categoryColors[c] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              TaskTheme.categoryIcons[c],
                              size: 18,
                              color: isSelected ? Colors.white : Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              c,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Mood Selection
                Text('Style', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: MoodTheme.gradients.keys.map((mood) {
                      final isSelected = selectedMood == mood;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedMood = mood),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: MoodTheme.gradients[mood],
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: MoodTheme.getTextColor(mood),
                                  )
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    if (taskToEdit != null) {
                      _editTask(taskToEdit, _taskController.text, selectedMood, selectedPriority, selectedCategory);
                    } else {
                      _addTask(_taskController.text, mood: selectedMood, priority: selectedPriority, category: selectedCategory);
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    elevation: 4,
                    shadowColor: Theme.of(context).primaryColor.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    taskToEdit == null ? 'Create Task' : 'Update Task',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(() {
      _taskController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;
    final completedCount = filteredTasks.where((t) => t.isCompleted).length;
    final progress =
        filteredTasks.isEmpty ? 0.0 : completedCount / filteredTasks.length;

    return Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        body: Stack(
          children: [
            // Background Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                    const Color(0xFF1A237E), // Deep Indigo
                  ],
                ),
              ),
            ),
            // Ambient Circles
            Positioned(
              top: -100,
              left: -100,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.purpleAccent.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -50,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.cyanAccent.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            // Main Content
            SafeArea(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // CENTERED HEADER
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    'My Day',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _timeString,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  // Calendar Strip
                                  Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    padding: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: TableCalendar(
                                      firstDay: DateTime.utc(2024, 1, 1),
                                      lastDay: DateTime.utc(2030, 12, 31),
                                      focusedDay: _focusedDay,
                                      calendarFormat: _calendarFormat,
                                      currentDay: DateTime.now(),
                                      selectedDayPredicate: (day) {
                                        return isSameDay(_selectedDay, day);
                                      },
                                      onDaySelected: (selectedDay, focusedDay) {
                                        if (!isSameDay(
                                            _selectedDay, selectedDay)) {
                                          setState(() {
                                            _selectedDay = selectedDay;
                                            _focusedDay = focusedDay;
                                          });
                                        }
                                      },
                                      onFormatChanged: (format) {
                                        if (_calendarFormat != format) {
                                          setState(() {
                                            _calendarFormat = format;
                                          });
                                        }
                                      },
                                      onPageChanged: (focusedDay) {
                                        _focusedDay = focusedDay;
                                      },
                                      headerVisible: false,
                                      daysOfWeekStyle: DaysOfWeekStyle(
                                        weekdayStyle: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.8)),
                                        weekendStyle: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.8)),
                                      ),
                                      calendarStyle: CalendarStyle(
                                        defaultTextStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        weekendTextStyle: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        selectedDecoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        selectedTextStyle: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        todayDecoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.3),
                                          shape: BoxShape.circle,
                                        ),
                                        todayTextStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Summary Cards
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                        const SizedBox(height: 12),
                                        Text(
                                          '$completedCount/${filteredTasks.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Completed',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                                        const SizedBox(height: 12),
                                        Text(
                                          '${(progress * 100).toInt()}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Overall Progress',
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Category Filter
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: ['All', ...TaskTheme.categories].map((c) {
                                  final isSelected = _selectedCategory == c;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(c),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setState(() => _selectedCategory = c);
                                      },
                                      labelStyle: TextStyle(
                                        color: isSelected ? Colors.black87 : Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      selectedColor: Colors.white,
                                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : filteredTasks.isEmpty
                            ? Center(
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(32),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.05),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.rocket_launch_rounded,
                                          size: 64,
                                          color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        _selectedCategory == 'All' 
                                          ? 'Ready to conquer the day?\nTap + to add a new task.'
                                          : 'No ${_selectedCategory.toLowerCase()} tasks yet.\nTime to plan ahead!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 16,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 24, 24, 100),
                                itemCount: filteredTasks.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  return TaskTile(
                                    task: filteredTasks[index],
                                    onCheckboxChanged: (value) =>
                                        _toggleTaskType(filteredTasks[index]),
                                    onDelete: () =>
                                        _deleteTask(filteredTasks[index]),
                                    onEdit: () => _showAddTaskModal(context,
                                        taskToEdit: filteredTasks[index]),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 6,
          elevation: 8,
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
              border: Border(
                // ignore: deprecated_member_use
                top: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddTaskModal(context),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add, size: 32),
        ));
  }
}
