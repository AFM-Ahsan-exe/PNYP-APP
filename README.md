# pynp_app

PYNP Mobile Management Application.

## Features

- Member registration, authentication, and profile management
- Admin dashboard for managing members, volunteers, applications, and renewals
- Events, news, documents, and gallery management
- Role-based access control with audit logging
- Push notifications and email verification
- Analytics and reporting

## Design System

The app uses a centralized design system built on Material 3:

- **Theme tokens**: `app_colors.dart`, `app_text_styles.dart`, `app_theme.dart`
- **Reusable widgets**: `AppStatusChip`, `AppListTile`, `AppPageHeader`, `AppSearchBar`, `AppEmptyState`, `AppErrorState`, `AppLoadingState`, `AppConfirmDialog`
- **Validation**: Shared validators in `lib/core/validators/registration_validators.dart`
- **Accessibility**: Semantic labels on core widgets and interactive elements

## Project Structure

```
lib/
  app/
    theme/           # Design tokens and theme configuration
  core/
    widgets/         # Reusable UI components
    validators/      # Shared validation logic
    network/         # API clients
  features/
    auth/            # Login, registration, password reset
    dashboard/       # Admin and member home screens
    members/         # Member management
    volunteers/      # Volunteer management
    events/          # Events listing and details
    news/            # News articles
    documents/       # Document management
    gallery/         # Photo albums
    notifications/   # Push notifications
    profile/         # User profile and directory
    reports/         # Reports and analytics
    settings/        # System and notification settings
    audit/           # Audit logs
    roles/           # Role management
    onboarding/      # Onboarding flow
test/
  core/              # Core widget and validator tests
  features/          # Feature-specific widget tests
server/              # Node.js backend API
```

## Getting Started

### Prerequisites

- Flutter SDK (3.24+)
- Firebase project with Authentication and Firestore
- Node.js (for backend server)

### Flutter Setup

1. Clone the repository and install dependencies:

```powershell
flutter pub get
```

2. Configure Firebase for your platform (Android/iOS) following the
   [FlutterFire setup guide](https://firebase.flutter.dev/docs/overview).

3. Update `lib/firebase_options.dart` with your Firebase project configuration.

### Backend Setup

1. Enable **Authentication** and create **Firestore Database** in the linked
   Firebase project.
2. Save the Firebase Admin service-account key as
   `server/service-account.json`. Never commit or share this file.
3. Deploy the client rules from the project root:

```powershell
firebase deploy --only firestore:rules
```

4. Bootstrap the first administrator once:

```powershell
node server/set-admin.js FIREBASE_UID
```

5. Run the protected management API:

```powershell
node server/index.js
```

For an Android emulator, the Flutter admin member screen calls the local
server at `http://10.0.2.2:3000`. Use HTTPS and a deployed backend outside
local development.

For a physical Android device on the same Wi-Fi network, pass the laptop LAN
address when launching Flutter:

```powershell
flutter run --dart-define=BACKEND_URL=http://192.168.100.182:3000
```

## Running Tests

```powershell
flutter test
```

## Building

```powershell
flutter build apk --debug
flutter build ios --debug
```

## Architecture

- **State Management**: Riverpod
- **Navigation**: go_router
- **Backend**: Firebase (Auth, Firestore, Cloud Functions)
- **Local Storage**: SharedPreferences
- **Image Loading**: Flutter cached network images with downsampling
