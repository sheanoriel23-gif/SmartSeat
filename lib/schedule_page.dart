import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'seat_page.dart';

class SchedulePage extends StatefulWidget {
  final String profId;
  final String profName;

  const SchedulePage({super.key, required this.profId, required this.profName});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final primaryColor = Colors.brown;
  final accentColor = Colors.orange.shade200;

  late DateTime _todayDate;
  late String _todayName;
  late String _selectedDay;

  late final Stream<QuerySnapshot> scheduleStream;

  @override
  void initState() {
    super.initState();
    _todayDate = DateTime.now();
    _todayName = _getWeekdayName(_todayDate.weekday);
    _selectedDay = _todayName;

    scheduleStream = FirebaseFirestore.instance
        .collection('schedules')
        .where('profId', isEqualTo: widget.profId)
        .snapshots();
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "Mon";
      case DateTime.tuesday:
        return "Tue";
      case DateTime.wednesday:
        return "Wed";
      case DateTime.thursday:
        return "Thu";
      case DateTime.friday:
        return "Fri";
      case DateTime.saturday:
        return "Sat";
      default:
        return "Mon";
    }
  }

  String _formatDateDM(DateTime date) => "${date.month}/${date.day}";

  String _formatDateFull(DateTime date) {
    const months = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return "${months[date.month]} ${date.day}, ${date.year}";
  }

  void _showNotTodayDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.info, color: Colors.brown),
            SizedBox(width: 8),
            Text("Cannot Record", style: TextStyle(color: Colors.brown)),
          ],
        ),
        content: const Text(
          "Cannot record attendance. This is not the current day.",
          style: TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.brown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateNext6Days() {
    List<Map<String, dynamic>> days = [];
    DateTime date = _todayDate;

    while (days.length < 6) {
      if (date.weekday != DateTime.sunday) {
        days.add({"day": _getWeekdayName(date.weekday), "date": date});
      }
      date = date.add(const Duration(days: 1));
    }

    return days;
  }

  Widget dayBox(String day, DateTime date, bool isSelected) {
    Color bgColor = isSelected
        ? primaryColor.withOpacity(0.85)
        : accentColor.withOpacity(0.6);
    Color textColor = bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade300, blurRadius: 4, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_formatDateDM(date),
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
          const SizedBox(height: 6),
          Text(day,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> next6Days = _generateNext6Days();

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Professor + Today full date card
            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.brown, size: 28),
                        const SizedBox(width: 12),
                        Text(widget.profName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Today: ${_formatDateFull(_todayDate)}",
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Carousel of days
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: next6Days.map((dayMap) {
                  final day = dayMap['day'] as String;
                  final date = dayMap['date'] as DateTime;
                  final isSelected = _selectedDay == day;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = day;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: dayBox(day, date, isSelected),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Schedule for selected day
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: scheduleStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  Map<String, List<Map<String, dynamic>>> schedulesPerDay = {
                    "Mon": [],
                    "Tue": [],
                    "Wed": [],
                    "Thu": [],
                    "Fri": [],
                    "Sat": []
                  };

                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final day = data['day'];
                    if (schedulesPerDay.containsKey(day)) {
                      schedulesPerDay[day]!.add({
                        'id': doc.id,
                        'subject': data['subject'],
                        'time': data['time'],
                        'room': data['room'],
                        'section': data['section'],
                      });
                    }
                  }

                  final daySchedules = schedulesPerDay[_selectedDay] ?? [];

                  if (daySchedules.isEmpty)
                    return const Center(child: Text("No schedules today."));

                  return ListView.builder(
                    itemCount: daySchedules.length,
                    itemBuilder: (context, index) {
                      final schedule = daySchedules[index];
                      bool canStartClass = _selectedDay == _todayName;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        elevation: 4,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          leading: const Icon(Icons.class_,
                              color: Colors.brown, size: 28),
                          title: Text(
                            "${schedule['time']} - ${schedule['subject']}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Row(
                            children: [
                              const Icon(Icons.group,
                                  size: 18, color: Colors.brown),
                              const SizedBox(width: 6),
                              Text(schedule['section'] ?? "",
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 12),
                              const Icon(Icons.meeting_room,
                                  size: 18, color: Colors.brown),
                              const SizedBox(width: 6),
                              Text(schedule['room'] ?? "",
                                  style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canStartClass
                                  ? primaryColor
                                  : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: canStartClass
                                ? () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SeatPage(
                                          scheduleId: schedule['id'],
                                          subject: schedule['subject']!,
                                          room: schedule['room']!,
                                          time: schedule['time']!,
                                          section: schedule['section']!,
                                          profId: widget.profId,
                                        ),
                                      ),
                                    );
                                  }
                                : _showNotTodayDialog,
                            child: const Text("Start",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}