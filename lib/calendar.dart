import 'dart:async';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// -------- Helpers top-level (accessibles partout) --------

DateTime dayKey(DateTime d) => DateTime.utc(d.year, d.month, d.day);

int notifIdFromDate(DateTime dt) => dt.millisecondsSinceEpoch ~/ 1000;

/// Event model to store more detailed information
class PregnancyEvent {
  final String? id; // Firestore doc id
  final String title;
  final String type;
  final DateTime dateTime;
  final String? notes;
  final bool isCompleted;
  final int? notifyId; // local notification id (for cancel/update)

  PregnancyEvent({
    this.id,
    required this.title,
    required this.type,
    required this.dateTime,
    this.notes,
    this.isCompleted = false,
    this.notifyId,
  });

  PregnancyEvent copyWith({
    String? id,
    String? title,
    String? type,
    DateTime? dateTime,
    String? notes,
    bool? isCompleted,
    int? notifyId,
  }) {
    return PregnancyEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      notifyId: notifyId ?? this.notifyId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'dateTime': Timestamp.fromDate(dateTime),
      'notes': notes,
      'isCompleted': isCompleted,
      'notifyId': notifyId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory PregnancyEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final DateTime dt = (data['dateTime'] as Timestamp).toDate();
    return PregnancyEvent(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      type: (data['type'] ?? 'Other') as String,
      dateTime: dt,
      notes: data['notes'] as String?,
      isCompleted: (data['isCompleted'] ?? false) as bool,
      notifyId: (data['notifyId'] as int?) ?? notifIdFromDate(dt),
    );
  }
}

class PregnancyCalendarPage extends StatefulWidget {
  const PregnancyCalendarPage({super.key});

  @override
  State<PregnancyCalendarPage> createState() => _PregnancyCalendarPageState();
}

class _PregnancyCalendarPageState extends State<PregnancyCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  // In-memory map built FROM Firestore snapshots
  Map<DateTime, List<PregnancyEvent>> _events = {};

  // Firestore subscription
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventsSub;

  // Event types for categorization
  final List<String> _eventTypes = [
    'Medical',
    'Supplement',
    'Exercise',
    'Nutrition',
    'Personal',
    'Other'
  ];

  // Colors for different event types
  final Map<String, Color> _typeColors = {
    'Medical': Colors.red,
    'Supplement': Colors.green,
    'Exercise': Colors.blue,
    'Nutrition': Colors.orange,
    'Personal': Colors.purple,
    'Other': Colors.grey,
  };

  // Icons for different event types
  final Map<String, IconData> _typeIcons = {
    'Medical': Icons.local_hospital,
    'Supplement': Icons.medication,
    'Exercise': Icons.fitness_center,
    'Nutrition': Icons.restaurant,
    'Personal': Icons.person,
    'Other': Icons.event,
  };

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();

    // Init local notifications
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings androidInit =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidInit);
    flutterLocalNotificationsPlugin.initialize(initSettings);

    // Android 13+ notif permission
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Subscribe to Firestore events of current user
    _subscribeToUserEvents();
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  CollectionReference<Map<String, dynamic>>? _userEventsCol() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    // ⚠ Remplace "users" par "user" si ta collection s’appelle ainsi.
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('events');
  }

  void _subscribeToUserEvents() {
    final col = _userEventsCol();
    if (col == null) return;

    _eventsSub = col.orderBy('dateTime').snapshots().listen((snap) {
      final map = <DateTime, List<PregnancyEvent>>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['dateTime'] == null) continue;
        final event = PregnancyEvent.fromDoc(doc);
        final key = dayKey(event.dateTime);
        (map[key] ??= []).add(event);
      }
      setState(() => _events = map);
    }, onError: (e) {
      debugPrint('Error listening to events: $e');
    });
  }

  /// Returns events for a specific day
  List<PregnancyEvent> _getEventsForDay(DateTime day) {
    return _events[dayKey(day)] ?? [];
  }

  /// Handles day selection
  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  /// Schedule a local notification (paramètres compatibles avec ta version)
  Future<void> _scheduleNotification(PregnancyEvent event) async {
    final id = event.notifyId ?? notifIdFromDate(event.dateTime);
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      '${event.type} Reminder',
      event.title,
      tz.TZDateTime.from(event.dateTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'pregnancy_reminder_channel',
          'Pregnancy Reminders',
          channelDescription: 'Reminders for pregnancy-related events',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
      // ⛔ Pas de uiLocalNotificationDateInterpretation ici
    );
  }

  /// Dialog to add an event (writes to Firestore)
  Future<void> _addEventDialog() async {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime selectedDate = _selectedDay ?? _focusedDay;
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);
    String selectedType = _eventTypes.first;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Add Pregnancy Event"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Event Title",
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: "Event Type",
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _eventTypes.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Row(
                            children: [
                              Icon(
                                _typeIcons[type],
                                color: _typeColors[type],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(type),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: "Notes (Optional)",
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2024),
                                lastDate: DateTime(2026),
                              );
                              if (picked != null) {
                                setDialogState(() => selectedDate = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (picked != null) {
                                setDialogState(() => selectedTime = picked);
                              }
                            },
                            icon: const Icon(Icons.access_time),
                            label: Text(selectedTime.format(context)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: const Text("Save"),
                  onPressed: () async {
                    final col = _userEventsCol();
                    if (col == null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('You must be logged in.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final eventTitle = titleController.text.isEmpty
                        ? "Untitled Event"
                        : titleController.text;

                    final scheduledDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    final notifyId = notifIdFromDate(scheduledDateTime);

                    final newEvent = PregnancyEvent(
                      title: eventTitle,
                      type: selectedType,
                      dateTime: scheduledDateTime,
                      notes: notesController.text.isEmpty
                          ? null
                          : notesController.text,
                      isCompleted: false,
                      notifyId: notifyId,
                    );

                    try {
                      final ref = await col.add(newEvent.toMap());
                      await ref.update({
                        'id': ref.id,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      await _scheduleNotification(newEvent);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Event "$eventTitle" added successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add event: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Toggle event completion status (updates Firestore)
  Future<void> _toggleEventCompletion(DateTime day, int index) async {
    final eventsOfDay = _getEventsForDay(day);
    if (index < 0 || index >= eventsOfDay.length) return;
    final event = eventsOfDay[index];
    final col = _userEventsCol();
    if (col == null || event.id == null) return;

    try {
      await col.doc(event.id).update({
        'isCompleted': !event.isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Delete an event (deletes Firestore doc + cancels local notification)
  Future<void> _deleteEvent(DateTime day, int index) async {
    final eventsOfDay = _getEventsForDay(day);
    if (index < 0 || index >= eventsOfDay.length) return;
    final event = eventsOfDay[index];
    final col = _userEventsCol();
    if (col == null || event.id == null) return;

    try {
      await col.doc(event.id).delete();
      await flutterLocalNotificationsPlugin.cancel(
        event.notifyId ?? notifIdFromDate(event.dateTime),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Event deleted'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Builds the calendar widget (UI unchanged)
  Widget _buildCalendar() {
    return TableCalendar<PregnancyEvent>(
      firstDay: DateTime.utc(2024, 1, 1),
      lastDay: DateTime.utc(2026, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: _getEventsForDay,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(
          color: Colors.pinkAccent,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        selectedDecoration: BoxDecoration(
          color: Colors.pink,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        weekendTextStyle: TextStyle(
          color: Colors.grey,
        ),
        markerDecoration: BoxDecoration(
          color: Colors.purple,
          shape: BoxShape.circle,
        ),
        markerSize: 6.0,
        markersMaxCount: 3,
        outsideDaysVisible: false,
      ),
      onDaySelected: _onDaySelected,
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
        });
      },
    );
  }

  /// Builds events list with enhanced UI (unchanged)
  Widget _buildEventsList() {
    final selectedEvents = _getEventsForDay(_selectedDay ?? _focusedDay);

    if (selectedEvents.isEmpty) {
      return Expanded(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note, size: 48, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No events for this day',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add an event',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Events for ${_selectedDay?.day ?? _focusedDay.day}/${_selectedDay?.month ?? _focusedDay.month}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.pink,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              physics: BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: selectedEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final event = selectedEvents[index];
                final typeColor = _typeColors[event.type] ?? Colors.grey;
                final typeIcon = _typeIcons[event.type] ?? Icons.event;

                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: typeColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: typeColor.withOpacity(0.1),
                        child: Icon(
                          typeIcon,
                          color: typeColor,
                        ),
                      ),
                      title: Text(
                        event.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          decoration: event.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: event.isCompleted ? Colors.grey : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${event.dateTime.hour}:${event.dateTime.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  event.type,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: typeColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (event.notes != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              event.notes!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              event.isCompleted
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: event.isCompleted
                                  ? Colors.green
                                  : Colors.grey,
                            ),
                            onPressed: () => _toggleEventCompletion(
                              _selectedDay ?? _focusedDay,
                              index,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteEvent(
                              _selectedDay ?? _focusedDay,
                              index,
                            ),
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
  }


  /// Build statistics widget (UI unchanged)
  Widget _buildQuickStats() {
    final today = DateTime.now();
    final todayEvents = _getEventsForDay(today);
    final completedToday = todayEvents.where((e) => e.isCompleted).length;
    final totalToday = todayEvents.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pink[100]!, Colors.pink[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                '$completedToday/$totalToday',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              const Text(
                'Today\'s Tasks',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.pink,
                ),
              ),
            ],
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.pink[200],
          ),
          Column(
            children: [
              Text(
                '${_events.length}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              const Text(
                'Total Days',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.pink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[25],
      appBar: AppBar(
        title: const Text("Pregnancy Calendar"),
        backgroundColor: Colors.pink[50],
        foregroundColor: Colors.pink[800],
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickStats(),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildCalendar(),
          ),
          const SizedBox(height: 8),
          _buildEventsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addEventDialog,
        backgroundColor: Colors.pink,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Event',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}