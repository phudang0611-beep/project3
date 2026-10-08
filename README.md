# OCR Expense Tracker & Receipt Parser (Flutter & Dart)

An offline, on-device AI personal expense tracking application built with Flutter 3.x. The app leverages **Google ML Kit Text Recognition** for sub-100ms offline OCR, a **custom regex heuristic engine** for parsing transaction amounts, dates, and merchant names, a local **SQLite** database, and **CustomPainter** for animated charts without third-party chart dependencies.

---

## 🌟 Key Features

1. **Camera Viewfinder & Crop Overlay**:
   - Live camera preview with flash cycling (`off`, `torch`, `auto`).
   - Tap-to-focus with animated target indicator.
   - Framing crop overlay with dark scrim, cyan corner brackets, and scanning laser animation.
   - Gallery picker fallback for testing on emulators and physical devices.

2. **On-Device Text Recognition (Google ML Kit)**:
   - 100% offline text extraction via `google_mlkit_text_recognition` (zero cloud API cost, privacy-preserving).
   - Near-instant inference (<100ms on modern devices).

3. **Heuristic Regex Parsing Engine**:
   - **Monetary amounts**: Extracts totals with comma/dot/space separators (e.g., `150,000 VND`, `150.000 đ`, `150 000`).
   - **Dates**: Recognizes `DD/MM/YYYY`, `DD-MM-YYYY`, `DD.MM.YYYY`, and `YYYY-MM-DD`.
   - **Merchants**: Identifies business names from the header while filtering invoice noise (`HÓA ĐƠN BÁN LẺ`, `RECEIPT`, etc.).
   - **Smart categorization**: Suggests categories (*Food, Study, Travel, Gear, Entertainment*) based on merchant keywords.

4. **Local Database & Storage Lifecycle**:
   - Persistent relational storage using **SQLite** (`sqflite`).
   - Receipt image thumbnail caching in the application documents directory (`path_provider`).
   - Automatic cascade deletion of image files upon deleting an expense record.

5. **Visualizations with CustomPainter (No Third-Party Libraries)**:
   - **Animated Donut / Pie Chart**: Shows categorical expense distribution with animated sweep arcs, center total, and legend.
   - **Animated Weekly Spending Bar Chart**: Visualizes expenses from Monday to Sunday with smooth gradient bars, dashed grid lines, and top value tags.

---

## 🏗️ Architecture & Directory Structure

```
lib/
├── main.dart                          # Application entrypoint & initial seed data
├── models/
│   ├── category_model.dart            # ExpenseCategory enum, colors & icons
│   └── transaction_model.dart         # SQLite entity model
├── services/
│   ├── database_helper.dart           # SQLite CRUD & aggregation queries
│   ├── heuristic_parser.dart          # Regex extraction & categorization logic
│   ├── ocr_service.dart               # Google ML Kit text recognition bridge
│   └── receipt_storage_service.dart   # File caching in application directory
├── views/
│   ├── analytics_screen.dart          # Visual dashboard with CustomPainter charts
│   ├── camera_scanner_screen.dart     # Camera viewfinder & live HUD
│   ├── home_screen.dart               # Bottom navigation & FAB container
│   ├── review_receipt_screen.dart     # Interactive editing & verification screen
│   └── transaction_list_screen.dart   # Searchable, filterable history list
└── widgets/
    ├── camera_overlay_painter.dart    # CustomPainter framing HUD & scanline
    └── charts/
        ├── donut_chart_painter.dart   # Animated Donut chart CustomPainter
        └── weekly_bar_chart_painter.dart # Animated Weekly Bar chart CustomPainter
```

---

## 🚀 Setup & Build Instructions

### Prerequisites
- **Flutter SDK** `>= 3.0.0` (tested on Flutter 3.47.6)
- **Dart SDK** `>= 3.0.0`
- **Android Studio** / VS Code with Flutter extension
- **Android SDK** (API 21+) or a connected Android phone

### 1. Clone or open the project
```bash
# If using Android Studio: Open > Select this folder
# If using VS Code: code C:\Users\phuda\StudioProjects\ocr_expense_tracker_01
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run in Debug Mode (requires connected device or emulator)
```bash
flutter run
```

### 4. Run Unit Tests (Heuristic Regex Parser)
```bash
flutter test
# Expected: 4/4 tests passed ✅
```

### 5. Static Analysis
```bash
flutter analyze
# Expected: No issues found ✅
```

### 6. Build Release APK (Deliverable 1)

> ⚠️ **Windows users**: Enable Developer Mode first:
> `Settings → System → For developers → Developer Mode → ON`
> Or run in PowerShell: `start ms-settings:developers`

```bash
flutter build apk --release
```

Output APK path:
```
build\app\outputs\flutter-apk\app-release.apk
```

---

## 📱 Deliverables & Submission Checklist

- [x] **Deliverable 1: Live Demo / Release APK** — `flutter build apk --release`
- [x] **Deliverable 2: Public GitHub Repository** — Clean architecture, unit tests, this README
- [x] **Deliverable 3: Short Technical Report (PDF)** — See [`TECHNICAL_REPORT.md`](./TECHNICAL_REPORT.md)

---

## 🔑 Permissions Required

| Permission | Purpose |
|---|---|
| `CAMERA` | Live camera viewfinder for scanning receipts |
| `READ_MEDIA_IMAGES` | Selecting images from gallery (Android 13+) |
| `READ_EXTERNAL_STORAGE` | Selecting images from gallery (Android ≤ 12) |

---

## 🧩 Dependencies

| Package | Version | Purpose |
|---|---|---|
| `camera` | ^0.11.0+2 | Live camera preview & capture |
| `google_mlkit_text_recognition` | ^0.14.0 | On-device offline OCR |
| `sqflite` | ^2.3.3+1 | Local SQLite database |
| `path_provider` | ^2.1.4 | App-local file storage |
| `path` | ^1.9.0 | Cross-platform path manipulation |
| `intl` | ^0.19.0 | Vietnamese currency & date formatting |
| `image_picker` | ^1.1.2 | Gallery image picker fallback |
| `uuid` | ^4.5.1 | Unique transaction IDs |
