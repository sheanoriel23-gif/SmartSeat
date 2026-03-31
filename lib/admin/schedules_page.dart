import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SchedulesPage extends StatefulWidget {
  const SchedulesPage({super.key});

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  final schedulesRef = FirebaseFirestore.instance.collection('schedules');
  final professorsRef = FirebaseFirestore.instance.collection('professors');

  final _time = TextEditingController();
  final _subject = TextEditingController();
  final _room = TextEditingController();
  final _section = TextEditingController();

  String? selectedProfId;
  String? selectedDay;

  String searchQuery = ""; // ✅ added

  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  // ✅ helper for correct day sorting
  int getDayOrder(String day) {
    const order = {'Mon': 1, 'Tue': 2, 'Wed': 3, 'Thu': 4, 'Fri': 5, 'Sat': 6};
    return order[day] ?? 0;
  }

  // ✅ ADD SCHEDULE
  void addSchedule() async {
    if (selectedDay == null ||
        _time.text.isEmpty ||
        _subject.text.isEmpty ||
        _room.text.isEmpty ||
        _section.text.isEmpty ||
        selectedProfId == null) return;

    await schedulesRef.add({
      'day': selectedDay,
      'time': _time.text,
      'subject': _subject.text,
      'room': _room.text,
      'section': _section.text,
      'profId': selectedProfId,
    });

    selectedDay = null;
    _time.clear();
    _subject.clear();
    _room.clear();
    _section.clear();
    selectedProfId = null;

    setState(() {});
  }

  // ✅ DELETE SCHEDULE
  void deleteSchedule(String id) async {
    await schedulesRef.doc(id).delete();
  }

  // ✅ EDIT SCHEDULE
  void editSchedule(String id, Map data) {
    String? editDay = data['day'];
    final t = TextEditingController(text: data['time']);
    final s = TextEditingController(text: data['subject']);
    final r = TextEditingController(text: data['room']);
    final sec = TextEditingController(text: data['section']);
    String? selectedProf = data['profId'];

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Edit Schedule"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: editDay,
                  decoration: const InputDecoration(
                    labelText: "Day",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.brown),
                  ),
                  items: days
                      .map((day) => DropdownMenuItem(value: day, child: Text(day)))
                      .toList(),
                  onChanged: (val) => setState(() => editDay = val),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: t,
                    decoration: const InputDecoration(
                        labelText: "Time",
                        prefixIcon: Icon(Icons.access_time, color: Colors.brown),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white)),
                const SizedBox(height: 10),
                TextField(
                    controller: s,
                    decoration: const InputDecoration(
                        labelText: "Subject",
                        prefixIcon: Icon(Icons.book, color: Colors.brown),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white)),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: professorsRef.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();

                    final profs = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: selectedProf,
                      decoration: const InputDecoration(
                        labelText: "Professor",
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.person, color: Colors.brown),
                      ),
                      items: profs.map((doc) {
                        final pdata = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(pdata['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        selectedProf = val;
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: r,
                    decoration: const InputDecoration(
                        labelText: "Room",
                        prefixIcon: Icon(Icons.meeting_room, color: Colors.brown),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white)),
                const SizedBox(height: 10),
                TextField(
                    controller: sec,
                    decoration: const InputDecoration(
                        labelText: "Section",
                        prefixIcon: Icon(Icons.group, color: Colors.brown),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white)),
              ],
            ),
          ),
          actions: [
            IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context)),
            IconButton(
              icon: const Icon(Icons.save, color: Colors.brown),
              onPressed: () async {
                if (editDay != null) {
                  await schedulesRef.doc(id).update({
                    'day': editDay,
                    'time': t.text,
                    'subject': s.text,
                    'room': r.text,
                    'section': sec.text,
                    'profId': selectedProf,
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildForm() => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        color: Colors.white,
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedDay,
                  decoration: const InputDecoration(
                    labelText: "Day",
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.calendar_today, color: Colors.brown),
                  ),
                  items: days
                      .map((day) => DropdownMenuItem(value: day, child: Text(day)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedDay = val),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: _time,
                    decoration: const InputDecoration(
                        labelText: "Time",
                        prefixIcon: Icon(Icons.access_time, color: Colors.brown),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white)),
                const SizedBox(height: 10),
                TextField(
                    controller: _subject,
                    decoration: const InputDecoration(
                        labelText: "Subject",
                        prefixIcon: Icon(Icons.book, color: Colors.brown),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white)),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: professorsRef.snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const CircularProgressIndicator();

                    final profs = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: selectedProfId,
                      decoration: const InputDecoration(
                        labelText: "Professor",
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.person, color: Colors.brown),
                      ),
                      items: profs.map((doc) {
                        final pdata = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(pdata['name']),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => selectedProfId = val),
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: _room,
                    decoration: const InputDecoration(
                        labelText: "Room",
                        prefixIcon: Icon(Icons.meeting_room, color: Colors.brown),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white)),
                const SizedBox(height: 10),
                TextField(
                    controller: _section,
                    decoration: const InputDecoration(
                        labelText: "Section",
                        prefixIcon: Icon(Icons.group, color: Colors.brown),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white)),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: addSchedule,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text("Add Schedule", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget buildScheduleCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: const Icon(Icons.schedule, color: Colors.brown),
        title: Text(data['subject'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "Day: ${data['day']} | Time: ${data['time']}\n"
          "Room: ${data['room']} | Section: ${data['section']}",
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.edit, color: Colors.brown),
                onPressed: () => editSchedule(doc.id, data)),
            IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteSchedule(doc.id)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.brown,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Icon(Icons.schedule, color: Colors.white),
      ),
      body: Column(
        children: [
          buildForm(),

          // ✅ SEARCH BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search subject, section, room...",
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: schedulesRef.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                List docs = snapshot.data!.docs;

                // ✅ FILTER
                if (searchQuery.isNotEmpty) {
                  final q = searchQuery.toLowerCase();
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['subject']?.toLowerCase().contains(q) ?? false) ||
                        (data['section']?.toLowerCase().contains(q) ?? false) ||
                        (data['room']?.toLowerCase().contains(q) ?? false) ||
                        (data['day']?.toLowerCase().contains(q) ?? false);
                  }).toList();
                }

                // ✅ SORT (Day → Time)
                docs.sort((a, b) {
                  final da = a.data() as Map<String, dynamic>;
                  final db = b.data() as Map<String, dynamic>;

                  int dayCompare =
                      getDayOrder(da['day']).compareTo(getDayOrder(db['day']));
                  if (dayCompare != 0) return dayCompare;

                  return (da['time'] ?? "").compareTo(db['time'] ?? "");
                });

                if (docs.isEmpty) {
                  return const Center(child: Text("No schedules yet."));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) => buildScheduleCard(docs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}