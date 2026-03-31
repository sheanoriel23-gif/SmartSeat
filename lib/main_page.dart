
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'schedule_page.dart';
import 'history_page.dart';

class MainPage extends StatefulWidget {
  final String profId;
  final String profName;

  const MainPage({super.key, required this.profId, required this.profName});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0; // Default to Schedule tab
  late final List<Widget> _pages;
  final Color primaryColor = Colors.brown;

  @override
  void initState() {
    super.initState();
    _pages = [
      SchedulePage(profId: widget.profId, profName: widget.profName),
      HistoryPage(profId: widget.profId, profName: widget.profName),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Welcome Professor ${widget.profName}!"),
        backgroundColor: Colors.brown,
        duration: const Duration(seconds: 2),
      ),
    );
  });
}
  

  void _onTabTapped(int index) {
    if (index == 2) {
      _showLogoutConfirmation();
    } else {
      setState(() => _currentIndex = index);
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.logout, color: Colors.brown),
            SizedBox(width: 8),
            Text("Logout"),
          ],
        ),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    // Different AppBar per page
    switch (_currentIndex) {
      case 0:
        return AppBar(
          title: const Text("My Schedule"),
          backgroundColor: primaryColor,
        );
      case 1:
        return AppBar(
          title: const Text("History"),
          backgroundColor: primaryColor,
        );
      default:
        return AppBar(
          title: const Text("SmartSeat"),
          backgroundColor: primaryColor,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _currentIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey.shade500,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule_outlined),
            activeIcon: Icon(Icons.schedule),
            label: "Schedule",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: "History",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout_outlined),
            activeIcon: Icon(Icons.logout),
            label: "Logout",
          ),
        ],
      ),
    );
  }
}
