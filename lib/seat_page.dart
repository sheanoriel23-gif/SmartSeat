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
  final int maxSeats = 2;
  final primaryColor = Colors.brown;

  List<Map<String, dynamic>> studentDocs = [];
  bool loadingStudents = true;
  bool actionLoading = false;

  final Set<int> shownAway10 = {};
  final Set<int> shownAway20 = {};
  bool dialogOpen = false;

  Timer? _uiTimer;
  int _uiTick = 0;
  final Map<int, int> _lastAwaySeconds = {1: 0, 2: 0};

  @override
  void initState() {
    super.initState();
    fetchStudents();
    ensureLiveAttendanceDoc();

    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _uiTick++;
        });
      }
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  Future<void> fetchStudents() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('students')
          .where('scheduleId', isEqualTo: widget.scheduleId)
          .get();

      studentDocs = query.docs.map((doc) {
        return {"id": doc.id, ...doc.data()};
      }).toList();

      studentDocs.sort(
        (a, b) => (a['seatNumber'] ?? 9999).compareTo(b['seatNumber'] ?? 9999),
      );
    } catch (e) {
      debugPrint("Error fetching students: $e");
    } finally {
      if (mounted) {
        setState(() {
          loadingStudents = false;
        });
      }
    }
  }

  Future<void> ensureLiveAttendanceDoc() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('live_attendance')
          .doc(widget.scheduleId);

      final snap = await docRef.get();

      if (!snap.exists) {
        await docRef.set({
          "scheduleId": widget.scheduleId,
          "subject": widget.subject,
          "section": widget.section,
          "room": widget.room,
          "time": widget.time,
          "classStarted": false,
          "classStartEpochMs": 0,
          "elapsedSeconds": 0,
          "presentCount": 0,
          "lateCount": 0,
          "absentCount": 0,
          "awayCount": 0,
          "seat1": {
            "seatNumber": 1,
            "status": "Waiting",
            "away": false,
            "awaySeconds": 0,
            "manualAbsent": false,
            "fsr": 0,
            "vib": 0,
          },
          "seat2": {
            "seatNumber": 2,
            "status": "Waiting",
            "away": false,
            "awaySeconds": 0,
            "manualAbsent": false,
            "fsr": 0,
            "vib": 0,
          },
        });
      }
    } catch (e) {
      debugPrint("Error ensuring live attendance doc: $e");
    }
  }

  Future<void> startClass() async {
    try {
      setState(() {
        actionLoading = true;
      });

      final sessionId = DateTime.now().millisecondsSinceEpoch;
      final startEpoch = DateTime.now().millisecondsSinceEpoch;

      shownAway10.clear();
      shownAway20.clear();
      dialogOpen = false;
      _lastAwaySeconds[1] = 0;
      _lastAwaySeconds[2] = 0;

      await FirebaseFirestore.instance
          .collection('live_attendance')
          .doc(widget.scheduleId)
          .set({
            "scheduleId": widget.scheduleId,
            "subject": widget.subject,
            "section": widget.section,
            "room": widget.room,
            "time": widget.time,
            "classStarted": true,
            "sessionId": sessionId,
            "classStartEpochMs": startEpoch,
            "elapsedSeconds": 0,
            "presentCount": 0,
            "lateCount": 0,
            "absentCount": 0,
            "awayCount": 0,
            "seat1": {
              "seatNumber": 1,
              "status": "Waiting",
              "away": false,
              "awaySeconds": 0,
              "manualAbsent": false,
              "fsr": 0,
              "vib": 0,
            },
            "seat2": {
              "seatNumber": 2,
              "status": "Waiting",
              "away": false,
              "awaySeconds": 0,
              "manualAbsent": false,
              "fsr": 0,
              "vib": 0,
            },
          });

      await FirebaseFirestore.instance
          .collection('room_sessions')
          .doc(widget.room)
          .set({
            "room": widget.room,
            "scheduleId": widget.scheduleId,
            "subject": widget.subject,
            "section": widget.section,
            "time": widget.time,
            "classStarted": true,
            "sessionId": sessionId,
          });
    } catch (e) {
      debugPrint("Error starting class: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to start class: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          actionLoading = false;
        });
      }
    }
  }

  Future<void> toggleManualAbsent(
    int seatNumber,
    bool currentManualAbsent,
    String currentStatus,
  ) async {
    try {
      final seatKey = "seat$seatNumber";
      final isCurrentlyAbsent =
          currentManualAbsent || currentStatus == "Absent";

      if (isCurrentlyAbsent) {
        await FirebaseFirestore.instance
            .collection('live_attendance')
            .doc(widget.scheduleId)
            .update({
              "$seatKey.manualAbsent": false,
              "$seatKey.status": "Present",
              "$seatKey.away": false,
              "$seatKey.awaySeconds": 0,
            });
      } else {
        await FirebaseFirestore.instance
            .collection('live_attendance')
            .doc(widget.scheduleId)
            .update({
              "$seatKey.manualAbsent": true,
              "$seatKey.status": "Absent",
              "$seatKey.away": false,
              "$seatKey.awaySeconds": 0,
            });
      }
    } catch (e) {
      debugPrint("Error toggling manual absent: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to update seat: $e")));
      }
    }
  }

  Future<void> markManualAbsent(int seatNumber) async {
    try {
      final seatKey = "seat$seatNumber";

      await FirebaseFirestore.instance
          .collection('live_attendance')
          .doc(widget.scheduleId)
          .update({
            "$seatKey.manualAbsent": true,
            "$seatKey.status": "Absent",
            "$seatKey.away": false,
            "$seatKey.awaySeconds": 0,
          });
    } catch (e) {
      debugPrint("Error marking manual absent: $e");
    }
  }

  Future<void> endClass(Map<String, dynamic> liveData) async {
    try {
      setState(() {
        actionLoading = true;
      });

      if (studentDocs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No students found for this schedule.")),
        );
        return;
      }

      final elapsedSeconds = _toInt(liveData['elapsedSeconds']);

      final students = List.generate(studentDocs.length, (i) {
        final seatNumber = studentDocs[i]['seatNumber'];
        final seatData = getSeatData(liveData, seatNumber);
        final status = (seatData['status'] ?? "Absent").toString();

        return {
          "name": studentDocs[i]['name'] ?? '',
          "seatNumber": seatNumber,
          "status": status == "Waiting" ? "Absent" : status,
        };
      });

      final attendanceData = {
        "scheduleId": widget.scheduleId,
        "profId": widget.profId,
        "subject": widget.subject,
        "section": widget.section,
        "room": widget.room,
        "time": widget.time,
        "timer":
            "${(elapsedSeconds ~/ 60).toString().padLeft(2, '0')}:${(elapsedSeconds % 60).toString().padLeft(2, '0')}",
        "students": students,
        "date": DateTime.now().millisecondsSinceEpoch,
      };

      await FirebaseFirestore.instance
          .collection('attendance')
          .add(attendanceData);

      await FirebaseFirestore.instance
          .collection('live_attendance')
          .doc(widget.scheduleId)
          .set({
            "classStarted": false,
            "classStartEpochMs": 0,
            "elapsedSeconds": 0,
            "presentCount": 0,
            "lateCount": 0,
            "absentCount": 0,
            "awayCount": 0,
            "seat1": {
              "seatNumber": 1,
              "status": "Waiting",
              "away": false,
              "awaySeconds": 0,
              "manualAbsent": false,
              "fsr": 0,
              "vib": 0,
            },
            "seat2": {
              "seatNumber": 2,
              "status": "Waiting",
              "away": false,
              "awaySeconds": 0,
              "manualAbsent": false,
              "fsr": 0,
              "vib": 0,
            },
          });

      await FirebaseFirestore.instance
          .collection('room_sessions')
          .doc(widget.room)
          .set({
            "room": widget.room,
            "scheduleId": widget.scheduleId,
            "subject": widget.subject,
            "section": widget.section,
            "time": widget.time,
            "classStarted": false,
            "sessionId": 0,
          });

      shownAway10.clear();
      shownAway20.clear();
      dialogOpen = false;
      _lastAwaySeconds[1] = 0;
      _lastAwaySeconds[2] = 0;

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error ending class: $e");
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to end class: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          actionLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> getSeatData(
    Map<String, dynamic> liveData,
    int seatNumber,
  ) {
    final seatKey = "seat$seatNumber";
    final raw = liveData[seatKey];

    if (raw is Map<String, dynamic>) {
      return raw;
    }

    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }

    return {};
  }

  String getSeatStudentName(int seatNumber) {
    final matches = studentDocs.where(
      (s) => (s['seatNumber'] ?? 0) == seatNumber,
    );

    if (matches.isEmpty) return "Seat $seatNumber";
    return (matches.first['name'] ?? "Seat $seatNumber").toString();
  }

  void handleAwayAlerts(Map<String, dynamic> liveData, bool classStarted) {
    if (!classStarted) {
      shownAway10.clear();
      shownAway20.clear();
      dialogOpen = false;
      _lastAwaySeconds[1] = 0;
      _lastAwaySeconds[2] = 0;
      return;
    }

    for (int seatNumber = 1; seatNumber <= 2; seatNumber++) {
      final seatData = getSeatData(liveData, seatNumber);
      final away = (seatData['away'] ?? false) as bool;
      final awaySeconds = _toInt(seatData['awaySeconds']);
      final manualAbsent = (seatData['manualAbsent'] ?? false) as bool;

      final prevAwaySeconds = _lastAwaySeconds[seatNumber] ?? 0;

      if (!away || manualAbsent || awaySeconds <= 0) {
        shownAway10.remove(seatNumber);
        shownAway20.remove(seatNumber);
        _lastAwaySeconds[seatNumber] = 0;
        continue;
      }

      if (prevAwaySeconds < 20 &&
          awaySeconds >= 20 &&
          !shownAway20.contains(seatNumber) &&
          !dialogOpen) {
        shownAway20.add(seatNumber);
        _lastAwaySeconds[seatNumber] = awaySeconds;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showAway20Dialog(seatNumber);
          }
        });
        return;
      }

      if (prevAwaySeconds < 10 &&
          awaySeconds >= 10 &&
          !shownAway10.contains(seatNumber) &&
          !dialogOpen) {
        shownAway10.add(seatNumber);
        _lastAwaySeconds[seatNumber] = awaySeconds;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            showAway10Dialog(seatNumber);
          }
        });
        return;
      }

      _lastAwaySeconds[seatNumber] = awaySeconds;
    }
  }

  Future<void> showAway10Dialog(int seatNumber) async {
    dialogOpen = true;
    final studentName = getSeatStudentName(seatNumber);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 50,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
              const Text(
                "Student Away",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "$studentName has been away for 10 seconds.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );

    dialogOpen = false;
  }

  Future<void> showAway20Dialog(int seatNumber) async {
    dialogOpen = true;
    final studentName = getSeatStudentName(seatNumber);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 50,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              const Text(
                "Student Away for 20 Seconds",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "$studentName has been away for 20 seconds.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Close"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      await markManualAbsent(seatNumber);
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Mark Absent"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    dialogOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    if (loadingStudents) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Seat Arrangement"),
          backgroundColor: primaryColor,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('live_attendance')
          .doc(widget.scheduleId)
          .snapshots(),
      builder: (context, snapshot) {
        final liveData = snapshot.hasData && snapshot.data!.exists
            ? (snapshot.data!.data() as Map<String, dynamic>)
            : <String, dynamic>{};

        final classStarted = (liveData['classStarted'] ?? false) as bool;
        final remoteElapsedSeconds = _toInt(liveData['elapsedSeconds']);
        final classStartEpochMs = _toInt(liveData['classStartEpochMs']);

        final elapsedSeconds = classStarted && classStartEpochMs > 0
            ? ((DateTime.now().millisecondsSinceEpoch - classStartEpochMs) /
                      1000)
                  .floor()
            : remoteElapsedSeconds;

        final presentCount = _toInt(liveData['presentCount']);
        final lateCount = _toInt(liveData['lateCount']);
        final absentCount = _toInt(liveData['absentCount']);
        final awayCount = _toInt(liveData['awayCount']);

        handleAwayAlerts(liveData, classStarted);

        final timerText =
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
                      Text(
                        widget.subject,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                              backgroundColor: classStarted
                                  ? Colors.red
                                  : primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: actionLoading
                                ? null
                                : () {
                                    if (classStarted) {
                                      endClass(liveData);
                                    } else {
                                      startClass();
                                    }
                                  },
                            child: Text(
                              actionLoading
                                  ? "Please wait..."
                                  : classStarted
                                  ? "End Class"
                                  : "Start Class",
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    statusCard(
                      "Present",
                      presentCount,
                      Colors.green,
                      Icons.check_circle,
                    ),
                    statusCard(
                      "Late",
                      lateCount,
                      Colors.orange,
                      Icons.access_time,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    statusCard("Absent", absentCount, Colors.red, Icons.cancel),
                    statusCard(
                      "Away",
                      awayCount,
                      Colors.purple,
                      Icons.event_seat,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    itemCount: maxSeats,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 20,
                        ),
                    itemBuilder: (context, index) {
                      final seatNumber = index + 1;
                      final seatData = getSeatData(liveData, seatNumber);

                      final status = (seatData['status'] ?? "Waiting")
                          .toString();
                      final away = (seatData['away'] ?? false) as bool;
                      final awaySeconds = _toInt(seatData['awaySeconds']);
                      final manualAbsent =
                          (seatData['manualAbsent'] ?? false) as bool;

                      return GestureDetector(
                        onLongPress: () {
                          toggleManualAbsent(seatNumber, manualAbsent, status);
                        },
                        child: seatBox(
                          seatNumber,
                          status,
                          away,
                          awaySeconds,
                          classStarted,
                          manualAbsent: manualAbsent,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget seatBox(
    int number,
    String status,
    bool away,
    int awayTime,
    bool classStarted, {
    bool manualAbsent = false,
  }) {
    Color color;

    if (!classStarted) {
      color = Colors.white;
    } else if (manualAbsent) {
      color = Colors.red.shade300;
    } else if (away) {
      color = awayTime < 5 ? Colors.purple.shade300 : Colors.purple.shade600;
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
        color: color,
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
