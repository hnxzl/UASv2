import 'package:flutter/material.dart';
import '../models/note_model.dart';

class NotePopup extends StatefulWidget {
  @override
  _NotePopupState createState() => _NotePopupState();
}

class _NotePopupState extends State<NotePopup> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Add Note"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: "Title"),
          ),
          TextField(
            controller: _contentController,
            decoration: InputDecoration(labelText: "Content"),
            maxLines: 5,
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
            Note newNote = Note(
              id: DateTime.now().toString(),
              userId: "currentUser",
              title: _titleController.text,
              content: _contentController.text,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            // Logic to save note
            Navigator.of(context).pop(newNote);
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}
