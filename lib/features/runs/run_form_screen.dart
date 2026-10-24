import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/providers.dart';

class RunFormScreen extends ConsumerStatefulWidget {
  const RunFormScreen({super.key});

  @override
  ConsumerState<RunFormScreen> createState() => _RunFormScreenState();
}

class _RunFormScreenState extends ConsumerState<RunFormScreen> {
  final title = TextEditingController();
  final location = TextEditingController();
  final points = TextEditingController(text: '10');
  DateTime startsAt = DateTime.now().add(const Duration(days: 1));
  bool saving = false;
  String? error;

  @override
  void dispose() {
    title.dispose();
    location.dispose();
    points.dispose();
    super.dispose();
  }

  Future<void> pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: startsAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(startsAt),
    );
    if (time == null) return;
    setState(
      () => startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ),
    );
  }

  Future<void> save() async {
    final parsedPoints = int.tryParse(points.text);
    if (title.text.trim().isEmpty ||
        location.text.trim().isEmpty ||
        parsedPoints == null ||
        parsedPoints < 1) {
      setState(() => error = 'Tüm alanları geçerli bilgilerle doldur.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ref
          .read(repositoryProvider)
          .createRun(
            title: title.text,
            startsAt: startsAt,
            location: location.text,
            points: parsedPoints,
          );
      ref.invalidate(runsProvider);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Koşu planlanamadı. Antrenör yetkini ve bağlantını kontrol et.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Koşu planla')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: title,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Koşu adı',
            hintText: 'Örn. Salı Tempo Koşusu',
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: location,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Buluşma noktası',
            hintText: 'Örn. Aydın Tekstil Park',
          ),
        ),
        const SizedBox(height: 14),
        ListTile(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Theme.of(context).colorScheme.outline),
            borderRadius: BorderRadius.circular(4),
          ),
          leading: const Icon(Icons.calendar_month),
          title: const Text('Tarih ve saat'),
          subtitle: Text(DateFormat('dd.MM.yyyy • HH:mm').format(startsAt)),
          onTap: pickDateTime,
        ),
        const SizedBox(height: 14),
        TextField(
          controller: points,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Katılım puanı',
            suffixText: 'puan',
          ),
        ),
        const SizedBox(height: 14),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        FilledButton.icon(
          onPressed: saving ? null : save,
          icon: const Icon(Icons.add),
          label: Text(saving ? 'Kaydediliyor…' : 'Koşuyu planla'),
        ),
      ],
    ),
  );
}
