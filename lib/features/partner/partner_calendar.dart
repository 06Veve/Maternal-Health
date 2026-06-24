import 'dart:async';
import 'package:bebezen/calendar.dart';
import 'package:bebezen/core/theme/bebezen_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

/// Read-only view of the shared household calendar for the partner.
class PartnerCalendarPage extends StatefulWidget {
  const PartnerCalendarPage({super.key});

  @override
  State<PartnerCalendarPage> createState() => _PartnerCalendarPageState();
}

class _PartnerCalendarPageState extends State<PartnerCalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<_PartnerEvent>> _events = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;

  static const Map<String, Color> _typeColors = {
    'Medical': Colors.red,
    'Supplement': Colors.green,
    'Exercise': Colors.blue,
    'Nutrition': Colors.orange,
    'Personal': Colors.purple,
    'Other': Colors.grey,
  };

  static const Map<String, IconData> _typeIcons = {
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
    _subscribe();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final householdId = userDoc.data()?['householdId'] as String?;
    if (householdId == null) return;

    _sub = FirebaseFirestore.instance
        .collection('households')
        .doc(householdId)
        .collection('events')
        .orderBy('dateTime')
        .snapshots()
        .listen((snap) {
          final map = <DateTime, List<_PartnerEvent>>{};
          for (final doc in snap.docs) {
            final data = doc.data();
            if (data['dateTime'] == null) continue;
            final dt = (data['dateTime'] as Timestamp).toDate();
            final key = dayKey(dt);
            (map[key] ??= []).add(
              _PartnerEvent(
                id: doc.id,
                title: data['title'] as String? ?? '',
                type: data['type'] as String? ?? 'Other',
                dateTime: dt,
                notes: data['notes'] as String?,
                isCompleted: data['isCompleted'] == true,
                partnerAttending: data['partnerAttending'] as bool?,
              ),
            );
          }
          if (mounted) setState(() => _events = map);
        });
  }

  List<_PartnerEvent> _eventsForDay(DateTime day) {
    return _events[dayKey(day)] ?? [];
  }

  Future<void> _setAttendance(String docId, String householdId, bool attending) async {
    await FirebaseFirestore.instance
        .collection('households')
        .doc(householdId)
        .collection('events')
        .doc(docId)
        .update({'partnerAttending': attending});
  }

  @override
  Widget build(BuildContext context) {
    final dayEvents = _eventsForDay(_selectedDay ?? _focusedDay);
    return Scaffold(
      backgroundColor: BebezenPalette.partnerBackground,
      appBar: AppBar(
        title: const Text('Shared Calendar'),
        backgroundColor: BebezenPalette.partnerBackground,
        foregroundColor: BebezenPalette.partnerPrimary,
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TableCalendar<_PartnerEvent>(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2027, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: _eventsForDay,
              startingDayOfWeek: StartingDayOfWeek.sunday,
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: BebezenPalette.partnerPrimary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Color(0xFF1565C0),
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: Color(0xFF42A5F5),
                  shape: BoxShape.circle,
                ),
                markerSize: 6,
                markersMaxCount: 3,
                outsideDaysVisible: false,
              ),
              onDaySelected: (sel, foc) => setState(() {
                _selectedDay = sel;
                _focusedDay = foc;
              }),
              onPageChanged: (foc) => setState(() => _focusedDay = foc),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'View only — events added by your partner',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Expanded(
            child: dayEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_note,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No events for this day',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: dayEvents.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final event = dayEvents[i];
                      final color =
                          _typeColors[event.type] ?? Colors.grey;
                      final icon =
                          _typeIcons[event.type] ?? Icons.event;
                      return _EventTile(
                        event: event,
                        color: color,
                        icon: icon,
                        onAttendance: (attending) async {
                          final uid =
                              FirebaseAuth.instance.currentUser?.uid;
                          if (uid == null) return;
                          final userDoc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .get();
                          final hId =
                              userDoc.data()?['householdId'] as String?;
                          if (hId == null) return;
                          await _setAttendance(event.id, hId, attending);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PartnerEvent {
  const _PartnerEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.dateTime,
    this.notes,
    this.isCompleted = false,
    this.partnerAttending,
  });
  final String id;
  final String title;
  final String type;
  final DateTime dateTime;
  final String? notes;
  final bool isCompleted;
  final bool? partnerAttending;
}

class _EventTile extends StatelessWidget {
  const _EventTile({
    required this.event,
    required this.color,
    required this.icon,
    required this.onAttendance,
  });
  final _PartnerEvent event;
  final Color color;
  final IconData icon;
  final Future<void> Function(bool attending) onAttendance;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(event.dateTime);
    final attending = event.partnerAttending;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          decoration: event.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: event.isCompleted
                              ? Colors.grey
                              : BebezenPalette.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            time,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event.type,
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (event.notes != null && event.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 4),
                  Icon(Icons.place_outlined, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.notes!,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (attending == true)
              _AttendRow(
                attending: true,
                onToggle: () => onAttendance(false),
              )
            else if (attending == false)
              _AttendRow(
                attending: false,
                onToggle: () => onAttendance(true),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => onAttendance(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Can\'t make it',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => onAttendance(true),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'I\'m attending',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AttendRow extends StatelessWidget {
  const _AttendRow({required this.attending, required this.onToggle});
  final bool attending;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final color = attending ? BebezenPalette.success : BebezenPalette.error;
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              attending ? Icons.check_circle : Icons.cancel_outlined,
              size: 15,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              attending
                  ? 'Attending  •  tap to change'
                  : 'Not attending  •  tap to change',
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
