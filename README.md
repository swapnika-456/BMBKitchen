# BMB Kitchen — Restaurant POS & Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2.svg)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod_3-purple.svg)](https://riverpod.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows%20%7C%20macOS-green.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

BMB Kitchen is a full-featured, multi-outlet Point of Sale (POS), Kitchen Display System (KDS), Inventory, Supply Chain, and Executive Analytics application built with Flutter. It connects to the BMB Kitchen REST API backend across 25 production modules.

---

## 🍽️ Key Features & Modules

### 1. POS Billing & Order Taking
- **Order Types**: Dine-in (with table assignment), Takeaway, Delivery, and Aggregator Online Orders.
- **KOT Management**: Item-level status lifecycle (`in_queue` ➔ `preparing` ➔ `ready` ➔ `served` ➔ `cancelled`).
- **Flexible Payments**: Cash, Card, UPI, Split payments, and Unpaid balance tracking.
- **Bill Operations**: Real-time CGST/SGST/IGST tax calculation, discount management, bill splitting, and cancellation rules.

### 2. Kitchen Display System (KDS)
- Kanban board view and compact list view.
- 15-second elapsed time ticker and 30-second live background refresh.
- Color-coded tickets with preparation indicators and order item modification tracking.

### 3. Supply Chain & Inventory
- **Real-time Stock**: In-stock levels, minimum stock alerts, and unit normalization (`kg`, `g`, `l`, `ml`, `pcs`, `box`).
- **Stock Adjustments**: Add, remove, and wastage adjustments with categorized audit reasons.
- **Vendors & Purchases**: Vendor directory, purchase orders, payment status tracking (`Paid`, `Partial`, `Unpaid`).
- **Recipe Costing**: Recipe ingredient mapping, yield calculations, and dynamic food cost percentages.

### 4. Financial Controls & Day Closing
- **Day Closing (Z-Report)**: Automated register reconciliation (Opening cash, Cash sales, Card/UPI collections, Pay-outs, Cash in drawer).
- **Audit History**: Historical closing records and supervisor reopen capabilities.
- **Tax Breakdown**: CGST & SGST summary by slab (5%, 12%, 18%, etc.).

### 5. Multi-Outlet & Central Kitchen
- **Multi-Outlet Switching**: Seamless outlet switching with scoped data isolation.
- **Central Kitchen Transfers**: Inter-outlet inventory transfers with multi-stage verification:
  `Requested` ➔ `Dispatched` ➔ `In Transit` ➔ `Received`.

### 6. Executive Dashboard & Reporting
- **Live Summary**: Single-request dashboard summary (`#159`) with 60-second periodic refresh and lifecycle resume reload.
- **Sales Trend Chart**: Proportional hourly and daily sales distribution bars.
- **Financial Reports**: Sales by channel, top selling items, expense tracking, and GST reporting.

### 7. Administration, Hardware & Integrations
- **Role-Based Access Control (RBAC)**: Fine-grained permissions across `owner`, `admin`, `cto`, and `staff`.
- **Thermal Printers**: Kitchen & billing thermal printer configuration via IP, Bluetooth, and USB.
- **Notifications**: In-app notifications inbox with live unread badge counters, multi-channel settings (SMS, Email, Push, WhatsApp).
- **Integrations**: Third-party aggregators and accounting connectors.

---

## 🏗️ Architecture & Tech Stack

```
lib/
├── core/                  # Design tokens, typography, colors, networking (Dio), base widgets
│   ├── network/           # DioClient, ApiResponse, error interceptors, JSON utilities
│   ├── theme/             # Sora typography, AppColors, spacing, radii
│   └── widgets/           # BmbCard, BmbButton, BmbKpiTile, BmbTag, dialogs
├── features/              # Feature modules (Layered architecture)
│   ├── auth/              # Authentication & user profile
│   ├── pos/               # POS ordering, billing, checkout sheets
│   ├── kitchen/           # KOT management & KDS screens
│   ├── tables/            # Table layout & status management
│   ├── menu/              # Menu categories & item catalog
│   ├── supply_chain/      # Inventory, vendors, purchases, recipes, wastage
│   ├── finance/           # Reports, day closing, expenses
│   ├── dashboard/         # Executive dashboard & metrics
│   └── settings/          # Outlets, roles, staff, printers, integrations, support
├── models/                # Typed immutable domain models with json_serializable
├── routing/               # GoRouter configuration with live sidebar badges
└── services/api/          # 25 dedicated API service clients covering endpoints #1 to #178
```

- **State Management**: [Riverpod 3](https://riverpod.dev) (`AsyncNotifier`, `NotifierProvider`, `ref.watch`).
- **Networking**: [Dio](https://pub.dev/packages/dio) with custom interceptors for authentication, JSON normalization, and error handling.
- **Routing**: [GoRouter](https://pub.dev/packages/go_router) with role-guarded routes and drawer navigation.
- **Typography**: [Google Fonts Sora](https://fonts.google.com/specimen/Sora) with strict typographic scale (`h1`, `h2`, `h3`, `bodyStrong`, `bodyMedium`, `caption`).

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.24.0 or newer)
- [Dart SDK](https://dart.dev/get-dart) (v3.5.0 or newer)
- Android Studio / Xcode / VS Code with Flutter extension

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/swapnika-456/BMBKitchen.git
   cd BMBKitchen
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run code generation / analysis**:
   ```bash
   flutter analyze
   ```

4. **Launch the application**:
   ```bash
   # Run on connected device / emulator
   flutter run

   # Run on Chrome
   flutter run -d chrome

   # Run on Windows desktop
   flutter run -d windows
   ```

---

## 🧪 Testing

The codebase includes comprehensive unit, widget, and layout responsiveness tests:

```bash
# Run all unit and widget tests
flutter test

# Run specific module test suites
flutter test test/dashboard_test.dart
flutter test test/report_test.dart
flutter test test/central_kitchen_test.dart
flutter test test/notification_test.dart
flutter test test/support_ticket_test.dart
flutter test test/integration_test.dart
```

### Viewport Responsiveness
All screens and cards are verified to render without layout overflow on:
- **Mobile Portrait**: 360 × 800
- **Mobile Landscape**: 800 × 360
- **Desktop / Tablet**: 1280 × 800
- **Accessibility**: 1.5× system font scaling

---

## 🔒 Security & Live Server Auditing

Live integration checks and verification scripts are organized under `tool/live_checks/`:
- **Credentials Policy**: No hardcoded test credentials or secrets are permitted in the codebase.
- **Audit Runner**: `tool/live_checks/run_audit.py` reads credentials securely from environment variables:
  ```bash
  BMB_TEST_EMAIL="user@bmb.com" BMB_TEST_PASSWORD="password" python tool/live_checks/run_audit.py
  ```
- **Auditing**: Automatically matches server MongoDB `_id` timestamps against HTTP `Date` response headers to verify live backend responses.

---

## 👥 Roles & Access Permissions

| Module / Screen | Owner | Admin | CTO | Staff |
|:---|:---:|:---:|:---:|:---:|
| **POS Billing & Tables** | ✅ | ✅ | ✅ | ✅ |
| **KOT Kitchen Display** | ✅ | ✅ | ✅ | ✅ |
| **Inventory & Stock Adjustments** | ✅ | ✅ | ✅ | Read Only |
| **Day Closing Reconciliation** | ✅ | ✅ | ✅ | Read Only |
| **Financial Reports & Dashboard** | ✅ | ✅ | ✅ | Read Only |
| **Central Kitchen Transfers** | Full | Full | Full | View / Create / Advance |
| **Printer & Tax Settings** | ✅ | ✅ | ✅ | ❌ |
| **Integrations & Notification Settings** | ✅ | ✅ | ✅ | ❌ |
| **User Role Assignment & Hard Deletes** | ✅ (Owner Only) | ❌ | ✅ | ❌ |

---

## 📄 License

Proprietary and confidential. All rights reserved.
