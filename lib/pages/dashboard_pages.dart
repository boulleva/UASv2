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
        return Colors.blueGrey;
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
        backgroundColor: theme.scaffoldBackgroundColor,
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
          selectedItemColor:
              Color(0xFF5FB2FF), // Warna biru untuk item terpilih
          unselectedItemColor: const Color.fromARGB(255, 131, 129, 129),
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
              _buildSearchBar(),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFF5FB2FF), // Warna biru untuk header
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
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none,
              size: 28, color: Colors.redAccent),
          onPressed: () => _showNotifications(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search tasks, notes & events...",
          prefixIcon: const Icon(Icons.search,
              color: Color(0xFF5FB2FF)), // Warna biru untuk ikon
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildSectionWithFilter(
      String title, Future<List<Map<String, dynamic>>> Function() fetchData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        FutureBuilder(
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
                .where((item) => item['title']
                    .toString()
                    .toLowerCase()
                    .contains(_searchQuery))
                .toList();

            if (filteredItems.isEmpty) {
              return _buildEmptyState(title);
            }

            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];

                if (title.contains('Tasks')) {
                  String priority = item['priority'] ?? 'Normal';
                  return _buildTaskCard(
                      item['title'],
                      priorityColor(item['priority'] ??
                          'normal'), // Default 'normal' untuk mencegah null
                      "Due: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(item['due_date']))}");
                } else if (title.contains('Events')) {
                  return _buildEventCard(
                    item['title'],
                    "On: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(item['event_date']))}",
                  );
                } else {
                  return _buildNoteCard(
                    item['title'] ?? "Untitled",
                    item['content'] ?? "No content available",
                  );
                }
              },
            );
          },
        ),
        const SizedBox(height: 15),
      ],
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
    // Implement notifications view
  }

  Widget _buildTaskCard(String title, Color priorityColor, String description) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          width: 5,
          height: 40,
          decoration: BoxDecoration(
            color: priorityColor, // Indikator warna prioritas
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          description.length > 50
              ? '${description.substring(0, 50)}...'
              : description,
          style: TextStyle(
              color: Colors.black87), // Gunakan warna teks lebih netral
        ),
        trailing: Icon(Icons.flag,
            color:
                priorityColor), // Menampilkan warna prioritas dengan ikon flag
      ),
    );
  }

  Widget _buildEventCard(String title, String time) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          width: 5,
          height: 40,
          color: Colors.orange.withOpacity(0.1), // Warna khas untuk event
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          time,
          style: TextStyle(color: Colors.orange.shade400),
        ),
      ),
    );
  }

  Widget _buildNoteCard(String title, String content) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          width: 5,
          height: 40,
          color: Colors.purple.withOpacity(0.1), // Warna khas untuk note
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          content.length > 50 ? '${content.substring(0, 50)}...' : content,
          style: TextStyle(color: Colors.purple.shade400),
        ),
      ),
    );
  }
}
