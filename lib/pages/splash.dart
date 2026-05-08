import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tailor_mate/pages/Login_SignUp/signn.dart';
import 'package:tailor_mate/pages/homepage.dart';

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    final double height = MediaQuery.of(context).size.height;

    return AnimatedSplashScreen(
      splash: Center(
        child: Lottie.asset(
          'assets/splash.json',
          fit: BoxFit.fitHeight,
          frameRate: FrameRate.max,
          repeat: false,
        ),
      ), // or your splash widget/image
      nextScreen: session == null ? const SignInPage() : const Homepage(),
      backgroundColor: Colors.blue,
      splashIconSize: height,
      duration: 1000,
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:lottie/lottie.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:tailor_mate/database/order_model.dart';
// import 'package:tailor_mate/pages/Login_SignUp/signn.dart';
// import 'package:tailor_mate/pages/homepage.dart';
// import 'package:tailor_mate/utils/notification_service.dart';
// import 'package:timezone/data/latest.dart' as tz;

// class Splash extends StatefulWidget {
//   const Splash({super.key});

//   @override
//   State<Splash> createState() => _SplashState();
// }

// class _SplashState extends State<Splash> {
//   @override
//   void initState() {
//     super.initState();
//     initializeApp();
//   }

//   Future<void> initializeApp() async {
//     try {
//       // --- Hive ---
//       await Hive.initFlutter();
//       Hive.registerAdapter(OrderAdapter());
//       await Hive.openBox('orders');
//       await Hive.openBox('orderIdBox');
//       await Hive.openBox('syncQueue');

//       // --- Supabase ---
//       await Supabase.initialize(
//         url: 'https://jkmvkfjvpzgcayhshxib.supabase.co',
//         anonKey:
//             'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImprbXZrZmp2cHpnY2F5aHNoeGliIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2ODE2OTksImV4cCI6MjA2ODI1NzY5OX0.fQcP6cmov1iCO4oCjBVhVXy7l91updUZRmzAFwi2gWE',
//       );

//       // --- Notifications ---
//       tz.initializeTimeZones();
//       NotificationService notificationService = NotificationService();
//       await notificationService.initialize();
//       await notificationService.scheduleDailyNotification();

//       // --- Routing ---
//       final session = Supabase.instance.client.auth.currentSession;

//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//             builder: (_) => session == null
//                 ? const SignInPage()
//                 : const Homepage()),
//       );
//     } catch (e) {
//       debugPrint("Initialization error: $e");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final height = MediaQuery.of(context).size.height;

//     return Scaffold(
//       backgroundColor: Colors.blue,
//       body: Center(
//         child: Lottie.asset(
//           'assets/splash.json',
//           height: height * 0.6,
//           fit: BoxFit.contain,
//           repeat: false,
//         ),
//       ),
//     );
//   }
// }
