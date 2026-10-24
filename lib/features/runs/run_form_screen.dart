import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/compact_date_time_picker.dart';

class RunFormScreen extends ConsumerStatefulWidget {
  const RunFormScreen({super.key, this.run});
  /// When non-null the form opens in edit mode for this run.
  final ClubRun? run;

  @override
  ConsumerState<RunFormScreen> createState() => _RunFormScreenState();
}

class _RunFormScreenState extends ConsumerState<RunFormScreen> {
  late final TextEditingController title;
  late final TextEditingController location;
  late final TextEditingController points;
  late final TextEditingController capacity;
  late DateTime startsAt;
  bool saving = false;
  String? error;

  bool get isEditing => widget.run != null;

  @override
  void initState() {
    super.initState();
    final r = widget.run;
    title = TextEditingController(text: r?.title ?? '');
    location = TextEditingController(text: r?.location ?? '');
    points = TextEditingController(text: '${r?.points ?? 10}');
    capacity = TextEditingController(text: '${r?.capacity ?? 30}');
    startsAt = r?.startsAt ?? DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    title.dispose();
    location.dispose();
    points.dispose();
    capacity.dispose();
    super.dispose();
  }

  Future<void> pickDateTime() async {
    final date = await showCompactDatePicker(
      context: context,
      initialDate: startsAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showCompactTimePicker(
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
    final parsedCapacity = int.tryParse(capacity.text);
    if (title.text.trim().isEmpty ||
        location.text.trim().isEmpty ||
        parsedPoints == null ||
        parsedPoints < 1 ||
        parsedCapacity == null ||
        parsedCapacity < 1) {
      setState(() => error = 'Tüm alanları geçerli bilgilerle doldur.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final repo = ref.read(repositoryProvider);
      if (isEditing) {
        await repo.updateRun(
          runId: widget.run!.id,
          title: title.text,
          startsAt: startsAt,
          location: location.text,
          points: parsedPoints,
          capacity: parsedCapacity,
        );
        // Notify users who reserved this run.
        final reservedUsers =
            await repo.getRunReservedUserIds(widget.run!.id);
        if (reservedUsers.isNotEmpty) {
          repo.sendNotification(
            type: 'run_updated',
            refId: widget.run!.id,
            targetUserIds: reservedUsers,
            title: 'Koşu güncellendi',
            body: '${title.text} koşusu güncellendi. Detayları kontrol et.',
          );
        }
      } else {
        await repo.createRun(
          title: title.text,
          startsAt: startsAt,
          location: location.text,
          points: parsedPoints,
          capacity: parsedCapacity,
        );
        // Notify all users about the new run.
        repo.sendNotification(
          type: 'new_run',
          title: 'Yeni koşu planlandı!',
          body: '${title.text} — katılmak için hemen yerini ayırt.',
        );
      }
      ref.invalidate(runsProvider);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = isEditing
              ? 'Koşu güncellenemedi. Tekrar dene.'
              : 'Koşu planlanamadı. Antrenör yetkini ve bağlantını kontrol et.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(isEditing ? 'Koşuyu düzenle' : 'Koşu planla'),
    ),
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
        TextField(
          controller: capacity,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Kişi limiti',
            suffixText: 'kişi',
          ),
        ),
        const SizedBox(height: 20),
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
          icon: Icon(isEditing ? Icons.save : Icons.add),
          label: Text(
            saving
                ? 'Kaydediliyor…'
                : isEditing
                    ? 'DEĞİŞİKLİKLERİ KAYDET'
                    : 'Koşuyu planla',
          ),
        ),
      ],
    ),
  );
}
