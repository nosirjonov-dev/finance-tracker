# 💰 Finance Tracker — Flutter App

A modern, dark-themed personal finance tracking app built with Flutter and SQLite. Features full CRUD operations, search/filter/sort, and a polished glassmorphism UI.

---

## ✨ Features

- **3 Screens**: Home Dashboard, Transactions List, Add/Edit Form
- **SQLite database** via `sqflite` — works fully offline, persists across restarts
- **Full CRUD**: Create, Read, Update, Delete transactions
- **Search**: Real-time search by title, description, or category
- **Filter**: All / Income / Expense tabs
- **Sort**: By date (newest/oldest) or amount (high/low)
- **8 sample transactions** pre-loaded on first launch
- **Input validation** on all form fields
- **Swipe to delete** with confirmation dialog
- **Pull to refresh** on all list screens
- **Modern dark UI** with glassmorphism cards and gradient accents

---

## 📱 Screenshots

| Home | Transactions | Add/Edit |
|------|-------------|---------|
| Balance hero card, quick actions, recent transactions | Full list with search, filter, sort | Form with type toggle, category grid, date picker |

---

## 🗃️ Database Structure

**Table: `transactions`**

| Column | Type | Description |
|--------|------|-------------|
| `id` | INTEGER PK | Auto-increment row ID |
| `title` | TEXT | Short name (required) |
| `description` | TEXT | Optional longer note |
| `amount` | REAL | Positive decimal value |
| `type` | TEXT | `"income"` or `"expense"` |
| `category` | TEXT | One of 10 category names |
| `date` | TEXT | ISO8601 date string |
| `created_at` | TEXT | ISO8601 creation timestamp |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Android Studio or VS Code with Flutter extension

### Installation

```bash
# Clone or unzip the project
cd finance_tracker

# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run

# Build release APK
flutter build apk --release
```

### iOS Setup (additional step)
```bash
cd ios && pod install && cd ..
flutter run
```

---

## 📦 Dependencies

```yaml
sqflite: ^2.3.0          # SQLite database
path: ^1.9.0             # File path utilities
flutter_animate: ^4.5.0  # Smooth animations
intl: ^0.19.0            # Date/currency formatting
uuid: ^4.3.3             # Unique ID generation
```

---

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── transaction.dart         # Transaction data model + enums
├── database/
│   └── database_helper.dart     # SQLite singleton + CRUD operations
├── screens/
│   ├── home_screen.dart         # Screen 1: Dashboard
│   ├── transactions_screen.dart # Screen 2: Full list with search/filter
│   └── add_edit_screen.dart     # Screen 3: Add/Edit form
├── widgets/
│   └── common_widgets.dart      # Reusable UI components
└── utils/
    ├── app_theme.dart           # Colors, text styles, Material theme
    └── formatters.dart          # Currency & date formatting helpers
```

---

## 🧩 Architecture

- **Pattern**: Simple MVC with a singleton DatabaseHelper
- **State**: `setState` for local widget state (no external state management needed for this scope)
- **Database**: Singleton `DatabaseHelper` class wraps all `sqflite` operations
- **Models**: Immutable `Transaction` class with `copyWith` for updates

---

## 🎨 Design System

- **Theme**: Dark glassmorphism with purple/cyan accents
- **Colors**: Deep navy background, card surfaces, category-specific accent colors
- **Typography**: Material 3 with custom weight/spacing overrides
- **Cards**: Rounded corners (20px), subtle borders, no harsh shadows

---

## 📝 License

MIT — free to use and modify.
