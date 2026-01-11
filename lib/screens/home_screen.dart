import 'dart:async';
import 'dart:ui';
import 'package:app/utils/mood_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/database_service.dart';
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
    if (_selectedDay == null) return _tasks;
    return _tasks.where((task) {
      return isSameDay(task.timestamp, _selectedDay);
    }).toList();
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

  Future<void> _addTask(String title, {String mood = 'default'}) async {
    if (title.isEmpty) return;

    final newTask = Task(
      id: _uuid.v4(),
      title: title,
      timestamp: _selectedDay ?? DateTime.now(),
      mood: mood,
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
    await _databaseService.deleteTask(task.id);
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
  }

  Future<void> _editTask(Task task, String newTitle, String newMood) async {
    task.title = newTitle;
    task.mood = newMood;
    // Keep the original timestamp or update it? Usually editing keeps original time
    // slightly problematic if sorting by time, but let's keep it.
    await _databaseService.updateTask(task);
    _loadTasks();
  }

  void _showAddTaskModal(BuildContext context, {Task? taskToEdit}) {
    String selectedMood = taskToEdit?.mood ?? 'default';
    _taskController.text = taskToEdit?.title ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                taskToEdit == null ? 'New Task' : 'Edit Task',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D3142),
                    ),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: MoodTheme.gradients.keys.map((mood) {
                    final isSelected = selectedMood == mood;
                    return GestureDetector(
                      onTap: () => setState(() => selectedMood = mood),
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
                          width: 48,
                          height: 48,
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
              const SizedBox(height: 24),
              TextField(
                controller: _taskController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onSubmitted: (value) {
                  if (taskToEdit != null) {
                    _editTask(taskToEdit, value, selectedMood);
                  } else {
                    _addTask(value, mood: selectedMood);
                  }
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (taskToEdit != null) {
                    _editTask(taskToEdit, _taskController.text, selectedMood);
                  } else {
                    _addTask(_taskController.text, mood: selectedMood);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  taskToEdit == null ? 'Add Task' : 'Save Changes',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      // Clear controller when closed if it was an add action, but for edit we might want to be careful
      // actually _addTask clears it, so we should be fine.
      // But if we cancel the modal without saving, we might want to clear.
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
                            if (!_isLoading && filteredTasks.isNotEmpty) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Progress',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                  ),
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  // ignore: deprecated_member_use
                                  backgroundColor:
                                      // ignore: deprecated_member_use
                                      Colors.white.withOpacity(0.2),
                                  valueColor: const AlwaysStoppedAnimation(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ],
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
                                            // ignore: deprecated_member_use
                                            color:
                                                // ignore: deprecated_member_use
                                                Colors.black.withOpacity(0.05),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.task_alt_rounded,
                                        size: 64,
                                        color: Colors.grey[300],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'All caught up!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF2D3142),
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Create a task to get started',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
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
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
              border: Border(
                // ignore: deprecated_member_use
                top: BorderSide(color: Colors.grey.withOpacity(0.12)),
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
