import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tododo/auth/auth_service.dart';
import 'package:tododo/pages/note_pages.dart';
import 'package:tododo/pages/event_pages.dart';
import 'package:tododo/pages/task_pages.dart';
import 'package:tododo/pages/setting_pages.dart';

class DashboardPage extends StatefulWidget {
  final AuthService authService;
  final SupabaseClient supabase;

  const DashboardPage(
      {super.key, required this.authService, required this.supabase});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String username = "User";
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final fetchedUsername = await widget.authService.getUserUsername();
    if (mounted) {
      setState(() {
        username = fetchedUsername ?? "User";
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchTasks() async {
    final userId = widget.supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await widget.supabase
        .from('tasks')
        .select('*')
        .eq('user_id', userId)
        .order('due_date', ascending: true);

    return response;
  }

  Future<List<Map<String, dynamic>>> fetchEvents() async {
    final userId = widget.supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await widget.supabase
        .from('events')
        .select('*')
        .eq('user_id', userId)
        .order('date', ascending: true);

    return response;
  }

  Future<List<Map<String, dynamic>>> fetchNotes() async {
    final userId = widget.supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await widget.supabase
        .from('notes')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            _buildDashboardView(),
            EventPage(authService: widget.authService),
            NotePage(authService: widget.authService),
            TaskPage(authService: widget.authService),
            SettingsPage(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: "Dashboard"),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
          BottomNavigationBarItem(icon: Icon(Icons.note), label: "Notes"),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: "Task"),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: "Settings"),
        ],
      ),
    );
  }

  Widget _buildDashboardView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Welcome back, $username",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.notifications,
                        color: Colors.redAccent),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                  hintText: "Search tasks, notes & events...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30)),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader("Today's Tasks", "Your tasks"),
                FutureBuilder(
                  future: fetchTasks(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final tasks = snapshot.data ?? [];
                    return tasks.isEmpty
                        ? const Text("No tasks available")
                        : Column(
                            children: tasks
                                .map((task) => _buildTaskCard(task['title'],
                                    "Due: ${task['due_date']}", Colors.blue))
                                .toList(),
                          );
                  },
                ),
                const SizedBox(height: 10),
                _buildSectionHeader("Upcoming Events", "Your events"),
                FutureBuilder(
                  future: fetchEvents(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final events = snapshot.data ?? [];
                    return events.isEmpty
                        ? const Text("No events available")
                        : Column(
                            children: events
                                .map((event) => _buildEventCard(event['title'],
                                    "On: ${event['event_date']}"))
                                .toList(),
                          );
                  },
                ),
                const SizedBox(height: 10),
                _buildSectionHeader("Recent Notes", "Your notes"),
                FutureBuilder(
                  future: fetchNotes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final notes = snapshot.data ?? [];
                    return notes.isEmpty
                        ? const Text("No notes available")
                        : Column(
                            children: notes
                                .map((note) => _buildNoteCard(
                                    note['title'] ?? "Untitled",
                                    note['content'] ?? "No content available",
                                    "Updated ${note['created_at'] ?? "Unknown"}"))
                                .toList(),
                          );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildTaskCard(String title, String time, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(width: 5, height: 40, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(time, style: TextStyle(color: Colors.red.shade400)),
      ),
    );
  }

  Widget _buildEventCard(String title, String date) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: const Icon(Icons.event, color: Colors.orange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(date, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildNoteCard(String title, String content, String subtitle) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.note, color: Colors.green),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
