# Tailor Buddy ✂️

Tailor Buddy is a modern **Flutter-based tailor shop order management system** designed to handle the complete tailoring workflow — from creating customer orders to bill generation, worker tracking, customer history, offline syncing, and delivery management.

Built with an **offline-first architecture**, the app stores data locally using Hive and automatically syncs with Supabase whenever internet connectivity is available.

---

<img width="1188" height="648" alt="TB readme1" src="https://github.com/user-attachments/assets/007ab8e6-6a8c-4a24-a140-8c0338d66571" />

<img width="1980" height="1080" alt="TB readme2" src="https://github.com/user-attachments/assets/01a57aa5-5482-4705-b669-b111d0529406" />

---

## ✨ Features

### 📦 Order Management
- Create, edit, delete, and track tailoring orders
- Manage pending and completed orders
- Smart payment status tracking:
  - Paid
  - Partial
  - Unpaid
- Search orders by:
  - Bill number
  - Customer name
  - Mobile number
- Swipe actions for quick bill preview and deletion

---

### 🧾 Bill Generation
- Generate professional bill images
- QR-based UPI payment support
- WhatsApp bill sharing
- Bills are automatically saved to device storage
- Pull-to-refresh bill preview screen

---

### 📊 Dashboard & Analytics
- Completed and pending order statistics
- Total income and profit overview
- Advance payment tracking
- Cash vs online payment analytics
- Customer count and delivery tracking
- Date filters:
  - Today
  - This Week
  - This Month
  - Custom Range

---

### 👥 Customer Management
- Customer history grouped by mobile number
- View all previous orders
- Search customers instantly
- Pending/completed status badges
- Direct call and save-to-contacts shortcuts

---

### 👷 Worker Management
- Worker-wise labour analytics
- Total items handled
- Labour earnings summary
- Item breakdown per worker
- Workday tracking

---

### 📝 Advanced Order Notes
- Attach photos using:
  - Camera
  - Gallery
- Fullscreen image preview with zoom support
- Built-in whiteboard for tailoring sketches and design notes
- Finger/stylus drawing support with:
  - Undo / Redo
  - Color picker
  - Pen thickness controls
  - Zoom & pan

---

### ☁️ Offline First Sync
- Orders are stored locally using Hive
- Automatic Supabase syncing
- Sync retry queue for failed uploads
- Reliable performance even with poor connectivity

---

### 🔐 Authentication & Device Control
- Google Sign-In with Supabase Auth
- Device whitelist verification
- Unauthorized devices are blocked until approved
- Secure shop-owner focused access control

---

### 🔔 Notifications
- Daily reminder notifications
- Exact alarm support on Android
- Styled in-app success notifications

---

## 🛠 Tech Stack

- Flutter
- Hive
- Supabase
- Provider
- Google Sign-In
- Local Notifications
- Lottie Animations

---

## 📱 Main Sections

- Dashboard
- My Orders
- Customers
- Workers
- New Order Workflow
- Bill Viewer
- Whiteboard Notes

---

## 🚀 Getting Started

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/your-username/tailor_Buddy.git
```

### 2️⃣ Install Dependencies

```bash
flutter pub get
```

### 3️⃣ Run the App

```bash
flutter run
```

---

## 📂 Storage

The app stores:
- Order photos
- Generated bills
- Whiteboard sketches

inside the device storage for offline access and sharing.

---

## 🎨 UI Highlights

- Status-driven color system
- Animated dashboard cards
- Clean order tiles
- Responsive layouts
- Smooth Flutter animations
- Material 3 inspired UI

---

## 📌 Note

This project uses Supabase for authentication and cloud syncing.

Before running the project, make sure to add **your own Supabase Project URL and Anon Key** inside the configuration files.
