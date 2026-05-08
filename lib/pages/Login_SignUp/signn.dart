// // ignore_for_file: use_build_context_synchronously

// import 'package:flutter/material.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'package:lottie/lottie.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:tailor_mate/pages/OrderDetails/order_details_provider.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'dart:io';

// class SignInPage extends StatefulWidget {
//   const SignInPage({super.key});

//   @override
//   State<SignInPage> createState() => _SignInPageState();
// }

// class _SignInPageState extends State<SignInPage> {
//   final supabase = Supabase.instance.client;

//   Future<void> _googleSignIn() async {
//     const webClientId =
//         '784537940006-o3euo95gkjlq2ihokkrr6hhj5rkhv1td.apps.googleusercontent.com';

//     final GoogleSignIn googleSignIn = GoogleSignIn(
//       scopes: ['email', 'openid', 'profile'],
//       serverClientId: webClientId,
//     );

//     try {
//       await googleSignIn.signOut(); // Ensure account picker shows
//       final googleUser = await googleSignIn.signIn();
//       if (googleUser == null) return;

//       final googleAuth = await googleUser.authentication;
//       final accessToken = googleAuth.accessToken;
//       final idToken = googleAuth.idToken;

//       if (accessToken == null || idToken == null) {
//         throw 'Missing Google auth tokens';
//       }

//       final response = await supabase.auth.signInWithIdToken(
//         provider: OAuthProvider.google,
//         idToken: idToken,
//         accessToken: accessToken,
//       );

//       if (response.user != null) {
//         final deviceId = await getDeviceId();
//         final userEmail = response.user!.email;

//         final result = await supabase
//             .from('allowed_devices')
//             .select()
//             .eq('email', userEmail.toString())
//             .eq('device_id', deviceId)
//             .maybeSingle();

//         if (result == null) {
//           // ❌ Not allowed — insert into pending_devices
//           await supabase.from('pending_devices').upsert({
//             'email': userEmail,
//             'device_id': deviceId,
//             // 'requested_at': DateTime.now().toIso8601String(), // optional timestamp field
//           });

//           await supabase.auth.signOut();
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text(
//                 '⏳ Your access request has been sent for approval.',
//               ),
//             ),
//           );
//           return;
//         }

//         // ✅ Device is allowed
//         await OrderDetailsProvider().loadOrSyncOrders();
//         Navigator.pushReplacementNamed(context, '/home');
//       } else {
//         throw 'Google sign-in failed: No user returned';
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('❌ Google sign-in failed: $e')));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.spaceAround,
//               children: [
//                 SizedBox(height: 20),
//                 SizedBox(
//                   height: 500,
//                   child: Stack(
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.only(top: 100.0),
//                         child: SizedBox(
//                           height: 350,
//                           child: Lottie.asset(
//                             'assets/sewing_machine.json',
//                             fit: BoxFit.cover,
//                           ),
//                         ),
//                       ),
//                       Align(
//                         alignment: Alignment.topCenter,
//                         child: Text(
//                           'Tailor Mate',
//                           style: TextStyle(
//                             fontSize: 40,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.only(top: 50.0),
//                         child: Text(
//                           'An Order management tool to help you manage your orders effectively.',
//                           style: TextStyle(fontSize: 20),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),

//                       // SizedBox(height: 20),
//                       Align(
//                         alignment: Alignment.bottomCenter,
//                         child: Padding(
//                           padding: const EdgeInsets.only(bottom: 20.0),
//                           child: InkWell(
//                             onTap: _googleSignIn,
//                             child: Container(
//                               width: double.maxFinite,
//                               decoration: BoxDecoration(
//                                 borderRadius: BorderRadius.circular(7),
//                                 color: Colors.blue,
//                               ),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(12),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Text(
//                                       'Continue with Google',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                       textAlign: TextAlign.center,
//                                     ),
//                                     Icon(
//                                       Icons.g_mobiledata_outlined,
//                                       size: 30,
//                                       color: Colors.white,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 Align(
//                   alignment: Alignment.bottomCenter,
//                   child: Text('Only registered shop owners can sign in.'),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// Future<String> getDeviceId() async {
//   final deviceInfo = DeviceInfoPlugin();

//   if (Platform.isAndroid) {
//     final androidInfo = await deviceInfo.androidInfo;
//     return androidInfo.id;
//   } else if (Platform.isIOS) {
//     final iosInfo = await deviceInfo.iosInfo;
//     return iosInfo.identifierForVendor ?? 'unknown_ios';
//   } else {
//     return 'unsupported_platform';
//   }
// }
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tailor_mate/pages/OrderDetails/order_details_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  late final AnimationController _controller;
  late final Animation<double> _fadeInAnimation;
  late final Animation<Offset> _slideTitleAnimation;
  late final Animation<Offset> _slideSubtitleAnimation;
  late final Animation<double> _scaleLottieAnimation;
  late final Animation<double> _fadeFooterAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Fade-in for whole content
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Slide from top for title
    _slideTitleAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
          ),
        );

    // Slide subtitle slightly delayed
    _slideSubtitleAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
          ),
        );

    // Scale animation for Lottie (gentle bounce)
    _scaleLottieAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Fade footer text in last
    _fadeFooterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.85, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _googleSignIn() async {
    const webClientId =
        '784537940006-o3euo95gkjlq2ihokkrr6hhj5rkhv1td.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'openid', 'profile'],
      serverClientId: webClientId,
    );

    try {
      await googleSignIn.signOut(); // Ensure account picker shows
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'Missing Google auth tokens';
      }

      // ignore: experimental_member_use
      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        final deviceId = await getDeviceId();
        final userEmail = response.user!.email;

        final result = await supabase
            .from('allowed_devices')
            .select()
            .eq('email', userEmail.toString())
            .eq('device_id', deviceId)
            .maybeSingle();

        if (result == null) {
          // ❌ Not allowed — insert into pending_devices
          await supabase.from('pending_devices').upsert({
            'email': userEmail,
            'device_id': deviceId,
          });

          await supabase.auth.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⏳ Your access request has been sent for approval.',
              ),
            ),
          );
          return;
        }

        // ✅ Device is allowed
        await OrderDetailsProvider().loadOrSyncOrders();
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        throw 'Google sign-in failed: No user returned';
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Google sign-in failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeInAnimation,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 500,
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 100.0),
                          child: ScaleTransition(
                            scale: _scaleLottieAnimation,
                            child: SizedBox(
                              height: 350,
                              child: Lottie.asset(
                                'assets/sewing_machine.json',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.topCenter,
                          child: SlideTransition(
                            position: _slideTitleAnimation,
                            child: const Text(
                              'Tailor Buddy',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 50.0),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SlideTransition(
                              position: _slideSubtitleAnimation,
                              child: const Text(
                                'An Order management tool to help you manage your orders effectively.',
                                style: TextStyle(fontSize: 20),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(7),
                              splashColor: Colors.lightBlueAccent.withOpacity(
                                0.5,
                              ),
                              onTap: _googleSignIn,
                              child: Container(
                                width: double.maxFinite,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  color: Colors.blue,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.6),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Continue with Google',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.g_mobiledata_outlined,
                                        size: 30,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FadeTransition(
                    opacity: _fadeFooterAnimation,
                    child: const Align(
                      alignment: Alignment.bottomCenter,
                      child: Text('Only registered shop owners can sign in.'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<String> getDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id;
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor ?? 'unknown_ios';
  } else {
    return 'unsupported_platform';
  }
}
