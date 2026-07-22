import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../models/auth_state.dart';
import '../providers/application_drafts_notifier.dart';
import '../providers/auth_notifier.dart';
import '../providers/connectivity_provider.dart';

/// Assignment 3.1, Part 7 — the job application form.
///
/// **Class shape (Part 7.3 checkpoint):**
///   - `HookConsumerWidget` — single class, no State subclass, no
///     `createState`, no explicit `dispose`.
///   - Required `String jobId` in the const constructor. Passed by
///     the router from `state.pathParameters['id']!`.
///
/// **Two-step form (Stretch A):**
///   - Step 1 collects personal details: full name, email, years of
///     experience, earliest start date.
///   - Step 2 collects the application content: cover letter,
///     portfolio URL, terms confirmation.
///   - Two `FormBuilder` widgets, each with its **own**
///     `GlobalKey<FormBuilderState>` created via
///     `useMemoized(() => GlobalKey<FormBuilderState>())`. Two
///     separate keys means each step has an independent
///     `FormBuilderState`; `saveAndValidate()` on step 1's key only
///     validates step-1 fields, so hidden step-2 validators do not
///     block the transition. See README 3.1 Stretch A on why this is
///     preferable to `Visibility(visible: false)`.
///   - Values are cached across step transitions in a `useState` map
///     so tapping **Back** to step 1 restores every previously
///     entered value, and tapping **Next** again re-mounts step 2
///     with its cached values.
///
/// **Animated field reveal (Stretch B):**
///   - Each `FormBuilderField` is wrapped in `_AnimatedFieldReveal`,
///     which composes `AnimatedOpacity` (0 → 1 over 240 ms) with
///     `AnimatedSlide` (offset `(0, 0.2)` → `Offset.zero`).
///   - Reveal is driven by a `useState<int> revealCount`; a field
///     with index `i` is "revealed" once `revealCount > i`.
///   - The reveal sequence is triggered from a `useEffect` keyed on
///     `stepIndex.value`. The effect resets the counter to 0, then
///     starts a `Timer.periodic(80 ms)` that increments the counter
///     once per tick until every field on the current step is
///     revealed. The effect's returned cleanup function cancels
///     any in-flight timer if the widget unmounts or the step
///     changes mid-sequence — a plain `Timer.periodic` inside
///     `build()` would leak on every rebuild.
///
/// **Offline application drafts (Stretch C):**
///   - `submit` reads `isOfflineProvider`. When online, a SnackBar
///     confirms and the screen pops. When offline, the assembled
///     value map is handed to `ApplicationDraftsController.saveDraft`
///     which writes one row to Isar. A "saved as draft" SnackBar
///     is shown and the screen pops.
///   - The reconnect sync-drain lives on the jobs screen — see
///     `HomeScreen.build`'s `ref.listen<bool>(isOfflineProvider,
///     ...)` callback.
///
/// **`ref.read` (not `ref.watch`) for the auth user (Part 7.3):**
///   - The user's email is prefilled into the email field's
///     initial value. The auth user does not change while this
///     screen is open, so `ref.read` is correct — `ref.watch`
///     would create a subscription and rebuild the form every time
///     the auth state changed, silently discarding whatever the
///     user had typed.
class ApplyScreen extends HookConsumerWidget {
  final String jobId;

  const ApplyScreen({super.key, required this.jobId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Part 7.3 — memoised GlobalKeys. Plain `final formKey =
    // GlobalKey<FormBuilderState>()` inside build() would allocate a
    // NEW key every rebuild; the FormBuilder's Element would detach
    // and remount, and every field value would be lost (see README
    // 3.1 Q3 last bullet).
    final step1Key = useMemoized(() => GlobalKey<FormBuilderState>(), const []);
    final step2Key = useMemoized(() => GlobalKey<FormBuilderState>(), const []);

    // Which step is showing. Stretch A.
    final stepIndex = useState<int>(0);

    // Stretch A — cached values so Back/Next preserve field state.
    final step1Cached = useState<Map<String, dynamic>>(const {});
    final step2Cached = useState<Map<String, dynamic>>(const {});

    // Stretch B — how many fields on the current step have "revealed"
    // so far. Wrapped fields with index < revealCount are visible.
    final revealCount = useState<int>(0);

    // Part 7.3 — read the auth user with `ref.read`. The email will
    // only be used if the cached step-1 values do not already
    // contain one (which happens on the very first mount).
    final authResolved = ref.read(authProvider).value;
    final userEmail = authResolved is Authenticated ? authResolved.user.email : '';

    // Stretch B — trigger the reveal sequence at mount, and again on
    // every step change. The dependency list `[stepIndex.value]`
    // causes useEffect to rerun the cleanup + effect body whenever
    // the step flips. The returned callback cancels the periodic
    // timer so a step change mid-sequence doesn't leave a timer
    // firing in the background.
    useEffect(() {
      // Field 0 reveals at 0 ms (immediately, no timer wait). Field
      // 1 reveals at 80 ms, field 2 at 160 ms, etc. — the exact
      // schedule the brief specifies. We seed revealCount = 1 so
      // field 0 (index 0) is already visible (`revealCount > 0`),
      // then the periodic timer counts up from there.
      revealCount.value = 1;
      // 4 fields on step 1, 3 fields on step 2. Extra ticks past
      // the field count are harmless — nothing indexes past the
      // array bound — but we cancel promptly to keep the callback
      // count minimal.
      final int fieldCount = stepIndex.value == 0 ? 4 : 3;
      var count = 1;
      final timer = Timer.periodic(const Duration(milliseconds: 80), (t) {
        count++;
        if (count > fieldCount) {
          t.cancel();
          return;
        }
        revealCount.value = count;
      });
      return timer.cancel;
    }, [stepIndex.value]);

    // ─────────────────────────────────────────────────────────────
    // Navigation between the two steps.
    // ─────────────────────────────────────────────────────────────

    void goToStep2() {
      final ok = step1Key.currentState?.saveAndValidate() ?? false;
      if (!ok) return;
      step1Cached.value =
          Map<String, dynamic>.from(step1Key.currentState!.value);
      stepIndex.value = 1;
    }

    void goBackToStep1() {
      // Non-validating save — we want to preserve whatever the user
      // typed on step 2 even if it isn't valid yet.
      step2Key.currentState?.save();
      final currentStep2 = step2Key.currentState?.value;
      if (currentStep2 != null) {
        step2Cached.value = Map<String, dynamic>.from(currentStep2);
      }
      stepIndex.value = 0;
    }

    // ─────────────────────────────────────────────────────────────
    // Submit — Stretch C aware.
    // ─────────────────────────────────────────────────────────────

    Future<void> submit() async {
      final ok = step2Key.currentState?.saveAndValidate() ?? false;
      if (!ok) return;

      final combined = <String, dynamic>{
        ...step1Cached.value,
        ...step2Key.currentState!.value,
      };

      final isOffline = ref.read(isOfflineProvider);

      if (isOffline) {
        // Stretch C — offline path. Save a draft, confirm, pop.
        await ref
            .read(applicationDraftsControllerProvider)
            .saveDraft(jobId, combined);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Saved as draft — will submit when back online.'),
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      // Online path — mock API accepts unconditionally.
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted!')),
      );
      Navigator.of(context).pop();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          stepIndex.value == 0
              ? 'Apply — your details'
              : 'Apply — your application',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: stepIndex.value == 0
            ? _Step1PersonalDetails(
                formKey: step1Key,
                cachedValues: step1Cached.value,
                userEmail: userEmail,
                revealCount: revealCount.value,
                onNext: goToStep2,
              )
            : _Step2ApplicationContent(
                formKey: step2Key,
                cachedValues: step2Cached.value,
                revealCount: revealCount.value,
                onBack: goBackToStep1,
                onSubmit: submit,
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Step 1 — personal details.
//
// Fields in order (indices for _AnimatedFieldReveal):
//   0 — full_name         (required, minLength 2)
//   1 — email             (required, email format, prefilled from auth)
//   2 — years_experience  (required, custom int >= 0)
//   3 — start_date        (required, today or later)
// ═══════════════════════════════════════════════════════════════════════════

class _Step1PersonalDetails extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;
  final Map<String, dynamic> cachedValues;
  final String userEmail;
  final int revealCount;
  final VoidCallback onNext;

  const _Step1PersonalDetails({
    required this.formKey,
    required this.cachedValues,
    required this.userEmail,
    required this.revealCount,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    // The form's initial value map. Cached values (from a previous
    // Next → Back) win over the auth-email default so a user's
    // manual edit is not clobbered on remount.
    final Map<String, dynamic> initialValue = <String, dynamic>{
      'email': userEmail,
      ...cachedValues,
    };

    return FormBuilder(
      key: formKey,
      initialValue: initialValue,
      // Keep the form off `autovalidateMode` — we only want errors
      // to render on Next / Submit.
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AnimatedFieldReveal(
            index: 0,
            revealCount: revealCount,
            child: FormBuilderTextField(
              name: 'full_name',
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.compose<String>([
                // required() FIRST — see README 3.1 Q4 on why the
                // ordering matters.
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(2),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          _AnimatedFieldReveal(
            index: 1,
            revealCount: revealCount,
            child: FormBuilderTextField(
              name: 'email',
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.compose<String>([
                FormBuilderValidators.required(),
                FormBuilderValidators.email(),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          _AnimatedFieldReveal(
            index: 2,
            revealCount: revealCount,
            child: FormBuilderTextField(
              name: 'years_experience',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Years of experience',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.compose<String>([
                FormBuilderValidators.required(),
                _yearsExperienceValidator,
              ]),
            ),
          ),
          const SizedBox(height: 16),
          _AnimatedFieldReveal(
            index: 3,
            revealCount: revealCount,
            child: FormBuilderDateTimePicker(
              name: 'start_date',
              inputType: InputType.date,
              decoration: const InputDecoration(
                labelText: 'Earliest start date',
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.compose<DateTime>([
                FormBuilderValidators.required(),
                _startDateValidator,
              ]),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onNext,
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Step 2 — application content.
//
// Fields in order:
//   0 — cover_letter   (required, minLength 50, multi-line)
//   1 — portfolio_url  (optional; if non-empty must be a URL)
//   2 — terms          (must be true)
// ═══════════════════════════════════════════════════════════════════════════

class _Step2ApplicationContent extends StatelessWidget {
  final GlobalKey<FormBuilderState> formKey;
  final Map<String, dynamic> cachedValues;
  final int revealCount;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const _Step2ApplicationContent({
    required this.formKey,
    required this.cachedValues,
    required this.revealCount,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return FormBuilder(
      key: formKey,
      initialValue: cachedValues,
      autovalidateMode: AutovalidateMode.disabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AnimatedFieldReveal(
            index: 0,
            revealCount: revealCount,
            child: FormBuilderTextField(
              name: 'cover_letter',
              minLines: 5,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Cover letter',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: FormBuilderValidators.compose<String>([
                FormBuilderValidators.required(),
                FormBuilderValidators.minLength(50),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          _AnimatedFieldReveal(
            index: 1,
            revealCount: revealCount,
            child: FormBuilderTextField(
              name: 'portfolio_url',
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Portfolio URL (optional)',
                hintText: 'https://…',
                border: OutlineInputBorder(),
              ),
              // The three-case validator from README 3.1 Q4:
              //   value is null/empty     → null (valid)
              //   value is a valid URL    → null (valid, via url())
              //   value is a non-URL      → 'Not a valid URL address'
              // NOT wrapped in required() — see brief.
              validator: _portfolioUrlValidator,
            ),
          ),
          const SizedBox(height: 16),
          _AnimatedFieldReveal(
            index: 2,
            revealCount: revealCount,
            child: FormBuilderCheckbox(
              name: 'terms',
              title: const Text(
                'I confirm my application is accurate and complete.',
              ),
              // Custom validator — see brief. Returns an error
              // string when value is null or false.
              validator: _termsValidator,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onSubmit,
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Custom validators.
// ═══════════════════════════════════════════════════════════════════════════

/// Years of experience — int.tryParse, non-null, >= 0.
///
/// When composed with `FormBuilderValidators.required()` first, this
/// only runs on non-null non-empty values; the null-defensive check
/// below is retained for the "no required first" path (Part 7.5's
/// exception clause allows it, though this project follows the
/// user's stricter "required first" instruction).
String? _yearsExperienceValidator(String? value) {
  final n = int.tryParse(value ?? '');
  if (n == null || n < 0) {
    return 'Enter a non-negative whole number.';
  }
  return null;
}

/// Earliest start date — today or later.
///
/// The brief specifies truncating both DateTimes to midnight via
/// `copyWith(hour: 0, minute: 0, second: 0, millisecond: 0)` so
/// picking today (which the DateTimePicker returns as
/// midnight-of-today, but only sometimes depending on the platform)
/// passes.
String? _startDateValidator(DateTime? value) {
  if (value == null) return null; // required() first will catch this
  final today = DateTime.now().copyWith(
    hour: 0,
    minute: 0,
    second: 0,
    millisecond: 0,
  );
  final selected = value.copyWith(
    hour: 0,
    minute: 0,
    second: 0,
    millisecond: 0,
  );
  if (selected.isBefore(today)) {
    return 'Earliest start date must be today or later.';
  }
  return null;
}

/// Portfolio URL — the three-case validator from README 3.1 Q4.
String? _portfolioUrlValidator(String? value) {
  if (value == null || value.isEmpty) return null;
  return FormBuilderValidators.url()(value);
}

/// Terms — a single-purpose validator, not composed. Returns an
/// error string when the value is null or false.
String? _termsValidator(bool? value) {
  if (value == null || value == false) {
    return 'You must confirm your application is accurate and complete.';
  }
  return null;
}

// ═══════════════════════════════════════════════════════════════════════════
// Stretch B — animated field reveal.
//
// A field is revealed once `revealCount > index`. Uses AnimatedOpacity
// AND AnimatedSlide together — a purely-implicit animation with no
// AnimationController for us to manage. See README 3.1 Stretch B for
// why useEffect drives the sequence rather than a call inside build().
// ═══════════════════════════════════════════════════════════════════════════

class _AnimatedFieldReveal extends StatelessWidget {
  final int index;
  final int revealCount;
  final Widget child;

  const _AnimatedFieldReveal({
    required this.index,
    required this.revealCount,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final bool visible = revealCount > index;
    return AnimatedSlide(
      offset: visible ? Offset.zero : const Offset(0, 0.2),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 240),
        child: child,
      ),
    );
  }
}
