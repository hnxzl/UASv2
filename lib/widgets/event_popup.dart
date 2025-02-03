import 'package:flutter/material.dart';
import '../models/event_model.dart';

class EventPopup extends StatefulWidget {
  @override
  _EventPopupState createState() => _EventPopupState();
}

class _EventPopupState extends State<EventPopup> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  DateTime? _startTime;
  DateTime? _endTime;

  Future<void> _selectDateTime(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Event"),
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
          TextField(
            controller: _locationController,
            decoration: InputDecoration(labelText: "Location"),
          ),
          Row(
            children: [
              Text("Start Time: "),
              TextButton(
                onPressed: () => _selectDateTime(context, true),
                child: Text(_startTime == null
                    ? "Select Date"
                    : "${_startTime!.toLocal()}".split(' ')[0]),
              ),
            ],
          ),
          Row(
            children: [
              Text("End Time: "),
              TextButton(
                onPressed: () => _selectDateTime(context, false),
                child: Text(_endTime == null
                    ? "Select Date"
                    : "${_endTime!.toLocal()}".split(' ')[0]),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            Event newEvent = Event(
              id: DateTime.now().toString(),
              userId: "currentUser",
              title: _titleController.text,
              description: _descriptionController.text,
              location: _locationController.text,
              startTime: _startTime ?? DateTime.now(),
              endTime: _endTime ?? DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            // Logic to save event
            Navigator.of(context).pop(newEvent);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}
