import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:criminal_tracker/models/criminal.dart';

class AttendanceCalendar extends StatefulWidget {
  const AttendanceCalendar({Key? key, required this.criminal})
      : super(key: key);

  final Criminal criminal;

  @override
  _AttendanceCalendarState createState() => _AttendanceCalendarState();
}

class _AttendanceCalendarState extends State<AttendanceCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<DateTime> attendanceDates = [];

  @override
  void initState() {
    super.initState();
    fetchAttendanceDates();
  }

  Future<void> fetchAttendanceDates() async {
    String uid = widget.criminal.uid;

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('attendance')
          .doc(uid)
          .collection('timestamps')
          .get();

      List<DateTime> dates = querySnapshot.docs
          .map((snapshot) => (snapshot.data()
              as Map<String, dynamic>)['timestamps'] as List<dynamic>)
          .expand((timestamps) =>
              timestamps.map((timestamp) => (timestamp as Timestamp).toDate()))
          .toList();

      setState(() {
        attendanceDates = dates;
      });
    } catch (e) {
      print('Error fetching attendance dates: $e');
    }
  }

  bool _isAttendanceDate(DateTime day) {
    return attendanceDates.any((date) => isSameDay(day, date));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            calendarFormat: _calendarFormat,
            focusedDay: _focusedDay,
            firstDay: DateTime.utc(2010),
            lastDay: DateTime.utc(2030),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (_isAttendanceDate(day)) {
                  return Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      width: 8,
                      height: 8,
                    ),
                  );
                } else {
                  return Container();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
