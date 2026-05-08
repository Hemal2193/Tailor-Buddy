import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tailor_mate/config/supabase_config.dart';
import 'package:tailor_mate/database/order_model.dart';
import 'package:tailor_mate/pages/Login_SignUp/signn.dart';
import 'package:tailor_mate/pages/New%20Order/new_order_provider.dart';
import 'package:tailor_mate/pages/OrderDetails/order_details_provider.dart';
import 'package:tailor_mate/pages/homepage.dart';
import 'package:tailor_mate/pages/splash.dart';
import 'package:tailor_mate/utils/notification_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(OrderAdapter());
  await Hive.openBox('orders');
  await Hive.openBox('orderIdBox');
  await Hive.openBox('syncQueue'); // For tracking unsynced orders

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey:
        SupabaseConfig.supabaseKey,
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // 🔒 Lock app orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  NotificationService notificationService = NotificationService();
  await notificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NewOrderProvider()),
        ChangeNotifierProvider(create: (context) => OrderDetailsProvider()),
      ],
      child: const MyApp(),
    ),
  );
  await notificationService.scheduleDailyNotification();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    // final session = Supabase.instance.client.auth.currentSession;
    return MaterialApp(
      // scaffoldMessengerKey: scaffoldMessengerKey,
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
      // initialRoute: session == null ? '/login' : '/home',
      home: Splash(),
      routes: {
        '/login': (context) => const SignInPage(),
        '/home': (context) => const Homepage(),
      },
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:tailor_mate/pages/New%20Order/new_order_provider.dart';
// import 'package:tailor_mate/pages/OrderDetails/order_details_provider.dart';
// import 'package:tailor_mate/pages/splash.dart';
// import 'package:tailor_mate/pages/homepage.dart';
// import 'package:tailor_mate/pages/Login_SignUp/signn.dart';

// final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
//     GlobalKey<ScaffoldMessengerState>();

// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   // UI settings only (safe)
//   SystemChrome.setSystemUIOverlayStyle(
//     const SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: Brightness.light,
//     ),
//   );

//   await SystemChrome.setPreferredOrientations([
//     DeviceOrientation.portraitUp,
//     DeviceOrientation.portraitDown,
//   ]);

//   // NO heavy initialization here

//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (context) => NewOrderProvider()),
//         ChangeNotifierProvider(create: (context) => OrderDetailsProvider()),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       scaffoldMessengerKey: scaffoldMessengerKey,
//       navigatorKey: navigatorKey,
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(useMaterial3: false),
//       builder: (context, child) {
//         return MediaQuery(
//           data: MediaQuery.of(context)
//               .copyWith(textScaler: const TextScaler.linear(1.0)),
//           child: child!,
//         );
//       },
//       home: const Splash(), // now a real async loader
//       routes: {
//         '/home': (context) => const Homepage(),
//         '/login': (context) => const SignInPage(),
//       },
//     );
//   }
// }
