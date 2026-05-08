import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tailor_mate/widgets/image_preview.dart';

class NotesDetails extends StatefulWidget {
  final String orderId; // Pass orderId to identify folder
  const NotesDetails({super.key, required this.orderId});

  @override
  State<NotesDetails> createState() => _NotesDetailsState();
}

class _NotesDetailsState extends State<NotesDetails> {
  List<File> photos = [];

  @override
  void initState() {
    super.initState();
    loadPhotos();
  }

  // Future<String> get orderFolderPath async {
  //   final dir = await getApplicationDocumentsDirectory();
  //   final path = '${dir.path}/order_photos/${widget.orderId}';
  //   await Directory(path).create(recursive: true);
  //   return path;
  // }

  Future<void> loadPhotos() async {
    final folderPath =
        '/storage/emulated/0/DCIM/AartiBeautique/${widget.orderId}';
    final dir = Directory(folderPath);
    if (await dir.exists()) {
      final files = dir
          .listSync()
          .where((f) => f.path.endsWith('.jpg') || f.path.endsWith('.png'))
          .map((f) => File(f.path))
          .toList();

      // 📁 Sort by number
      files.sort((a, b) {
        int aNum =
            int.tryParse(
              RegExp(r'(\d+)\.jpg').firstMatch(a.path)?.group(1) ?? '0',
            ) ??
            0;
        int bNum =
            int.tryParse(
              RegExp(r'(\d+)\.jpg').firstMatch(b.path)?.group(1) ?? '0',
            ) ??
            0;
        return aNum.compareTo(bNum);
      });

      setState(() {
        photos = files;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final hasPermission = await _ensurePermission(source);
    if (!hasPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Camera permission denied'
                : 'Storage permission denied',
          ),
        ),
      );
      return;
    }

    final pickedImage = await ImagePicker().pickImage(
      source: source,
    );
    if (pickedImage == null) return;

    final folderPath =
        '/storage/emulated/0/DCIM/AartiBeautique/${widget.orderId}';
    final folder = Directory(folderPath);
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    // 🔢 Get next number
    final existingFiles = folder
        .listSync()
        .where((f) => f.path.endsWith('.jpg'))
        .map(
          (f) => int.tryParse(
            RegExp(r'(\d+)\.jpg').firstMatch(f.path)?.group(1) ?? '0',
          ),
        )
        .whereType<int>()
        .toList();

    final nextNumber = (existingFiles.isEmpty
        ? 1
        : (existingFiles.reduce((a, b) => a > b ? a : b) + 1));
    final fileName = '$nextNumber.jpg';

    final savedImage = await File(
      pickedImage.path,
    ).copy('$folderPath/$fileName');

    setState(() {
      photos.add(savedImage);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalTiles = photos.length + 1;

    return Scaffold(
      body: GridView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: totalTiles,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // 3 tiles per row
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1, // square
        ),
        itemBuilder: (context, index) {
          if (index == 0) {
            return GestureDetector(
              onTap: _showImageSourceOptions,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, size: 40),
              ),
            );
          }

          final photo = photos[index - 1];
          return Stack(
            alignment: Alignment.topRight,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ImagePreviewPage(
                        images: photos,
                        initialIndex: index - 1,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: double.maxFinite,
                    width: double.maxFinite,
                    child: Image.file(photo, fit: BoxFit.cover),
                  ),
                ),
              ),
              InkWell(
                onTap: () async {
                  final fileToDelete = photos[index - 1];

                  if (await fileToDelete.exists()) {
                    try {
                      await fileToDelete.delete();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error deleting image: $e')),
                      );
                    }
                  }

                  setState(() {
                    photos.removeAt(index - 1);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 15,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showImageSourceOptions() async {
    await showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _ensurePermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      return status.isGranted;
    }

    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) return true;
    }

    final photosStatus = await Permission.photos.request();
    return photosStatus.isGranted;
  }
}
