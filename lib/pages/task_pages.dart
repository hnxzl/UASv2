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
    setState(() {
      isLoading = true;
    });

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
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
      setState(() {
        isLoading = true;
      });

      await taskDatabase.deleteTask(task);

      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void selectDueDate(
      BuildContext context, Function(DateTime) onSelected) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        onSelected(selectedDateTime);
      }
    }
  }

  Future<void> addNewTask() async {
    try {
      if (titleController.text.isEmpty ||
          descriptionController.text.isEmpty ||
          dueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all required fields')),
        );
        return;
      }

      if (!mounted) return;
      setState(() {
        isLoading = true;
      });

      final newTask = TaskModel(
        // Remove id parameter - let Supabase generate it
        userId: userId!,
        title: titleController.text,
        description: descriptionController.text,
        dueDate: dueDate!,
        priority: priority,
        status: status,
        // Remove createdAt and updatedAt - let them use defaults
      );

      await taskDatabase.createTask(newTask);

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      titleController.clear();
      descriptionController.clear();
      dueDate = null;
      priority = 'Normal';
      status = 'Pending';

      Navigator.pop(context);
    } catch (e, stackTrace) {
      print('Error adding task: $e');
      print('Stack trace: $stackTrace');

      if (!mounted) return;
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add task: ${e.toString()}')),
      );
    }
  }

  void showTaskDialog([TaskModel? task]) {
    // Reset form state di awal
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
      barrierDismissible: false, // Prevent dismissing during loading
      builder: (context) => WillPopScope(
        onWillPop: () async => !isLoading, // Prevent back button during loading
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(task == null ? "New Task" : "Edit Task"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        errorText: null, // Reset error state
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        errorText: null, // Reset error state
                      ),
                      maxLines: null,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      title: const Text("Due Date & Time"),
                      subtitle: Text(
                        dueDate == null
                            ? "Select date and time"
                            : DateFormat('yyyy-MM-dd HH:mm').format(dueDate!),
                      ),
                      onTap: isLoading
                          ? null
                          : () async {
                              // Pilih tanggal
                              final DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: dueDate ?? DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2101),
                              );

                              if (pickedDate != null) {
                                // Pilih waktu setelah memilih tanggal
                                final TimeOfDay? pickedTime =
                                    await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.now(),
                                );

                                if (pickedTime != null) {
                                  // Gabungkan tanggal dan waktu
                                  final DateTime combinedDateTime = DateTime(
                                    pickedDate.year,
                                    pickedDate.month,
                                    pickedDate.day,
                                    pickedTime.hour,
                                    pickedTime.minute,
                                  );

                                  setDialogState(() {
                                    dueDate = combinedDateTime;
                                  });
                                }
                              }
                            },
                    ),
                    DropdownButtonFormField<String>(
                      value: priority,
                      decoration: const InputDecoration(labelText: "Priority"),
                      items: ['High', 'Normal', 'Low'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (newValue) {
                              if (newValue != null) {
                                setDialogState(() {
                                  priority = newValue;
                                });
                              }
                            },
                    ),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(labelText: "Status"),
                      items: ['Completed', 'Pending', 'Not Completed']
                          .map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (newValue) {
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
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (task == null) {
                            await addNewTask();
                          } else {
                            await updateTask(task);
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(task == null ? "Save" : "Update"),
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
        return const Color.fromARGB(255, 204, 77, 89);
      case 'Low':
        return const Color.fromARGB(255, 138, 255, 142);
      default:
        return const Color.fromARGB(255, 123, 193, 243);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tasks")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showTaskDialog(),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: taskDatabase.getTasksByUser(userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return const Center(child: Text('No tasks yet'));
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
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                secondaryBackground: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    await deleteTask(task);
                    setState(() {}); // Perbarui tampilan setelah menghapus
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
                  color: _getPriorityColor(task.priority),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: task.status == 'Completed'
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(task.description),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('yyyy-MM-dd').format(task.dueDate),
                              style: const TextStyle(fontSize: 12),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: task.status == 'Completed'
                                    ? Colors.green
                                    : task.status == 'Not Completed'
                                        ? Colors.red
                                        : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                task.status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: task.status != 'Completed'
                        ? IconButton(
                            icon: const Icon(Icons.check_circle_outline),
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
                        : const Icon(Icons.check_circle, color: Colors.green),
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
