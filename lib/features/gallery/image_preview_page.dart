import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ImagePreviewPage extends StatelessWidget {
  const ImagePreviewPage({
    super.key,
    required this.image,
    required this.heroTag,
  });

  final File image;
  final String heroTag;

  Future<void> _shareImage(BuildContext context) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(image.path)],
          text: 'Mira esta imagen de mi galeria',
          subject: 'Imagen compartida',
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo compartir la imagen.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Vista Previa'),
        actions: [
          IconButton(
            tooltip: 'Compartir imagen',
            onPressed: () => _shareImage(context),
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: Container(
        color: Colors.black87,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Hero(
              tag: heroTag,
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.file(image, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              bottom: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pinch_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Pellizca para zoom',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
