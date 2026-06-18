import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:bebezen/shared/widgets/bz_components.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bebezen/core/utils/pdf_generator.dart';

class SymptomTracker extends StatefulWidget {
  const SymptomTracker({super.key});

  @override
  State<SymptomTracker> createState() => _SymptomTrackerState();
}

class _SymptomTrackerState extends State<SymptomTracker> {
  final List<String> _symptoms = [
    "Nausea",
    "Fatigue",
    "Headache",
    "Back Pain",
    "Dizziness",
    "Cravings",
    "Mood Swings",
  ];

  final Map<String, int> _selectedSymptoms = {};

  Future<void> _saveSymptoms() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final householdId = profile.data()?['householdId'] as String?;
    if (householdId == null) return;
    await FirebaseFirestore.instance
        .collection('households')
        .doc(householdId)
        .collection('healthLogs')
        .add({
          'type': 'symptoms',
          'date': FieldValue.serverTimestamp(),
          'symptoms': _selectedSymptoms,
          'createdBy': user.uid,
        });

    setState(() => _selectedSymptoms.clear());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Symptoms saved successfully!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Symptom Tracker"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.picture_as_pdf,
              color: BebezenPalette.primary,
            ),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;
              final profile = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .get();
              final householdId = profile.data()?['householdId'] as String?;
              if (householdId == null) return;
              final snap = await FirebaseFirestore.instance
                  .collection('households')
                  .doc(householdId)
                  .collection('healthLogs')
                  .orderBy('date', descending: true)
                  .get();
              final symptomDocs = snap.docs
                  .where((doc) => doc.data()['type'] == 'symptoms')
                  .toList();
              if (symptomDocs.isNotEmpty)
                PdfGenerator.generateSymptomReport(symptomDocs);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              "How are you feeling today?",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _symptoms.length,
                itemBuilder: (context, index) {
                  final s = _symptoms[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: BZCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: BebezenPalette.textSecondary,
                            ),
                            onPressed: () => setState(() {
                              _selectedSymptoms[s] =
                                  (_selectedSymptoms[s] ?? 0) - 1;
                              if (_selectedSymptoms[s]! < 0)
                                _selectedSymptoms[s] = 0;
                            }),
                          ),
                          Text(
                            "${_selectedSymptoms[s] ?? 0}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: BebezenPalette.primary,
                            ),
                            onPressed: () => setState(
                              () => _selectedSymptoms[s] =
                                  (_selectedSymptoms[s] ?? 0) + 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            BZButton(label: "Save Entry", onPressed: _saveSymptoms),
          ],
        ),
      ),
    );
  }
}
