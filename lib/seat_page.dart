import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SeatPage extends StatefulWidget {
  final String scheduleId;
  final String subject;
  final String room;
  final String time;
  final String section;
  final String profId;

  const SeatPage({
    super.key,
    required this.scheduleId,
    required this.subject,
    required this.room,
    required this.time,
    required this.section,
    required this.profId,
  });

  @override
  State<SeatPage> createState() => _SeatPageState();
}

class _SeatPageState extends State<SeatPage> {
  bool classStarted = false;
  int elapsedSeconds = 0;
  Timer? classTimer;

  List<Map<String, dynamic>> studentDocs = [];
  List<String> seatStatus = [];
  List<bool> isAway = [];
  List<int> awaySeconds = [];
  List<Timer?> awayTimers = [];

  final int maxSeats = 5; // Number of seats per row (1-5)
  final primaryColor = Colors.brown;

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  @override
  void dispose() {
    classTimer?.cancel();
    for (var t in awayTimers) t?.cancel();
    super.dispose();
  }

  Future<void> fetchStudents() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('students')
          .where('scheduleId', isEqualTo: widget.scheduleId)
          .get();

      // Get all student docs
      studentDocs = query.docs.map((doc) => doc.data()).toList();

      // Sort by seatNumber to align with their actual seats
      studentDocs.sort((a, b) => (a['seatNumber'] ?? 9999).compareTo(b['seatNumber'] ?? 9999));

      // Initialize status arrays
      seatStatus = List.generate(studentDocs.length, (_) => "");
      isAway = List.generate(studentDocs.length, (_) => false);
      awaySeconds = List.generate(studentDocs.length, (_) => 0);
      awayTimers = List.generate(studentDocs.length, (_) => null);

      setState(() {});
    } catch (e) {
      debugPrint("Error fetching students: $e");
    }
  }

  void startClass() {
    if (studentDocs.isEmpty) return;

    setState(() {
      classStarted = true;
      elapsedSeconds = 0;
      seatStatus = List.generate(studentDocs.length, (_) => "Present");
    });

    classTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedSeconds++;

      if (elapsedSeconds == 10) {
        for (int i = 0; i < seatStatus.length; i++) {
          if (seatStatus[i] == "") seatStatus[i] = "Late";
        }
      }

      if (elapsedSeconds == 20) {
        for (int i = 0; i < seatStatus.length; i++) {
          if (seatStatus[i] == "") seatStatus[i] = "Absent";
        }
      }

      setState(() {});
    });
  }

  void markAway(int index, bool away) {
    if (!classStarted) return;

    isAway[index] = away;

    if (away) {
      awaySeconds[index] = 0;
      awayTimers[index]?.cancel();

      awayTimers[index] = Timer.periodic(const Duration(seconds: 1), (t) {
        awaySeconds[index]++;

        if (awaySeconds[index] == 5) {
          showAwayAlert(index);
        }

        if (awaySeconds[index] == 20) {
          t.cancel();
          showAbsentDecisionAlert(index);
        }

        setState(() {});
      });
    } else {
      awayTimers[index]?.cancel();
      awaySeconds[index] = 0;
      if (seatStatus[index] != "Absent") {
        seatStatus[index] = "Present";
      }
      setState(() {});
    }
  }

  void showAwayAlert(int index) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 50, color: Colors.orange),
              const SizedBox(height: 12),
              const Text(
                "Student Away",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "${studentDocs[index]['name']} has been away for ${awaySeconds[index]} seconds.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              )
            ],
          ),
        ),
      ),
    );
  }

  void showAbsentDecisionAlert(int index) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 50, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                "Mark Absent?",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "${studentDocs[index]['name']} has been away for 20 seconds.\nDo you want to mark them absent?",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      seatStatus[index] = "Absent";
                      isAway[index] = false;
                      awayTimers[index]?.cancel();
                      awaySeconds[index] = 0;
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text("Yes"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      awayTimers[index]?.cancel();
                      setState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text("No"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> endClass() async {
    classTimer?.cancel();
    for (var t in awayTimers) t?.cancel();

    final attendanceData = {
      "scheduleId": widget.scheduleId,
      "profId": widget.profId,
      "subject": widget.subject,
      "section": widget.section,
      "room": widget.room,
      "time": widget.time,
      "timer":
          "${(elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(elapsedSeconds % 60).toString().padLeft(2, '0')}",
      "students": List.generate(studentDocs.length, (i) => {
            "name": studentDocs[i]['name'],
            "seatNumber": studentDocs[i]['seatNumber'],
            "status": seatStatus[i] == "" ? "Absent" : seatStatus[i],
          }),
      "date": DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await FirebaseFirestore.instance
          .collection('attendance')
          .add(attendanceData);
    } catch (e) {
      debugPrint("Error saving attendance: $e");
    }

    Navigator.pop(context, attendanceData);
  }

  @override
  Widget build(BuildContext context) {
    int presentCount = seatStatus.where((s) => s == "Present").length;
    int lateCount = seatStatus.where((s) => s == "Late").length;
    int absentCount = seatStatus.where((s) => s == "Absent").length;
    int awayCount = isAway.where((a) => a).length;

    String timerText =
        "${(elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(elapsedSeconds % 60).toString().padLeft(2, '0')}";

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Seat Arrangement"),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.subject,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18),
                      const SizedBox(width: 6),
                      Text(widget.time),
                      const SizedBox(width: 20),
                      const Icon(Icons.groups, size: 18),
                      const SizedBox(width: 6),
                      Text(widget.section),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.meeting_room, size: 18),
                      const SizedBox(width: 6),
                      Text(widget.room),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (classStarted)
                        Row(
                          children: [
                            const Icon(Icons.timer, size: 18),
                            const SizedBox(width: 6),
                            Text("Duration: $timerText"),
                          ],
                        ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              classStarted ? Colors.red : primaryColor,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: classStarted ? endClass : startClass,
                        child:
                            Text(classStarted ? "End Class" : "Start Class"),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                statusCard(
                    "Present", presentCount, Colors.green, Icons.check_circle),
                statusCard("Late", lateCount, Colors.orange, Icons.access_time),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                statusCard("Absent", absentCount, Colors.red, Icons.cancel),
                statusCard("Away", awayCount, Colors.purple, Icons.event_seat),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                itemCount: maxSeats, // Always show 1-5
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 20,
                ),
                itemBuilder: (context, gridIndex) {
                  // Find the student with this seatNumber
                  final studentIndex = studentDocs.indexWhere(
                      (s) => (s['seatNumber'] ?? 0) == gridIndex + 1);

                  if (studentIndex == -1) {
                    // Empty seat
                    return seatBox(gridIndex + 1, "", false, 0);
                  }

                  return GestureDetector(
                    onTap: () {
                      if (seatStatus[studentIndex] == "Present" ||
                          seatStatus[studentIndex] == "Late") {
                        markAway(studentIndex, !isAway[studentIndex]);
                      }
                    },
                    onLongPress: () {
                      if (seatStatus[studentIndex] == "Absent") {
                        seatStatus[studentIndex] = "Present";
                      } else {
                        seatStatus[studentIndex] = "Absent";
                        isAway[studentIndex] = false;
                        awayTimers[studentIndex]?.cancel();
                        awaySeconds[studentIndex] = 0;
                      }
                      setState(() {});
                    },
                    child: seatBox(
                        gridIndex + 1,
                        seatStatus[studentIndex],
                        isAway[studentIndex],
                        awaySeconds[studentIndex]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget statusCard(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(title),
            Text(
              count.toString(),
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget seatBox(int number, String status, bool away, int awayTime) {
    Color color;

    if (away) {
      color =
          awayTime < 5 ? Colors.purple.shade300 : Colors.purple.shade600;
    } else {
      switch (status) {
        case "Present":
          color = Colors.green.shade300;
          break;
        case "Late":
          color = Colors.orange.shade300;
          break;
        case "Absent":
          color = Colors.red.shade300;
          break;
        default:
          color = Colors.white;
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 55,
      decoration: BoxDecoration(
        color: classStarted ? color : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}