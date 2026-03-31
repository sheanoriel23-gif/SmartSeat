import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final studentsRef = FirebaseFirestore.instance.collection('students');
  final schedulesRef = FirebaseFirestore.instance.collection('schedules');

  final nameController = TextEditingController();
  int? seat;
  String? sched;

  String searchQuery = ""; // ✅ added

  // Check seat availability
  Future<bool> checkSeatAvailable(String scheduleId, int seatNum, [String? excludeId]) async {
    final query = await studentsRef
        .where('scheduleId', isEqualTo: scheduleId)
        .where('seatNumber', isEqualTo: seatNum)
        .get();
    return excludeId != null
        ? query.docs.every((doc) => doc.id == excludeId)
        : query.docs.isEmpty;
  }

  Future<void> addStudent() async {
    if (nameController.text.isEmpty || seat == null || sched == null) return;

    if (!(await checkSeatAvailable(sched!, seat!))) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Seat already taken")));
      return;
    }

    await studentsRef.add({
      'name': nameController.text,
      'seatNumber': seat,
      'scheduleId': sched,
    });

    nameController.clear();
    setState(() {
      seat = null;
      sched = null;
    });
  }

  Future<void> editStudent(String id, Map data) async {
    final editNameController = TextEditingController(text: data['name']);
    int editSeat = data['seatNumber'] as int;
    String editSched = data['scheduleId'];

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Student"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: editNameController,
                decoration: const InputDecoration(
                  labelText: "Student Name",
                  prefixIcon: Icon(Icons.person, color: Colors.brown),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: schedulesRef.snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const CircularProgressIndicator();
                  return DropdownButtonFormField<String>(
                    value: editSched,
                    decoration: const InputDecoration(
                      labelText: "Schedule",
                      prefixIcon: Icon(Icons.schedule, color: Colors.brown),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: snap.data!.docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                          value: doc.id,
                          child: Text("${d['subject']} (${d['section']})"));
                    }).toList(),
                    onChanged: (v) => editSched = v!,
                  );
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: editSeat,
                decoration: const InputDecoration(
                  labelText: "Seat",
                  prefixIcon: Icon(Icons.event_seat, color: Colors.brown),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: List.generate(5, (i) => i + 1)
                    .map((e) => DropdownMenuItem(value: e, child: Text("Seat $e")))
                    .toList(),
                onChanged: (v) => editSeat = v!,
              ),
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
                if (!await checkSeatAvailable(editSched, editSeat, id)) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text("Seat already taken")));
                  return;
                }
                await studentsRef.doc(id).update({
                  'name': editNameController.text,
                  'seatNumber': editSeat,
                  'scheduleId': editSched,
                });
                Navigator.pop(context);
              }),
        ],
      ),
    );
  }

  Future<String> getScheduleName(String scheduleId) async {
    final doc = await schedulesRef.doc(scheduleId).get();
    if (!doc.exists) return "Unknown";
    final d = doc.data() as Map<String, dynamic>;
    return "${d['subject']} (${d['section']})";
  }

  Widget buildForm() => Card(
        color: Colors.white,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Student Name",
                  prefixIcon: Icon(Icons.person, color: Colors.brown),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<QuerySnapshot>(
                stream: schedulesRef.snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const CircularProgressIndicator();
                  return DropdownButtonFormField<String>(
                    value: sched,
                    decoration: const InputDecoration(
                      labelText: "Schedule",
                      prefixIcon: Icon(Icons.schedule, color: Colors.brown),
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    items: snap.data!.docs.map((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                          value: doc.id,
                          child: Text("${d['subject']} (${d['section']})"));
                    }).toList(),
                    onChanged: (v) => setState(() => sched = v),
                  );
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: seat,
                decoration: const InputDecoration(
                  labelText: "Seat",
                  prefixIcon: Icon(Icons.event_seat, color: Colors.brown),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: List.generate(5, (i) => i + 1)
                    .map((e) => DropdownMenuItem(value: e, child: Text("Seat $e")))
                    .toList(),
                onChanged: (v) => setState(() => seat = v),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Add Student", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                  onPressed: addStudent,
                ),
              ),
            ],
          ),
        ),
      );

  Widget buildStudentCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FutureBuilder<String>(
      future: getScheduleName(data['scheduleId']),
      builder: (context, schedSnap) {
        final scheduleName = schedSnap.data ?? "Loading...";
        return Card(
          color: Colors.white,
          margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: const Icon(Icons.person, color: Colors.brown),
            title: Text(data['name'], overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Seat: ${data['seatNumber']}"),
                Text("Schedule: $scheduleName", overflow: TextOverflow.ellipsis, maxLines: 1),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: const Icon(Icons.edit, color: Colors.brown),
                    onPressed: () => editStudent(doc.id, data)),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => studentsRef.doc(doc.id).delete()),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.brown,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Icon(Icons.school, color: Colors.white),
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
                hintText: "Search student...",
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
              stream: studentsRef.snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                List docs = snap.data!.docs;

                // ✅ FILTER
                if (searchQuery.isNotEmpty) {
                  final q = searchQuery.toLowerCase();
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['name']?.toLowerCase().contains(q) ?? false) ||
                        (data['seatNumber'].toString().contains(q)) ||
                        (data['scheduleId']?.toLowerCase().contains(q) ?? false);
                  }).toList();
                }

                // ✅ SORT BY SEAT
                docs.sort((a, b) {
                  final da = a.data() as Map<String, dynamic>;
                  final db = b.data() as Map<String, dynamic>;
                  return (da['seatNumber'] ?? 0).compareTo(db['seatNumber'] ?? 0);
                });

                if (docs.isEmpty) {
                  return const Center(child: Text("No students found."));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) =>
                      buildStudentCard(docs[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}