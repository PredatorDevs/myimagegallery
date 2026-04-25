import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/services/local_storage_service.dart';
import 'pdf_preview_page.dart';

class PdfsPage extends StatefulWidget {
  const PdfsPage({super.key});

  @override
  State<PdfsPage> createState() => _PdfsPageState();
}

class _PdfsPageState extends State<PdfsPage> {
  final LocalStorageService _storageService = LocalStorageService();
  List<File> _pdfs = <File>[];

  @override
  void initState() {
    super.initState();
    _loadPdfs();
  }

  Future<void> _loadPdfs() async {
    final List<File> pdfs = await _storageService.loadPdfs();
    if (mounted) {
      setState(() {
        _pdfs = pdfs;
      });
    }
  }

  Future<void> _pickPdf() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['pdf'],
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    final File storedFile = await _copyPdfToAppStorage(
      sourcePath: result.files.single.path!,
      originalName: result.files.single.name,
    );

    setState(() {
      _pdfs.add(storedFile);
    });

    await _storageService.savePdfs(_pdfs);
  }

  Future<File> _copyPdfToAppStorage({
    required String sourcePath,
    required String originalName,
  }) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory pdfDir = Directory(
      '${appDir.path}${Platform.pathSeparator}pdfs',
    );

    if (!pdfDir.existsSync()) {
      pdfDir.createSync(recursive: true);
    }

    final String safeName = originalName.trim().isEmpty
        ? 'document.pdf'
        : originalName;
    final String targetPath =
        '${pdfDir.path}${Platform.pathSeparator}${DateTime.now().millisecondsSinceEpoch}_$safeName';

    final File sourceFile = File(sourcePath);
    return sourceFile.copy(targetPath);
  }

  Future<void> _deletePdf(int index) async {
    setState(() {
      _pdfs.removeAt(index);
    });

    await _storageService.savePdfs(_pdfs);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF eliminado'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        title: const Text('Mis PDFs'),
      ),
      body: _pdfs.isEmpty ? _buildEmptyState(context) : _buildPdfList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickPdf,
        icon: const Icon(Icons.picture_as_pdf_rounded),
        label: const Text('Agregar PDF'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.picture_as_pdf_outlined,
              size: 76,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No hay PDFs guardados',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Toca Agregar PDF para seleccionar un archivo',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfList() {
    return ListView.separated(
      itemCount: _pdfs.length,
      padding: const EdgeInsets.all(12),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final File file = _pdfs[index];
        final String fileName = file.path.split(Platform.pathSeparator).last;

        return Card(
          child: ListTile(
            leading: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.red,
            ),
            title: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: const Text('Toca para previsualizar'),
            trailing: IconButton(
              tooltip: 'Eliminar PDF',
              onPressed: () => _showDeleteDialog(index),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PdfPreviewPage(pdf: file)),
              );
            },
          ),
        );
      },
    );
  }

  void _showDeleteDialog(int index) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 32,
          ),
          title: const Text('Eliminar PDF'),
          content: const Text(
            'Esta accion no se puede deshacer.\n\nDeseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                _deletePdf(index);
                Navigator.pop(dialogContext);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}
