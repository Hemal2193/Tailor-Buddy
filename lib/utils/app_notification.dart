import 'package:flutter/material.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class AppNotification {
  /// Call this like:
  /// AppNotification.show(Overlay.of(context), "Message here");
  static void show(OverlayState? overlay, String message) {
    if (overlay == null) return;

    showTopSnackBar(
      overlay,
      _CustomStyledNotification(message),
      animationDuration: const Duration(milliseconds: 350),
      displayDuration: const Duration(seconds: 2),
      dismissType: DismissType.onSwipe,
      dismissDirection: [DismissDirection.horizontal],
    );
  }
}

class _CustomStyledNotification extends StatelessWidget {
  final String message;

  const _CustomStyledNotification(this.message);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(width: 2, color: Colors.blue),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_active_outlined,
              color: Color(0xFF007BFF),
              size: 22,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  color: Color(0xFF007BFF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
