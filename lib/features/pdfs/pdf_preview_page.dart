import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfPreviewPage extends StatefulWidget {
  const PdfPreviewPage({super.key, required this.pdf});

  final File pdf;

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  bool _isReady = false;
  String? _errorMessage;

  Future<void> _sharePdf(BuildContext context) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(widget.pdf.path)],
          text: 'Mira este PDF',
          subject: 'Documento PDF',
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo compartir el PDF.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool exists = widget.pdf.existsSync();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Preview PDF'),
        actions: [
          IconButton(
            tooltip: 'Compartir PDF',
            onPressed: () => _sharePdf(context),
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: !exists
          ? const Center(child: Text('El archivo PDF no existe en esta ruta.'))
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : Stack(
              children: [
                SfPdfViewer.file(
                  widget.pdf,
                  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                    if (mounted) {
                      setState(() {
                        _isReady = true;
                        _errorMessage = null;
                      });
                    }
                  },
                  onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                    if (mounted) {
                      setState(() {
                        _errorMessage =
                            'No se pudo abrir el PDF: ${details.error}';
                      });
                    }
                  },
                ),
                if (!_isReady && _errorMessage == null)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
    );
  }
}
