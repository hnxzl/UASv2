import 'package:flutter/material.dart';
import 'package:tododo/auth/auth_service.dart';
import 'package:tododo/models/note_model.dart';
import 'package:google_fonts/google_fonts.dart';
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
      setState(() {});
      noteController.clear();
      titleController.clear();
      Navigator.pop(context);
    }
  }

  /// Dialog Tambah atau Edit Catatan
  void showNoteDialog({NoteModel? note}) {
    titleController.text = note?.title ?? '';
    noteController.text = note?.content ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Color(0xFFFFF8E1), // Warna soft
        title: Text(
          note == null ? "Tambah Catatan" : "Edit Catatan",
          style: GoogleFonts.patrickHand(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Judul Catatan",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: "Isi Catatan",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF5FB2FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (note == null) {
                await addNewNote();
              } else {
                await noteDatabase.updateNote(
                    note, noteController.text, titleController.text);
                if (mounted) setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  /// Konfirmasi Hapus Catatan
  Future<bool> deleteNote(NoteModel note) async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Note?"),
            content: const Text("This action cannot be undone."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await noteDatabase.deleteNote(note);
                  if (mounted) setState(() {});
                  Navigator.pop(context, true);
                },
                child:
                    const Text("Delete", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF8E1), // Warna krem pastel
      appBar: AppBar(
        title: Text(
          "Notes 📝",
          style: GoogleFonts.patrickHand(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Color(0xFF5FB2FF), // Warna soft pink
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showNoteDialog(),
        backgroundColor: Color(0xFF5FB2FF),
        child: const Icon(Icons.add, color: Colors.white),
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
            return const Center(
              child: Text(
                'No notes yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final note = notes[index];
              return Dismissible(
                key: Key(note.id),
                background: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.edit, color: Colors.white),
                ),
                secondaryBackground: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    return await deleteNote(note);
                  } else {
                    showNoteDialog(note: note);
                    return false;
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(
                        0xFFFFF3B0), // Kuning pastel, biar mirip sticky notes
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Color(0xFFE6A700), width: 1), // Efek kertas
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  constraints: BoxConstraints(
                      minHeight: 120), // Biar nggak terlalu pendek
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: GoogleFonts.patrickHand(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          decoration: TextDecoration.underline,
                          color: Color(
                              0xFF6D4C41), // Warna coklat tua biar mirip tinta pena
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        note.content,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.patrickHand(
                          fontSize: 18,
                          fontStyle: FontStyle.italic, // Tambahin efek miring
                          color: Color(0xFF6D4C41),
                        ),
                      ),
                    ],
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
