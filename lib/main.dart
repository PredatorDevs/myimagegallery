import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Image Gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: AppBarTheme(elevation: 0, centerTitle: true),
      ),
      home: const GalleryPage(title: 'Mi Galería de Imágenes'),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key, required this.title});

  final String title;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<File> images = [];
  final ImagePicker picker = ImagePicker();
  late SharedPreferences prefs;
  static const String _imagesKey = 'saved_images';

  @override
  void initState() {
    super.initState();
    _initializePreferences();
  }

  Future<void> _initializePreferences() async {
    prefs = await SharedPreferences.getInstance();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final List<String>? savedPaths = prefs.getStringList(_imagesKey);
    if (savedPaths != null) {
      setState(() {
        images = savedPaths.map((path) => File(path)).toList();
      });
    }
  }

  Future<void> _saveImages() async {
    final List<String> paths = images.map((file) => file.path).toList();
    await prefs.setStringList(_imagesKey, paths);
  }

  Future<void> pickImage() async {
    final XFile? pickFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickFile != null) {
      setState(() {
        images.add(File(pickFile.path));
      });
      await _saveImages();
    }
  }

  Future<void> _deleteImage(int index) async {
    setState(() {
      images.removeAt(index);
    });
    await _saveImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 28),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      body: images.isEmpty
          ? _buildEmptyState(context)
          : _buildGalleryGrid(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => pickImage(),
        icon: Icon(Icons.add_photo_alternate_rounded),
        label: Text('Agregar'),
        tooltip: 'Agregar foto de la galería',
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Icon(
              Icons.image_not_supported_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No hay imágenes aún',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'Toca el botón "+" para agregar fotos\na tu galería',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(12),
      itemCount: images.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        return _buildGalleryItem(context, index);
      },
    );
  }

  Widget _buildGalleryItem(BuildContext context, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailPage(image: images[index])),
        );
      },
      onLongPress: () {
        _showDeleteDialog(index);
      },
      child: Hero(
        tag: 'image_$index',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Image.file(images[index], fit: BoxFit.cover),
                // Overlay para mejor UX
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
        title: const Text('Eliminar imagen'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta imagen?\n\nEsta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _deleteImage(index);
              Navigator.pop(context);
              _showDeleteSuccessSnackBar();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('Imagen eliminada'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final File image;

  const DetailPage({required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.image_rounded, size: 28, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Vista Previa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.black87,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Hero(
              tag: 'image_detail',
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.file(image, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              bottom: 24,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
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
