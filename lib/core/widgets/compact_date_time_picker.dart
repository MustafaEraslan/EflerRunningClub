import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Shows a compact date picker.
/// On all platforms the dialog is capped at 500×550 px and text scaling is
/// reset to 1.0 so that "Accessibility → Larger Text" settings do not blow
/// the dialog out of the visible screen area.
Future<DateTime?> showCompactDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    initialEntryMode: DatePickerEntryMode.calendarOnly,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.noScaling,
      ),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
          child: child!,
        ),
      ),
    ),
  );
}

/// Shows a compact time picker using a Cupertino bottom sheet on all
/// platforms; this avoids the oversized clock face on iOS.
Future<TimeOfDay?> showCompactTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) async {
  DateTime tempDate = DateTime(2000, 1, 1, initialTime.hour, initialTime.minute);
  final confirmed = await showCupertinoModalPopup<bool>(
    context: context,
    builder: (ctx) => _CupertinoTimerSheet(
      initialTime: tempDate,
      onChanged: (d) => tempDate = d,
    ),
  );
  if (confirmed != true) return null;
  return TimeOfDay(hour: tempDate.hour, minute: tempDate.minute);
}

class _CupertinoTimerSheet extends StatelessWidget {
  const _CupertinoTimerSheet({
    required this.initialTime,
    required this.onChanged,
  });
  final DateTime initialTime;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      color: CupertinoTheme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                child: const Text('İptal'),
                onPressed: () => Navigator.pop(context, false),
              ),
              CupertinoButton(
                child: const Text(
                  'Tamam',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: initialTime,
              use24hFormat: true,
              onDateTimeChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
