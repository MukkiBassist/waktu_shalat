import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hijri/hijri_calendar.dart';

class HijriCalendarWidget extends StatefulWidget {
  const HijriCalendarWidget({super.key});

  @override
  State<HijriCalendarWidget> createState() => _HijriCalendarWidgetState();
}

class _HijriCalendarWidgetState extends State<HijriCalendarWidget> {
  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  @override
  Widget build(BuildContext context) {
    return TableCalendar(
      focusedDay: focusedDay,
      firstDay: DateTime(2020),
      lastDay: DateTime(2100),
      selectedDayPredicate: (day) => isSameDay(selectedDay, day),
      onDaySelected: (selected, focused) {
        setState(() {
          selectedDay = selected;
          focusedDay = focused; // update `_focusedDay` here as well
        });
      },
      calendarBuilders: CalendarBuilders(
        defaultBuilder: (context, date, _) {
          final hijriDate = HijriCalendar.fromDate(date);
          return Center(
            child: Text(
              '${hijriDate.hDay}',
              style: const TextStyle(fontSize: 12),
            ),
          );
        },
        todayBuilder: (context, date, _) {
          final hijri = HijriCalendar.fromDate(date);
          return Container(
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),

            child: Center(
              child: Text(
                '${hijri.hDay}',
                style: const TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
