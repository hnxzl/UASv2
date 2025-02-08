import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tododo/auth/auth_service.dart';
import 'package:tododo/pages/note_pages.dart';
import 'package:tododo/pages/event_pages.dart';
import 'package:tododo/pages/task_pages.dart';
import 'package:tododo/pages/setting_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardPage extends StatefulWidget {
  final AuthService authService;
  final SupabaseClient supabase;

  const DashboardPage(
      {super.key, required this.authService, required this.supabase});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String username = "User ";
  int _selectedIndex = 0;
  String _searchQuery = "";
  bool isDarkMode = false;
  Color accentColor = Colors.blue;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPreferences();
    _initializeNotifications();
  }

  Future<void> _loadUserData() async {
    final fetchedUsername = await widget.authService.getUserUsername();
    if (mounted) {
      setState(() {
        username = fetchedUsername ?? "User ";
      });
    }
  }

  Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
      final savedColor = prefs.getInt('accentColor') ?? Colors.blue.value;
      accentColor = Color(savedColor);
    });
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    await prefs.setInt('accentColor', accentColor.value);
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
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
        .order('event_date', ascending: true);

    return response;
  }

  Future<List<Map<String, dynamic>>> fetchNotes() async {
    final userId = widget.supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await widget.supabase
        .from('notes')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: true);

    return response;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> openLocationInMaps(String location) async {
    final encodedLocation = Uri.encodeComponent(location);
    final url =
        'https://www.google.com/maps/search/?api=1&query=$encodedLocation';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = isDarkMode ? ThemeData.dark() : ThemeData.light();

    return Theme(
      data: theme.copyWith(
        primaryColor: Color(0xFF5FB2FF), // Warna biru untuk primary color
        colorScheme: theme.colorScheme.copyWith(
            secondary: Color(0xFFFFC8DD)), // Warna pink untuk secondary color
      ),
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: SafeArea(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              _buildDashboardView(), // Dashboard (Index 0)
              TaskPage(authService: widget.authService), // Task (Index 1)
              EventPage(authService: widget.authService), // Events (Index 2)
              NotePage(authService: widget.authService), // Notes (Index 3)
              SettingsPage(
                  authService: widget.authService), // Settings (Index 4)
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Color(0xFF5FB2FF), // Warna biru untuk navbar
          selectedItemColor: const Color.fromARGB(
              255, 255, 255, 255), // Warna putih untuk item terpilih
          unselectedItemColor:
              Colors.white, // Abu-abu untuk item tidak terpilih
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard), label: "Dashboard"),
            BottomNavigationBarItem(icon: Icon(Icons.task), label: "Task"),
            BottomNavigationBarItem(icon: Icon(Icons.event), label: "Events"),
            BottomNavigationBarItem(icon: Icon(Icons.note), label: "Notes"),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: "Settings"),
          ],
        ),
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
              _buildHeader(),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionWithFilter("Today's Tasks", fetchTasks),
                const SizedBox(height: 10),
                _buildSectionWithFilter("Upcoming Events", fetchEvents),
                const SizedBox(height: 10),
                _buildSectionWithFilter("Recent Notes", fetchNotes),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5F49FF), Color(0xFF5FB2FF)], // Gradient ungu biru
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Text(
                      username[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Welcome back,",
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none,
                        size: 28, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Fitur belum tersedia saat ini")),
                      );
                    },
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Search Bar langsung di dalam header
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search tasks, notes & events...",
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String title) {
    if (title.contains('Task')) {
      return Colors.blue.withOpacity(0.5);
    } else if (title.contains('Event')) {
      return Colors.orange.withOpacity(0.5);
    } else {
      return Colors.green.withOpacity(0.5);
    }
  }

  Widget _buildCategoryHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getCategoryColor(title),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "$count ${title.contains('Task') ? 'pending' : title.contains('Event') ? 'events' : 'new'}",
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWithFilter(
      String title, Future<List<Map<String, dynamic>>> Function() fetchData) {
    return FutureBuilder(
      future: fetchData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final items = snapshot.data ?? [];
        final filteredItems = items
            .where((item) =>
                item['title'].toString().toLowerCase().contains(_searchQuery))
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCategoryHeader(title, filteredItems.length),
            filteredItems.isEmpty
                ? _buildEmptyState(title)
                : ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];

                      if (title.contains('Tasks')) {
                        String priority = item['priority'] ?? 'Normal';
                        return _buildTaskCard(
                          item['title'],
                          priorityColor(priority), // Pastikan ada warna default
                          "Due: ${DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.parse(item['due_date']))}",
                        );
                      } else if (title.contains('Events')) {
                        return _buildEventCard(
                          item['title'],
                          "On: ${DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.parse(item['event_date']))}",
                          item[
                              'location'], // Tambahkan lokasi agar bisa dipakai di event card
                        );
                      } else {
                        return _buildNoteCard(
                          item['title'] ?? "Untitled",
                          item['content'] ?? "No content available",
                        );
                      }
                    },
                  ),
            const SizedBox(height: 15),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String section) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            section.contains('Tasks')
                ? Icons.task
                : section.contains('Events')
                    ? Icons.event
                    : Icons.note,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(height: 8),
          Text(
            "No ${section.toLowerCase()} available",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Ubah warna latar belakang
          title: Text(
            "Notifikasi",
            style: TextStyle(color: Colors.black), // Warna teks judul
          ),
          content: Text(
            "Fitur belum tersedia saat ini.",
            style: TextStyle(color: Colors.black87), // Warna teks isi
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "OK",
                style: TextStyle(color: Colors.blue), // Warna tombol
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskCard(String title, Color priorityColor, String dueDate) {
    String cleanDate = dueDate.replaceFirst("Due: ", "").trim();
    DateTime parsedDate = DateFormat("MMM dd, yyyy - HH:mm").parse(cleanDate);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Colors.grey[300]!, width: 1), // Garis pinggir abu-abu tipis
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Bayangan tipis
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 70,
            decoration: BoxDecoration(
              color: priorityColor.withOpacity(0.85),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
          ),
          Expanded(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(
                title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black),
              ),
              subtitle: Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(parsedDate),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('HH:mm').format(parsedDate),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(String title, String dateTime, String? location) {
    // Membersihkan teks tambahan sebelum parsing
    String cleanDateTime =
        dateTime.replaceAll(RegExp(r'^(On: |Due: )'), '').trim();
    DateTime parsedDate =
        DateFormat("MMM dd, yyyy - HH:mm").parse(cleanDateTime);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Icon(Icons.event, color: Colors.blueGrey[600], size: 28),
        title: Text(
          title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        subtitle: Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              DateFormat('MMM dd, yyyy').format(parsedDate),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(width: 16),
            Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              DateFormat('HH:mm').format(parsedDate),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: location != null && location.isNotEmpty
            ? GestureDetector(
                onTap: () => openLocationInMaps(location),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildNoteCard(String title, String content) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black),
            ),
            const SizedBox(height: 5),
            Text(
              content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
