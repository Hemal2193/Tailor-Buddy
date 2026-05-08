import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tailor_mate/pages/dashboardpage.dart';
import 'package:tailor_mate/pages/myorders.dart';
import 'package:tailor_mate/pages/New%20Order/new_order_page.dart';
import 'package:tailor_mate/pages/New%20Order/new_order_provider.dart';
import 'package:tailor_mate/pages/worker_page.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    DashBoardPage(),
    MyOrders(),
    WorkerManagementPage(),
    NewOrderPage(),
  ];

  @override
  void initState() {
    super.initState();
    _askForStoragePermission();
    // Retry syncing any unsynced orders in background
    NewOrderProvider.retryUnsyncedOrders();
  }

  // -------------------- 🧩 STORAGE PERMISSION POPUP --------------------
  Future<void> _askForStoragePermission() async {
    final status = await Permission.manageExternalStorage.status;
    if (status.isGranted) return;

    await Future.delayed(const Duration(milliseconds: 400)); // wait till build

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: const [
            Icon(Icons.sd_storage_rounded, color: Colors.blue),
            SizedBox(width: 10),
            Text('Storage Permission'),
          ],
        ),
        content: const Text(
          'We need storage access to save your bill images in the DCIM folder.\n\n'
          'Please allow access to all files so the app can store images properly.',
          style: TextStyle(fontSize: 15, height: 1.3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final newStatus = await Permission.manageExternalStorage
                  .request();

              if (newStatus.isGranted) {
                debugPrint('✅ Full storage permission granted');
              } else if (newStatus.isPermanentlyDenied) {
                if (!mounted) return;
                await showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Permission Required'),
                    content: const Text(
                      'Storage permission is permanently denied.\nPlease enable it from settings.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await openAppSettings();
                        },
                        child: const Text('Open Settings'),
                      ),
                    ],
                  ),
                );
              }
            },
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  // -------------------- 🧩 BOTTOM NAVIGATION --------------------
  void _onItemTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        elevation: 20,
        currentIndex: _currentIndex,

        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list_rounded),
            label: 'My Orders',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.man_2), label: 'Workers'),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add_alt_1_rounded),
            label: 'New Order',
          ),
        ],
      ),
      body: _pages[_currentIndex],
    );
  }
}
