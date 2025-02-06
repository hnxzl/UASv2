import 'package:flutter/material.dart';
import 'package:tododo/auth/auth_service.dart';
import 'package:tododo/models/note_model.dart';
import 'package:tododo/services/note_database.dart';

class NotePage extends StatefulWidget {
  final AuthService authService;

  const NotePage({super.key, required this.authService});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  late final NoteDatabase noteDatabase;
  final TextEditingController noteController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = widget.authService.supabase.auth.currentUser?.id;
    noteDatabase = NoteDatabase(supabase: widget.authService.supabase);
  }

  @override
  void dispose() {
    noteController.dispose();
    titleController.dispose();
    super.dispose();
  }

  /// Tambah catatan baru
  Future<void> addNewNote() async {
    if (noteController.text.isEmpty || titleController.text.isEmpty) return;

    final newNote = NoteModel(
      content: noteController.text,
      userId: userId!,
      title: titleController.text,
      id: '',
    );

    await noteDatabase.createNote(newNote);

    if (mounted) {
      setState(() {}); // 🔄 Refresh UI setelah save
      noteController.clear();
      titleController.clear();
      Navigator.pop(context); // ✅ Tutup dialog setelah save
    }
  }

  /// Update catatan dengan dialog
  Future<void> updateNoteDialog(NoteModel note) async {
    titleController.text = note.title;
    noteController.text = note.content;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Note"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: "Edit title",
                  labelText: "Title",
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  hintText: "Edit your note",
                  labelText: "Content",
                ),
                maxLines: null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await noteDatabase.updateNote(
                  note,
                  noteController.text,
                  titleController.text,
                );
                if (mounted) {
                  setState(() {}); // 🔄 Refresh UI setelah update
                  Navigator.pop(context); // ✅ Langsung menutup dialog
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  /// Hapus catatan dengan konfirmasi
  Future<bool> deleteNote(NoteModel note) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Note?"),
          content: const Text("This action cannot be undone."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                await noteDatabase.deleteNote(note);
                if (mounted) {
                  setState(() {}); // 🔄 Refresh UI setelah delete
                }
                Navigator.pop(context, true);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    return confirmDelete ?? false;
  }

  /// Dialog tambah catatan baru
  void showAddNoteDialog() {
    titleController.clear();
    noteController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Note"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Enter title",
                labelText: "Title",
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                hintText: "Enter your note",
                labelText: "Content",
              ),
              maxLines: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await addNewNote();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notes")),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddNoteDialog,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: noteDatabase.getNotesByUser(userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notes = snapshot.data ?? [];
          if (notes.isEmpty) {
            return const Center(child: Text('No notes yet'));
          }

          return ListView.separated(
            itemCount: notes.length,
            separatorBuilder: (context, index) =>
                const Divider(thickness: 1, height: 20),
            itemBuilder: (context, index) {
              final note = notes[index];
              return Dismissible(
                key: Key(note.id),
                background: Container(
                  color: Colors.green,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                secondaryBackground: Container(
                  color: Colors.red,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    return await deleteNote(note);
                  } else {
                    updateNoteDialog(note);
                    return false;
                  }
                },
                child: ListTile(
                  title: Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: Text(note.content),
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
