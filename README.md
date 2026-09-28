# Fishi

Realtime messaging app built with Flutter and Supabase.

## Supabase setup

1. Open the SQL Editor and run `supabase/schema.sql`.
2. Go to Authentication, Sign In / Providers, and turn on anonymous sign-ins.

## Running

Copy `.env.example` to `.env` and fill in your project URL and publishable key, then:

```
flutter pub get
flutter run --dart-define-from-file=.env
```

Release build for Android:

```
flutter build apk --release --dart-define-from-file=.env
```
