import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessorsPage extends StatefulWidget {
  const ProfessorsPage({super.key});

  @override
  State<ProfessorsPage> createState() => _ProfessorsPageState();
}

class _ProfessorsPageState extends State<ProfessorsPage> {
  final ref = FirebaseFirestore.instance.collection('professors');

  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  String searchQuery = ""; // ✅ added

  void add() async {
    if (name.text.isEmpty || email.text.isEmpty || password.text.isEmpty) return;

    await ref.add({
      'name': name.text,
      'email': email.text,
      'password': password.text,
    });

    name.clear();
    email.clear();
    password.clear();
    setState(() {});
  }

  void update(String id, Map data) {
    final n = TextEditingController(text: data['name']);
    final e = TextEditingController(text: data['email']);
    final p = TextEditingController(text: data['password']);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit Professor"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: n,
                decoration: const InputDecoration(
                  labelText: "Name",
                  prefixIcon: Icon(Icons.person, color: Colors.brown),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: e,
                decoration: const InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email, color: Colors.brown),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: p,
                decoration: const InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock, color: Colors.brown),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
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
              await ref.doc(id).update({
                'name': n.text,
                'email': e.text,
                'password': p.text,
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.brown;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.brown,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Icon(Icons.person, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Form card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: "Name",
                        prefixIcon: Icon(Icons.person, color: Colors.brown),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: email,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email, color: Colors.brown),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: password,
                      decoration: const InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock, color: Colors.brown),
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text("Add", style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: primary),
                        onPressed: add,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Search Bar (added, same UI style)
            TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search professor...",
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // List of professors
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: ref.snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var docs = snap.data!.docs;

                  // ✅ Apply search filter
                  if (searchQuery.isNotEmpty) {
                    final q = searchQuery.toLowerCase();
                    docs = docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return (data['name']?.toLowerCase().contains(q) ?? false) ||
                          (data['email']?.toLowerCase().contains(q) ?? false);
                    }).toList();
                  }

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text("No professors found.", style: TextStyle(fontSize: 16)),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final d = docs[i];
                      final data = d.data() as Map<String, dynamic>;

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          leading: const Icon(Icons.person, color: Colors.brown),
                          title: Text(data['name'], overflow: TextOverflow.ellipsis),
                          subtitle: Text("Email: ${data['email']}\nID: ${d.id}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.brown),
                                onPressed: () => update(d.id, data),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => ref.doc(d.id).delete(),
                              ),
                            ],
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