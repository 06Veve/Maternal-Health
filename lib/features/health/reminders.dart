import 'package:flutter/material.dart';
import 'package:bebezen/core/services/notification_service.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  TimeOfDay _vitaminTime = const TimeOfDay(hour: 8, minute: 0);

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _vitaminTime,
    );
    if (picked != null && picked != _vitaminTime) {
      setState(() {
        _vitaminTime = picked;
      });
    }
  }

  void _scheduleVitaminReminder() {
    NotificationService().scheduleDailyReminder(
      id: 1,
      title: "Prenatal Vitamins",
      body: "Time to take your vitamins! 💊",
      hour: _vitaminTime.hour,
      minute: _vitaminTime.minute,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Reminder set for ${_vitaminTime.format(context)}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3F7),
      appBar: AppBar(
        title: const Text("Reminders"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.medication, color: Colors.pinkAccent),
                title: const Text("Daily Vitamins"),
                subtitle: Text("Current time: ${_vitaminTime.format(context)}"),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => _selectTime(context),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _scheduleVitaminReminder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text("Set Vitamin Reminder", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
