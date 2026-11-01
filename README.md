# BMB Kitchen — Restaurant POS & Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2.svg)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod_3-purple.svg)](https://riverpod.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows%20%7C%20macOS-green.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

BMB Kitchen is an enterprise-grade, multi-outlet Point of Sale (POS), Kitchen Display System (KDS), Inventory & Supply Chain, and Executive Analytics application built with Flutter. It connects to the BMB Kitchen REST API backend across 25 production modules and 187+ endpoints.

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

## 📡 Backend API Coverage (25 Service Modules)

All endpoints conform to the BMB Kitchen Backend API specification. Implemented across 25 client services in `lib/services/api/`:

| # | Module / Domain | API Service File | Endpoints Covered | Role Permissions |
|:---:|:---|:---|:---:|:---:|
| 1 | **Authentication** | [`auth_api_service.dart`](file:///lib/services/api/auth_api_service.dart) | `#1`–`#7` | Public / All |
| 2 | **Organization** | [`organization_api_service.dart`](file:///lib/services/api/organization_api_service.dart) | `#8`–`#11` | Owner / Admin |
| 3 | **Outlets** | [`outlet_api_service.dart`](file:///lib/services/api/outlet_api_service.dart) | `#12`–`#16` | Owner / Admin |
| 4 | **Roles & Permissions** | [`role_api_service.dart`](file:///lib/services/api/role_api_service.dart) | `#17`–`#21` | Owner / CTO |
| 5 | **Menu Categories** | [`menu_category_api_service.dart`](file:///lib/services/api/menu_category_api_service.dart) | `#22`–`#27` | All Roles |
| 6 | **Menu Items** | [`menu_item_api_service.dart`](file:///lib/services/api/menu_item_api_service.dart) | `#28`–`#32` | All Roles |
| 7 | **Table Management** | [`table_api_service.dart`](file:///lib/services/api/table_api_service.dart) | `#33`–`#43` | All Roles |
| 8 | **Order Taking & POS** | [`order_api_service.dart`](file:///lib/services/api/order_api_service.dart) | `#44`–`#57` | All Roles |
| 9 | **Payments & Billing** | [`payment_api_service.dart`](file:///lib/services/api/payment_api_service.dart) | `#58`–`#65` | All Roles |
| 10 | **Inventory Catalog** | [`inventory_api_service.dart`](file:///lib/services/api/inventory_api_service.dart) | `#66`–`#72` | All (Staff Read-Only) |
| 11 | **Vendors** | [`vendor_api_service.dart`](file:///lib/services/api/vendor_api_service.dart) | `#73`–`#80` | Owner / Admin |
| 12 | **Purchases** | [`purchase_api_service.dart`](file:///lib/services/api/purchase_api_service.dart) | `#81`–`#87` | Owner / Admin |
| 13 | **Recipe & Costing** | [`recipe_cost_api_service.dart`](file:///lib/services/api/recipe_cost_api_service.dart) | `#88`–`#94` | Owner / Admin / CTO |
| 14 | **Wastage & Adjustments** | [`wastage_adjustment_api_service.dart`](file:///lib/services/api/wastage_adjustment_api_service.dart) | `#95`–`#104` | All (Staff Read-Only) |
| 15 | **Central Kitchen** | [`central_kitchen_api_service.dart`](file:///lib/services/api/central_kitchen_api_service.dart) | `#105`–`#115` | All Roles |
| 16 | **Day Closing (Z-Report)**| [`day_closing_api_service.dart`](file:///lib/services/api/day_closing_api_service.dart) | `#116`–`#124` | All Roles |
| 17 | **Financial Reports** | [`report_api_service.dart`](file:///lib/services/api/report_api_service.dart) | `#125`–`#135` | Owner / Admin |
| 18 | **Executive Dashboard** | [`dashboard_api_service.dart`](file:///lib/services/api/dashboard_api_service.dart) | `#159`–`#165` | All Roles |
| 19 | **Hardware Printers** | [`printer_api_service.dart`](file:///lib/services/api/printer_api_service.dart) | `#136`–`#143` | Owner / Admin |
| 20 | **Tax Settings** | [`tax_settings_api_service.dart`](file:///lib/services/api/tax_settings_api_service.dart) | `#144`–`#148` | Owner / Admin |
| 21 | **Notifications Inbox** | [`notification_api_service.dart`](file:///lib/services/api/notification_api_service.dart) | `#149`–`#153` | All Roles |
| 22 | **Notification Config** | [`notification_settings_api_service.dart`](file:///lib/services/api/notification_settings_api_service.dart) | `#154`–`#158` | Owner / Admin |
| 23 | **Integrations** | [`integration_api_service.dart`](file:///lib/services/api/integration_api_service.dart) | `#166`–`#170` | Owner / Admin |
| 24 | **Support Tickets** | [`support_ticket_api_service.dart`](file:///lib/services/api/support_ticket_api_service.dart) | `#171`–`#174` | All Roles |
| 25 | **Subscription** | [`subscription_api_service.dart`](file:///lib/services/api/subscription_api_service.dart) | `#175`–`#178` | Owner Only |

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

3. **Run static analysis**:
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

The codebase includes automated unit, widget, and layout responsiveness tests:

```bash
# Run all tests
flutter test

# Run specific module test suites
flutter test test/dashboard_test.dart
flutter test test/report_test.dart
flutter test test/central_kitchen_test.dart
flutter test test/notification_test.dart
flutter test test/support_ticket_test.dart
flutter test test/subscription_test.dart
flutter test test/integration_test.dart
```

### Viewport Responsiveness
All screens and widgets are verified to render without layout overflow across:
- **Mobile Portrait**: 360 × 800
- **Mobile Landscape**: 800 × 360
- **Desktop / Tablet**: 1280 × 800
- **Accessibility**: 1.5× system font scaling

---

## 🔒 Security & Live Server Auditing

Live integration verification scripts are organized under `tool/live_checks/`:
- **Credentials Policy**: No hardcoded test credentials or secrets are permitted in the codebase.
- **Audit Runner**: `tool/live_checks/run_audit.py` reads credentials securely from environment variables:
  ```bash
  # Linux / macOS
  export BMB_TEST_EMAIL="user@bmb.com"
  export BMB_TEST_PASSWORD="password"
  python tool/live_checks/run_audit.py

  # Windows PowerShell
  $env:BMB_TEST_EMAIL="user@bmb.com"
  $env:BMB_TEST_PASSWORD="password"
  python tool\live_checks\run_audit.py
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
