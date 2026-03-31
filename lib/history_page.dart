import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'class_history_page.dart';

class HistoryPage extends StatefulWidget {
  final String profId;
  final String profName;

  const HistoryPage({super.key, required this.profId, required this.profName});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String searchQuery = "";
  String sortOption = "Date Desc"; // default

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
    const double cardPadding = 16.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where('profId', isEqualTo: widget.profId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List<QueryDocumentSnapshot> docs = snapshot.data!.docs;

          // Convert to Map for filtering
          List<Map<String, dynamic>> entries = docs
              .map((doc) => {
                    "id": doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  })
              .toList();

          // Apply search filter
          if (searchQuery.isNotEmpty) {
            final q = searchQuery.toLowerCase();
            entries = entries.where((entry) {
              return (entry['subject']?.toLowerCase().contains(q) ?? false) ||
                  (entry['section']?.toLowerCase().contains(q) ?? false) ||
                  (entry['room']?.toLowerCase().contains(q) ?? false);
            }).toList();
          }

          // Apply sorting
          entries.sort((a, b) {
            switch (sortOption) {
              case "Date Asc":
                return (a['date'] ?? 0).compareTo(b['date'] ?? 0);
              case "Subject A→Z":
                return (a['subject'] ?? "").compareTo(b['subject'] ?? "");
              case "Subject Z→A":
                return (b['subject'] ?? "").compareTo(a['subject'] ?? "");
              default: // Date Desc
                return (b['date'] ?? 0).compareTo(a['date'] ?? 0);
            }
          });

          if (entries.isEmpty) {
            return const Center(
              child: Text(
                "No classes yet.",
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(cardPadding),
            child: Column(
              children: [
                // Search + Sort row
                Row(
                  children: [
                    // Search Bar
                    Expanded(
                      child: TextField(
                        onChanged: (value) => setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: "Search by subject, section, room...",
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Styled Sort Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.white, // background color
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<String>(
                        value: sortOption,
                        underline: const SizedBox(), // remove default underline
                        items: const [
                          DropdownMenuItem(
                            value: "Date Desc",
                            child: Text("Date ↓"),
                          ),
                          DropdownMenuItem(
                            value: "Date Asc",
                            child: Text("Date ↑"),
                          ),
                          DropdownMenuItem(
                            value: "Subject A→Z",
                            child: Text("Subject A→Z"),
                          ),
                          DropdownMenuItem(
                            value: "Subject Z→A",
                            child: Text("Subject Z→A"),
                          ),
                        ],
                        onChanged: (value) => setState(() {
                          if (value != null) sortOption = value;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // List
                Expanded(
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final attendanceId = entry['id'];
                      final int dateMillis = entry['date'] ?? 0;
                      final String formattedDate =
                          dateMillis != 0 ? _formatDate(dateMillis) : "No date";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        elevation: 4,
                        shadowColor: Colors.grey.shade300,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClassHistoryPage(
                                  attendanceId: attendanceId,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(cardPadding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Subject + delete + arrow
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry['subject'] ?? "",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Date: $formattedDate",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        // Delete icon
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                backgroundColor: Colors.white,
                                                title: const Text("Delete Record?"),
                                                content: const Text(
                                                    "Are you sure you want to delete this class record? This action cannot be undone."),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(context, false),
                                                    child: const Text("Cancel"),
                                                  ),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.red,
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(context, true),
                                                    child: const Text("Delete"),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              try {
                                                await FirebaseFirestore.instance
                                                    .collection('attendance')
                                                    .doc(attendanceId)
                                                    .delete();
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text("Record deleted")),
                                                );
                                              } catch (e) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                      content: Text(
                                                          "Failed to delete: $e")),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                        const Icon(Icons.arrow_forward_ios,
                                            size: 18, color: Colors.brown),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                // Section + Room
                                Row(
                                  children: [
                                    const Icon(Icons.groups, size: 18, color: Colors.brown),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Section: ${entry['section'] ?? ""}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.meeting_room, size: 18, color: Colors.brown),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Room: ${entry['room'] ?? ""}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Time + Duration
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, size: 18, color: Colors.brown),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Time: ${entry['time'] ?? ""}",
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 16),
                                    const Icon(Icons.timer, size: 18, color: Colors.brown),
                                    const SizedBox(width: 6),
                                    if (entry['timer'] != null)
                                      Text(
                                        "Duration: ${entry['timer']}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}