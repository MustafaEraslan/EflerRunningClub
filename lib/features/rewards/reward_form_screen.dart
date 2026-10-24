import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/providers/providers.dart';

class RewardFormScreen extends ConsumerStatefulWidget {
  const RewardFormScreen({super.key});

  @override
  ConsumerState<RewardFormScreen> createState() => _RewardFormScreenState();
}

class _RewardFormScreenState extends ConsumerState<RewardFormScreen> {
  final name = TextEditingController();
  final description = TextEditingController();
  final points = TextEditingController(text: '100');
  final stock = TextEditingController(text: '10');
  Uint8List? imageBytes;
  bool saving = false;
  String? error;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    points.dispose();
    stock.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
      requestFullMetadata: false,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (mounted) setState(() => imageBytes = bytes);
  }

  Future<void> save() async {
    final pointValue = int.tryParse(points.text);
    final stockValue = int.tryParse(stock.text);
    if (name.text.trim().isEmpty ||
        pointValue == null ||
        pointValue < 1 ||
        stockValue == null ||
        stockValue < 0) {
      setState(() => error = 'Ödül bilgilerini geçerli şekilde doldur.');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final repo = ref.read(repositoryProvider);
      final rewardId = await repo.createReward(
        name: name.text,
        description: description.text,
        pointsCost: pointValue,
        stock: stockValue,
      );
      if (imageBytes != null) {
        await repo.uploadRewardImage(rewardId, imageBytes!);
      }
      ref.invalidate(rewardsProvider);
      if (mounted) context.pop();
    } catch (_) {
      if (mounted) setState(() => error = 'Ödül kaydedilemedi. Tekrar dene.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Yeni ödül')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: pickImage,
          child: Ink(
            height: 210,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: const Color(0xFF242126),
              image: imageBytes == null
                  ? null
                  : DecorationImage(
                      image: MemoryImage(imageBytes!),
                      fit: BoxFit.cover,
                    ),
            ),
            child: imageBytes == null
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 48),
                      SizedBox(height: 10),
                      Text('ÖDÜL GÖRSELİ EKLE'),
                    ],
                  )
                : const Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircleAvatar(child: Icon(Icons.edit)),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Ödül adı'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: description,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Açıklama'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: points,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Puan bedeli'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stok'),
              ),
            ),
          ],
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: saving ? null : save,
          icon: const Icon(Icons.card_giftcard),
          label: Text(saving ? 'Kaydediliyor…' : 'ÖDÜLÜ YAYINLA'),
        ),
      ],
    ),
  );
}
