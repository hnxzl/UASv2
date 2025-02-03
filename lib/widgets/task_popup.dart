import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class TaskPopup extends StatefulWidget {
  final SupabaseClient supabase; // Supabase instance

  const TaskPopup({Key? key, required this.supabase}) : super(key: key);

  @override
  _TaskPopupState createState() => _TaskPopupState();
}

class _TaskPopupState extends State<TaskPopup> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _dueDate;
  String _priority = "Normal";

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _saveTask() async {
    final user = widget.supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not logged in!")),
      );
      return;
    }

    final newTask = {
      "id": Uuid().v4(), // Generate UUID untuk task ID
      "userId": user.id, // User ID dari Supabase
      "title": _titleController.text,
      "description": _descriptionController.text,
      "dueDate": _dueDate?.toIso8601String(),
      "priority": _priority,
      "status": "Pending",
      "created_at": DateTime.now().toIso8601String(),
      "updated_at": DateTime.now().toIso8601String(),
    };

    final response = await widget.supabase.from("tasks").insert(newTask);

    if (response.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to save task: ${response.error!.message}")),
      );
    } else {
      Navigator.of(context).pop(true); // Kembalikan true jika berhasil
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Task"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: "Title"),
          ),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: "Description"),
          ),
          Row(
            children: [
              Text("Due Date: "),
              TextButton(
                onPressed: () => _selectDate(context),
                child: Text(_dueDate == null
                    ? "Select Date"
                    : "${_dueDate!.toLocal()}".split(' ')[0]),
              ),
            ],
          ),
          DropdownButton<String>(
            value: _priority,
            onChanged: (String? newValue) {
              setState(() {
                _priority = newValue!;
              });
            },
            items: ["High", "Normal", "Low"].map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(false), // Kembalikan false jika batal
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: _saveTask, // Simpan task
          child: Text("Save"),
        ),
      ],
    );
  }
}
