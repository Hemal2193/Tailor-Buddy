import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Stroke {
  final Color color;
  final double width;
  final List<Offset> points;

  Stroke({required this.color, required this.width, required this.points});
}

class WhiteboardPainter extends CustomPainter {
  final List<Stroke> strokes;

  const WhiteboardPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.length > 1) {
        final paint = Paint()
          ..color = stroke.color
          ..strokeWidth = stroke.width
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;

        final path = Path();
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class WhiteboardPage extends StatefulWidget {
  final String orderId;
  const WhiteboardPage({required this.orderId, super.key});

  @override
  State<WhiteboardPage> createState() => _WhiteboardPageState();
}

class _WhiteboardPageState extends State<WhiteboardPage> {
  List<Stroke> strokes = [];
  List<Stroke> redo = [];
  Stroke? currentStroke;

  final Set<int> _activePointers = {}; // track fingers

  double currentWidth = 6.0;
  Color currentColor = Colors.black;

  final Map<String, Color> colorOptions = {
    "Black": Colors.black,
    "Red": Colors.red,
    "Blue": Colors.blue,
    "Green": Colors.green,
    "Yellow": Colors.yellow,
  };

  final List<double> thicknessOptions = [2, 4, 6, 8, 10, 12, 15, 20];

  void _startStroke(Offset p) {
    currentStroke = Stroke(
      color: currentColor,
      width: currentWidth,
      points: [p],
    );
  }

  void _addPoint(Offset p) {
    if (currentStroke != null) {
      setState(() {
        currentStroke!.points.add(p);
      });
    }
  }

  void _endStroke() {
    if (currentStroke != null && currentStroke!.points.length > 1) {
      setState(() {
        strokes.add(currentStroke!);
        redo.clear();
      });
    }
    currentStroke = null;
  }

  void _undo() {
    if (strokes.isNotEmpty) {
      setState(() => redo.add(strokes.removeLast()));
    }
  }

  void _redo() {
    if (redo.isNotEmpty) {
      setState(() => strokes.add(redo.removeLast()));
    }
  }

  void _clear() {
    setState(() {
      strokes.clear();
      redo.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.dark),
    );

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            // ---- TOP BAR ----
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.grey.shade200,
              child: Row(
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<Color>(
                      value: currentColor,
                      items: colorOptions.entries.map((e) {
                        return DropdownMenuItem<Color>(
                          value: e.value,
                          child: Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: e.value,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black26),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(e.key),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (c) => setState(() => currentColor = c!),
                    ),
                  ),

                  const SizedBox(width: 20),

                  DropdownButtonHideUnderline(
                    child: DropdownButton<double>(
                      value: currentWidth,
                      items: thicknessOptions.map((w) {
                        return DropdownMenuItem<double>(
                          value: w,
                          child: Text("${w.toInt()} px"),
                        );
                      }).toList(),
                      onChanged: (w) => setState(() => currentWidth = w!),
                    ),
                  ),

                  const Spacer(),
                  IconButton(icon: const Icon(Icons.undo), onPressed: _undo),
                  IconButton(icon: const Icon(Icons.redo), onPressed: _redo),
                  IconButton(icon: const Icon(Icons.delete), onPressed: _clear),
                ],
              ),
            ),

            // ---- WHITEBOARD ----
            Expanded(
              child: Listener(
                onPointerDown: (event) {
                  _activePointers.add(event.pointer);
                  if (_activePointers.length == 1) {
                    _startStroke(event.localPosition);
                  }
                  setState(() {});
                },

                onPointerMove: (event) {
                  if (_activePointers.length == 1) {
                    _addPoint(event.localPosition);
                  }
                },

                onPointerUp: (event) {
                  _activePointers.remove(event.pointer);
                  if (_activePointers.isEmpty) {
                    _endStroke();
                  }
                  setState(() {});
                },

                child: InteractiveViewer(
                  panEnabled: _activePointers.length >= 2,
                  scaleEnabled: _activePointers.length >= 2,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  minScale: 0.3,
                  maxScale: 5,
                  child: CustomPaint(
                    painter: WhiteboardPainter(
                      strokes: currentStroke == null
                          ? strokes
                          : [...strokes, currentStroke!],
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
