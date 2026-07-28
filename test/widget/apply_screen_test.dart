// Assignment 3.2, Part 6 — ApplyScreen widget tests.
//
// **Deviation from the brief.** In this codebase ApplyScreen is a
// two-step form (Assignment 3.1 Stretch A). Step 1 fields:
// full_name, email, years_experience, start_date, + "Next".
// Step 2 fields: cover_letter, portfolio_url, terms, + "Back" /
// "Submit". Tests 6.3 and 6.4 exercise step 1 only; tests
// 6.5–6.7 exercise step 2, which requires first passing step 1.
// The date picker is NEVER opened by any test — start_date is
// filled programmatically by reaching into the FormBuilder's
// state via `tester.state<FormBuilderState>(...)` and calling
// `fields['start_date']!.didChange(future)`. See README 3.2
// assumption 11.
//
// **Fake notifiers.** Both `jobsProvider` and `authProvider` are
// overridden. The auth notifier returns an `Authenticated` state
// with a known test email so the email-field pre-population
// assertion (6.3) has a concrete value to compare against.

import 'package:careerhub_mobile/models/auth_state.dart';
import 'package:careerhub_mobile/models/job.dart';
import 'package:careerhub_mobile/models/user.dart';
import 'package:careerhub_mobile/providers/auth_notifier.dart';
import 'package:careerhub_mobile/providers/jobs_notifier.dart';
import 'package:careerhub_mobile/screens/apply_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Part 6.1 — the fake jobs notifier. Returns a synchronous list;
// no repository, no network, no cache stream. Two entries so the
// checkpoint requirement of "returns at least two entries" is met.
class _FakeJobsNotifier extends JobsNotifier {
  @override
  Future<List<Job>> build() async => [
        Job(
          id: 'job-1',
          title: 'Senior Flutter Engineer',
          company: 'Bitcube',
          location: 'Cape Town, ZA',
          locationType: LocationType.onSite,
          employmentType: 'Full-time',
        ),
        Job(
          id: 'job-2',
          title: 'Backend Engineer',
          company: 'Nimbus Systems',
          location: 'Remote',
          locationType: LocationType.remote,
          employmentType: 'Contract',
        ),
      ];
}

// Part 6.1 — the fake auth notifier. Returns Authenticated with a
// known test email. `skipBiometricGate = true` bypasses the
// LocalAuthentication platform-channel call that would otherwise
// hang the test. The gate exists precisely so tests can bypass
// it — see the class-level docstring on AuthNotifier.
const String _kTestEmail = 'test@example.com';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async {
    skipBiometricGate = true;
    return const Authenticated(
      user: User(
        id: 'user-1',
        email: _kTestEmail,
        displayName: 'Test User',
      ),
    );
  }
}

// Part 6.2 — the buildSubject helper. Returns a ProviderScope
// wrapping MaterialApp wrapping ApplyScreen with the two providers
// overridden. Called from every test with the same `jobId` — its
// specific value is irrelevant because ApplyScreen doesn't render
// job data (that lives on JobDetailScreen).
//
// **Auth pre-warm.** ApplyScreen reads the auth user via
// `ref.read(authProvider).value` at build time (see
// apply_screen.dart:101), a one-shot snapshot with no
// subscription. If the fake auth notifier's build() has not
// resolved before ApplyScreen's first frame, the read returns
// AsyncLoading (value = null), and the email initialValue falls
// back to '' — a state the production code never sees because in
// production a user has already logged in. The `_AuthWarmup`
// gate mounts ApplyScreen only after `authProvider` reports
// AsyncData, guaranteeing the read finds Authenticated.
Widget buildSubject({String jobId = 'fixture-job-id'}) {
  return ProviderScope(
    overrides: [
      jobsProvider.overrideWith(_FakeJobsNotifier.new),
      authProvider.overrideWith(_FakeAuthNotifier.new),
    ],
    child: MaterialApp(
      home: _AuthWarmup(
        child: ApplyScreen(jobId: jobId),
      ),
    ),
  );
}

class _AuthWarmup extends ConsumerWidget {
  final Widget child;
  const _AuthWarmup({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return auth.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (_) => child,
    );
  }
}

/// Reach into the mounted FormBuilder's state and programmatically
/// set the `start_date` field to a value one day in the future.
/// This is the mechanism the brief's Q3 explicitly names as the
/// widget-test alternative to opening the native date picker — we
/// bypass the picker route entirely and mutate the field's
/// controlled value directly.
///
/// Called before tapping the step-1 "Next" button so step-1
/// validation passes and the widget can transition to step 2.
void fillStartDateProgrammatically(WidgetTester tester) {
  final formState = tester.state<FormBuilderState>(find.byType(FormBuilder));
  formState.fields['start_date']!.didChange(
    DateTime.now().add(const Duration(days: 1)),
  );
}

/// Enter text into the FormBuilderTextField with the given `name`.
/// Reaches into the FormBuilder state and calls `didChange` on the
/// named field — this is the reliable widget-test path because it
/// doesn't depend on `find.widgetWithText(TextField, label)`
/// matching a Text CHILD of the field (TextField's value lives in
/// its controller, not in a Text widget descendant).
void setFieldValue(WidgetTester tester, String name, Object? value) {
  final formState = tester.state<FormBuilderState>(find.byType(FormBuilder));
  formState.fields[name]!.didChange(value);
}

/// Fill every step-1 field with a valid value and tap "Next".
/// Used by every step-2 test to advance the form.
///
/// Note that we DO NOT interact with the DateTimePicker — see
/// `fillStartDateProgrammatically` above.
Future<void> advanceToStep2(WidgetTester tester) async {
  setFieldValue(tester, 'full_name', 'Jane Doe');
  // Email is already prepopulated by auth override — leave it.
  setFieldValue(tester, 'years_experience', '3');
  fillStartDateProgrammatically(tester);

  // Tap the step-1 "Next" button.
  await tester.tap(find.widgetWithText(FilledButton, 'Next'));
  await tester.pumpAndSettle();
}

void main() {
  group('ApplyScreen', () {
    testWidgets(
      'email field is pre-populated from the authenticated user',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // The FormBuilder's field state carries the initialValue as
        // its `value`. Reading it directly is the reliable
        // widget-test check — the TextField's rendered controller
        // text does not appear as a Text widget descendant, so
        // `find.widgetWithText` would return zero even when the
        // field is correctly prepopulated.
        final formState =
            tester.state<FormBuilderState>(find.byType(FormBuilder));
        expect(formState.fields['email']!.value, equals(_kTestEmail));
      },
    );

    testWidgets(
      'tapping Next with all step-1 fields empty shows multiple required errors',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        // Clear the pre-populated email so it also produces a
        // required error — the assertion counts multiple errors
        // simultaneously per brief Step 6.4.
        setFieldValue(tester, 'email', '');

        await tester.tap(find.widgetWithText(FilledButton, 'Next'));
        await tester.pumpAndSettle();

        // form_builder_validators' default English "required"
        // message is "This field cannot be empty." — matching on
        // "empty" is the substring that survives version drift.
        // `findsAtLeastNWidgets(2)` confirms the plural intent
        // from the brief.
        expect(
          find.textContaining(
            RegExp('cannot be empty', caseSensitive: false),
          ),
          findsAtLeastNWidgets(2),
        );
      },
    );

    testWidgets(
      'cover letter shorter than 50 chars produces a length validation error',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await advanceToStep2(tester);

        // Confirm we are on step 2 — the Submit button is present.
        expect(find.widgetWithText(FilledButton, 'Submit'), findsOneWidget);

        // Enter a short cover letter (below the minLength(50)
        // threshold from apply_screen.dart:397) and tap Submit.
        setFieldValue(tester, 'cover_letter', 'Too short');
        await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
        await tester.pumpAndSettle();

        // form_builder_validators' minLength message is
        // "Value must have a length greater than or equal to 50."
        // Matching a substring of that message survives
        // form_builder_validators version drift and localisation.
        expect(
          find.textContaining(
            RegExp('greater than or equal', caseSensitive: false),
          ),
          findsAtLeastNWidgets(1),
        );
      },
    );

    testWidgets(
      'portfolio URL is optional — an empty value produces no URL error',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await advanceToStep2(tester);

        // Do NOT enter anything into portfolio_url. Tap Submit —
        // other required errors will appear (cover_letter empty,
        // terms unchecked) but the portfolio field's URL error
        // must NOT be among them. See brief Step 6.6.
        await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
        await tester.pumpAndSettle();

        // form_builder_validators' URL error message contains
        // 'valid URL'. Absence of the substring confirms the
        // portfolio field did not produce a format error.
        expect(
          find.textContaining(RegExp('valid URL', caseSensitive: false)),
          findsNothing,
        );
      },
    );

    testWidgets(
      'portfolio URL rejects a non-URL value with a format error',
      (tester) async {
        await tester.pumpWidget(buildSubject());
        await tester.pumpAndSettle();

        await advanceToStep2(tester);

        // Enter a non-URL. The portfolio field's validator is a
        // custom three-case function (see apply_screen.dart:505)
        // that returns the form_builder_validators.url() error
        // when the value is non-empty and not a URL.
        setFieldValue(tester, 'portfolio_url', 'not-a-url');
        await tester.tap(find.widgetWithText(FilledButton, 'Submit'));
        await tester.pumpAndSettle();

        expect(
          find.textContaining(RegExp('valid URL', caseSensitive: false)),
          findsAtLeastNWidgets(1),
        );
      },
    );
  });
}
