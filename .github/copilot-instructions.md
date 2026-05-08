# Copilot Instructions for Tailor Mate

## Project Overview
**Tailor Mate** is a Flutter app for managing tailoring business operations. It tracks orders, customers, workers, and payments with hybrid online/offline support via Supabase + Hive.

**Key platforms:** Android, iOS (primary); Web/Windows (secondary)  
**State management:** Provider (ChangeNotifier pattern)  
**Data persistence:** Hive (local SQLite-like), Supabase (PostgreSQL backend)

---

## Architecture Patterns

### State Management: Provider + ChangeNotifier
The app uses **Provider** with `ChangeNotifier` for reactive UI updates. Two main providers:

1. **`NewOrderProvider`** (`lib/pages/New Order/new_order_provider.dart`)
   - Manages creating new orders across a 3-tab form (Details → Items → Notes)
   - Holds controllers for all order fields, calculates totals/payment status
   - Exports payment amount calculations: `totalAmount`, `remainingAmount`, `paymentStatus`
   - Call `provider.saveOrder(context)` to persist to both Hive and Supabase

2. **`OrderDetailsProvider`** (`lib/pages/OrderDetails/order_details_provider.dart`)
   - Manages viewing/editing existing orders
   - Must call `initialize(Order, bool autoEdit)` in `initState` via `WidgetsBinding.instance.addPostFrameCallback`
   - Syncs edited data back to Hive and Supabase

**Provider setup in `main.dart`:**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (context) => NewOrderProvider()),
    ChangeNotifierProvider(create: (context) => OrderDetailsProvider()),
  ],
  child: const MyApp(),
)
```

### Data Model: Order (Hive)
Located in `lib/database/order_model.dart`. Uses Hive code generation (`@HiveType`, `@HiveField`):
- Core fields: `id`, `billNo`, `customerName`, `mobileNumber`, `items` (List<Map>), `notes`
- Payment tracking: `advancePayment`, `paidAmount`, `discount`, `paidMode`, `paidDate`
- Dates: `bookingDate`, `deliveryDate`, `advanceDate`
- Status: `isCompleted` (boolean)

**Generated adapter must be registered in `main.dart`:**
```dart
Hive.registerAdapter(OrderAdapter());
```

### Data Flow: Offline-First with Sync Queue
1. **Local-first:** Orders written to Hive immediately for instant UI feedback
2. **Background sync:** `syncQueue` box tracks unsynced orders; retry logic in `NewOrderProvider.retryUnsyncedOrders()`
3. **Pull sync:** On app startup, if Hive is empty, fetch from Supabase: `OrderDetailsProvider.loadOrSyncOrders()`
4. **Upload:** `saveOrder()` calls `_uploadOrderToSupabase()` in background

**Key Hive boxes in `main.dart`:**
- `'orders'`: All Order objects
- `'orderIdBox'`: Tracks bill number sequences
- `'syncQueue'`: Tracks which orders need Supabase upload

---

## Critical Conventions & Patterns

### Date Formatting
All date inputs use **dd/mm/yy format** (e.g., "25/06/24"). Parse with:
```dart
final parts = dateString.split('/');
DateTime date = DateTime(
  int.parse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]),
  int.parse(parts[1]),
  int.parse(parts[0]),
);
```

### Mobile Number Normalization
Strip `+91` prefix and spaces; store only 10-digit number:
```dart
String number = mobileController.text.trim();
if (number.startsWith('+91')) {
  number = number.replaceFirst(RegExp(r'^\+91[-\s]?'), '');
}
```

### Item Structure
Order items are stored as `List<Map<String, dynamic>>`. Standard keys:
```dart
{
  'itemname': 'Shirt',
  'qty': '3',
  'price': '150.0',
  'worker': 'Ram',
  'labour': '50.0',
  'wdate': '25/06/24',
  'bgitem': 'Buttons',
  'bgqty': '2',
  'bgitemprice': '20.0'
}
```

### Bill Number Uniqueness
Always check for duplicates before saving:
```dart
final exists = Hive.box('orders').values.cast<Order>().any(
  (order) => order.billNo.trim() == enteredBillNo.trim(),
);
```

### Consumer Pattern for UI Updates
Use `Consumer<ProviderName>` to listen to provider changes:
```dart
Consumer<NewOrderProvider>(
  builder: (context, provider, child) => Text(provider.totalAmount.toString()),
)
```

### Disposal of Controllers
Always dispose TextEditingControllers in `dispose()` to prevent memory leaks:
```dart
@override
void dispose() {
  _searchController.dispose();
  super.dispose();
}
```

---

## Key Files by Function

| Directory | Purpose | Key Files |
|-----------|---------|-----------|
| `lib/database/` | Data models | `order_model.dart`, `order_model.g.dart` (generated) |
| `lib/pages/` | Screen logic | `homepage.dart`, `myorders.dart`, `dashboardpage.dart` |
| `lib/pages/New Order/` | Create order flow | `new_order_page.dart`, `new_order_provider.dart`, `items_page.dart` |
| `lib/pages/OrderDetails/` | View/edit order | `order_details.dart`, `order_details_provider.dart` |
| `lib/utils/` | Utilities | `bill_generator.dart` (PDF/image generation), `tmp_file_bill.dart` |
| `lib/widgets/` | Reusable UI | `input_fields.dart`, `order_tile.dart` variants, `image_preview.dart` |

---

## Build & Development Commands

| Task | Command |
|------|---------|
| Clean & rebuild | `flutter clean; flutter pub get` |
| Generate code (Hive, providers) | `flutter pub run build_runner build --delete-conflicting-outputs` |
| Watch mode (live rebuild) | `flutter pub run build_runner watch` |
| Run app | `flutter run` |
| Build release APK | `flutter build apk --release` |
| Build iOS | `flutter build ios --release` |
| Analyze code | `flutter analyze` |

**Note:** Always run `build_runner` after modifying `order_model.dart` to regenerate `order_model.g.dart`.

---

## Permissions & Platform Integration

### Android Permissions (declared in `pubspec.yaml` & AndroidManifest.xml)
- `MANAGE_EXTERNAL_STORAGE`: Bill images saved to DCIM folder
- `READ_CONTACTS`: Import customer numbers from device contacts
- `CAMERA`, `READ_EXTERNAL_STORAGE`: Image picker for order images

**Runtime permission flow:**
```dart
Permission.manageExternalStorage.request().then((status) {
  if (status.isGranted) { /* proceed */ }
});
```

### External Services
- **Supabase (PostgreSQL):** Orders table, auth (Google Sign-In)
- **Google Sign-In:** Authentication in `lib/pages/Login_SignUp/signn.dart`
- **Image generation:** Lottie animations for loading/splash

---

## Common Tasks

### Adding a New Order Field
1. Add field to `Order` model with `@HiveField(nextId)`
2. Run `flutter pub run build_runner build --delete-conflicting-outputs`
3. Add controller to relevant provider (e.g., `NewOrderProvider`)
4. Update `saveOrder()` logic to include new field
5. Add UI input in corresponding page (e.g., `ctmr_details_page.dart`)

### Syncing Order to Supabase
In provider, use:
```dart
final response = await Supabase.instance.client
  .from('orders')
  .insert(order.toMap());
```

### Filtering Orders
Most pages (e.g., `myorders.dart`, `customers_page.dart`) group orders in-memory:
```dart
final Map<String, List<Order>> grouped = {};
for (var order in orders) {
  final key = order.customerName;
  grouped[key] = (grouped[key] ?? [])..add(order);
}
```

---

## Debugging Tips

- **Provider not updating?** Check `notifyListeners()` is called after state changes
- **Hive data persisting?** Verify adapter registered and box opened in `main.dart`
- **Dates parse wrong?** Confirm dd/mm/yy format; log `dateString.split('/')`
- **Network issues?** Check `syncQueue` box for pending uploads; manually retry via `retryUnsyncedOrders()`

---

## Project-Specific Context

This is a **local-first business app** for small tailors. UI patterns prioritize:
- Quick data entry (tabs, controllers pre-populated)
- Offline reliability (Hive cache, retry queues)
- Mobile-first (portrait orientation locked via `SystemChrome.setPreferredOrientations`)
- Privacy (no sensitive data in logs; `use_build_context_synchronously` ignored to avoid false positives)
