import 'dart:io';
import 'package:flutter/material.dart';

class ImagePreviewPage extends StatefulWidget {
  final List<File> images;
  final int initialIndex;

  const ImagePreviewPage({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ImagePreviewPage> createState() => _ImagePreviewPageState();
}

class _ImagePreviewPageState extends State<ImagePreviewPage>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;

  final List<TransformationController> _controllers = [];
  final List<AnimationController> _animationControllers = [];
  final List<Animation<Matrix4>> _animations = [];

  final double _zoomScale = 3.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    for (int i = 0; i < widget.images.length; i++) {
      _controllers.add(TransformationController());

      final animationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );

      animationController.addListener(() {
        _controllers[i].value = _animations[i].value;
      });

      _animationControllers.add(animationController);
      _animations.add(
        Matrix4Tween(
          begin: Matrix4.identity(),
          end: Matrix4.identity(),
        ).animate(animationController),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var ac in _animationControllers) {
      ac.dispose();
    }
    super.dispose();
  }

  void _handleDoubleTap(int index, TapDownDetails details) {
    final controller = _controllers[index];
    final animationController = _animationControllers[index];

    final position = details.localPosition;

    final currentMatrix = controller.value;
    // ignore: unused_local_variable
    final targetMatrix = Matrix4.identity();

    if (currentMatrix != Matrix4.identity()) {
      _animations[index] = Matrix4Tween(
        begin: currentMatrix,
        end: Matrix4.identity(),
      ).animate(animationController);
    } else {
      final zoomed = Matrix4.identity()
        ..translate(
          -position.dx * (_zoomScale - 1),
          -position.dy * (_zoomScale - 1),
        )
        ..scale(_zoomScale);

      _animations[index] = Matrix4Tween(
        begin: currentMatrix,
        end: zoomed,
      ).animate(animationController);
    }

    animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text("Image ${_currentIndex + 1} / ${widget.images.length}"),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return GestureDetector(
            onDoubleTapDown: (details) => _handleDoubleTap(index, details),
            child: InteractiveViewer(
              transformationController: _controllers[index],
              panEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.file(widget.images[index]),
            ),
          );
        },
      ),
    );
  }
}
