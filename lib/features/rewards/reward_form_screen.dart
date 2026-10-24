import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/widgets/confirm_dialog.dart';

class RewardFormScreen extends ConsumerStatefulWidget {
  const RewardFormScreen({super.key, this.reward});
  /// When non-null the form opens in edit mode for this reward.
  final Reward? reward;

  @override
  ConsumerState<RewardFormScreen> createState() => _RewardFormScreenState();
}

class _RewardFormScreenState extends ConsumerState<RewardFormScreen> {
  late final TextEditingController name;
  late final TextEditingController description;
  late final TextEditingController points;
  late final TextEditingController stock;
  Uint8List? imageBytes;
  bool saving = false;
  bool deleting = false;
  String? error;

  bool get isEditing => widget.reward != null;

  @override
  void initState() {
    super.initState();
    final r = widget.reward;
    name = TextEditingController(text: r?.name ?? '');
    description = TextEditingController(text: r?.description ?? '');
    points = TextEditingController(text: '${r?.pointsCost ?? 100}');
    stock = TextEditingController(text: '${r?.stock ?? 10}');
  }

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
      if (isEditing) {
        await repo.updateReward(
          rewardId: widget.reward!.id,
          name: name.text,
          description: description.text,
          pointsCost: pointValue,
          stock: stockValue,
        );
        var imageFailed = false;
        if (imageBytes != null) {
          try {
            await repo.uploadRewardImage(widget.reward!.id, imageBytes!);
          } catch (_) {
            imageFailed = true;
          }
        }
        ref.invalidate(rewardsProvider);
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          context.pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                imageFailed
                    ? 'Ödül güncellendi; görsel yüklenemedi.'
                    : 'Ödül başarıyla güncellendi.',
              ),
            ),
          );
        }
      } else {
        final rewardId = await repo.createReward(
          name: name.text,
          description: description.text,
          pointsCost: pointValue,
          stock: stockValue,
        );
        var imageFailed = false;
        if (imageBytes != null) {
          try {
            await repo.uploadRewardImage(rewardId, imageBytes!);
          } catch (_) {
            imageFailed = true;
          }
        }
        ref.invalidate(rewardsProvider);
        if (mounted) {
          final messenger = ScaffoldMessenger.of(context);
          context.pop();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                imageFailed
                    ? 'Ödül kaydedildi; görsel yüklenemedi.'
                    : 'Ödül başarıyla yayınlandı.',
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() => error = 'Ödül kaydedilemedi. Tekrar dene.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> deleteReward() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Ödülü sil',
      message: '${widget.reward!.name} kalıcı olarak kaldırılsın mı?',
      confirmLabel: 'Sil',
    );
    if (!confirmed || !mounted) return;
    setState(() => deleting = true);
    try {
      await ref.read(repositoryProvider).deleteReward(widget.reward!.id);
      ref.invalidate(rewardsProvider);
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        context.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Ödül silindi.')),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ödül silinemedi. Tekrar dene.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show existing image in edit mode when no new image is picked.
    final existingImageUrl = isEditing && widget.reward!.imagePath != null
        ? ref.read(repositoryProvider).mediaUrl(widget.reward!.imagePath!)
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Ödülü düzenle' : 'Yeni ödül'),
        actions: [
          if (isEditing)
            IconButton(
              onPressed: deleting ? null : deleteReward,
              icon: deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.delete_outline),
              tooltip: 'Ödülü sil',
            ),
        ],
      ),
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
                image: imageBytes != null
                    ? DecorationImage(
                        image: MemoryImage(imageBytes!),
                        fit: BoxFit.cover,
                      )
                    : existingImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(existingImageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
              ),
              child: (imageBytes == null && existingImageUrl == null)
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
            icon: Icon(isEditing ? Icons.save : Icons.card_giftcard),
            label: Text(
              saving
                  ? 'Kaydediliyor…'
                  : isEditing
                      ? 'DEĞİŞİKLİKLERİ KAYDET'
                      : 'ÖDÜLÜ YAYINLA',
            ),
          ),
        ],
      ),
    );
  }
}
