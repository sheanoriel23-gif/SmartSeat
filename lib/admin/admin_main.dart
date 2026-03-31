import 'package:flutter/material.dart';
import 'professors_page.dart';
import 'schedules_page.dart';
import 'students_page.dart';
import '../login_page.dart'; // import the login page

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const ProfessorsPage(),
    const SchedulesPage(),
    const StudentsPage(),
  ];

  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
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
        content: const Text("Are you sure you want to log out?"),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context, false),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.brown),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (result == true) {
     
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed, // disables animation
        unselectedItemColor: Colors.grey,
        selectedItemColor: Colors.brown,
        onTap: (index) {
          if (index == 3) {
            _confirmLogout();
          } else {
            setState(() => _currentIndex = index);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Professors"),
          BottomNavigationBarItem(icon: Icon(Icons.schedule), label: "Schedules"),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: "Students"),
          BottomNavigationBarItem(icon: Icon(Icons.logout), label: "Logout"),
        ],
      ),
    );
  }
}