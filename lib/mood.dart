import 'package:bebezen/core/services/account_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Mood extends StatefulWidget {
  const Mood({super.key});

  @override
  State<Mood> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends State<Mood> {
  String? _selectedEmoji;
  String? _selectedLabel;
  int _energy = 0;
  bool _saving = false;
  bool _saved = false;

  static const Map<String, String> _moods = {
    '😄': 'Great',
    '😊': 'Good',
    '😐': 'Okay',
    '😔': 'Low',
    '😟': 'Stressed',
    '😡': 'Upset',
  };

  Future<void> _saveCheckin() async {
    if (_selectedEmoji == null) return;
    setState(() {
      _saving = true;
      _saved = false;
    });
    try {
      final householdId = await AccountService().currentHouseholdId();
      if (householdId == null) return;
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await FirebaseFirestore.instance
          .collection('households')
          .doc(householdId)
          .collection('dailyStatus')
          .doc(today)
          .set({
            'emoji': _selectedEmoji,
            'mood': _selectedLabel ?? '',
            'energy': _energy,
            'symptoms': [],
            'updatedAt': FieldValue.serverTimestamp(),
            'updatedBy': FirebaseAuth.instance.currentUser?.uid,
          });
      if (mounted) setState(() => _saved = true);
    } catch (_) {
      // network error — silently skip, local selection is still visible
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color _bgColor() {
    switch (_selectedEmoji) {
      case '😄':
        return Colors.pinkAccent;
      case '😊':
        return const Color(0xFFFF6B9D);
      case '😔':
        return Colors.pink.shade100;
      case '😡':
        return Colors.red.shade400;
      case '😐':
        return Colors.purple.shade100;
      case '😟':
        return Colors.purple.shade200;
      default:
        return const Color(0xFFFFE6F0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Text(
                'How are you feeling today?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: _moods.keys.map((emoji) {
                  final isSelected = _selectedEmoji == emoji;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedEmoji = emoji;
                      _selectedLabel = _moods[emoji];
                      _saved = false;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutBack,
                      width: isSelected ? 76 : 64,
                      height: isSelected ? 76 : 64,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.pinkAccent
                            : Colors.white.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.pinkAccent.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_selectedEmoji != null) ...[
                const SizedBox(height: 28),
                Text(
                  _selectedLabel ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Energy level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => setState(() => _energy = i + 1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          i < _energy
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveCheckin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.pinkAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.pinkAccent,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _saved ? '✓ Check-in saved!' : 'Save Check-in',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                if (_saved) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Your partner can now see how you\'re doing today.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
