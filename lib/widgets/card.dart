// import 'package:flutter/material.dart';

// class CustomCard extends StatelessWidget {
//   final String cardTitle;
//   final String cardValue;
//   final Color cardColor;
//   const CustomCard({
//     super.key,
//     required this.cardTitle,
//     required this.cardValue,
//     required this.cardColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: cardColor,
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.shade300,
//             spreadRadius: 2,
//             blurRadius: 5,
//             offset: Offset(0, 3), // changes position of shadow
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(10),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               cardTitle,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             SizedBox(height: 5),
//             Text(
//               cardValue,
//               style: TextStyle(
//                 fontSize: 26,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';

class CustomCard extends StatefulWidget {
  final String cardTitle;
  final String cardValue;
  final Color cardColor;

  const CustomCard({
    super.key,
    required this.cardTitle,
    required this.cardValue,
    required this.cardColor,
  });

  @override
  State<CustomCard> createState() => _CustomCardState();
}

class _CustomCardState extends State<CustomCard> with TickerProviderStateMixin {
  late String
  _currentValue; // currently visible value (old until animation finishes)
  String? _incomingValue; // new value that will slide in
  late final AnimationController _ctrl;
  late final Animation<Offset> _oldOffset;
  late final Animation<double> _oldOpacity;
  late final Animation<Offset> _newOffset;
  late final Animation<double> _newOpacity;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.cardValue;
    _incomingValue = null;

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Old value: slide up and fade out during the first half
    _oldOffset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1))
        .animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
          ),
        );
    _oldOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    // New value: start invisible below and appear during the second half
    _newOffset = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
          ),
        );
    _newOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    // When the full animation finishes, commit the new value as current
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && _incomingValue != null) {
        setState(() {
          _currentValue = _incomingValue!;
          _incomingValue = null;
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant CustomCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cardValue != widget.cardValue) {
      // start a fresh transition: old -> disappear, then new -> appear
      _incomingValue = widget.cardValue;
      _ctrl.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    );

    return Container(
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade600,
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.cardTitle,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            // Sized box locks the height so the sliding text doesn't change layout
            SizedBox(
              height: 34,
              child: ClipRect(
                // ClipRect prevents text from drawing outside the boxed area during the slide.
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Old (currently visible) value - animated when incomingValue != null
                    if (_incomingValue !=
                        null) // animate only when a transition is happening
                      SlideTransition(
                        position: _oldOffset,
                        child: FadeTransition(
                          opacity: _oldOpacity,
                          child: Text(_currentValue, style: textStyle),
                        ),
                      )
                    else
                      // No transition -> show current plainly
                      Text(_currentValue, style: textStyle),

                    // New incoming value (only present while animating)
                    if (_incomingValue != null)
                      SlideTransition(
                        position: _newOffset,
                        child: FadeTransition(
                          opacity: _newOpacity,
                          child: Text(_incomingValue!, style: textStyle),
                        ),
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
