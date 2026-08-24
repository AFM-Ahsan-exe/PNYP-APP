# pynp_app

PYNP Mobile Management Application.

## Auth and approval setup

The Flutter app uses Firebase Authentication and stores account profiles in
`users/{uid}`. New registrations are always created as `role: member` and
`status: pending`. Only an administrator can approve, reject, suspend, or
promote a member through the protected Node server.

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

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
