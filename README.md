# Field Agent Scheduler

A production-quality Flutter mobile application for managing field agent schedules, GPS-based check-ins, visit reports, and operational oversight — built entirely with local demo data, no backend required.

---

## Table of Contents

- [Overview](#overview)
- [Screenshots & Screens](#screenshots--screens)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Running the App](#running-the-app)
- [Demo Credentials](#demo-credentials)
- [Feature Guide](#feature-guide)
  - [Splash Screen](#splash-screen)
  - [Login](#login)
  - [Dashboard](#dashboard)
  - [Schedules](#schedules)
  - [Create Schedule](#create-schedule)
  - [Schedule Details & Check-In](#schedule-details--check-in)
  - [Check-Out](#check-out)
  - [Reports](#reports)
  - [Profile & Settings](#profile--settings)
- [Architecture](#architecture)
  - [State Management](#state-management)
  - [Local Persistence](#local-persistence)
  - [Location Service](#location-service)
  - [Data Versioning](#data-versioning)
- [Color Palette](#color-palette)
- [Adding New Features](#adding-new-features)
  - [Bumping Demo Data](#bumping-demo-data)
  - [Adding a New Screen](#adding-a-new-screen)
  - [Adding a New Field to Schedule](#adding-a-new-field-to-schedule)
- [Known Limitations](#known-limitations)
- [Dependencies](#dependencies)

---

## Overview

Field Agent Scheduler gives field agents a single place to:

- View and manage their scheduled site visits
- Check in at a location using GPS (within a 100 m radius)
- Submit visit reports on check-out
- Track completion status across all jobs
- Switch between light and dark mode

All data is stored locally using `SharedPreferences`. There is no backend, no authentication server, and no network calls beyond GPS.

---

## Screenshots & Screens

| Screen | Description |
|---|---|
| Splash | Animated logo, routes to Dashboard or Login |
| Login | Demo credential login with tap-to-fill hint |
| Dashboard | Stats overview, quick actions, recent activity |
| Schedules | Full list with search and status filter |
| Create Schedule | Form to add a new field visit |
| Schedule Details | Full info, GPS check-in, check-out trigger |
| Check-Out | Visit report submission |
| Reports | All completed schedules with visit reports |
| Profile | User info, dark mode toggle, demo data reset |

---

## Tech Stack

| Concern | Package / Approach |
|---|---|
| Framework | Flutter (latest stable) |
| State management | `provider ^6.1.2` |
| Local storage | `shared_preferences ^2.3.2` |
| GPS / location | `geolocator ^13.0.2` + `permission_handler ^11.3.1` |
| Date formatting | `intl ^0.19.0` |
| UUID generation | `uuid ^4.5.1` |
| UI system | Material 3 |
| Null safety | Enabled (Dart SDK `^3.12.0`) |

---

## Project Structure

```
lib/
├── main.dart                    # App entry, theme builder, route table
│
├── models/
│   └── schedule.dart            # Schedule data model + ScheduleStatus enum
│
├── providers/
│   ├── auth_provider.dart       # Login/logout state
│   ├── schedule_provider.dart   # Schedule CRUD, filters, persistence, seeding
│   └── theme_provider.dart      # Light/dark mode, persisted preference
│
├── services/
│   ├── auth_service.dart        # Demo credential check + SharedPrefs auth
│   └── location_service.dart    # Geolocator wrapper + Haversine distance
│
├── screens/
│   ├── splash_screen.dart       # Animated splash, session check
│   ├── login_screen.dart        # Login form
│   ├── main_shell.dart          # Bottom nav shell (IndexedStack)
│   ├── dashboard_screen.dart    # Stats, quick actions, recent activity
│   ├── schedules_screen.dart    # Schedule list with search/filter
│   ├── create_schedule_screen.dart  # New schedule form
│   ├── schedule_details_screen.dart # Details + check-in action
│   ├── checkout_screen.dart     # Visit report + checkout
│   ├── reports_screen.dart      # Completed schedules + reports
│   └── profile_screen.dart      # Profile, settings, demo reset
│
├── widgets/
│   ├── custom_text_field.dart   # Reusable styled TextFormField
│   ├── schedule_card.dart       # Card used in schedule list
│   └── dashboard_card.dart      # Stat card (unused in current dashboard)
│
└── utils/
    └── app_constants.dart       # Colors, strings, spacing, status helpers
```

---

## Getting Started

### Prerequisites

- Flutter SDK **3.x** or later ([install guide](https://docs.flutter.dev/get-started/install))
- Dart SDK **3.12.0** or later (bundled with Flutter)
- Android Studio or VS Code with the Flutter extension
- A connected Android/iOS device or emulator

Verify your setup:

```bash
flutter doctor
```

### Installation

```bash
# 1. Clone or open the project
cd "d:\Agent Manager\feild_agent_scheduler"

# 2. Install dependencies
flutter pub get
```

### Running the App

```bash
# Run on connected device / emulator
flutter run

# Run on a specific device
flutter run -d <device-id>

# List available devices
flutter devices
```

On first launch, the app automatically seeds **5 demo schedules** — no manual setup needed.

#### Android permissions

Location permissions are declared in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

The app requests runtime permission when the agent taps **Check In** for the first time.

---

## Demo Credentials

```
Email:    agent@test.com
Password: 123456
```

On the login screen, tap the **Demo** hint bar to auto-fill both fields.

---

## Feature Guide

### Splash Screen

Displays for ~2 seconds with a fade-in/scale animation. Checks `SharedPreferences` for an existing session:

- Session found → loads schedules → goes to **Dashboard**
- No session → goes to **Login**

---

### Login

- Validates that both fields are non-empty before submitting
- Wrong credentials show a red snackbar
- Successful login persists session and loads schedules
- Tap the demo hint bar at the bottom to fill credentials automatically

---

### Dashboard

The main hub after login. Contains:

| Section | What it shows |
|---|---|
| Status bar | Today's date, total schedule count, pending count pill |
| Stats card | Total / Completed / Pending / Active — single card, 4 columns |
| Quick actions | Create Schedule · All Schedules · View Reports |
| Recent activity | Last 5 schedules by creation date, tappable |

Pull down anywhere on the page to refresh schedule data.

The **New Schedule** FAB (bottom right) opens the create form directly.

---

### Schedules

Full list of all schedules sorted newest-first.

- **Search**: tap the search icon in the AppBar to reveal a search field that filters by customer name in real time
- **Filter chips**: All · Pending · Checked In · Completed
- **Pull to refresh**: swipe down to reload from storage
- **Empty state**: shown when no schedules match the active filter/search, with a shortcut to create one
- Tap any card to open Schedule Details

---

### Create Schedule

Form fields:

| Field | Validation |
|---|---|
| Customer Name | Required |
| Location Name | Required |
| Latitude | Required, must be −90 to 90 |
| Longitude | Required, must be −180 to 180 |
| Initial Field Report | Required, minimum 10 characters |

On save, the schedule is added to the provider and persisted immediately. You are returned to the previous screen with a success snackbar.

**Tip:** Use Google Maps → long press a location → tap the coordinate shown at the top to copy it.

---

### Schedule Details & Check-In

Shows all schedule information in labelled sections: Customer, Coordinates, Initial Report, Visit Report (if available), Timeline.

**Check-In flow:**

1. Tap **Check In**
2. The app requests location permission if not yet granted
3. GPS fix is obtained (up to 15 s timeout)
4. Haversine distance between your position and the schedule coordinates is calculated
5. **Within 100 m** → status changes to *Checked In*, timestamp recorded, success snackbar
6. **Outside 100 m** → amber warning banner shows the distance to target; the status does not change

Once checked in, the **Check Out** button becomes available.

---

### Check-Out

Accessible from Schedule Details when status is *Checked In*.

- Enter a visit report (minimum 15 characters)
- A character counter is shown below the field
- Tap **Complete Check-Out**
- Status changes to *Completed*, checkout timestamp recorded, visit report saved
- App navigates back to the Dashboard

---

### Reports

Shows only *Completed* schedules with their submitted visit reports.

- Summary bar at the top shows completed count and overall completion percentage
- Each card shows customer name, location, visit report preview (2 lines), and check-in/check-out timestamps
- Tap any card to view full details

---

### Profile & Settings

| Section | Contents |
|---|---|
| Avatar card | Initials "DA", role chip "Field Agent", email |
| Stats row | Total · Done · Pending · Active |
| Settings | Dark Mode toggle, Notifications toggle (demo) |
| About | App version, Privacy Policy, Terms of Service |
| Developer | **Reset Demo Data** — restores all 5 sample schedules |
| Logout | Confirmation dialog, clears session, returns to Login |

**Dark Mode** preference is saved to SharedPreferences and restored on next launch.

---

## Architecture

### State Management

Three `ChangeNotifier` providers registered in `main.dart` via `MultiProvider`:

```
AuthProvider       → login/logout state, user email
ScheduleProvider   → schedule list, CRUD, filters, persistence
ThemeProvider      → light/dark mode, persisted preference
```

All screens access providers via `context.watch<T>()` (reactive) or `context.read<T>()` (one-shot action). Business logic lives entirely in providers; screens contain only UI code.

### Local Persistence

`SharedPreferences` is used for three things:

| Key | Type | Content |
|---|---|---|
| `is_logged_in` | bool | Whether a session exists |
| `user_email` | String | Logged-in user's email |
| `schedules` | List\<String\> | JSON-encoded list of Schedule maps |
| `data_version` | int | Schema version for cache busting |
| `theme_mode` | String | `'light'` or `'dark'` |

Every write goes through `ScheduleProvider._persist()` which serialises the full list synchronously after each mutation.

### Location Service

`LocationService` (singleton) wraps Geolocator:

```
requestPermission()   → checks service enabled, requests runtime permission
getCurrentPosition()  → high-accuracy fix, 15 s timeout
checkProximity(...)   → returns ProximityResult { isWithinRadius, distanceMeters, error }
```

Distance is calculated with the **Haversine formula** — no network call needed.

The allowed check-in radius is set in `AppConstants`:

```dart
static const double checkInRadiusMeters = 100.0;
```

Change this value to adjust how close an agent must be.

### Data Versioning

`AppConstants.currentDataVersion` (currently `2`) is written to SharedPreferences on every clean seed. On app launch, `ScheduleProvider.loadSchedules()` compares the stored version with the current one:

- **Match** → load normally
- **Mismatch** → wipe stored schedules, reseed demo data, write new version

This means you can force all existing installs to get fresh demo data by bumping the constant:

```dart
// lib/utils/app_constants.dart
static const int currentDataVersion = 3; // ← bump here
```

---

## Color Palette

All colors are defined as constants in `AppConstants` and used directly throughout — no widget reads `colorScheme.primary` from the seed algorithm.

| Role | Constant | Hex | Used for |
|---|---|---|---|
| Primary accent | `primaryAccent` | `#2563EB` | Buttons, FAB, active nav, cobalt stats, links |
| Deep navy | `deepNavy` | `#0F172A` | AppBar, splash/login gradient, dark scaffold |
| Slate 800 | `slate800` | `#1E293B` | Dark cards, dark nav bar |
| Slate 600 | `slate600` | `#475569` | Secondary labels, icons, hints |
| Slate 200 | `slate200` | `#E2E8F0` | Dividers, borders |
| Slate 50 | `slate50` | `#F8FAFC` | Light scaffold background |
| Success green | `successColor` | `#16A34A` | Completed status, check-out button |
| Amber | `warningColor` | `#F59E0B` | Pending status, proximity warning |
| Error red | `errorColor` | `#C62828` | Error states, logout button |

Status colors are centralised in `AppConstants.statusColor(String status)` so changing a status color updates every chip, dot, and label across the app in one place.

---

## Adding New Features

### Bumping Demo Data

If you change the `Schedule` model or want a fresh dataset for testers:

1. Edit `lib/utils/app_constants.dart`
2. Increment `currentDataVersion`
3. Update `_seedDemoData()` in `schedule_provider.dart` with any new fields or entries

On next cold launch every device will automatically get the fresh data.

### Adding a New Screen

1. Create `lib/screens/your_screen.dart`
2. Add a route in `main.dart`:
   ```dart
   '/your-screen': (_) => const YourScreen(),
   ```
3. Navigate to it:
   ```dart
   Navigator.pushNamed(context, '/your-screen');
   // or with arguments:
   Navigator.pushNamed(context, '/your-screen', arguments: someId);
   // read arguments inside the screen:
   final id = ModalRoute.of(context)?.settings.arguments as String?;
   ```

### Adding a New Field to Schedule

1. Add the field to `lib/models/schedule.dart` (constructor, `copyWith`, `toMap`, `fromMap`)
2. Bump `AppConstants.currentDataVersion` — this triggers a reseed on all existing installs
3. Update `_seedDemoData()` in `schedule_provider.dart` to populate the new field in demo records
4. Update any screens that display or edit the field

---

## Known Limitations

- **No backend** — all data is device-local. There is no sync between devices.
- **GPS on emulator** — location permission works but the emulator returns a fixed mock coordinate. Use a real device for the 100 m check-in radius to behave accurately. You can temporarily raise `checkInRadiusMeters` to a large value (e.g. `999999`) during emulator testing.
- **iOS permissions** — `NSLocationWhenInUseUsageDescription` must be added to `ios/Runner/Info.plist` before running on a real iOS device. The geolocator package documentation covers this.
- **Single user** — the app is designed for a single field agent per device. Multi-user or team features would require a backend.
- **No image attachments** — visit reports are text-only.

---

## Dependencies

| Package | Version | Purpose |
|---|---|---|
| `provider` | ^6.1.2 | State management |
| `shared_preferences` | ^2.3.2 | Local key-value storage |
| `geolocator` | ^13.0.2 | GPS location |
| `permission_handler` | ^11.3.1 | Runtime permission requests |
| `intl` | ^0.19.0 | Date/time formatting |
| `uuid` | ^4.5.1 | Unique ID generation |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |
| `flutter_lints` | ^6.0.0 | Lint rules (dev) |

---

*Field Agent Scheduler v1.0.0 — Flutter · Material 3 · No backend required*
