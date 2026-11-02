import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

/// シェアカード：写真とひとことを、AniMatch のロゴ入りの画像にして、SNSなどに出せる。
/// 自分の投稿（ペット自慢・団体の里親募集やお知らせ）だけに出す。
class ShareCard {
  static Future<void> open(
    BuildContext context, {
    required String imageUrl,
    required String title,
    String subtitle = '',
    String label = '',
    String footer = '',
    Color color = const Color(0xFFE8845A),
  }) {
    return showDialog(
      context: context,
      builder: (_) => _ShareCardDialog(
        imageUrl: imageUrl,
        title: title,
        subtitle: subtitle,
        label: label,
        footer: footer,
        color: color,
      ),
    );
  }
}

class _ShareCardDialog extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String label;
  final String footer;
  final Color color;
  const _ShareCardDialog({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.footer,
    required this.color,
  });

  @override
  State<_ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends State<_ShareCardDialog> {
  final _cardKey = GlobalKey();
  final _buttonKey = GlobalKey();
  bool _busy = false;
  bool _imageReady = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('no boundary');
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('no bytes');
      // iPad では、シェアの画面を出す位置が必要
      final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
      final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(bytes.buffer.asUint8List(), mimeType: 'image/png', name: 'animatch.png')],
        fileNameOverrides: const ['animatch.png'],
        text: '#AniMatch',
        sharePositionOrigin: origin,
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('シェアカードのエラー: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('画像を作れませんでした。写真が読みこまれてから、もう一度ためしてください')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('画像にしてシェア',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
            const SizedBox(height: 4),
            Text('この画像が、そのままSNSなどに出ます',
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            const SizedBox(height: 12),
            RepaintBoundary(
              key: _cardKey,
              child: _CardFace(
                imageUrl: widget.imageUrl,
                title: widget.title,
                subtitle: widget.subtitle,
                label: widget.label,
                footer: widget.footer,
                color: widget.color,
                onImageReady: () {
                  if (!_imageReady && mounted) setState(() => _imageReady = true);
                },
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('やめる'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    key: _buttonKey,
                    onPressed: _busy || !_imageReady ? null : _share,
                    icon: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.ios_share_rounded, size: 18),
                    label: Text(_imageReady ? 'シェアする' : '写真を読みこみ中…'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

class _CardFace extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String label;
  final String footer;
  final Color color;
  final VoidCallback onImageReady;
  const _CardFace({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.label,
    required this.footer,
    required this.color,
    required this.onImageReady,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F5),
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  frameBuilder: (context, child, frame, sync) {
                    if (frame != null || sync) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => onImageReady());
                    }
                    return child;
                  },
                  errorBuilder: (_, __, ___) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => onImageReady());
                    return Container(
                      color: color.withOpacity(0.15),
                      child: const Center(child: Text('🐾', style: TextStyle(fontSize: 60))),
                    );
                  },
                ),
              ),
              if (label.isNotEmpty)
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
                    child: Text(label,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF3D2B1F))),
          ),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(subtitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, height: 1.5, color: Colors.grey[800])),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(footer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.4))),
                  child: Text('🐾 AniMatch',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: color)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
