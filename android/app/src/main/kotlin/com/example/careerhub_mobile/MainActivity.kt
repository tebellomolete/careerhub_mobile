package com.example.careerhub_mobile

// Assignment 2.4 Stretch B — `local_auth` requires the host
// Activity to derive from `FragmentActivity` (its BiometricPrompt
// call attaches a Fragment to the current Activity's
// FragmentManager). Plain `FlutterActivity` does not; the
// `FlutterFragmentActivity` variant that ships with Flutter does.
// Swapping the base is the only Android-side change needed to make
// local_auth work — see local_auth's README under "Android
// integration".
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
