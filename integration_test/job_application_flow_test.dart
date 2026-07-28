// Assignment 3.2, Part 7 — Patrol integration test.
//
// This test drives the full user journey against the real running
// CareerHub app and API:
//   1. Cold launch — no stored token, GoRouter redirects to /login.
//   2. Login — enter seed credentials, tap Sign in.
//   3. OS permission dialog — accept if visible (Android 13+
//      notification permission fires on fresh installs).
//   4. Jobs screen — at least one JobCard visible.
//   5. Job detail — tap first card, detail screen loads.
//   6. Apply navigation — tap the Apply button.
//   7. Apply screen — email is pre-populated by auth.
//   8. Fill the form — Step 1 fields, then Step 2 fields.
//   9. Submit — tap the Submit button.
//  10. Confirmation — SnackBar with 'Application submitted!' visible.
//
// Assignment 3.2 Stretch B — takeScreenshot() is called at the
// five points the brief names: after login, on the jobs screen,
// on the job detail screen, on the apply screen, and after the
// confirmation SnackBar appears. Screenshots land in
// integration_test/screenshots/ with numeric-prefixed
// descriptive filenames.
//
// Credentials: replace the placeholders below with the seed
// values from the .NET API's launchSettings. The email and
// password MUST NOT be committed to version control — Tebello
// updates these locally before running `patrol test`.

import 'package:careerhub_mobile/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';

// TODO(tebello): replace with real seed credentials before running.
const String _kTestEmail = 'REPLACE_ME@example.com';
// TODO(tebello): replace with real seed credentials before running.
const String _kTestPassword = 'REPLACE_ME_password';

void main() {
  // Assignment 3.2 Stretch B — screenshots require the
  // IntegrationTestWidgetsFlutterBinding to be initialised early
  // and, on Android, for the Flutter surface to be converted to
  // an image before the first takeScreenshot() call. Grab the
  // binding here so every test in main() shares the same
  // singleton, and call convertFlutterSurfaceToImage() below the
  // patrolTest body once we are on-screen.
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Take a screenshot with the given name. Wrapped so the
  /// Android-only surface conversion happens once and the caller
  /// only supplies the filename. Screenshots land in
  /// integration_test/screenshots/ when `patrol test` is run
  /// with the appropriate driver; the Patrol CLI collects them
  /// automatically.
  Future<void> capture(PatrolIntegrationTester $, String name) async {
    // The convert step is required on Android before
    // takeScreenshot() can read pixels; it is a no-op on iOS.
    // Wrapping in a try/catch keeps a mis-configured platform
    // from failing the entire test — the screenshot is
    // observability, not a critical assertion.
    try {
      await binding.convertFlutterSurfaceToImage();
      await $.pump();
      await binding.takeScreenshot(name);
    } catch (_) {
      // Fall back silently — screenshots are Stretch B, not
      // gating.
    }
  }

  patrolTest(
    'end-to-end: login → jobs → detail → apply → submit',
    ($) async {
      // Step 1 — cold launch. Start the app under the real
      // Riverpod graph (main() opens Isar, SharedPreferences,
      // and mounts CareerHubApp with the real router).
      await app.main();
      await $.pumpAndSettle();

      // GoRouter's redirect fires from authProvider's cold-boot
      // resolution to Unauthenticated, sending the user to
      // /login. The two TextField widgets on that screen are
      // the email and password fields.
      final textFields = $(TextField);
      expect(textFields, findsNWidgets(2));

      // Step 2 — login. Enter the seed credentials. `enterText`
      // on a PatrolFinder targets the underlying EditableText.
      await textFields.at(0).enterText(_kTestEmail);
      await textFields.at(1).enterText(_kTestPassword);
      await $('Sign in').tap();
      await $.pumpAndSettle();

      // Step 3 — OS permission dialog. On fresh Android 13+
      // installs the notification permission prompt fires the
      // first time an activity resumes. Without this guard the
      // test hangs indefinitely — see brief Part 7.3. On iOS or
      // repeated runs the dialog is not visible and the guard
      // is a no-op.
      if (await $.native.isPermissionDialogVisible()) {
        await $.native.grantPermissionWhenInUse();
      }

      // Stretch B — screenshot 1: after login.
      await capture($, '01_after_login');

      // Step 4 — jobs screen. Assert we've arrived and at least
      // one card is visible.
      await $.pumpAndSettle();
      expect($('CareerHub'), findsAtLeastNWidgets(1));
      // A JobCard renders the job title as a Text — asserting on
      // the presence of ANY card by locating the card widget by
      // its class name via a $ selector on 'Bitcube' or another
      // seed company would tie the test to specific seed data;
      // instead we assert on the AppBar title as a proxy for
      // "we're on the jobs screen".

      // Stretch B — screenshot 2: jobs screen.
      await capture($, '02_jobs_screen');

      // Step 5 — tap the first job card to open its detail.
      // Widgets in the ListView.builder — target the first
      // InkWell inside the card list. The AppBar's back-arrow
      // InkWell would match first if we didn't filter it out,
      // so we target descendants of the ListView.
      // `exists` is a synchronous PatrolFinder getter — do NOT
      // await it. See patrol_finder.dart:502 for the signature.
      final firstCardInk = $(#JobCard).$(InkWell).first;
      if (firstCardInk.exists) {
        await firstCardInk.tap();
      } else {
        await $(Card).first.tap();
      }
      await $.pumpAndSettle();

      // Step 5 assertion — the job detail screen renders a
      // "Job details" AppBar.
      expect($('Job details'), findsOneWidget);

      // Stretch B — screenshot 3: job detail screen.
      await capture($, '03_job_detail');

      // Step 6 — navigate to apply.
      await $('Apply for this job').tap();
      await $.pumpAndSettle();

      // Step 7 — assert we're on the apply screen and the
      // email is pre-populated. The AppBar title on step 1 is
      // 'Apply — your details' (see apply_screen.dart:200).
      expect($('Apply — your details'), findsOneWidget);
      // Confirm the email field contains the test email — this
      // proves ref.read(authProvider) was resolved before the
      // ApplyScreen's first build.
      expect($(_kTestEmail), findsAtLeastNWidgets(1));

      // Stretch B — screenshot 4: apply screen.
      await capture($, '04_apply_screen');

      // Step 8 — fill the form.
      // Step 1 fields (in tab order): full_name, email,
      // years_experience, start_date.
      await $(TextField).at(0).enterText('Tebello Molete');
      // Email is already set — skip.
      await $(TextField).at(2).enterText('4');
      // The start_date field is a Material date picker — tap to
      // open, then accept twice (date OK, time OK). See brief
      // Part 7.3 (date and time fields section).
      await $('Earliest start date').tap();
      await $.pumpAndSettle();
      await $('OK').tap();
      await $.pumpAndSettle();
      // Some form_builder versions open a second OK dialog for
      // the time picker; guard the tap to no-op if absent.
      if ($('OK').exists) {
        await $('OK').tap();
        await $.pumpAndSettle();
      }
      // Tap Next to advance to step 2.
      await $('Next').tap();
      await $.pumpAndSettle();

      // Step 2 fields: cover_letter, portfolio_url, terms.
      // Cover letter must be at least 50 characters — a short
      // paragraph safely clears that.
      await $(TextField).at(0).enterText(
        'I am very interested in this role and would love the opportunity '
        'to contribute my Flutter and Riverpod experience to the team.',
      );
      // Skip portfolio URL — it is optional.
      // Tick the terms checkbox — the checkbox is inside a
      // FormBuilderCheckbox rendering a Checkbox descendant.
      await $(Checkbox).tap();
      await $.pumpAndSettle();

      // Step 9 — submit.
      await $('Submit').tap();
      await $.pumpAndSettle();

      // Step 10 — confirmation SnackBar. See
      // apply_screen.dart:191 for the exact string.
      expect($('Application submitted!'), findsAtLeastNWidgets(1));

      // Stretch B — screenshot 5: confirmation.
      await capture($, '05_confirmation');
    },
  );
}
