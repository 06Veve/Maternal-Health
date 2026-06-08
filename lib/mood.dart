import 'package:flutter/material.dart';

class Mood extends StatefulWidget {
  const Mood({super.key});

  @override
  State<Mood> createState() => _MoodTrackerPageState();
}

class _MoodTrackerPageState extends State<Mood> {
  String? selectedMessage;
  String? selectedEmoji;
  final Map<String, String> messages = {
    '😄': 'I am feeling great today!',
    '😔': 'Je ne feel pas goodent.',
    '😡': 'I am feeling quite angry right now.',
    '😐': 'I am feeling okay, nothing special.',
    '😃': 'I am feeling really excited about something!',

  };
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: selectedEmoji != null
          ? _getBackgroundColor(selectedEmoji!)
          : const Color(0xFFFFE6F0),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'How are you feeling today?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                // runSpacing: 10,
                children: messages.keys.map((message) {
                  final isSelected = selectedEmoji == message;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedEmoji = message;
                        selectedMessage = messages[message];
                      });
                    },

                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutBack,
                      width: isSelected ? 70 : 60,
                      height: isSelected ? 70 : 60,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.pinkAccent
                            : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          message,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (selectedMessage != null)
                Text(
                  selectedMessage!,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _getBackgroundColor(String emoji) {
  switch (emoji) {
    case '😄':
      return Colors.pinkAccent;
    case '😔':
      return Colors.pink.shade100;
    case '😡':
      return Colors.red.shade400;
    case '😐':
      return Colors.purple.shade100;
    case '😃':
      return Colors.purple.shade200;

    default:
      return const Color.fromARGB(255, 117, 178, 207);
  }
}
