# Masaref — Shared Expense Tracker

A cross-platform app for two users to track shared expenses, split bills by percentage or individual amounts, and see who owes whom — all in real-time.

**[Live Demo](https://hisham733.github.io/calculation_mobile_app/)** — Open on any device, no install needed.

## Features

### Core
- **Expense Tracking** — Log expenses with description, amount, date, category, and who paid
- **Two Split Modes:**
  - **Percentage** — Split 50/50 or customize to any ratio (60/40, 70/30, etc.)
  - **Individual** — Enter each person's exact amount (A=15, B=18)
- **Dashboard** — Monthly summary showing total spent, each user's paid vs share, and settlement (who owes whom)
- **History** — Browse past months with category filters
- **Budget Tracking** — Set monthly budgets per category with color-coded progress bars

### Real-Time Sync
- **Firebase Firestore** — All data synced to the cloud in real-time
- **Shared Data** — Both users see the same expenses, balances, and changes instantly
- **No Login Required** — Open the web app and start tracking immediately

### Extra
- **Dark Mode** — Toggle in Settings
- **Pie Chart** — Visual breakdown of spending by category on the Budget tab
- **Recurring Expenses** — Mark expenses as "Repeat monthly" to auto-generate them
- **Custom Categories** — Add, edit, or delete categories with custom budgets and icons

## Screens

| Screen | Description |
|---|---|
| **Dashboard** | Month overview, settlement card, recent expenses |
| **History** | Month-by-month navigation, category filter chips |
| **Budget** | Per-category progress bars + spending pie chart |
| **Settings** | Edit user names, manage categories, dark mode, reset data |

## Tech Stack

- **Framework:** Flutter (Dart)
- **Web Build:** Flutter Web
- **Backend:** Firebase Firestore (real-time cloud database)
- **State:** Built-in setState + Firestore streams
- **Charts:** fl_chart

## Setup for Development

```bash
# Clone
git clone https://github.com/hisham733/calculation_mobile_app.git
cd calculation_mobile_app

# Get dependencies
flutter pub get

# Run locally (web)
flutter run -d chrome
```

## Build & Deploy

### Web (GitHub Pages)
The repo includes a GitHub Actions workflow (`.github/workflows/deploy.yml`) that auto-builds and deploys to GitHub Pages on every push to `main`.

### iOS/macOS
Needs a Mac with Xcode. The `ios/` and `macos/` directories are included. To build:

```bash
flutter build ios
```

## Project Structure

```
lib/
├── main.dart                    # App entry, Firebase init, dark mode
├── models/                      # Data classes
│   ├── expense.dart             # Expense model (split modes, recurring)
│   ├── category.dart            # Category model (budget, icon)
│   └── user_profile.dart        # User model (name, color)
├── services/
│   ├── storage_service.dart     # Abstract storage interface
│   ├── storage_provider.dart    # Platform-aware factory
│   └── impl/                    # Platform implementations
│       ├── storage_firebase.dart # Firebase Firestore (web)
│       ├── storage_mobile.dart  # SQLite (Android/iOS)
│       ├── storage_web.dart     # SharedPreferences (fallback)
│       └── storage_stub.dart    # Development stub
├── screens/                     # UI screens
│   ├── home_screen.dart         # Tab navigation (4 tabs)
│   ├── dashboard_screen.dart    # Monthly summary + settlement
│   ├── add_expense_screen.dart  # Add expense form
│   ├── history_screen.dart      # Month browsing + filters
│   ├── budget_screen.dart       # Budget bars + pie chart
│   └── settings_screen.dart     # Users, categories, dark mode
└── helpers/
    ├── calculations.dart        # Balance/summary calculations
    ├── id_generator.dart        # String ID generation
```

## License

MIT
