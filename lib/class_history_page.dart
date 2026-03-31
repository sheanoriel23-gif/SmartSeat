import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClassHistoryPage extends StatelessWidget {
  final String attendanceId;
  const ClassHistoryPage({super.key, required this.attendanceId});

  String _formatDate(int timestampMillis) {
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    const months = [
      "",
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return "${months[date.month]} ${date.day}, ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.brown;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Class Details"),
        backgroundColor: primaryColor,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .doc(attendanceId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          if (data == null) {
            return const Center(child: Text("Class not found."));
          }

          // Convert students to Map<String, dynamic>
          final seats = List<Map<String, dynamic>>.from(data['students'] ?? []);

          // Sort by seatNumber safely
          seats.sort((a, b) {
            int seatA = 9999; // Default large number if missing
            int seatB = 9999;

            if (a.containsKey('seatNumber') && a['seatNumber'] != null) {
              seatA = int.tryParse(a['seatNumber'].toString()) ?? 9999;
            }

            if (b.containsKey('seatNumber') && b['seatNumber'] != null) {
              seatB = int.tryParse(b['seatNumber'].toString()) ?? 9999;
            }

            return seatA.compareTo(seatB);
          });

          final present = seats.where((s) => s['status'] == "Present").toList();
          final late = seats.where((s) => s['status'] == "Late").toList();
          final absent = seats.where((s) => s['status'] == "Absent").toList();

          // Get class date
          final int dateMillis = data['date'] ?? 0;
          final String formattedDate =
              dateMillis != 0 ? _formatDate(dateMillis) : "No date";

          Widget infoItem(IconData icon, String label, String value) {
            return Expanded(
              child: Row(
                children: [
                  Icon(icon, size: 18, color: Colors.brown),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600)),
                        Text(value,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Class info card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['subject'] ?? "",
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("Date: $formattedDate",
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade700)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          infoItem(Icons.group, "Section", data['section'] ?? ""),
                          infoItem(Icons.meeting_room, "Room", data['room'] ?? ""),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          infoItem(Icons.access_time, "Schedule", data['time'] ?? ""),
                          infoItem(Icons.timer, "Duration", data['timer'] ?? "00:00"),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Status cards (SeatPage style)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: statusCard("Present", present.length, Colors.green, Icons.check_circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: statusCard("Late", late.length, Colors.orange, Icons.access_time),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: statusCard("Absent", absent.length, Colors.red, Icons.cancel),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Student list
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListView.separated(
                      itemCount: seats.length,
                      separatorBuilder: (_, __) =>
                          Divider(color: Colors.grey.shade200, height: 12),
                      itemBuilder: (context, index) {
                        final s = seats[index];

                        Color color;
                        IconData icon;

                        switch (s['status']) {
                          case "Present":
                            color = Colors.green;
                            icon = Icons.check_circle;
                            break;
                          case "Late":
                            color = Colors.orange;
                            icon = Icons.access_time;
                            break;
                          case "Absent":
                            color = Colors.red;
                            icon = Icons.cancel;
                            break;
                          default:
                            color = Colors.grey;
                            icon = Icons.help;
                        }

                        return Row(
                          children: [
                            Icon(icon, color: color, size: 20),
                            const SizedBox(width: 10),
                            Text(s['name'] ?? "",
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Text(s['status'] ?? "",
                                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // SeatPage-style status card
  Widget statusCard(String title, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          Text(
            count.toString(),
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}