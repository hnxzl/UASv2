import 'package:flutter/material.dart';
import 'package:tododo/auth/auth_service.dart';
import 'package:tododo/widgets/task_popup.dart';
import 'package:tododo/widgets/event_popup.dart';
import 'package:tododo/widgets/note_popup.dart';
import 'package:tododo/models/task_model.dart';
import 'package:tododo/models/event_model.dart';
import 'package:tododo/models/note_model.dart';
import 'package:tododo/services/task_services.dart';
import 'package:tododo/services/event_services.dart';
import 'package:tododo/services/note_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatefulWidget {
  final AuthService authService;
  final SupabaseClient supabase;

  const DashboardPage(
      {super.key, required this.authService, required this.supabase});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late TaskService taskService;
  late EventService eventService;
  late NoteService noteService;
  String username = "";
  List<Task> tasks = [];
  List<Event> events = [];
  List<Note> notes = [];

  @override
  void initState() {
    super.initState();
    taskService = TaskService(supabase: widget.supabase);
    eventService = EventService(supabase: widget.supabase);
    noteService = NoteService(supabase: widget.supabase);
    _loadUsername();
    _loadData();
  }

  void _loadUsername() async {
    final fetchedUsername = await widget.authService.getUserUsername();
    setState(() {
      username = fetchedUsername ?? "User";
    });
  }

  Future<void> _loadData() async {
    final fetchedTasks = await taskService.getTasks();
    final fetchedEvents = await eventService.getEvents();
    final fetchedNotes = await noteService.getNotes();

    setState(() {
      tasks = fetchedTasks.map((data) => Task.fromJson(data)).toList();
      events = fetchedEvents.map((data) => Event.fromJson(data)).toList();
      notes = fetchedNotes.map((data) => Note.fromJson(data)).toList();
    });
  }

  void _showAddPopup(String type) async {
    bool? isAdded;
    if (type == "Task") {
      isAdded = await showDialog<bool>(
        context: context,
        builder: (context) => TaskPopup(supabase: Supabase.instance.client),
      );
    } else if (type == "Event") {
      isAdded = await showDialog(
        context: context,
        builder: (context) => EventPopup(),
      );
    } else {
      isAdded = await showDialog(
        context: context,
        builder: (context) => NotePopup(),
      );
    }

    if (isAdded == true) {
      _loadData();
    }
  }

  void _showDescription(String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem(String title, String description) {
    return ListTile(
      title: Text(title),
      onTap: () => _showDescription(title, description),
      trailing: PopupMenuButton<String>(
        onSelected: (value) {
          if (value == "edit") {
            // Handle edit
          } else if (value == "delete") {
            // Handle delete
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(value: "edit", child: Text("Edit")),
          PopupMenuItem(value: "delete", child: Text("Delete")),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: Column(
            children: [
              Text("Welcome, $username",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                children: [
                  ElevatedButton(
                      onPressed: () => _showAddPopup("Task"),
                      child: Text("Add Task")),
                  ElevatedButton(
                      onPressed: () => _showAddPopup("Event"),
                      child: Text("Add Event")),
                  ElevatedButton(
                    onPressed: () => _showAddPopup("Note"),
                    child: Text("Add Note"),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  children: [
                    ...tasks.map((task) => _buildListItem(
                        task.title, task.description ?? "No Description")),
                    ...events.map((event) =>
                        _buildListItem(event.title, event.description)),
                    ...notes.map(
                        (note) => _buildListItem(note.title, note.content)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
