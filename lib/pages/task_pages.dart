import 'package:flutter/material.dart';
import 'package:tododo/auth/auth_service.dart';
import 'package:tododo/models/task_model.dart';
import 'package:tododo/services/task_database.dart';
import 'package:intl/intl.dart';

class TaskPage extends StatefulWidget {
  final AuthService authService;

  const TaskPage({super.key, required this.authService});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  late final TaskDatabase taskDatabase;
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime? dueDate;
  String priority = 'Normal';
  String status = 'Pending';
  String? userId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    userId = widget.authService.supabase.auth.currentUser?.id;
    taskDatabase = TaskDatabase(supabase: widget.authService.supabase);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> updateTask(TaskModel task) async {
    FocusScope.of(context).requestFocus(FocusNode());
    setState(() => isLoading = true);

    final updatedTask = TaskModel(
      id: task.id,
      userId: task.userId,
      title: titleController.text,
      description: descriptionController.text,
      dueDate: dueDate!,
      priority: priority,
      status: status,
      createdAt: task.createdAt,
      updatedAt: DateTime.now(),
    );

    await taskDatabase.updateTask(updatedTask);

    if (mounted) {
      setState(() {
        isLoading = false;
        titleController.clear();
        descriptionController.clear();
        dueDate = null;
      });
      Navigator.pop(context);
    }
  }

  Future<void> deleteTask(TaskModel task) async {
    FocusScope.of(context)
        .requestFocus(FocusNode()); // Hilangkan fokus sebelum dialog muncul

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);
      await taskDatabase.deleteTask(task);
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> addNewTask() async {
    try {
      if (titleController.text.isEmpty ||
          descriptionController.text.isEmpty ||
          dueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all required fields'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() => isLoading = true);

      final newTask = TaskModel(
        userId: userId!,
        title: titleController.text,
        description: descriptionController.text,
        dueDate: dueDate!,
        priority: priority,
        status: status,
      );

      await taskDatabase.createTask(newTask);

      if (!mounted) return;
      setState(() => isLoading = false);

      titleController.clear();
      descriptionController.clear();
      dueDate = null;
      priority = 'Normal';
      status = 'Pending';

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add task: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void showTaskDialog([TaskModel? task]) {
    if (task != null) {
      titleController.text = task.title;
      descriptionController.text = task.description;
      dueDate = task.dueDate;
      priority = task.priority;
      status = task.status;
    } else {
      titleController.clear();
      descriptionController.clear();
      dueDate = null;
      priority = 'Normal';
      status = 'Pending';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => !isLoading,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              title: Text(
                task == null ? "Tugas Baru" : "Edit Tugas",
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              content: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Judul",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Isi",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: isLoading
                          ? null
                          : () async {
                              FocusScope.of(context).unfocus();
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: dueDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2101),
                              );

                              if (pickedDate != null) {
                                final TimeOfDay? pickedTime =
                                    await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );

                                if (pickedTime != null) {
                                  setDialogState(() {
                                    dueDate = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                  });
                                }
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                dueDate == null
                                    ? "Pilih tanggal jatuh tempo"
                                    : DateFormat('dd MMM yyyy, HH:mm')
                                        .format(dueDate!),
                                style: TextStyle(
                                  color: dueDate == null
                                      ? Colors.grey[600]
                                      : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: priority, // Using the local variable directly
                      decoration: InputDecoration(
                        labelText: "Prioritas",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'High', child: Text('High')),
                        DropdownMenuItem(
                            value: 'Normal', child: Text('Normal')),
                        DropdownMenuItem(value: 'Low', child: Text('Low')),
                      ],
                      onChanged: isLoading
                          ? null
                          : (String? newValue) {
                              if (newValue != null) {
                                setDialogState(() {
                                  priority = newValue;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 16),

                    // Status Dropdown
                    DropdownButtonFormField<String>(
                      value: status, // Using the local variable directly
                      decoration: InputDecoration(
                        labelText: "Status",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Completed', child: Text('Completed')),
                        DropdownMenuItem(
                            value: 'Pending', child: Text('Pending')),
                        DropdownMenuItem(
                            value: 'Not Completed',
                            child: Text('Not Completed')),
                      ],
                      onChanged: isLoading
                          ? null
                          : (String? newValue) {
                              if (newValue != null) {
                                setDialogState(() {
                                  status = newValue;
                                });
                              }
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                FilledButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          FocusScope.of(context).unfocus();
                          if (task == null) {
                            await addNewTask();
                          } else {
                            await updateTask(task);
                          }
                        },
                  child: isLoading
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : Text(task == null ? "Simpan" : "Perbarui"),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red.withOpacity(0.1);
      case 'Low':
        return Colors.green.withOpacity(0.1);
      default:
        return Colors.blue.withOpacity(0.1);
    }
  }

  Color _getPriorityTextColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Tugas ✅",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFF5FB2FF), // Warna header
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTaskDialog(),
        backgroundColor: Color(0xFFFFC8DD), // Warna tombol tambah
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder(
        stream: taskDatabase.getTasksByUser(userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Terjadi Kesalahan: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_alt,
                      size: 64, color: Colors.white.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada tugas',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: tasks.length,
            padding: const EdgeInsets.all(16),
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return Dismissible(
                key: Key(task.id),
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.edit, color: Colors.blue),
                ),
                secondaryBackground: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                onDismissed: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    await deleteTask(task);
                    setState(() {});
                  }
                },
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    showTaskDialog(task);
                    return false;
                  }
                  return true;
                },
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  color: _getPriorityColor(task.priority),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  decoration: task.status == 'Completed'
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: task.status == 'Completed'
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(task.priority),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _getPriorityTextColor(task.priority),
                                ),
                              ),
                              child: Text(
                                task.priority,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _getPriorityTextColor(task.priority),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(task.dueDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('HH:mm').format(task.dueDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Spacer(),
                            if (task.status != 'Completed')
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                ),
                                onPressed: () async {
                                  final completedTask = TaskModel(
                                    id: task.id,
                                    userId: task.userId,
                                    title: task.title,
                                    description: task.description,
                                    dueDate: task.dueDate,
                                    priority: task.priority,
                                    status: 'Completed',
                                    createdAt: task.createdAt,
                                    updatedAt: DateTime.now(),
                                  );
                                  await taskDatabase.updateTask(completedTask);
                                  setState(() {});
                                },
                              )
                            else
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: task.status == 'Completed'
                                    ? Colors.green.withOpacity(0.1)
                                    : task.status == 'Not Completed'
                                        ? Colors.red.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: task.status == 'Completed'
                                      ? Colors.green
                                      : task.status == 'Not Completed'
                                          ? Colors.red
                                          : Colors.orange,
                                ),
                              ),
                              child: Text(
                                task.status,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: task.status == 'Completed'
                                      ? Colors.green
                                      : task.status == 'Not Completed'
                                          ? Colors.red
                                          : Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
