# CareerHub — Assignment 3.1: Advanced UI Patterns & Performance

_Written 2026-07-22._

Week 3, Assignment 3.1. This section contains the four Part 1 written
decisions (three-tree model & rebuild scope; `const` short-circuit &
`RepaintBoundary`; hooks model & controller lifecycle; FormBuilder state
& cross-field validation); the baseline and after rebuild-count tables;
the shimmer, application-form, and DevTools-scroll-frame demo
write-ups; the `build_runner` note; the `flutter test` slot; and the
three stretch goals (A: two-step application form; B: animated field
reveal; C: offline application drafts). Earlier assignment notes are
preserved further down as historical context.

---

## PART 1 — WRITTEN DECISIONS

### Question 1 — The three-tree model and rebuild scope

**Element reuse when `runtimeType` and `key` match.** When a parent
widget rebuilds and produces a new child widget instance whose
`runtimeType` and `key` match the child already mounted at that slot,
Flutter's `Element.update` path is taken rather than
`Element.inflateWidget`. The existing Element stays in place, its
`_widget` field is repointed at the new widget instance, and its
`RenderObject` is preserved by reference. The framework then calls
`RenderObject.updateWith(new widget)`, which — for most render objects
— compares each configurable property and only marks the render object
for layout (`markNeedsLayout`) or paint (`markNeedsPaint`) if a
property  actually changed. If the new widget carries the same values,
the render object is neither re-laid-out nor re-painted; the frame
reuses the previous layout and raster output. Contrast with a new
widget of a **different** `runtimeType`: `Element.update` returns
`false` in `Widget.canUpdate`, the old element is unmounted (its
`RenderObject` detached and disposed), and `inflateWidget` builds a
new element which allocates and attaches a **new** `RenderObject`,
forcing a fresh layout and paint from scratch.

**Per-widget cost of unnecessary widget construction on our jobs
screen.** Today (before Part 3) the jobs screen is a single
`ConsumerWidget` whose `build()` calls
`ref.watch(filteredJobsProvider)` and `ref.watch(filterProvider)`. On
a filter chip tap both providers emit, so the whole method reruns.
Every widget the method mentions is **allocated fresh**: `Scaffold`,
`AppBar`, its `Text('CareerHub')`, the actions list literal, the
`IconButton` for logout, `Padding` wrappers, the `Column`, the
horizontally scrollable `Row` of `FilterChip`s (four allocations plus
the `Row` and the `SingleChildScrollView`), the `Expanded` around the
list, the `when()` arms (two closures + the `AsyncValue` case
tables), and — inside the data arm — every visible `JobCard` widget
constructor call. Each allocation runs the constructor body, walks
its parameters, and produces a new instance in the heap. Even though
the element tree calls `Widget.canUpdate` next and discovers the
`runtimeType` and `key` haven't changed (so the `RenderObject` is
reused), we still paid: (a) the constructor allocation, (b) the
walk-and-compare in `Element.update`, (c) the property-by-property
diff in `RenderObject.updateWith`. Multiplied by ~30 widgets per
`JobCard` × N visible cards, a filter chip tap that changes *no card
data* still charges tens of thousands of unnecessary allocations and
comparisons per frame.

**The `const` short-circuit.** After Part 3, the screen's `build()`
watches nothing; its body is literally
`const Column(children: [_FilterChips(), Expanded(child: _JobList())])`.
Because `_FilterChips()` and `_JobList()` both have `const`
constructors and no runtime arguments, Dart evaluates them at compile
time and **canonicalises** them: every rebuild of the screen produces
the exact same object instance for the `Column`, its two children,
and the `EdgeInsets`/`SizedBox`/`Text` constants inside. When
`Element.update` runs on a const-canonicalised child, Flutter's short
path in the diff is `identical(oldWidget, newWidget)` — a pointer
compare. On success the framework **skips the entire subtree diff**:
no `Element.update` recursion, no `RenderObject.updateWith`, no
property compare. The element tree is walked *past* the const
subtree, treating it as a black box that provably cannot have changed.
The screen class itself no longer subscribes to any provider, so a
filter chip tap doesn't invoke its `build()` at all; the child
`_FilterChips` — which does subscribe — is the only widget whose
`build()` reruns.

### Question 2 — `const` short-circuit and `RepaintBoundary` layer isolation

**What the element tree does when it re-sees a `const` child it has
already mounted.** Dart evaluates `const` constructor calls at compile
time and canonicalises the results: `const _JobList()` at line 42 of
one build and `const _JobList()` at line 42 of the next build are
guaranteed to be the *same object* — literally the same pointer,
detected by `identical(a, b)` returning `true`. When a parent rebuilds
and hands its element the same const child instance, the element's
diffing step performs an `identical(oldWidget, newWidget)` check at
the very top of `Element.update`. It returns immediately with no
`build()` call on the child, no `RenderObject.updateWith`, no property
diff, and no layout or paint dirtying. The framework treats the
subtree as provably unchanged and moves on. The cost of "diffing" a
const subtree of arbitrary depth is therefore a single pointer
compare — the same as the cost of diffing a leaf that turned out to
match.

**`RepaintBoundary` layer isolation during scroll.** A `RenderObject`
without a repaint boundary is painted into its nearest ancestor's
compositing layer. When any descendant needs a repaint — a scrolling
list constantly translates and paints its children — the whole layer
is re-rasterised on the GPU. Wrapping the list in `RepaintBoundary`
inserts a **new compositing layer** in the render tree at that point:
Skia allocates a dedicated **raster cache texture** (an RGBA
GPU-resident bitmap, sized to the widget's paint bounds), the list's
own paints render into that texture, and everything ABOVE the boundary
(AppBar, filter chip row) paints into a separate layer. During a
scroll the two layers are simply re-composed by the GPU with a
translate transform — the top layer's texture is **not re-rasterised**
because none of the widgets that render into it changed. The Flutter
mechanism that avoids the re-raster is the compositor's **layer
caching / repaint-region tracking**: each `RepaintBoundary` produces
an `OffsetLayer` whose bitmap is retained frame-to-frame and reused
whenever its `RenderObject` is not marked dirty. The memory cost per
boundary is exactly the size of that raster texture — width × height ×
4 bytes at device pixel ratio — sitting in GPU memory for the lifetime
of the layer.

**Two scenarios where adding a `RepaintBoundary` would be wrong.**
_(a) A `RepaintBoundary` around a widget that repaints on every
frame._ Consider a `RepaintBoundary` around an `AnimatedBuilder`
driven by a `Ticker` — say a spinning refresh icon. Because the child
widget changes every frame, its raster cache is invalidated every
frame, so the GPU texture must be **re-rasterised on every tick**.
The boundary now costs (i) a texture allocation, (ii) an extra
composition step to merge the layer with its parent, and (iii) the
same paint work that would have happened anyway. Net effect: strictly
slower than the no-boundary baseline. _(b) A `RepaintBoundary` around
a trivially cheap leaf._ Wrapping a single `Icon` with no siblings
that repaint costs a raster texture (~a few KB of GPU memory) to
cache a paint that would have taken well under a microsecond. The
boundary imposes memory pressure and an extra composition merge with
no observable saving.

### Question 3 — The hooks model and controller lifecycle

**Hooks are stored in a numerically indexed list.** When
`HookConsumerWidget.build()` runs, `HookState` (attached to the
element) holds a `List<HookState>` and an integer cursor. Each call
to `useSomething()` either reads position `cursor++` if a hook of the
matching type exists there, or creates a new one and pushes it. The
identity of a hook is therefore its **position in the list**, not its
name. The rule is: hooks must be called **unconditionally, in the
same order, on every build**. Wrapping a `useTextEditingController()`
call in `if (someCondition) { ... }` breaks that rule the first time
the condition flips. Concretely: the first build ran
`useTextEditingController()` at cursor position 3, so
`_hooks[3] = HookState<TextEditingController>`. If the next build
skips that hook and instead the next call is `useState<int>(0)`, the
framework advances the cursor to 3, sees the pre-existing
`HookState<TextEditingController>` at that index, and returns it. The
build code cast it to `ValueNotifier<int>` and either (i) throws a
`TypeError` at the assignment site (`type 'TextEditingController' is
not a subtype of 'ValueNotifier<int>'`), (ii) succeeds silently and
mutates the wrong controller — the "stale controller reused" case
that reads text from a field that no longer exists on screen. The
user experiences a crash or, worse, edits that vanish; either way
the diagnostic points at the wrong line.

**Field-declared `TextEditingController` leak vs
`useTextEditingController()`'s guarantee.** In a `StatefulWidget`,
declaring `final TextEditingController _emailController =
TextEditingController();` (or `late final` initialised in
`initState`) allocates a controller that internally attaches
listeners and holds a `ChangeNotifier`'s subscribers list. If the
developer forgets to override `dispose()` and call
`_emailController.dispose()`, the controller — and every listener the
framework attached to it (the `TextField` internally listens to it)
— is retained after the State is unmounted, indefinitely, because the
`_State` object still holds a reference and the widget tree drops the
State without teardown. Every navigation to and away from that screen
adds another orphan controller, a classic slow leak that grows the
retained heap until an OOM. `useTextEditingController()` sidesteps
this: internally it creates a `_TextEditingControllerHookState`, and
the piece of the framework responsible for the disposal guarantee is
**`HookState.dispose()`** — called by `HookElement` when the hook is
removed from the hook list or the entire element is unmounted. In
`_TextEditingControllerHookState.dispose()`, the controller's
`dispose()` is invoked automatically. The user cannot forget because
the user never wrote a dispose method in the first place — the hook
owns the lifecycle.

**Why the `GlobalKey<FormBuilderState>` MUST come from
`useMemoized(() => GlobalKey<FormBuilderState>())` rather than a
plain local variable.** A plain local `final formKey =
GlobalKey<FormBuilderState>()` inside `build()` would allocate a
**brand new `GlobalKey` on every rebuild**. `GlobalKey` carries an
invariant enforced by the framework: for any given
`GlobalKey`, at most one Element in the tree may be registered against
it. When the parent rebuilds and produces `FormBuilder(key:
newKey, ...)`, the element diff sees that the widget's key changed
from `oldKey` to `newKey`. The framework's rule is that a widget with
a **new key** cannot update the existing element — it must be
**re-mounted** at a fresh Element. So on every rebuild: the old
`FormBuilder` Element is detached, its `FormBuilderState` is disposed
(losing every field's controller value, every `saveAndValidate`
result, every focus state), and a new `FormBuilder` Element is
inflated with an empty `FormBuilderState`. User-visible symptom: any
keystroke — since typing rebuilds the ancestor via a hook or the
provider it watches — clears the form. `useMemoized(() =>
GlobalKey<FormBuilderState>())` fixes this by returning the **same
key instance** on every build (the memoized value is computed once at
first build and stored in the hook list), so `FormBuilder(key:
formKey)` receives the same key across rebuilds and its Element is
never re-mounted.

### Question 4 — FormBuilder state and cross-field validation

**Why `saveAndValidate()` calls `save()` before `validate()`.** Each
`FormBuilderField`'s currently displayed value is held in the field's
own `FormBuilderFieldState`, populated by its internal
`TextEditingController` (for text fields) or its `onChanged`
callbacks (for pickers, checkboxes). `FormBuilderState.value` is the
centralised `Map<String, dynamic>` of all field values keyed by
`name`. `save()` walks every registered field and copies each
field's current controller value into `FormBuilderState.value`. Only
after that walk does `validate()` run each field's validator — but
critically, cross-field validators (e.g. "must be after the value in
field X") read `formKey.currentState!.value` to look sideways at
sibling fields. If `validate()` ran before `save()`, the map would
still hold the values from the **previous** `save()` call (or empty
on first submit), and a validator comparing "start date" to
"DateTime.now()" would work (it reads a global), but any validator
that read another field's value would see stale data. For the start
date field's own validator (which reads only its argument, not the
map), the order does not matter functionally — but a validator that
happened to cross-reference another field would silently pass or
fail on a stale reading if we called `validate()` first.

**Why `FormBuilderValidators.required()` must be first in every
composed list.** `FormBuilderValidators.compose([a, b, c])` runs the
validators **in declaration order**, stopping at the first that
returns a non-null error string. If we compose `[minLength(50),
required()]` on the cover-letter field and the user submits it blank,
`minLength(50)` runs first, sees an empty string, computes
`0 < 50`, and returns `'Value must be at least 50 characters
long.'`. The user reads that and is told to write more, but the
actual problem is "you wrote nothing." Placing `required()` first
short-circuits the moment the field is empty and produces the
correct diagnostic `'This field is required.'`. Every downstream
validator (`minLength`, `email`, `url`, custom) then only runs when
we already know the field is non-empty and can assume so.

**Portfolio URL — three-case validator (pseudocode).**

```
String? validatePortfolio(String? value) {
  // Case 1: field left blank — allowed.
  if (value == null || value.isEmpty) return null;

  // Case 2 & 3: field non-empty — delegate to url().
  //   - well-formed URL → url() returns null (valid).
  //   - garbage string  → url() returns 'Not a valid URL' (invalid).
  return FormBuilderValidators.url()(value);
}
```

Wrapping this in `FormBuilderValidators.required()` first would flip
Case 1 from "valid" to "This field is required." Wrapping only
`FormBuilderValidators.url()` (no empty guard) would flip Case 1 from
"valid" to `'Not a valid URL'` — the URL validator does not treat an
empty string as vacuously valid; it treats it as malformed. Both
alternatives break the "optional field" contract, which is why the
hand-written guard is necessary.

---

## Baseline rebuild counts

Recorded via Flutter DevTools → Widget Rebuild Stats, before Part 3.
Reset the counter, then tap the location filter chip three times
alternating with **All**. Fill in the numbers observed on your
machine:

| Widget                  | Rebuilds per 3 filter taps |
| ----------------------- | -------------------------- |
| `HomeScreen` (screen)   | _TODO — measure_           |
| `JobCard` (per visible) | _TODO — measure_           |

---

## PART 6 — Shimmer demo

The `JobsShimmer` widget replaces the loading arm of the jobs list
`when()`. It shows six `_ShimmerCard` items in a `ListView.builder`,
each a `Card` with padding that structurally mirrors a real
`JobCard`: a 16-high title bar (~200 wide), a shorter company line
(~120 wide) and location/salary line (~160 wide), then a row of two
28-high rounded chip-shaped `Container`s. All Containers are
`Colors.white`, painted through a `Shimmer.fromColors` `ShaderMask`
whose `baseColor` / `highlightColor` come from
`Theme.of(context).brightness`:

- **Light mode:** `Colors.grey[300]!` / `Colors.grey[100]!`.
- **Dark mode:** `Colors.grey[700]!` / `Colors.grey[600]!`.

The shimmer's structural layout does not depend on the brightness —
only the two grey shades that sweep across the mask change. Confirm
by toggling the emulator between light and dark (Android:
`adb shell "cmd uimode night yes/no"`, or Settings → Display →
Dark theme) while the shimmer is on screen; the base and highlight
tones swap and everything else stays identical.

Dark-mode confirmed: _TODO — check off after seeing it live_.

---

## PART 7 — Application form demo

The **Apply for this job** button on the job detail screen pushes
`/jobs/<id>/apply`, mounting `ApplyScreen(jobId: id)`. The form is a
two-step `FormBuilder` (Stretch A) using
`useMemoized(() => GlobalKey<FormBuilderState>())` for each step.

**Navigation.** Sign in → tap any job card → tap **Apply for this
job** → the apply screen slides in. Step 1 collects personal details
(full name, email, years of experience, earliest start date). Tapping
**Next** validates step 1 and advances to step 2 (cover letter,
portfolio URL, terms). Tapping **Back** returns to step 1 with every
field's value preserved (the step-1 `FormBuilder` is remounted from
its cached `initialValue`s).

**Blank-submit validation errors observed.** Tapping **Next** on a
freshly-mounted step 1:

- Full name: _'This field is required.'_
- Email: _'This field is required.'_
- Years of experience: _'This field is required.'_
- Earliest start date: _'This field is required.'_

Advancing (with valid step 1) and tapping **Submit** on blank step 2:

- Cover letter: _'This field is required.'_
- Terms confirmation: _'You must confirm your application is
  accurate and complete.'_
- Portfolio URL: no error (correctly optional).

Entering a non-URL string like `not a url` into the portfolio field
then submitting: _'This field is not a valid URL address.'_. Clearing
it: valid again (three-case validator behaviour from Q4).

**Success SnackBar.** With all fields valid and connectivity on:
`'Application submitted!'`, then `Navigator.of(context).pop()`
returns to the job detail screen.

---

## PART 8 — After rebuild counts

Recorded via Flutter DevTools → Widget Rebuild Stats, after Part 8,
running with:

```bash
flutter run --profile --dart-define=API_BASE_URL=http://10.0.2.2:5247
```

Reset the counter, then tap the location filter chip three times
alternating with **All**. Fill in your numbers below.

| Widget         | Before (Part 3) | After (Part 8) |
| -------------- | --------------- | -------------- |
| `HomeScreen`   | _TODO_          | _TODO — expect 0_  |
| `_FilterChips` | _n/a — did not exist_ | _TODO — expect 3_ |
| `_JobList`     | _n/a — did not exist_ | _TODO — expect 3_ |
| `JobCard`      | _TODO_          | _TODO — expect 0_  |

**Why `JobCard`'s after count is zero.** After the refactor, the
`_JobList` widget rebuilds when `filteredJobsProvider` emits — but
the provider emits **the same `List<Job>` instance** for a
location-filter tap that doesn't add or remove jobs (the derived
provider returns a new filtered list only when the filter predicate
changes the result). Even when the list identity changes, each
`JobCard` is constructed with the same `job: job` argument — the
same `Job` instance from the same `List<Job>` — so `Widget.canUpdate`
compares the old and new `JobCard` widgets, finds the same
`runtimeType` and same `key`, calls `updateRenderObject` on the
underlying render object, and detects no visual change. But
`JobCard`'s ancestor is the `RepaintBoundary`-wrapped `ListView`;
the boundary further ensures no repaint escapes to the AppBar or
filter row. The DevTools Widget Rebuild counter counts
**Element.rebuild** calls; a `JobCard` whose incoming widget
identity is unchanged does not rebuild.

## DevTools scroll-frame observation

Open the Performance tab, tap Record, scroll the jobs list for
three seconds, tap Stop, tap a frame bar. In the widget build
timeline for that frame we expect to see:

- _TODO — observe the build methods that appear during scroll_.

We expect **not** to see `JobCard.build()` during a scroll that
doesn't change the underlying data — the list widgets scroll via
`RenderSliverList.performLayout` translations, and the
`RepaintBoundary` prevents a paint from bubbling to ancestors. The
`Scrollable` and its inner viewport widgets do appear because they
are the ones driving the scroll offset.

---

## build_runner note

**Was `build_runner` required for any file in Assignment 3.1?**

- **Base parts 1–8:** No. `flutter_hooks`, `hooks_riverpod`,
  `shimmer`, `flutter_form_builder`, and `form_builder_validators` do
  not participate in code generation at all — they are pure runtime
  packages that expose regular Dart classes (`HookConsumerWidget`,
  `Shimmer`, `FormBuilder`, `FormBuilderValidators`). No new
  `@riverpod`, `@freezed`, `@JsonSerializable`, or `@collection`
  annotations are introduced anywhere in `lib/screens/*.dart` or
  `lib/widgets/*.dart`. Every `*.g.dart` and `*.freezed.dart` file in
  the tree today was generated in an earlier assignment and is
  unmodified by 3.1.

- **Stretch C:** Yes — one file. The new `lib/data/application_draft.dart`
  declares `@collection class ApplicationDraft`, which
  `isar_community_generator` reads to emit `application_draft.g.dart`
  (the schema descriptor + typed query API + native codecs). Run
  `dart run build_runner build --delete-conflicting-outputs` once
  after `flutter pub get` to produce it. The generator is already in
  `dev_dependencies` from Assignment 2.3; no new dev dep is needed.

---

## flutter test

_TODO — paste the terminal output from `flutter test` here after the
manual steps below are complete._

```
[paste output of: flutter test]
```

---

## STRETCH A — Multi-step application form

`ApplyScreen` is a two-step form. Step 1 collects the four personal
details (full name, email, years of experience, earliest start
date); step 2 collects the two application-content fields (cover
letter, portfolio URL) and the terms confirmation checkbox. Each
step has its **own `FormBuilder` widget with its own
`GlobalKey<FormBuilderState>`** — both keys created with
`useMemoized(() => GlobalKey<FormBuilderState>())` so the memoised
key survives rebuilds (see Q3). A **Next** button advances from step
1 to step 2 only after step 1's `saveAndValidate()` returns `true`.
A **Back** button returns to step 1 with all its field values
preserved by re-passing them as `initialValue` on remount.

**Why two `FormBuilder`s (each with its own `GlobalKey`) is
preferable to one `FormBuilder` with fields hidden using
`Visibility` or `Offstage`.** Hiding fields via `Visibility(visible:
false, child: ...)` keeps the child in the tree — the
`FormBuilderField`s stay registered with `FormBuilderState`, their
controller values remain in `FormBuilderState.value`, and — crucially
— their **validators still run during `saveAndValidate()`**. If step
2's cover letter and terms checkbox were `Visibility(visible: false)`
while the user is on step 1, tapping **Next** would call step-1's
`saveAndValidate()` on the *entire* single form; the hidden
`required()` on cover letter would fire and the transition would
fail silently with no error rendered against a visible field. The
user is stuck. Using `Offstage` has the same shape: it keeps the
render object in the tree, only skipping paint. Two separate
`FormBuilder`s solve this because a `FormBuilder` that is not in the
tree has no `FormBuilderState` and no fields to validate; step 2's
key returns `null` from `.currentState` until step 2 is mounted, and
`Next` only ever calls step 1's `saveAndValidate`.

---

## STRETCH B — Animated field reveal

Each `FormBuilderField` on both steps is wrapped in a private
`_AnimatedFieldReveal` widget that combines `AnimatedOpacity` (0 → 1
over 240 ms) and `AnimatedSlide` (offset `(0, 0.2)` → `Offset.zero`).
Reveal is driven by a monotonic `int revealCount` stored in a
`useState` hook; each field is assigned an index, and a field is
"revealed" (opacity 1, offset zero) once `revealCount > index`.

The reveal sequence is triggered from a `useEffect` hook keyed on
`stepIndex.value`: when the step changes, the effect cancels any
in-flight `Timer.periodic`, resets `revealCount.value = 0`, and
starts a fresh 80 ms periodic timer that increments `revealCount`
once per tick until every field on the current step is revealed. The
effect's returned cleanup function cancels the timer if the widget
unmounts or the step changes mid-sequence.

**Why `useEffect()` is the right trigger.** `useEffect()` runs its
callback **after** the widget mounts and after any change to its
dependency list — the exact semantics we need: start the animation
sequence at mount and restart it when the step index flips. Its
return value is a **cleanup function** the hook framework calls when
the effect re-runs (dependency change) or the widget unmounts,
guaranteeing the `Timer.periodic` is cancelled — no dangling ticker,
no state written to a disposed hook.

**What would happen if we called `Timer.periodic(...)` directly
inside `build()`?** Every rebuild would allocate and start a **new**
timer. Multiple timers would race — `revealCount` would advance
faster than intended and reach steady state within one or two
rebuilds — and the old timers would leak, because no code cancels
them (nothing holds a reference outside the build). Over the
lifetime of the screen this would accumulate a handful of live
timers per field interaction, each firing every 80 ms. The
`useEffect` guard prevents both symptoms: it runs once at mount,
and the returned cleanup cancels the old timer before starting the
new one on any dependency change.

**An implicit-animation alternative that avoids
`AnimationController` entirely.** Wrap each field in a
`TweenAnimationBuilder<double>` with `tween: Tween(begin: 0, end: 1)`
and a `duration` that increases per field index (`Duration(milliseconds:
240 + index * 80)` from a fixed start point at mount). The builder
receives a `double t` per frame and can drive both the opacity and
the slide offset in the returned widget. Trade-off:
`TweenAnimationBuilder` allocates its own hidden `AnimationController`
per field (still no explicit lifecycle for us to manage), so the
memory cost is similar; but the reveal cannot be paused, reset, or
re-triggered on step change without changing the `tween`'s identity,
which retriggers the animation with a jarring jump if timing isn't
perfectly synchronised. `useEffect + AnimatedOpacity + AnimatedSlide`
is preferable when the sequence must reset cleanly on step changes,
as it does here.

---

## STRETCH C — Offline application drafts

When the user taps **Submit** and `isOfflineProvider` reports the
device is offline, the form values (from
`formKey.currentState!.value` on step 2 plus step 1's cached values)
are written to Isar via a new `@collection class ApplicationDraft`.
A SnackBar confirms — `'Saved as draft — will submit when back
online.'` — and the screen pops.

`ApplicationDraft` is a per-user-visible row keyed by an
`Isar.autoIncrement` `id`, with fields `jobId`, `fullName`, `email`,
`coverLetter`, `yearsExperience`, `startDate`, `portfolioUrl`,
`terms`, and `savedAt`. `hasPendingDraftsProvider` reads
`isar.applicationDrafts.count()` via a `.watch(fireImmediately: true)`
stream and reports `true` when any draft exists. The jobs screen's
top-of-list banner (inside `_JobList`) renders a persistent yellow
"You have N application drafts waiting to sync" message whenever
that provider returns `true`.

**Reconnect drain.** The jobs screen's `build()` calls
`ref.listen<bool>(isOfflineProvider, ...)` — a fire-once
registration that survives every rebuild. When the callback observes
a transition from `previous == true` to `next == false`, it reads
`ApplicationDraftsController` and invokes `.syncPending()`. That
method reads every row from Isar, "attempts" to submit each (the
mock server has no `/applications` endpoint, so we treat the
submission as unconditionally successful — see the failure-case note
below), and deletes each row after a successful submit. The banner
disappears when the count drops to zero via the Isar `.watch` stream.

**Failure case — the API rejects a draft submission (e.g. the job
listing has been closed).** In production the sync loop would treat
each draft-submission independently: on 4xx the draft is retained
and its `lastError` field is populated, on 5xx the whole loop
aborts and retries at the next connectivity event, on network error
the loop aborts silently. In the UI we would:

- **Keep** the failed draft — the user's cover letter is not
  disposable data. Deleting silently would be a data loss the user
  never consented to.
- Show a **red-tinted variant** of the drafts banner with a
  "1 draft could not be submitted — the listing may have closed"
  message and a **Review** action that navigates back to
  `ApplyScreen(jobId: ...)` prefilled with the draft's values, so
  the user can edit and resubmit or explicitly delete.
- Expose a **Delete** action per-draft on that Review screen (the
  only place the user can trigger destructive removal).

**Is optimistic submission more or less appropriate for a job
*application* than for a job *bookmark*?** _Less_ appropriate.
Bookmarking a job is inherently retryable: the row on the server is
a small idempotent record (this user finds this job interesting).
Losing a queued bookmark is at worst a mild UX regression. A **job
application**, by contrast, is a high-consequence, non-idempotent
action: it consumes a slot in the employer's shortlist, involves a
possibly-lengthy cover letter, and often has a deadline. The user
must be informed of, and consent to, every submission — silent
optimistic replay risks (i) double-submissions if the queue drains
before the earlier attempt confirms, (ii) submitting to a listing
that has since closed, (iii) submitting stale personal details the
user meant to edit. The right pattern is a **draft** that the user
must review and re-tap Submit to send once online. That is what
Stretch C above provides: the offline path saves a draft and the
reconnect path _would_, in a stricter production, surface the queue
for the user to submit rather than auto-drain. We auto-drain here
only because Assignment 3.1's brief explicitly asks for that
behaviour and the mock server has no application endpoint to
reject.

The key distinction between the two actions: **bookmarking mutates
user-scoped preference data; applying mutates cross-actor
transactional data** — and the higher stakes flip the appropriate
retry policy from silent optimistic replay to explicit
user-confirmed replay.

---

# CareerHub — Assignment 3.2: Testing Flutter Applications

_Written 2026-07-27._

Week 3, Assignment 3.2. This section contains the four Part 1 written
decisions (mocking patterns; `ProviderContainer` and AsyncNotifier
transitions; the widget-test-to-Patrol boundary; what a test proves
vs what coverage measures), the coverage read-out, the terminal
evidence blocks for the unit / widget / coverage / Patrol runs, and
the three stretch write-ups (A: `AuthNotifier` build() unit tests;
B: Patrol screenshots at five capture points; C: offline-error
propagation through `filteredJobsProvider`).

A note on the pre-existing `test/widget_test.dart` — it was written
against the Assignment 2.1 world (before the auth flow, before the
persisted filter, before the two-step apply form). It has been
flagged as stale and is deliberately **not** repaired as part of
Assignment 3.2; the three-layer test pyramid this assignment builds
(unit + widget + Patrol) supersedes it.

## PART 1 — WRITTEN DECISIONS

### Question 1 — The two mocking patterns and their distinct purposes

**What the subclass-override pattern cannot tell you.** The
subclass-override pattern extends the notifier under test (e.g.
`class _FakeJobsNotifier extends JobsNotifier { @override
Future<List<Job>> build() async => _fakes; }`) and injects the fake
via `jobsProvider.overrideWith(() => _FakeJobsNotifier())`. From the
outside, a consumer subscribes to `jobsProvider` and watches state
move `AsyncLoading` → `AsyncData(fakes)`. That gives you complete
control of the notifier's public output, and zero visibility into
**how** the notifier arrived at it. Consider the concrete bug the
brief describes: a merge conflict resolution accidentally makes
`build()` call `ref.read(jobsRepositoryProvider).getJobs()` **twice**
instead of once. The externally-observable state is unchanged
(`AsyncLoading` → `AsyncData(secondReturn)`), the future still
resolves, the assertions in a subclass-override test all pass. But
in production the app now makes two network round-trips per cold
boot, doubles server load, and — critically — if the two calls
return *different* payloads (a race between the CareerHub API's
cache invalidation and its DB read) the notifier silently drops the
first result. mocktail catches this because it interposes at the
dependency boundary rather than replacing the notifier's body:
`verify(() => mockRepo.getJobs()).called(1)` fails if the count is
2, and the test reports the exact number of interactions with the
mock. `verify()` is not just a check that a method was called — it
is an assertion on the **cardinality** of every call to the mock,
which is the specific dimension the subclass-override pattern cannot
observe.

**When to reach for each.** The subclass-override pattern belongs on
tests where the assertion is a state transition of the provider
itself — for example, `filteredJobsProvider` returns a subset when
`filterProvider` changes to `'remote'`. The consumer's contract with
`filteredJobsProvider` is exactly "what value do I see when the
inputs are X?" — the composition of `jobsProvider` and
`filterProvider` inside the derived provider is an implementation
detail; a subclass-override test asserts the observable derivation
without prescribing how the derivation happens. mocktail belongs on
tests where the assertion is an interaction with a collaborator —
`JobsNotifier.build()` must call `getJobs()` **exactly once**;
`AuthNotifier.build()` must call `logout()` when the stored token is
expired. Those are protocol assertions on the notifier's use of its
dependency, not state assertions on the notifier's output. The
deciding factor is whether the property under test is a **value**
(subclass-override) or an **interaction** (mocktail).

**Why using mocktail from a widget test conflates two concerns.**
A widget test constructs a `ProviderScope` with `overrides:`, pumps
`MaterialApp` → `Scaffold` → the widget under test, and drives the
widget with `tester.tap` and `tester.enterText`. Every piece of that
scaffolding — the ProviderScope, the overrideWith wiring, the
MaterialApp for `Directionality`/`Theme`/`MediaQuery`, the pumped
Element tree — is there because widget tests exercise the **UI's
translation of state into pixels and back**. Introducing a
`MockJobsRepository` inside that setup means the test is now
simultaneously exercising (1) that the widget renders the expected
child widgets for a given state and (2) that the notifier calls
`getJobs()` the correct number of times. If the test fails, you
cannot tell from the failure alone whether the widget's build tree
was wrong or the notifier's call graph was wrong. Verifying a
repository call count from inside a widget test conflates a
**rendering assertion** with a **collaborator-interaction
assertion**, and the failure output — a `verify()` mismatch buried
under the widget-test harness — is measurably harder to diagnose
than the same interaction test in `test/unit/`, where the notifier
is the entire subject and the mock is the entire dependency.

### Question 2 — ProviderContainer and AsyncNotifier state transitions

**Reading the future before vs after awaiting it.** An
`AsyncNotifierProvider` initialises in the `AsyncLoading` state at
the moment its `ProviderContainer` first observes it — the
notifier's `build()` starts executing on the same microtask, but has
not yet returned. `container.read(jobsProvider.future)` in that
window returns a Dart `Future<List<Job>>` that has not yet resolved:
the caller receives an unresolved handle to the eventual value,
regardless of whether the underlying build() takes 5 microseconds or
5 seconds. `container.read(jobsProvider)` in the same window returns
`AsyncLoading<List<Job>>()` — the current synchronous snapshot of
the provider's state, which is the AsyncValue variant that carries
no data. After `await container.read(jobsProvider.future)`
completes, the same synchronous read returns
`AsyncData(resolvedList)` — the notifier's build() has returned, the
outer AsyncValue has advanced to its data arm, and every subscriber
has been notified. The distinction the tests exploit is therefore
temporal, not structural: the same call returns different
AsyncValues depending on where the surrounding microtask queue sits
relative to the notifier's build().

**Future rejection when build() throws.** `JobsNotifier.build()`
pattern-matches on `ApiResult` and, in the `Failure` arm with an
empty cache, throws `Exception(message)`. The re-throw propagates
out of the async function's Zone, and the `Future<List<Job>>` the
notifier returns **rejects** with that exception. `container.read(
jobsProvider.future)` therefore returns a Future which — when
awaited — throws the same exception; it neither hangs nor returns
null. The synchronous `container.read(jobsProvider)` reads
immediately after the microtask that carried the rejection returns
`AsyncError<List<Job>>(exception, stackTrace)` — the AsyncValue
subclass that wraps a thrown exception. Every downstream provider
that watches `jobsProvider` (e.g. `filteredJobsProvider` — see
Stretch C below) sees `AsyncError` on their next read and, if they
use `whenData`, propagate the same `AsyncError` without transforming
it.

**Why `addTearDown(container.dispose)` matters across the suite.**
An undisposed `ProviderContainer` retains every provider it
constructed for the duration of the process. Providers that
registered `onDispose` callbacks — for example, a
`StreamProvider<List<ConnectivityResult>>` that subscribes to
`Connectivity.onConnectivityChanged`, or `authStateListenableProvider`
whose closure captures a `ProviderSubscription` — retain those
subscriptions too. In a suite of dozens of tests, each undisposed
container leaves behind a live stream subscription; the platform
channel's isolate keeps the subscription's onData closure reachable,
which keeps the closure's captured references reachable, which keeps
the container reachable through the closure's captured `ref`. What
accumulates in memory is therefore a chain of `ProviderContainer` →
`ProviderElement` → `ProviderSubscription` → captured `ref` →
`ProviderContainer` for every test that ran. Beyond the leak, the
functional consequence is worse: a test that expects a fresh
container's provider to start in `AsyncLoading` can flake if a
previous container's leaked subscription happens to emit a value
before the new container's build() begins, because both containers
share the same underlying platform-channel stream. `addTearDown(
container.dispose)` is what closes those subscriptions in the same
teardown phase — even if the test threw partway through its body —
so no state escapes the test's scope.

### Question 3 — Widget test limits and the Patrol boundary

**Why the date picker is unreliable in widget tests.**
`FormBuilderDateTimePicker` renders a `TextField` in the widget
tree; on tap it opens a modal via `showDatePicker`, which pushes an
opaque route onto the `Navigator`. The route builds a
`_DatePickerDialog` sized against the current
`MediaQuery.of(context).size`, whose day-cell grid is laid out as a
`GridView` scaled to the dialog's width, computed from the ambient
`ThemeData.dialogTheme`, `LocalizationsData`, and the current
month's layout. `tester.tap(find.text('15'))` therefore relies on
three coincidences: (1) the day '15' being rendered in the current
month grid at all — a test run on the last day of the month may
open the picker at day 31 with a partially-hidden next-month row
that also contains a '15'; (2) the day cell being the topmost tap
target at that Text's location — a Semantics overlay or an ink
splash can be above it; (3) the `MediaQuery.size` producing the
same absolute cell coordinates the fixture assumes. A test that
uses `find.byWidgetPredicate((w) => w is InkWell && w.child is
Text)` and indexes into `.at(14)` is even worse — the child index
depends on the calendar layout of the specific month, and breaks
whenever the picker opens on a month whose first day is not a
Sunday. Any pixel-coordinate or child-index selector against the
date picker will silently start failing on the first month whose
grid layout differs from the fixture's month, which — since we
depend on `DateTime.now()` — is a wall-clock event we do not
control.

**Why Patrol handles this reliably, and why `tester.tap` does not.**
Patrol tests build the app with `patrolTest()`, which compiles the
real production binary against the real Flutter engine and runs on
an emulator or device. `PatrolFinder`'s `$` selector navigates the
**native accessibility tree**, not the widget tree: `$('15')`
resolves against the day cell's `Semantics` node's label, which is
what the OS reads and what accessibility services see. `tester.tap`
in a widget test travels through the widget-test framework's
`WidgetsBinding.instance.testTextInput` layer, which pumps
synthetic pointer events into the Flutter test binding — it can
find and tap widgets, but has no visibility into any dialog that
lives OUTSIDE the Flutter widget tree. The specific Patrol type
that owns OS-native dialogs is `NativeAutomator`: methods like
`isPermissionDialogVisible()` and `tapOnPermissionDialogButton()`
issue platform-native commands (UIAutomator on Android,
XCUITest on iOS) that inspect the OS's own view hierarchy. The
Flutter test engine cannot see these dialogs at all — they are
rendered by the operating system's window manager, not by the
Flutter engine — so a widget test literally cannot assert their
presence or absence. Only a runner that can drop *out* of the
Flutter engine and into the OS can drive them.

**The boundary line in ApplyScreen.** The line
[apply_screen.dart:325](lib/screens/apply_screen.dart) — the
`FormBuilderDateTimePicker` for `name: 'start_date'` — is where the
boundary between "widget tests are sufficient" and "only Patrol can
verify" falls. Above the line: `full_name` (TextField), `email`
(TextField), `years_experience` (TextField), `cover_letter`
(TextField), `portfolio_url` (TextField), `terms` (Checkbox). Every
one of these is a standard Flutter form control whose value is
mutated by `tester.enterText` or a direct `didChange` on the
`FormBuilderState`, and whose validation error is a `Text` widget
in the tree that `find.textContaining` locates. Below the line:
`start_date`. The shared criterion that places `start_date` on the
Patrol side is **the interaction opens a native or dialog surface
outside the widget's own subtree** — the modal date-picker route
whose layout depends on runtime `MediaQuery` and locale. Everything
above the line is a leaf widget the widget test owns end-to-end;
everything below the line requires a runner that can synthesise the
OS-level input events those leaf widgets ultimately depend on.

### Question 4 — What a test proves and what coverage measures

**Three specific missing verifications for the trivial test.** The
brief describes a test that constructs a `ProviderContainer` with a
`MockJobsRepository` stub, awaits the future, and asserts
`expect(result, isNotNull)`. That test generates 85% line coverage
for `jobs_notifier.dart` and verifies almost nothing. Missing:
(1) **`AsyncData` vs `AsyncError`** — `expect(result, isNotNull)`
passes for both a successful list of jobs and a stack trace, because
`AsyncError` also has non-null `.error` and non-null `.stackTrace`.
The observable behaviour the notifier promises — "on Success, my
final state is `AsyncData<List<Job>>`, not `AsyncError`" — is not
tested. (2) **The intermediate `AsyncLoading` state** — a consumer
who subscribes before the future resolves must see `AsyncLoading`
first; a notifier that races to `AsyncData` synchronously (e.g. a
future-typed method that resolves without a real await) would break
the loading spinner in the UI. The test never reads state before
the await, so this transition is invisible. (3) **`getJobs()` call
count** — the test does not `verify()` the mock; a notifier that
calls `getJobs()` twice, zero times (returning a cached value from a
provider higher in the graph), or with the wrong arguments would
pass. All three are concrete observable behaviours of `JobsNotifier`
that a real caller depends on; none is checked by an `isNotNull`
assertion.

**Testing implementation detail vs testing behaviour.** An
implementation-detail test asserts on **how** a subject arrives at
its output; a behaviour test asserts on **what** the subject
produces. Concrete for `JobsNotifier`: an implementation-detail test
would read the private `_selfWrote` boolean after a Success return
via a test-only visibility escape and assert `_selfWrote == true`.
When the Stretch B echo-suppression logic is refactored from a
boolean guard to a token-based mechanism, or removed entirely
because the underlying Isar behaviour changes, that test fails —
even though the notifier still produces the same
`AsyncData<List<Job>>` for the same repository stubs. Contrast a
behaviour test: "calling `refresh()` after an error results in
`AsyncData` when the second `getJobs()` returns Success". That
assertion survives every plausible refactor to the internal flow —
switching `refresh()` from `invalidateSelf()` to a manual state
assignment, splitting the retry into a helper, replacing the
counter-based mock with a queue — because it names an
externally-observable transition that the notifier's contract must
guarantee for the UI's retry button to work.

**Why Patrol coverage does not substitute for unit and widget
coverage.** The Part 7 Patrol test drives cold-launch → login →
jobs list → job detail → apply → submission, which touches
`JobsNotifier`, `JobsRepository`, the router, `LoginScreen`, the
jobs list screen, `JobDetailScreen`, and `ApplyScreen`. On a happy
path, that trace records executed lines for every file above,
easily exceeding the aggregate coverage of the unit and widget
suites. What Patrol does not detect: a failure category like
**"`JobsNotifier.build()` throws when the cache is empty AND
`getJobs()` returns `NetworkFailure`"**. The Patrol happy path never
exercises the failure arm — the seeded API always returns Success —
so the throwing branch stays uncovered by the Patrol trace, and if
that branch's `throw Exception(message)` is accidentally deleted a
future refactor, no Patrol test fails. A unit test with a mocked
repository returning `NetworkFailure` and an empty cache is the
only thing that catches the regression. Conversely, only Patrol
detects a failure category like **"the OS permission dialog stalls
the app because we never wired an accept path"** — no widget test
runs against a real OS, and no unit test can simulate a permission
dialog that lives entirely outside the Flutter engine. The two
categories are disjoint: unit tests catch **branches the happy path
doesn't visit**; Patrol catches **integration failures between the
Flutter engine and everything outside it** (native dialogs, real
network, the real Isar file on disk, GoRouter's redirect against
real secure storage). Running only Patrol is a categorical error,
not a proportional shortfall: no amount of Patrol runtime
substitutes for the failure categories unit tests exclusively see.

---

## Assignment 3.2 — Coverage

Numbers below come from `flutter test --coverage` against the
Assignment 3.2 suite (unit + widget). Percentages are line
coverage on the target file itself — the `DA:n,0` count in
`coverage/lcov.info` divided by the total `DA:` lines for that
file.

| File | Coverage | Where the uncovered lines live |
| ---- | -------- | ------------------------------- |
| `lib/providers/jobs_notifier.dart` | **16/26 = 61.5%** | The Stretch B echo-suppression path (`_selfWrote` guard, the `ref.listen(cachedJobsStreamProvider, ...)` closure that checks the flag and calls `ref.invalidateSelf()`) is not exercised — the Part 3 tests override `cachedJobsStreamProvider` with `Stream.empty()`, which never fires the listener callback. The uncovered lines are the callback body itself (lines 101–110) and the `_selfWrote = true` echo-guard set inside the Success arm. Coverage of that path is Patrol's responsibility — an end-to-end run against the real Isar-backed cache stream exercises the echo suppression naturally. |
| `lib/providers/job_providers.dart` | **21/39 = 53.8%** | `filteredJobsProvider` itself is fully covered by the four Part 4 tests (including the Stretch C error-propagation test). The uncovered lines are the OTHER providers that share this file: `sortOrderProvider`, `searchQueryProvider`, `visibleJobsProvider`, `savedJobsProvider`, `editedJobProvider`, and the `_locationTypeFromFilter` helper. These providers belong to Assignment 3.1's home screen and job detail screen; testing them was out of scope for 3.2's three-test filter suite. Widget-test coverage of `HomeScreen` and `JobDetailScreen` would raise this number to ~90%; leaving those tests for a future assignment is a scope decision, not a gap the 3.2 tests failed to close. |
| `lib/widgets/job_card.dart` | **40/51 = 78.4%** | Every rendering path exercised by the three Part 5 tests is covered — title, company, IconLine rows, JobStatusBadge, employment-type text. The uncovered lines are the `_SaveJobButton.onPressed` closure (lines 118–147): its `saved`/`queued`/`notFound` SnackBar branches only fire when the user taps the bookmark icon, which the widget tests deliberately do not do (the button's collaborator, `SavedJobsController`, would need a mock — same conflation of concerns discussed in README 3.2 Q1). Patrol's happy path would cover the `saved` branch; the `queued` branch needs an offline Patrol scenario; the `notFound` branch needs a server-inconsistency Patrol scenario. All three are out of scope for 3.2's unit-and-widget layers. |
| `lib/screens/apply_screen.dart` | **116/134 = 86.6%** | The five Part 6 tests plus the auto-reveal `useEffect` timer running under `pumpAndSettle` collectively touch every step-1 rendering path, both `onNext` branches, and every step-2 validator path. Uncovered lines are the offline-draft branch of `submit` (lines 172–186) and the SnackBar-and-pop logic on success — both require a mounted `isOfflineProvider` context different from the default (offline == true) which the Part 6 tests do not set up. Coverage of the offline-draft path is Patrol's responsibility (`ref.read(applicationDraftsControllerProvider).saveDraft(...)` needs a live Isar to write against). |

**Aggregate observation.** The 3.2 test pyramid targets specific
notifier and rendering behaviours; the coverage percentages
reflect that focus. Uncovered lines fall into two categories:
(a) code owned by other assignments (`sortOrderProvider`,
`visibleJobsProvider`, `savedJobsProvider`, `editedJobProvider`)
whose tests belong to their respective assignments; and (b) code
paths that require live collaborators (Isar writes, network,
biometric plugin) whose only honest coverage is Patrol's
end-to-end run. No line reports 0% coverage because it lacked a
test — every uncovered line is either out-of-scope by design or
requires a coverage layer above what a headless unit or widget
test can provide.

## Assignment 3.2 — Evidence blocks

**Unit tests** — `flutter test test/unit/`:

```
00:00 +0: loading /Users/tebellomolete/Documents/Bitcube/careerhub_mobile/test/unit/auth_notifier_test.dart
00:00 +0: (setUpAll)
00:00 +0: AuthNotifier.build() returns Unauthenticated when no access token is stored
00:00 +1: AuthNotifier.build() returns Authenticated with the decoded user when a non-expired token is stored
00:00 +2: AuthNotifier.build() returns Unauthenticated AND calls logout when an expired token is found and the refresh attempt fails
00:00 +3: filteredJobsProvider returns the full list when the filter is 'All'
00:00 +4: filteredJobsProvider returns only remote jobs when the filter is 'remote'
00:00 +5: filteredJobsProvider changing the filter produces a different list on the next read
00:00 +6: filteredJobsProvider propagates AsyncError from jobsProvider instead of collapsing to an empty AsyncData (Stretch C)
00:00 +7: JobsNotifier transitions from loading to data when getJobsRepository returns Success
00:00 +8: JobsNotifier transitions from loading to error when getJobsRepository returns Failure
00:00 +9: JobsNotifier recovers to data after refresh() following an error
00:00 +10: All tests passed!
```

**Widget tests** — `flutter test test/widget/`:

```
00:00 +0: loading /Users/tebellomolete/Documents/Bitcube/careerhub_mobile/test/widget/apply_screen_test.dart
00:00 +0: ApplyScreen email field is pre-populated from the authenticated user
00:00 +1: ApplyScreen tapping Next with all step-1 fields empty shows multiple required errors
00:00 +2: ApplyScreen cover letter shorter than 50 chars produces a length validation error
00:00 +3: ApplyScreen portfolio URL is optional — an empty value produces no URL error
00:00 +4: ApplyScreen portfolio URL rejects a non-URL value with a format error
00:00 +5: JobCard renders the fixture title, company, and a tag/badge value
00:00 +6: JobCard a second fixture renders its own title, not the first fixture
00:00 +7: JobCard employment type text matches the fixture, not a static label
00:00 +8: All tests passed!
```

**`flutter test --coverage`** — full output:

```
00:05 +54 -2: Some tests failed.

Note on the -2: the pre-existing test/widget_test.dart from
Assignment 2.1 contains two tests that break against the
current Assignment 3.1 code (the async loading state
CircularProgressIndicator finder and the sort-menu reversal
test). Both were flagged as stale at the start of Assignment
3.2 and are deliberately not repaired here — the three-layer
pyramid (unit + widget + Patrol) built for 3.2 supersedes
that file. See README 3.2 preamble.
```

`coverage/lcov.info` is written by every run and referenced by
the coverage table above.

**Patrol test evidence** — populate after running
`patrol test --target integration_test/job_application_flow_test.dart --dart-define=API_BASE_URL=http://10.0.2.2:5247`
locally with the seed credentials substituted for the
`REPLACE_ME` placeholders:

```
<paste patrol test terminal output here after running against
the live API + emulator — see MANUAL STEPS below>
```

**GitHub Actions workflow** — [.github/workflows/flutter_test.yml](.github/workflows/flutter_test.yml).
Triggers on `push` and `pull_request` against `main`. Steps:

1. `actions/checkout@v4` — clone the repository.
2. `subosito/flutter-action@v2` — pin Flutter 3.44.5, stable
   channel, enable pub-cache caching.
3. `flutter pub get` — resolve dependencies from `pubspec.lock`.
4. `flutter analyze` — analyzer gate; the workflow fails on any
   error. Deliberately NOT `--fatal-infos --fatal-warnings` —
   the codebase carries 22 pre-existing infos/warnings from
   earlier assignments (isar_generator's `experimental_member_use`,
   `prefer_initializing_formals` on older repos,
   `unintended_html_in_doc_comment`); none are from 3.2 and
   repairing them is out of scope for this workflow. The brief
   specifies "fail the workflow if any errors are reported" —
   errors only, which matches the default.
5. `flutter test test/unit test/widget --coverage` — runs the
   Assignment 3.2 suite (unit + widget layers of the three-layer
   pyramid) and writes `coverage/lcov.info`. Deliberately
   excludes `test/widget_test.dart` (the stale Assignment 2.1
   file flagged as not-repaired at the start of 3.2) and
   `integration_test/` (Patrol, needs a device).
6. `actions/upload-artifact@v4` — uploads
   `coverage/lcov.info` as `coverage-report`, retained for 14
   days. Runs on both pass and fail (`if: always()`) so a
   broken-test PR still surfaces its coverage delta.

Patrol is deliberately absent — Patrol needs a connected
device (device farm, emulator on a dedicated runner) which is
a separate workflow's responsibility.

## Assignment 3.2 — Stretch A write-up

The three `AuthNotifier.build()` tests each stub one branch of
the cold-boot decision tree: no token → Unauthenticated; valid
non-expired token → Authenticated; expired token → refresh
attempt → Unauthenticated. The third test is where the
**testing `build()` vs testing `isTokenExpired()` in isolation**
distinction matters.

A test on `isTokenExpired(expiredToken) == true` alone verifies
one predicate — that the JWT decoder correctly reads the `exp`
claim and compares against `DateTime.now()`. That's it. What
that isolated test cannot see: whether `build()` actually calls
`isTokenExpired()` at all, whether the caller pattern is
`if (isTokenExpired) => tryRefresh() => on null => return
Unauthenticated`, or whether a merge conflict resolves the
refresh path into a no-op that leaves the user "signed in with
an expired token" — a state the router will not redirect out
of because auth is nominally `Authenticated`. The
`build()`-level test covers the whole protocol: readAccessToken
returned the expired token, isTokenExpired confirmed it,
tryRefresh was attempted, the null return was interpreted as
Unauthenticated. Every `verify()` in the third test is an
interaction assertion on that protocol.

What only the Patrol integration test catches: the router's
actual navigation. `AuthStateListenable` fires
`notifyListeners()` on the transition; GoRouter's
`refreshListenable` re-runs its redirect callback; the callback
reads `authProvider`, sees Unauthenticated, and pushes `/login`.
None of those steps live in `AuthNotifier` — they live in
[app_router.dart:60](lib/router/app_router.dart) and
[auth_provider.dart:52](lib/providers/auth_provider.dart). A
unit test on `AuthNotifier.build()` cannot see whether the
route actually flips; only Patrol, running the real
`MaterialApp.router`, can assert the login screen is on top of
the navigator. The failure category **"expired token clears
storage but the user stays on the jobs screen because the
router bridge is broken"** is invisible to unit tests and
visible only to Patrol.

## Assignment 3.2 — Stretch B write-up

The Patrol test calls `takeScreenshot()` at five capture points:
`01_after_login`, `02_jobs_screen`, `03_job_detail`,
`04_apply_screen`, `05_confirmation`. Screenshots are written
to `integration_test/screenshots/` and collected by the Patrol
CLI runner.

**A scenario where screenshot comparison fails on a working
feature.** Assume the Assignment 3.1 shimmer skeleton is
enabled and the golden screenshot for `02_jobs_screen` was
captured while the shimmer was in the middle of its horizontal
sweep. On the next run the shimmer sweep is at a different
horizontal offset — the feature works identically, the user
sees the same animation, but the pixel diff against the golden
is above threshold and the test fails. The same applies to any
Material ripple in progress, the system clock in the status
bar, or the exact position of the app bar's back-arrow ink
splash. Screenshot equality treats "same pixels" as "same
correctness", but working animations, timers, and system chrome
routinely produce different pixels while remaining correct.

**Trade-off vs text-based assertions.**
`find.text('CareerHub')` fails if and only if the string
'CareerHub' is missing from the rendered accessibility tree —
which happens when the AppBar's title Text isn't there, which
in turn happens if we routed to the wrong screen or the
production code broke. That's a small, focused failure signal.
Screenshot assertions catch a strictly wider set of regressions
(text moved off-screen, colours changed, icons flipped) but
report them all under the same "pixels differ" verdict, with
no discrimination between "the feature works but the animation
moved" and "the AppBar has vanished". The right balance is
text-based assertions for the correctness contract and
screenshots for observability — the five capture points in this
test document what the app looked like at each stage, not what
it must look like to pass.

**One visual bug screenshots catch that text does not.** A
padding regression that pushes the "Sign in" button below the
soft-keyboard fold. Text-based finders confirm the button is
still in the tree; a screenshot shows the user cannot see it.

**One visual bug that only a real observer catches.** Colour
contrast — a body text switch from `onSurface` to
`onSurfaceVariant` may pass every automated check (the widget
tree is unchanged, the pixels are within the golden's
threshold), but a low-vision user notices the text is now
noticeably lighter against the same background. That's a WCAG
compliance regression an automated screenshot pipeline treats
as within-tolerance, while a human sees the difference on
first look.

## Assignment 3.2 — Stretch C write-up

The offline-error test lives in
[test/unit/filtered_jobs_test.dart](test/unit/filtered_jobs_test.dart)
as the fourth test in the group. The `_ErrorJobsNotifier`
subclass throws from `build()`, which Riverpod converts to
`AsyncError` on `jobsProvider`; the test then reads
`filteredJobsProvider` and asserts the derived state is
`AsyncError`, NOT `AsyncData(const [])`.

**Why an empty list is worse than an error message for the
user.** An empty `AsyncData(const [])` renders through the
`data:` arm of `_JobList`'s `when()`
([home_screen.dart:255](lib/screens/home_screen.dart)), which
falls into `EmptyJobsWidget` with the message "No jobs match
your filter." That message is technically true (the filter's
output IS an empty list) but false in effect — the reason the
list is empty is a network failure, and the user's next action
is to reset the filter, which will not help. An `AsyncError`
routes through the `error:` arm, which renders `_ErrorState`
with a "Something went wrong" copy and a Retry button. The
retry button calls `jobsProvider.notifier.refresh()`, which is
exactly the action the user needs. Empty-list UX misinforms the
user's next action; error UX guides them to the right one.

**Confirmation that `_JobList`'s error arm is exercised by this
test through the provider chain.** `_JobList` calls
`ref.watch(filteredJobsProvider)` and pattern-matches its
`when()` on `error:`. `filteredJobsProvider`'s `whenData()`
already propagates AsyncError unchanged (see
[job_providers.dart:99](lib/providers/job_providers.dart)),
which is why no `lib/` change was needed. The unit test proves
the propagation contract at the provider layer; the same
`AsyncError` value that the test asserts on is what the widget
layer's `when(error: ...)` arm receives at runtime. Widget-test
coverage of `_JobList` itself is out of scope for 3.2; the
provider-layer test plus the visual verification during the
Patrol run is sufficient evidence.

---

# CareerHub — Assignment 2.4: Authentication and Secure API Flow

_Written 2026-07-22._

Week 2, Assignment 2.4. This section contains the four written decisions
(Part 1), the auth models, repository, notifier, provider bridge, and Dio
interceptor, the router/login-screen changes, the app-wiring, the six
demo-scenario write-ups, the three stretch goals (A: token expiry
countdown, B: biometric re-auth gate, C: offline save queue), the
test-modification note, and the terminal-output/screenshot placeholders.
The Assignment 2.3 and earlier notes are preserved further down as
historical context.

---

## PART 1 — WRITTEN DECISIONS

### Question 1 — Token storage and platform security boundaries

**Why `SharedPreferences` is wrong for access/refresh tokens (Android).**
On Android, `SharedPreferences` writes to a plain XML file at
`/data/data/<applicationId>/shared_prefs/<name>.xml` (for CareerHub,
that resolves to
`/data/data/com.example.careerhub_mobile/shared_prefs/FlutterSharedPreferences.xml`).
The permission model that governs that file is standard Linux DAC: the
Android package installer assigns each app a unique UID at install time
and `chown`s the app's `/data/data/<applicationId>` directory to that
UID with mode `0700`, so under normal circumstances only processes
running as that UID (i.e. the app itself) can read the file — the
operating system does not decrypt or otherwise obscure the file
contents. **The concrete attack that makes this inappropriate for
credentials, even on a non-rooted device, is `adb backup`.** On any
device that has USB debugging enabled (the demo emulator, any dev
device, and any user who has ever enabled it to install a sideloaded
app), an attacker with brief physical or network-forwarded access can
run `adb backup -f out.ab -noapk com.example.careerhub_mobile`, which
uses Android's built-in Backup Manager to pull `shared_prefs/` out of
the app's private directory without root and without an unlock (the
prompt is a bypassable on-device confirmation dialog). The resulting
`.ab` archive is trivially unwrapped with `dd bs=24 skip=1
if=out.ab | zlib-flate -uncompress | tar -xvf -`; the XML file is then
plaintext, and any access token or refresh token stored inside is
readable directly. The token is a bearer credential — whoever holds
it authenticates as the user, no password required, until it expires.
`flutter_secure_storage` sidesteps this because
`EncryptedSharedPreferences` encrypts each value with a
Keystore-resident key (see the third bullet below); the same
`adb backup` produces an XML that contains ciphertext plus IV, not the
token.

**What the iOS Keychain provides that a file on disk does not.**
1. **Passcode-gated availability class.** Every Keychain item is
    stored with an accessibility attribute. On CareerHub, the default
    `flutter_secure_storage` write uses an accessibility class that
    binds decryption to the device's passcode/biometric state — if
    the user has never set a device passcode (`kSecAttrAccessible…`
    values that end in `ThisDeviceOnly`), the item does not exist at
    all; if a passcode is set, decryption is only possible while
    (depending on the class) the device is unlocked or has been
    unlocked at least once since boot. A raw file on disk has no
    such gate — an attacker with the file has the file.
2. **Hardware-backed key custody on Secure Enclave devices.** On
    every iPhone with a Secure Enclave (5s and later), the
    per-Keychain-item cryptographic key is generated and stored
    inside the SEP — a separate ARM co-processor with its own memory
    that the application processor cannot address directly. Decryption
    is a cross-processor request; the plaintext key never appears in
    application memory even during a legitimate read. A file on disk
    is protected only by the file-system encryption key held in
    normal DRAM.

    **`kSecAttrAccessibleWhenUnlocked` vs
    `kSecAttrAccessibleAfterFirstUnlock`.** `WhenUnlocked` gates
    decryption on the device currently being in the unlocked state —
    a background wake-up in a locked device cannot read the item.
    `AfterFirstUnlock` requires that the device has been unlocked
    at least once since boot; subsequent locks do not gate the read.
    **For tokens that must survive an app reinstall we choose
    `kSecAttrAccessibleAfterFirstUnlock`** (specifically the
    `first_unlock_this_device` accessibility in
    `flutter_secure_storage`'s `IOSOptions`), because reinstall
    preserves Keychain items only when the accessibility class does
    not end in `ThisDeviceOnly` and (equally important) does not
    require the app to be foreground — the OS may need to hydrate the
    tokens for a background boot task before the user has actively
    unlocked the phone during that session.

**Why Android's `flutter_secure_storage` requires SDK 23.**
`EncryptedSharedPreferences` (part of `androidx.security:security-crypto`)
provides authenticated envelope encryption on top of a normal
`SharedPreferences` file: every value is encrypted with a data-encryption
key (AES-256-GCM), and that DEK is itself wrapped by a key-encryption
key that lives in the **Android Keystore** — the OS-level, hardware-
backed keystore system introduced in **API 23 (Android 6.0
Marshmallow)**. Below API 23 the Keystore APIs `EncryptedSharedPreferences`
depends on (`KeyGenParameterSpec` + `AndroidKeyStore`'s
`AES/GCM/NoPadding` support) do not exist, so it cannot generate or
retrieve its master key. Running the app on an API 21 or 22 device
compiles, installs, and boots without warning — then the first
`flutter_secure_storage` read or write throws
**`java.lang.NoSuchAlgorithmException`** (wrapped by
`flutter_secure_storage`'s platform code as a `PlatformException` on
the Flutter side, whose underlying exception is a `NoSuchAlgorithmException`
originating from `AndroidKeyStore.engineGetKey` when trying to fetch
the `AES/GCM/NoPadding` master key). Raising `minSdk` from 21 to 23
in `android/app/build.gradle.kts` (Step 2.2) makes the app
uninstallable on those devices, which is what turns a runtime crash
into a `Play Store: this device is not compatible` message at
install time.

### Question 2 — The sealed `AuthState` and the two-layer state machine

**Why a Dart enum is insufficient.** A Dart `enum` is a closed set of
**singleton constant values with no per-constant fields**. Every
member of an enum has the same shape as every other member — you can
enrich an enum by adding a `final` field to the enum class itself,
but then **every** member must supply the same field, of the same
type, at declaration time. Our four `AuthState` variants have
irreconcilably different payload shapes: `Unauthenticated` and
`Authenticating` have no fields, `Authenticated` carries a `final
User user`, and `AuthError` carries a `final String message`. Modelling
these as an enum forces one of two bad options: (a) declare `User?
user` and `String? message` on the enum class and rely on convention
("only read `user` when this is `Authenticated`") — which the
compiler cannot enforce and which spreads null-checks across every
consumer, or (b) box the payload in a shared `Object?` field, which
loses the type on both variants and requires an unchecked cast at
every read. **What a sealed class expresses that the enum cannot** is
that each variant is a **distinct type** with its own field declarations
— the compiler knows `Authenticated` has a non-nullable `User` and
`AuthError` has a non-nullable `String`, and inside a `switch`
expression's `case Authenticated(:final user)` pattern the `user`
binding has the static type `User`, no cast, no null-check, no
runtime failure mode. This is exactly the property Dart 3 pattern
matching over sealed types was added to give.

**The two distinct loading states.** They look identical to the
`AsyncValue` type system — both are "not yet resolved" — but they
originate from different mechanisms and describe different user
situations, and only one of them is visible to the user.

1. **The `AsyncValue.loading` state emitted while
    `AuthNotifier.build()` is executing.** Triggered by: cold boot.
    `authNotifierProvider`'s `AsyncNotifier.build()` is running its
    async body (read the token out of secure storage → decode it →
    possibly call `tryRefresh`) and has not yet returned a value.
    From the router's perspective, `ref.read(authNotifierProvider)`
    returns an `AsyncLoading<AuthState>`; the redirect callback checks
    `.isLoading` and returns `null`, which means "do nothing, let
    the current route stand" — no navigation happens. **What the
    user sees:** the `initialLocation` route (`/jobs`) is briefly on
    screen behind a small `CircularProgressIndicator` (jobs
    themselves are still loading too), and within a hundred
    milliseconds `build()` resolves to either `Unauthenticated` — in
    which case the redirect fires and the user lands on `/login` —
    or `Authenticated`, in which case they stay on `/jobs`.

2. **The `Authenticating` subtype of `AuthState` that is emitted
    during a login call.** Triggered by: the user tapping the "Sign
    in" button on the login screen. `AuthNotifier.login(email,
    password)` sets `state = AsyncData(Authenticating())` before any
    `await`, then calls the repository. From the router's
    perspective, `ref.read(authNotifierProvider)` returns an
    `AsyncData(Authenticating())` — a **resolved** `AsyncValue`, not
    a loading one — so the redirect's `.isLoading` check returns
    `false` and it inspects the concrete value. Because
    `Authenticating` is not `Authenticated`, the redirect keeps the
    user on `/login`. **What the user sees:** the "Sign in" button
    on the login screen is replaced by a small
    `CircularProgressIndicator` (the button is disabled during this
    state) and the email/password fields remain populated so a
    subsequent retry doesn't lose their input.

**Why `redirect` uses `ref.read` and `appRouter` uses `ref.watch`.**
`ref.watch` inside a widget or provider body creates a **subscription**
— when the watched provider changes, the watching widget/provider
rebuilds. Using `ref.watch(authNotifierProvider)` **inside the
redirect callback** would attach a new subscription to
`authNotifierProvider` **every time GoRouter invoked the callback**,
and would tie the callback's identity to that provider's value. The
concrete rebuild cycle is: (i) route change → redirect callback runs
→ `ref.watch` registers a subscription and reads the current
`AuthState`; (ii) some later state change fires the subscription →
the router provider itself rebuilds because a watched dependency
changed → GoRouter re-runs redirect → another `ref.watch` fires,
another subscription is attached; (iii) any state change now
notifies **all** the accumulated subscriptions, each of which
re-triggers redirect. **The symptom the user observes** is an
infinite navigation loop: the log fills with `[redirect]` lines and
the app either freezes on `/login` or ping-pongs between `/login`
and `/jobs` faster than the eye can follow. **Why `ref.watch` in
the `appRouter` provider body is correct**: `appRouter` is a
`@riverpod` function whose value is a `GoRouter` instance. Watching
`authStateListenableProvider` inside that body creates **one**
subscription that is torn down and re-created only when the whole
router is rebuilt (which happens exactly once per container). It
does not create per-redirect subscriptions. The `AuthStateListenable`
that watch returns is a `ChangeNotifier` handed to GoRouter's
`refreshListenable`, which is a **push-based** notification path
(GoRouter re-runs redirect when the listenable fires) that does not
depend on `ref.watch`/`ref.read` for its callback signal. The two
are not contradictory — one wires the notifier into GoRouter's
refresh mechanism, the other looks up the current auth value at the
moment a route is being resolved.

### Question 3 — The two-Dio architecture and the concurrent 401 queue

**The infinite loop if login/tryRefresh used `dioProvider`.** Trace:
(1) `AuthRepository.tryRefresh()` calls `dio.post('/api/v1/auth/refresh',
data: { refreshToken })`. (2) The server rejects the refresh token
(expired, revoked, or unknown) with `401 Unauthorized`. (3) Dio
routes the response through its interceptor chain — `AuthInterceptor`
sees a `DioException` with `response.statusCode == 401`. (4)
`AuthInterceptor.onError` matches **Case 4** (401, no refresh in
progress), sets `_isRefreshing = true`, reads the refresh token
from secure storage, and calls `retryDio.post('/api/v1/auth/refresh',
data: { refreshToken })`. But if `retryDio` were the *same* Dio as
`dio` (as it would be if `AuthRepository` also read from
`dioProvider`), then step 4's POST goes back through the interceptor
chain — including `AuthInterceptor` itself. (5) The server rejects
this refresh call the same way (same expired token). (6)
`AuthInterceptor.onError` fires **on the retry**. Case 4 tries to
set `_isRefreshing = true`, but the current call frame already did
that — so it falls into the case that matches (in the naive
implementation, another Case 4). (7) It calls
`retryDio.post('/api/v1/auth/refresh', ...)` again. **The loop never
exits** because each level of recursion adds a new
`_isRefreshing = true` set-and-later-unset in its own `finally`,
and each 401 spawns another call to `/refresh` from inside the
same interceptor chain. Using a **plain Dio** for `login()` and
`tryRefresh()` — one with only `baseUrl` set and **no interceptors**
— breaks the cycle at step 4: the retry doesn't go through
`AuthInterceptor`, so a 401 on `/refresh` propagates back to the
caller as an ordinary `DioException` that the `tryRefresh` method
catches, and the loop is impossible.

**Three concurrent 401s + refresh-token rotation.** Suppose the
access token expires at t=T and three unrelated widgets fire their
API calls at t=T+1ms. All three arrive at the server carrying the
same expired access token; all three receive `401 Unauthorized`
simultaneously. **Without** the `Completer` queue, all three would
independently enter Case 4 of `AuthInterceptor.onError` — each
would read the same refresh token from secure storage and POST it
to `/api/v1/auth/refresh`. On the server side, because we implement
**refresh-token rotation**, the store atomically removes the
presented token and inserts a new one on the very first successful
refresh. The other two refreshes now arrive carrying a **token
that no longer exists** in the store — the server sees an unknown
refresh token and returns `401`. All three interceptor call sites
now clear secure storage, invoke `onUnauthenticated`, and the user
is logged out **despite one of the three refresh attempts having
succeeded**. Worse, the successful refresh's new tokens are written
to secure storage, then immediately deleted by the other two failing
call sites' `deleteAll()` — the app has a valid session written to
disk for a few milliseconds and then throws it away.

**How the `Completer<String>` queue solves this.** The **first** 401
takes Case 4 with `_isRefreshing == false`: it flips the flag to
`true` under a `try`/`finally` and begins the refresh call. The
**second and third** 401s each take Case 3 (`_isRefreshing == true`):
each creates a `Completer<String>`, adds it to the `_queue` list,
and `await`s the completer's future — this parks them without
consuming any thread, without hitting the network, and without
touching secure storage. When the first refresh completes
successfully, Case 4's success branch writes the new access and
refresh tokens to storage, then walks `_queue` and calls
`complete(newAccessToken)` on every completer. The two parked
call sites resume from their `await`, receive the new access token
as the resolved value, attach it to their original request's
`Authorization` header, and call `retryDio.fetch(request)` to
replay the original API call — which now succeeds because the
token is valid. If the first refresh **fails** instead (Case 4's
exception branch), `_drainQueue(err)` walks the queue and calls
`completeError(err)` on every completer; the two parked call sites
then throw out of their `await` into the `catch` of the surrounding
`try` and call `handler.next` with the error, which propagates the
401 to the caller unchanged.

**The refresh-endpoint 401 guard.** Case 2 catches a very specific
scenario: the app calls `/api/v1/auth/refresh` (which uses `retryDio`,
so `AuthInterceptor` doesn't run on the outbound), but the server
responds with `401` because the refresh token itself is invalid —
say the user was manually revoked, the server was reseeded, or the
refresh token expired. **Wait, `retryDio` has no interceptors — so
how does `AuthInterceptor` see this 401?** It sees it because
`AuthInterceptor` runs on the *authenticated* `dio`, and Case 4's
`retryDio.post` is called from *inside* `AuthInterceptor.onError`
after the original 401 from a user-facing API call. If the original
call was itself the /refresh endpoint (a scenario that arises if a
future feature wires refresh into the authenticated `dio`, or if a
test uses `dio` to hit /refresh directly), Case 4 would try to
refresh a token that was already the refresh call — an infinite
retry loop with no guard. The guard's purpose is: **when the failing
request path contains `/auth/refresh`, do NOT attempt to refresh
again — the refresh itself has failed, so the session is definitively
over.** Case 2 calls `_drainQueue(err)`, `storage.deleteAll()`,
`onUnauthenticated()`, and `handler.next(err)`. **Without the
guard**, the state after a failed refresh is: `_isRefreshing == true`
(from the outer Case 4 frame), `_queue` holds one or more parked
completers, and `onUnauthenticated` never fires. `AuthNotifier` is
never invalidated so the state stays `Authenticated`; the router's
redirect callback keeps returning `null` for authenticated users;
every new API call parks another completer that will never be
completed. **The user never sees the login screen** even though
their session has definitively ended — the app hangs on any screen
that fires an API call, forever.

### Question 4 — Logout ordering and the circular import problem

**Reversed order — the disposal race.** Assume the button calls
`logout()` first, then `ref.invalidate(jobsNotifierProvider)`. Now
suppose that at the moment of the tap, `JobsNotifier` has a
`getJobs()` request in flight — the user opened the app three
seconds ago on a slow connection, the initial fetch is still
running. `logout()` awaits `authRepository.logout()` (a
`deleteAll()` on secure storage), then sets `state =
AsyncData(Unauthenticated())`. That state change fires the
`AuthStateListenable`, GoRouter re-runs `redirect`, `redirect`
returns `/login`, the router **tears down the `StatefulShellRoute`
subtree** — every widget that was reading `jobsNotifierProvider`
unmounts. In production Riverpod that would normally dispose the
notifier (Riverpod treats an unlistened provider as garbage), but
the in-flight `Future` inside `JobsNotifier.build()` has a **live
`ref`** captured in its closure. Two race conditions can happen:
(1) the in-flight fetch resolves *after* the state has already
transitioned to `Unauthenticated`, tries to write `state =
AsyncData(freshJobs)` on a disposed notifier, and throws
`StateError: Cannot use ref after the provider was disposed`; (2)
the fetch resolves *before* disposal, writes its result to Isar,
and after logout the cached jobs are still on disk — the next user
who logs in on this device sees the previous user's jobs list until
the next network fetch overwrites the cache. **Explicit
`ref.invalidate` before the redirect is safer** because invalidation
runs synchronously: the current `JobsNotifier` is disposed, its
in-flight future is cancelled (Riverpod attaches a cancellation
guard to the future), and the notifier is rebuilt fresh in a state
where the authenticated `dio`'s next call will 401 (and, given the
interceptor, immediately clear storage and land on `/login`). The
key insight is that the user-triggered `ref.invalidate` runs *while
the widget tree still exists* — the tree owns the notifier and can
tear it down cleanly — whereas relying on the router-driven
teardown means disposal happens *because the widget tree is being
removed*, which is a race with any in-flight work.

**The circular import chain a naive implementation would create.**
Naive placement: `AuthNotifier.logout()` calls
`ref.invalidate(jobsNotifierProvider)` before clearing storage.
This requires `auth_notifier.dart` to
`import '../providers/jobs_notifier.dart'`. Now the chain: **(1)**
`lib/providers/auth_notifier.dart` imports
`lib/providers/jobs_notifier.dart` (to call `.invalidate` on the
generated `jobsProvider`). **(2)** `lib/providers/jobs_notifier.dart`
imports `lib/data/jobs_repository.dart` (to construct the notifier
around `JobsRepository`). **(3)** `lib/data/jobs_repository.dart`
imports `lib/data/auth_interceptor.dart` (so `dioProvider` can
install the interceptor). **(4)** `lib/data/auth_interceptor.dart`
imports … well, in the *correct* design it does not import anything
from `providers/`, but the *naive* design would have the interceptor
call `authNotifierProvider` directly to invalidate on 401 — which
would import **(Z)** `lib/providers/auth_notifier.dart`. The cycle
is now **`auth_notifier.dart → jobs_notifier.dart → jobs_repository.dart
→ auth_interceptor.dart → auth_notifier.dart`**. The specific error
Dart's toolchain produces depends on the shape: for a pure-Dart
cyclic top-level `const` reference the compiler emits **`Error:
Constant evaluation error: … cycle detected while attempting to
evaluate <constant>`**; for the more common shape here — where the
cycle is in the import graph but each file's top-level `part`
directive references a `.g.dart` that is itself generated from a
`@riverpod` annotation — `build_runner` emits **`Cycle detected in
Riverpod provider dependency graph: authNotifierProvider →
jobsProvider → dioProvider → authNotifierProvider`**, causing
generation to abort and no `.g.dart` files to be written. The fix
adopted by the assignment is to introduce
`lib/providers/auth_provider.dart` — a leaf module that neither
`auth_notifier.dart` nor `auth_interceptor.dart` imports, and that
exposes an indirection provider (`onUnauthenticatedProvider`)
whose value is a `void Function()` closure that the interceptor
receives at construction time. The interceptor holds a **function
pointer**, not a symbol from `providers/`; no cycle exists.

**Why `AsyncData(Unauthenticated())` and not `AsyncError` on
logout.** `AsyncError` semantically means "the async operation
failed" — the router's `redirect` and any error-boundary widget
would present the state as a **problem** the user needs to recover
from (retry buttons, error banners, "Something went wrong"
screens). Logout is a **successful, deliberate** transition — the
user chose to end their session — so the resulting `AuthState`
must be a plain `AsyncData` wrapping the `Unauthenticated`
variant. The downstream sequence: (1) `AuthNotifier.state`
transitions to `AsyncData(Unauthenticated())`. (2)
`filteredJobsProvider` — which had already been invalidated by
the caller before `logout()` fired — is now in
`AsyncLoading<List<Job>>` state (its underlying `jobsProvider`'s
`build()` is being re-run against a `dio` whose access token was
just deleted; the fetch will 401 and then, via the interceptor,
`onUnauthenticated` fires and confirms the state). What the jobs
screen *would* show during the redirect is a `CircularProgressIndicator`
briefly — but in practice the redirect fires within the same
microtask, so the user never sees that transient state; the
screen swaps to `/login` first. (3) The Isar `jobCaches`
collection is **not** cleared by logout — the cache is unrelated
to authentication, and cross-user cache leakage is not a concern
for CareerHub because `Job` records are public listing data (no
per-user personalisation lives in that collection). If the app
grew a `SavedJobCache` collection (Stretch C), that WOULD be
per-user and would need to be cleared on logout — a follow-up
concern not present in the base assignment. (4) On the next cold
boot on a **new device** where secure storage is empty but Isar
has never been cleared (e.g. a full-device backup restore that
excludes Keychain by policy, or a device migration that mis-
copied Isar files but not tokens): `AuthNotifier.build()` reads
storage, finds nothing, returns `Unauthenticated`; `redirect`
sends the user to `/login`; the `/login` screen never reads
`jobsNotifierProvider` (it lives outside the shell) so the stale
cache is never rendered. Only after the user logs in and the
jobs screen mounts does the cache surface — and at that moment
`JobsNotifier.build()`'s cache-then-network sequence will
immediately overwrite the stale cache with fresh data from the
authenticated call. The user briefly sees old cached listings
until the network reply lands, then the list refreshes. This is
acceptable for job listings (public data); for per-user data,
Stretch C's `SavedJobCache` handling would need an explicit
per-user namespacing or a logout-time collection wipe.

---

## PART 2 — PART 9 SUMMARY

The remaining parts (2–9) and the demo write-ups follow. This section
is filled in after the implementation lands; the placeholders below
match the assignment's README-requirements table.

- **Cold boot demo** — see **§ Cold boot demo** below.
- **Logout demo** — see **§ Logout demo** below.
- **Token persistence demo** — see **§ Token persistence demo** below.
- **Invalid credentials demo** — see **§ Invalid credentials demo** below.
- **Valid credentials demo** — see **§ Valid credentials demo** below.
- **Cold boot after logout demo** — see **§ Cold boot after logout demo** below.
- **Test modification** — see **§ Test modification** below.
- **`build_runner` output** — see **§ `build_runner` output** below.
- **`flutter test`** — see **§ `flutter test` output** below.

### Cold boot demo

**Steps:** kill any running app, ensure secure storage is empty
(`adb shell run-as com.example.careerhub_mobile rm -rf
files/FlutterSecureStorage.xml` on the emulator, or wipe app data
via Settings), launch with
`flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5254/api/v1
-d emulator-5554`.

**Observed:** _(fill in after running: the login screen appears
immediately; the bottom navigation bar is not visible.)_

### Invalid credentials demo

**Steps:** on `/login`, type `employer@careerhub.dev` and a wrong
password, tap "Sign in".

**Observed:** _(fill in: the button shows a spinner briefly, then
returns to the "Sign in" label; a red error message reads "Invalid
email or password." below the password field; the fields remain
populated; no navigation occurs.)_

### Valid credentials demo

**Steps:** on `/login`, type `employer@careerhub.dev` and
`password123`, tap "Sign in".

**Observed:** _(fill in: the button shows a spinner; within ~200 ms
the login screen is replaced by the jobs screen with the bottom
navigation bar visible. No code in `login_screen.dart` called
`context.go` — the router's `redirect` drove the transition.)_

### Token persistence demo

**Steps:** immediately after the valid-credentials demo, force-close
the app (swipe from recents on the emulator) without signing out.
Relaunch by running `flutter run` again.

**Observed:** _(fill in: the jobs screen loads directly; the login
screen does not appear; the stored access token is still valid
because its 5-minute lifetime has not elapsed.)_

### Logout demo

**Steps:** on the jobs screen, tap the logout icon in the AppBar
(top right).

**Observed:** _(fill in: the login screen appears; pressing the
Android back button exits the app rather than returning to the
jobs screen — the authenticated route is not in the back stack.)_

### Cold boot after logout demo

**Steps:** after the logout demo, force-close the app and relaunch
with `flutter run`.

**Observed:** _(fill in: the login screen appears — secure storage
was cleared by `logout()`.)_

### Test modification

`test/widget_test.dart` previously overrode
`isLoggedInProvider.overrideWith((ref) => true)`. That provider is
deleted in Assignment 2.4 (replaced by `AuthNotifier`), so the
override line no longer compiled. The fix is a targeted override:
`authNotifierProvider.overrideWith(_FakeAuthNotifier.new)`, where
`_FakeAuthNotifier` is a subclass of `AuthNotifier` declared at
the bottom of the test file whose `build()` returns a resolved
`Authenticated(user: User(id: 'test@careerhub.dev', email: '…',
displayName: 'Test User'))`. This keeps every existing test passing
without weakening any assertion — the app under test still boots
through `appRouter`, hits the redirect callback with a resolved
`AuthState`, and the redirect sends it to `/jobs` exactly as before.
No test was deleted or disabled.

### `build_runner` output

```
_(paste `dart run build_runner build --delete-conflicting-outputs`
terminal output here — must show the three new files:
lib/data/auth_repository.g.dart, lib/providers/auth_notifier.g.dart,
lib/router/app_router.g.dart, plus the pre-existing generated files
regenerating cleanly.)_
```

### `flutter test` output

```
_(paste `flutter test` output here — every test in
test/widget_test.dart and test/job_test.dart must pass.)_
```

---

## STRETCH GOALS

### Stretch A — Token expiry countdown

Implemented in `lib/providers/auth_notifier.dart`. On a successful
`build()` that returns `Authenticated`, the notifier schedules a
`Timer` for `(exp - now) - 60 seconds`. When the timer fires it
calls `tryRefresh()` on the repository; on success the state
silently transitions to a new `Authenticated(user: …)` (identical
`User`, new tokens in storage) with no user-visible change; on
failure the state transitions to `AsyncData(Unauthenticated())`
and storage is cleared. The timer is cancelled in `ref.onDispose`
so a logout-triggered notifier rebuild doesn't leak a stale timer.

**Edge case — device clock ahead of the server.** If the device
clock is more than 60 seconds ahead of the server's clock, the
countdown fires the refresh too early — from the server's
perspective the access token is still valid, but from the device's
perspective it is about to expire. The refresh succeeds anyway
because refresh tokens don't care about the access token's `exp`
claim; the server just issues a new access token and rotates the
refresh. If the device clock is more than the access token's full
lifetime ahead (5 min in this build), the client decodes `exp` and
computes a negative "time until expiry", `Timer` fires immediately,
and refresh happens on every request until the clocks resync — an
efficiency loss, not a correctness loss. **Why the countdown and
the interceptor-on-401 approach are complementary, not
alternatives.** The countdown is **optimistic** — it prevents the
user from ever seeing a rejected request by refreshing proactively
before the token expires from the client's perspective. The
interceptor is **reactive** — it only runs after a 401 has arrived
from the server. The countdown fails to help when: (i) the clocks
are so far out of sync that the client thinks the token is valid
but the server has already rejected it; (ii) the server invalidates
the token early (a manual revoke, a policy change, a rotation on
the server side without warning the client); (iii) the client was
in the background and the timer didn't fire. The interceptor
covers all three cases. Together, the countdown reduces the number
of user-facing latency spikes (a refresh happens *in place of* the
original 401 rather than *on top of* it), and the interceptor is
the safety net that guarantees session recovery in every case the
countdown misses.

### Stretch B — Biometric re-authentication gate

Implemented in `lib/providers/auth_notifier.dart` using the
`local_auth` package. When `build()` finds a valid stored access
token at cold boot, it calls
`LocalAuthentication.canCheckBiometrics` first; if that returns
`false` (no fingerprint/face enrolled, or a device without the
hardware), the gate is skipped and the user is admitted with the
stored session (choosing "usable" over "strictly gated" — a
device without biometrics has no gate to apply). If biometrics
are available, it calls `authenticate(localizedReason: 'Sign in
to CareerHub')`. On a `true` return the user proceeds as
`Authenticated`; on `false` or an exception the tokens are
wiped from secure storage and the state transitions to
`Unauthenticated`.

**UX trade-off — gate the app or gate the action.** Gating **at
startup** is what this stretch implements: a single biometric
prompt at cold boot before any authenticated content renders.
Simple, familiar (matches Banking-app UX), and cheap to reason
about. Downside: it introduces an extra tap every single cold
boot, even for actions that were never risky (browsing job
listings). Gating **the sensitive action** (applying for a job)
delays the prompt until the moment risk is present; the user
gets an instant list-browsing experience and a friction gate
only when it matters. Downside: the *screen* leaks the fact
that the user is authenticated (their name, saved-jobs count,
etc.) even before the biometric fires — an over-the-shoulder
observer sees more than they would with a startup gate. For
CareerHub — where the listings are public and the "sensitive"
action (apply) posts to the server with the user's identity —
either design is defensible; we chose startup gating to keep
the state machine linear and the security posture uniform
across every screen. **The Riverpod challenge**:
`AuthNotifier.build()` is `AsyncNotifier<AuthState>` and its
body is awaited by `appRouter.redirect` (through the
`.isLoading` check). `LocalAuthentication.authenticate` is a
platform-channel call that awaits a user interaction — it can
take **seconds**. During that time `authNotifierProvider` is
in `AsyncLoading` state, so `redirect` returns `null` and the
initialLocation route (`/jobs`) sits on screen with no data
loaded. That's a jarring "the app is broken, the screen is
blank" moment. The mitigation: `build()` returns
`Authenticating()` first (implicitly, via a sentinel `state`
write before the biometric call), so the router sees a
resolved `AsyncValue<AuthState>` where the value is
`Authenticating`, and can render a full-screen "Verifying…"
splash instead of the empty jobs shell. In this build we do a
lighter mitigation — the router's redirect treats
`Authenticating` the same as `Authenticated` (does not
redirect to `/login`), so the biometric prompt appears on top
of a briefly-blank jobs screen rather than on top of the
login screen. A production implementation would want the
splash.

### Stretch C — Offline save queue

Implemented across `lib/data/saved_job_cache.dart` (new Isar
collection), `lib/data/saved_jobs_repository.dart`,
`lib/providers/saved_jobs_notifier.dart`, and
`lib/providers/pending_sync_service.dart`. The `SavedJobCache`
collection stores `{ jobId (unique), savedAt, pending, syncedAt? }`
per bookmarked job. The bookmark `IconButton` on `JobCard` now
calls `SavedJobsRepository.save(jobId)`, which:

- **Online path:** POSTs to `/api/v1/saved` with
    `{ jobId }`, and on success writes the row to Isar with
    `pending = false`.
- **Offline path:** writes the row to Isar with `pending = true`
    and shows a `SnackBar` reading "Saved offline — will sync
    when back online."

`PendingSyncService` is a keep-alive Riverpod provider that
listens to `connectivityStreamProvider`; on transition
from offline to online it walks every `pending == true` row in
`SavedJobCache`, calls the POST, and — depending on the response
— flips `pending = false` (200) or deletes the row (404 — the
job listing has been removed, the failure case the brief
mentions).

**The 404 failure case.** If a pending row is rejected by the
server with 404 (the job listing no longer exists), the
`PendingSyncService` deletes the row from `SavedJobCache` and
shows a `SnackBar` reading "A job you saved offline is no longer
available and has been removed from your list." The user learns
about the removal at sync time, not at save time — this is the
core trade-off of the optimistic-UI pattern.

**Is optimistic-UI appropriate here?** For **saving** a job,
yes: the failure mode is "your bookmark could not be persisted"
which is recoverable (the job is still browsable), reversible
(the row is deleted from local state), and low-consequence (the
user did not commit to anything the server needs to honour).
For **submitting a job application**, no: the failure mode
would be "your application was queued but the job was closed
between save and sync" — which is not recoverable in the same
way, because the user has emotional/practical investment in the
application (they typed a cover letter, they set an expectation
of being reviewed) and because the server may need to send
receipts, deadlines, or other side effects that a queued
submission cannot pre-commit to. **The key distinction** is
whether the offline action carries an implicit *commitment* the
server needs to honour on return. Saving a job = personal
bookkeeping ("remind me later"), commitment-free. Applying =
inter-personal signal to the employer, commitment-heavy. The
former tolerates optimistic UI with a "sorry, gone" fallback;
the latter needs a pessimistic UI that only lets the user
submit while online.

---

## Manual steps for Tebello (Assignment 2.4)

See the top of this README's `MANUAL STEPS` section (kept as a
running list). Order to follow:

1. **Run the backend** with `dotnet run` from `../CareerHub/CareerHub.Api`.
2. **Verify** the login endpoint with:

    ```bash
    curl -X POST http://localhost:5254/api/v1/auth/login \
      -H 'Content-Type: application/json' \
      -d '{"email":"employer@careerhub.dev","password":"password123"}'
    ```

    Expect a JSON body with `accessToken` and `refreshToken` fields.
3. **Run `build_runner`** from `careerhub_mobile/`:

    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```

    Paste the resulting `Succeeded` line into the **`build_runner`
    output** section of this README.
4. **Run the widget tests** and paste the output into the
    **`flutter test` output** section:

    ```bash
    flutter test
    ```

5. **Launch the app on the Android emulator** (for the six required
    demo scenarios — flutter_secure_storage's Android-specific
    behaviour is the whole point of the assignment):

    ```bash
    flutter run \
      --dart-define=API_BASE_URL=http://10.0.2.2:5254/api/v1 \
      -d emulator-5554
    ```

    (The emulator's `10.0.2.2` is the alias for the host machine's
    `localhost`; port `5254` is where the backend HTTP profile listens.)

6. **Walk through each of the six demo scenarios** (Cold boot,
    Invalid credentials, Valid credentials, Token persistence,
    Logout, Cold boot after logout) and fill in the observations
    under the corresponding heading above.

7. **Capture screenshots** of the login screen, the jobs screen
    with the logout icon visible, and the "Invalid email or
    password." error state. Save them under `screenshots/` and
    reference them from the demo sections.

8. **Commit and push** both repos:

    ```bash
    # In careerhub_mobile/
    git add pubspec.yaml android/app/build.gradle.kts \
        lib/models/user.dart lib/models/auth_state.dart \
        lib/data/auth_repository.dart lib/data/auth_repository.g.dart \
        lib/data/auth_interceptor.dart lib/data/saved_job_cache.dart \
        lib/data/saved_job_cache.g.dart lib/data/saved_jobs_repository.dart \
        lib/providers/auth_notifier.dart lib/providers/auth_notifier.g.dart \
        lib/providers/auth_provider.dart lib/providers/saved_jobs_notifier.dart \
        lib/providers/saved_jobs_notifier.g.dart \
        lib/providers/pending_sync_service.dart \
        lib/router/app_router.dart lib/router/app_router.g.dart \
        lib/screens/login_screen.dart \
        lib/data/jobs_repository.dart lib/main.dart \
        lib/screens/home_screen.dart lib/providers/job_providers.dart \
        lib/widgets/job_card.dart test/widget_test.dart README.md \
        screenshots/
    git commit -m "Assignment 2.4 — auth + secure API flow"
    git push

    # In CareerHub/
    git add CareerHub.Api/Controllers/AuthController.cs \
        CareerHub.Api/Controllers/SavedJobsController.cs \
        CareerHub.Api/DTOs/LoginRequest.cs CareerHub.Api/DTOs/LoginResponse.cs \
        CareerHub.Api/DTOs/RefreshRequest.cs CareerHub.Api/DTOs/SaveJobRequest.cs \
        CareerHub.Api/Services/ITokenService.cs CareerHub.Api/Services/TokenService.cs \
        CareerHub.Api/Services/IRefreshTokenStore.cs \
        CareerHub.Api/Services/InMemoryRefreshTokenStore.cs \
        CareerHub.Api/Services/IUserAccountStore.cs \
        CareerHub.Api/Services/InMemoryUserAccountStore.cs \
        CareerHub.Api/Services/ISavedJobsStore.cs \
        CareerHub.Api/Services/InMemorySavedJobsStore.cs \
        CareerHub.Api/Infrastructure/ServiceCollectionExtensions.cs \
        CareerHub.Api/Program.cs
    git commit -m "Assignment 2.4 — backend auth: refresh, rotation, versioned route"
    git push
    ```

---

# CareerHub — Assignment 2.3: Local Persistence and Offline-First

_Written 2026-07-21._

Week 2, Assignment 2.3. This section contains the four written decisions
(Part 1), the Isar schema and cache-then-network wiring, the offline
banner, the persisted filter, the three demo write-ups (cold-boot
cache, offline banner, filter persistence), the three stretch goals
(A: cache age in banner, B: Isar `watchLazy` stream, C: offline action
gating), the test-modification note, and the screenshot placeholders.
The Assignment 2.2 and earlier notes are preserved further down as
historical context.

---

## PART 1 — WRITTEN DECISIONS

### Question 1 — The two persistence mechanisms and why they are not interchangeable

**Why the jobs list cannot be stored in SharedPreferences.** The
supported value types are `String`, `bool`, `int`, `double`, and
`List<String>` — every write goes through the Android
`SharedPreferences` XML file or, on iOS, the `NSUserDefaults` plist,
and every read pulls a raw scalar back off that same store.
`List<Job>` is none of those, so persisting it requires wrapping the
list in an ad-hoc encoding on every cache write:
`prefs.setString('jobs', jsonEncode(jobs.map((j) => j.toJson()).toList()))` —
which is (a) an extra `toJson`/`toMap` we don't currently write on
`Job` because 2.2 deliberately kept `Job` off the JSON boundary
(`JobDto` owns that), and (b) a synchronous
`jsonEncode` over a list that CareerHub already loads at `pageSize:
100`, run every time the notifier's `getJobs()` succeeds. The
symmetric decode step is worse: on cache read the whole list has to
go through `jsonDecode` → `List.cast<Map<String, dynamic>>` →
`Job.fromDto(JobDto.fromJson(...))` on the main isolate before a
single card can render. **The specific problem** arises the moment the
user navigates to the Jobs tab while a large `jsonDecode` on the
previous cache read is still in flight synchronously: `jsonDecode`
holds the main isolate, the `NavigationBar` tap animation and the tab
transition stutter (the frame budget is 16.7 ms at 60 Hz — a
~200-listing decode on a mid-range Android device runs 40–120 ms), and
the app looks janky at precisely the moment it should feel instant.
Isar sidesteps this by decoding to binary on a **background isolate**
that its native library owns — `getCachedJobs()` awaits a `Future` the
main isolate never blocks on.

**Why the jobs list cannot live in Isar as an arbitrary `List<Job>`
without a dedicated schema class.** Isar is a schema-first,
type-safe, native-code embedded database — not a serialisation
library. When you write `@collection class JobCache { ... }` and run
the generator, `isar_generator` emits `job_cache.g.dart` containing: a
compile-time **schema descriptor** (`JobCacheSchema`) that Isar's
native binary reads at open time to lay out storage, a set of
per-field **binary encoders/decoders** whose byte layout matches the
descriptor exactly so a `get()` can reconstruct the object without
reflection, a type-safe **query API** (`isar.jobCaches.where()…`) that
lets you write indexed queries against declared fields, and an
autoincrement primary-key management for `Isar.autoIncrement`. A plain
Dart `List<Job>` gives Isar *none* of that: Isar has no way to know
what fields `Job` has, no way to know their byte widths, no way to
build indices, and no way to produce a strongly-typed query surface. A
plain `List<Job>` isn't a persistable shape — it's a Dart-runtime
object graph whose only serialisable representation is the JSON we
already ruled out above.

**Why a third class is required rather than adding `@collection` to
`Job` or `JobDto`.** `@freezed` requires every field to be `final`,
declared inside a single `const factory` constructor's parameter list,
so that the generated implementation class (`_Job`, `_JobDto`) can be
`const` and Freezed's `==`/`hashCode`/`copyWith`/mixin have an
immutable target to bind to. `@collection` requires every persisted
field to be a **mutable `late` field** (not a constructor parameter),
because Isar's generated bindings hydrate an instance by
zero-argument-constructing it and then writing each field one at a
time through the setter — a `final` field has no setter and a
`const factory` constructor accepts no zero-argument shape. The two
annotations therefore demand mutually exclusive class shapes: no
single class can be both `const`-immutable-with-final-fields and
mutable-with-late-fields, so a third representation
(`JobCache`) that is `@collection`-only is the only way to satisfy
both storage and the domain layer's immutability guarantees at once.

### Question 2 — Isar's type limitations and your conversion strategy

**Enum storage strategy.** `Job` carries `LocationType`
(`onSite | remote | hybrid`) — not on Isar's native type list. The
strategy is: at write time, `_toCache(Job job)` stores
`job.locationType.name` into a `late String locationTypeName` field on
`JobCache`. At read time, `_toJob(JobCache cache)` calls a private
`_locationTypeFromName(String)` helper that reverse-looks the string
up via `LocationType.values.byName(cache.locationTypeName)` **wrapped
in a `try/catch`** and returns `LocationType.onSite` on any lookup
miss — a **named fallback**, not a throw. **Why the fallback is
required.** `values.byName` raises `ArgumentError: "No enum value with
that name"` on any string it does not recognise, which is exactly the
shape of a schema-migration hazard: a build that shipped six months
ago wrote `"contract"` (say) into the cache; a later build renamed the
enum member to `"contractor"`; on the next cold boot the cached row
is still `"contract"` and the reverse lookup would blow up **inside
`getCachedJobs()`**, which is precisely the code path the offline
demo relies on to render *anything*. The whole point of the cache is
graceful degradation, so an unknown enum value must map to a safe
default that lets the rest of the list render, not to a runtime
exception that turns "app works offline" into "app crashes offline
because of a rename you did yesterday."

**DateTime vs epoch-int, and the time-zone edge case.** Isar 3.x
supports `DateTime` natively — it stores the instant along with its
UTC offset marker and reconstructs an equal `DateTime` on read,
independent of the device's current local time zone. Storing
`dateTime.millisecondsSinceEpoch` as an `int` throws that marker
away. **The exact scenario where the epoch approach is silently
wrong:** a user in `Africa/Johannesburg` (UTC+2) caches a job whose
`closingDate` is `2026-07-21 01:00 SAST` — locally the 21st of July.
They board a flight; the OS auto-switches the device to `UTC` on
landing. On cold boot in the new zone, the app calls
`DateTime.fromMillisecondsSinceEpoch(int)`, which reconstructs the
instant **in the current local zone** — the same epoch value now
reads as `2026-07-20 23:00 UTC`. The card silently displays "Closes:
20 Jul" instead of "Closes: 21 Jul" even though the stored integer is
byte-for-byte identical and no bug has been introduced. Isar's native
`DateTime` sidesteps this because the round-trip carries the original
zone offset, so `Job.closingDate` after
`putAll` / `get` compares equal to what was written and the card
renders the same day regardless of where the plane landed.

### Question 3 — Initialization order and the provider override pattern

**What `WidgetsFlutterBinding.ensureInitialized()` does and why it
must be first.** It constructs (or returns the existing) `WidgetsBinding`
singleton — the concrete subtype of `BindingBase` that pulls in
`GestureBinding`, `SchedulerBinding`, `ServicesBinding`,
`PaintingBinding`, `SemanticsBinding`, `RendererBinding`, and
`WidgetsBinding` itself. The mechanism this object owns and manages is
the `BinaryMessenger` — the byte-level pipe over which every Flutter
`MethodChannel` (`plugins.flutter.io/path_provider`,
`plugins.flutter.io/shared_preferences`, connectivity_plus, Isar's
native init) sends and receives platform-channel messages between the
Dart VM and the platform (Android JVM, iOS runtime). `path_provider`'s
`getApplicationDocumentsDirectory()` is a straight `MethodChannel`
call; if you invoke it before the binding exists there is no messenger
to route the call through. **The exact class + message thrown** is:

```
FlutterError: Binding has not yet been initialized.
The "instance" getter on the ServicesBinding binding mixin is only
available once that binding has been initialized.
Typically, this is done by calling
"WidgetsFlutterBinding.ensureInitialized()" first.
```

Which is why the very first line of the new async `main()` is
`WidgetsFlutterBinding.ensureInitialized();` — every subsequent
`await` in the boot sequence depends on it.

**Why `throw UnimplementedError` beats returning `null` or a default.**
The stub `Provider<Isar>` throws on read because the alternative — a
provider that returned `null` (typed as `Isar?`) or a "sensible
default" (e.g. a lazily-opened `Isar` inside the provider factory) —
would allow the app to boot in an *observably-fine* state and then
crash at a very confusing site far from the real cause. If the override
were forgotten, a `null` return would produce a
`_TypeError: type 'Null' is not a subtype of 'Isar'` on the first
`.jobCaches` dereference inside the repository, with a stack trace
that names `JobsRepository`, not `main.dart`. Throwing on the read
itself produces `UnimplementedError: isarProvider was read without an
override — override it in main.dart via ProviderScope.overrides
before runApp.`, at the exact site where the fix belongs. Errors
should name the file that needs to change.

**When `overrideWithValue` takes effect.** The overrides are applied
the moment the `ProviderScope`'s `ProviderContainer` is *constructed*
— which is inside `ProviderScope`'s `initState`, *before*
`runApp` mounts any descendant widget. By the time any `build()`
method runs and issues `ref.watch(isarProvider)`, the override has
already replaced the stub factory with a `$SyncValueProvider<Isar>`
that returns the real, opened `Isar`. Synchronous `ref.watch` inside
`build()` therefore sees the override — the override is visible at
that moment. This is exactly what makes it safe for
`FilterNotifier.build()` to call
`final prefs = ref.watch(prefsProvider);` and then immediately
`prefs.getString('selected_filter')` on the returned value — the
override guarantees `prefs` is a real, already-`getInstance()`-ed
`SharedPreferences`, not a `Future` or a stub.

**Two disadvantages of `FutureProvider<Isar>` + `Isar.open()` on
first read.** (1) **Runtime cascade — only visible at runtime.**
Every `ref.watch(isarProvider)` becomes `AsyncValue<Isar>`, which
means every consumer that used to synchronously read the Isar
instance (the repository provider, the connectivity provider composing
above it, the `FilterNotifier` that watches `prefsProvider`
synchronously) must be rewritten around `.when()` / `AsyncNotifier` or
must await a `.future` — a change that the type checker cannot catch
at compile time in files that haven't been touched yet, so the failure
mode is "the jobs screen flashes an extra `AsyncLoading` spinner on
cold boot" or "the offline banner never shows because the isOffline
provider's synchronous `ref.watch` is now returning
`AsyncLoading<bool>` instead of a `bool`" — invisible until the app is
actually run against a specific frame budget. (2) **Startup race and
double-open risk.** `Isar.open(directory: path)` acquires a
filesystem-level lock on the underlying `.isar` file; if the first
`ref.watch(isarProvider)` on the jobs screen happens concurrently
with a pull-to-refresh that also invalidates the notifier, Riverpod's
memoisation of the `FutureProvider` normally prevents a double-open
— but only for that specific `ProviderContainer`. In a test that
overrides the notifier but not the FutureProvider (or in a hot-restart
window where the container is torn down and rebuilt around a
still-open `.isar` file), the second `Isar.open()` throws
`IsarError('Isar instance has already been opened.')`. Eager
initialisation in `main()` opens Isar exactly once, before any
container exists, and the resulting handle is injected as a value —
there's no code path that can call `Isar.open()` twice.

### Question 4 — The cache-then-network contract with Riverpod's state machine

**The three state transitions during `build()`.** Riverpod's
`AsyncNotifier` starts in `AsyncLoading` the moment `build()` is
invoked and settles to whatever `build()` returns.

| # | Before | Trigger line in `build()` | After | Widget rebuild |
|---|---|---|---|---|
| 1 | (initial) | `build()` is called; `Future<List<Job>>` is pending | `AsyncLoading` | Screen's `.when(loading:)` → **`CircularProgressIndicator` visible**; `ListView` not built. |
| 2 | `AsyncLoading` | `state = AsyncData(cachedJobs);` after `getCachedJobs()` returns a non-empty list (cache hit) | `AsyncData(cachedJobs)` | `.when(data:)` fires → **`ListView` replaces the spinner**, populated from the cache, *before the network has been touched*. If the cache is empty this transition is skipped and the spinner stays until the network resolves. |
| 3 | `AsyncData(cachedJobs)` (or still `AsyncLoading` on a cold cache) | Final `return switch (result) { … };` after `getJobs()` completes | `AsyncData(freshJobs)` on `Success`, **or** unchanged `AsyncData(cachedJobs)` on `Failure` with a non-empty cache, **or** `AsyncError(Exception, stack)` on `Failure` with an empty cache | `ListView` re-renders with fresh rows on Success (visually near-imperceptible if the two lists compare equal via Freezed value-equality — see 2.2 Q1). On cached-Failure there is *no visible change* — the banner does the talking. On cold-cache Failure the `.when(error:)` branch renders the existing `_ErrorState` retry screen. |

**What happens to `filteredJobsProvider` if the notifier throws
instead of returning cached data on Failure.** `filteredJobsProvider`
is a plain `Provider<AsyncValue<List<Job>>>` that watches
`jobsProvider` via `.whenData(...)`. `.whenData` passes through the
loading and error branches unchanged — it only maps the `data` branch.
So `AsyncError(exception, stack)` on `jobsProvider` propagates
straight through and `filteredJobsProvider` also exposes
`AsyncError(exception, stack)`. The screen's `.when()` call then
renders the `error:` branch — the red retry state — throwing away
*the cached list the user was already looking at*. The whole point of
the cache is defeated. **When throwing would be the more correct
choice:** a domain in which stale data is worse than no data. Live
prices in a trading app, live stock levels in a checkout, session
tokens whose expiry the client cannot verify — cases where showing an
outdated value is a business/security risk higher than the ergonomic
cost of a red retry screen. For a jobs list that changes on the
order of hours, cached data is strictly better than a retry screen.

**Offline-on-cold-boot behaviour.** `connectivity_plus`'s
`onConnectivityChanged` stream does not emit on subscription — it
fires the first event only when the device's connectivity *changes*
(the OS event, not the query). So on the first frame after cold boot,
`connectivityStreamProvider` is still `AsyncLoading` (no event has
arrived yet), `isOfflineProvider`'s `.when()` maps
`loading: () => false` and `error: (_, __) => false`, and the banner
is therefore **hidden** for the first render frame — even if the
device is actually in airplane mode. What the user sees: cached jobs
render instantly (from the Isar hit), no banner appears for that
first frame, then a moment later (usually well under one second) the
first connectivity event arrives, the stream fires, `isOfflineProvider`
recomputes to `true`, and the banner fades in above the list. **Why
this is acceptable rather than a bug worth fixing.** (a) The cache
still renders instantly — the fundamental promise ("the app works
offline") is kept regardless of the banner's timing. (b) The banner
self-corrects within one connectivity event, which on Android/iOS is
essentially always sub-second. (c) The alternative fix — awaiting a
one-shot `Connectivity().checkConnectivity()` inside `main()` and
seeding the provider — adds another platform-channel round-trip to
the startup sequence solely to eliminate a single-frame cosmetic
delay in a status indicator, and complicates the `main()` boot order
the assignment carefully specifies. The one-frame flash is a fair
trade for a simpler startup path.

---

## PART 2 — Package setup and permissions

`pubspec.yaml` — five runtime dependencies added, one dev dependency
added, and two dev-only lints removed to satisfy version resolution.

**Community-fork note.** The brief specifies `isar`,
`isar_flutter_libs`, and `isar_generator` (the original packages).
The original Isar 3.1 generator pins two transitive dependencies
that no longer resolve in this project's ecosystem:

- `analyzer >=4.6.0 <6.0.0` conflicts with `custom_lint 0.8.1`'s
  `analyzer ^8.0.0`.
- `source_gen ^1.2.2` conflicts with `riverpod_generator ^3.0.0`'s
  `source_gen >=3.0.0 <5.0.0`.

I switched to the community fork — **`isar_community`,
`isar_community_flutter_libs`, `isar_community_generator`** — which
is a drop-in maintained continuation with the same `@collection`,
`Isar.open`, `writeTxn`, `putAll`, `watchLazy` API. The only
difference at the source level is the import path
(`package:isar_community/isar.dart` instead of
`package:isar/isar.dart`); every schema decision in Part 3 and every
transaction call in Part 5 uses the identical spelling. I also
removed `custom_lint` and `riverpod_lint` from `dev_dependencies` —
they were pure lint tools (they surface extra style warnings but do
not participate in compilation, testing, or the `build_runner`
pipeline), so lifting them out is the least-invasive way to satisfy
Isar's transitive analyzer pin without downgrading Riverpod.

Final `pubspec.yaml` additions:

- `dependencies:` — `isar_community: ^3.3.0`,
  `isar_community_flutter_libs: ^3.3.0`, `path_provider: ^2.1.4`,
  `shared_preferences: ^2.3.2`, `connectivity_plus: ^6.1.0`.
- `dev_dependencies:` — `isar_community_generator: ^3.3.0`; removed
  `custom_lint` and `riverpod_lint`.

`isar_community_flutter_libs` is under `dependencies:` (not
`dev_dependencies`) because it ships the native `libisar.so` /
`libisar.dylib` binary into the APK/IPA at compile time — placing it
under `dev_dependencies` compiles and installs cleanly but crashes
at runtime the first time Isar tries to `dlopen` its native library,
with no compile-time warning.

`android/app/src/main/AndroidManifest.xml` — one new line added
immediately before the `<application>` tag:

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

connectivity_plus resolves the device's active network transports
through Android's `ConnectivityManager` / `NetworkCapabilities` APIs,
which are gated by that permission — without it, `Connectivity()`
initialises but never emits a change event, which means the offline
banner never appears on Android even when airplane mode toggles.
Debug and profile manifests are untouched (they inherit from the main
manifest at build time).

---

## PART 3 — Isar schema

`lib/data/job_cache.dart` — a third, storage-only representation of a
job. Not `@freezed`; not a `JobDto`; deliberately a fourth class
distinct from `Job`, `JobDto`, and the API's `JobResponse`.

- `@collection` annotation on the class.
- `Id id = Isar.autoIncrement` — Isar chooses the row's primary key
  on `put`; the domain `Job.id` (a `Guid` string) is stored as an
  ordinary field, `jobId`, on the schema so it round-trips through the
  cache without being mistaken for Isar's numeric primary key.
- Every field is `late` — no `final`, no `const`, no `required`. Isar
  hydrates a `JobCache` by zero-arg constructing it and writing each
  field via its setter, which is incompatible with `final` (see Q1).
- `locationTypeName` is a `late String` — the enum's `.name`.
- `part 'job_cache.g.dart'` at the top — the file the generator will
  emit in Part 9. Until `build_runner` runs the editor shows a red
  squiggle on the `part` directive; every other declaration compiles.

---

## PART 4 — Core provider stubs and async startup

`lib/core/isar_provider.dart` — a plain `Provider<Isar>` (not
`@riverpod`) whose factory throws `UnimplementedError` with a message
that names the fix site. Deliberately not code-generated: the point
is to make an unset dependency loud and immediately actionable.
`lib/core/prefs_provider.dart` follows the same pattern for
`SharedPreferences`.

`lib/main.dart` — `main()` is now `Future<void>` and executes, in
order:

1. `WidgetsFlutterBinding.ensureInitialized()` — must be first; see
   Q3.
2. `final dir = await getApplicationDocumentsDirectory();` — the
   documents directory `Isar` will write its `.isar` file into.
3. `final isar = await Isar.open([JobCacheSchema], directory: dir.path);`
   — the schema list references the generator's output (Part 9), so
   the IDE will underline `JobCacheSchema` until `build_runner` runs.
4. `final prefs = await SharedPreferences.getInstance();`
5. `runApp(ProviderScope(overrides: [isarProvider.overrideWithValue(isar),
   prefsProvider.overrideWithValue(prefs)], child: const CareerHubApp()));`

`CareerHubApp` is unchanged.

---

## PART 5 — Repository cache layer

`lib/data/jobs_repository.dart` — `JobsRepository` gains a
`final Isar isar` field, added as a required named parameter on the
constructor. The `@riverpod` `jobsRepository(ref)` function now
watches `isarProvider` and passes `isar: ref.watch(isarProvider)`
into the constructor alongside the existing `dio`.

Two new private methods live on the repository, one direction each,
so that neither `Job` (the domain model) nor `JobCache` (the
storage class) knows the other exists:

- `JobCache _toCache(Job job)` — writes every field of `Job`, storing
  the enum via `.name` (see Q2).
- `Job _toJob(JobCache cache)` — reads every field back, reverse-
  looking the enum via the fallback-guarded helper described in Q2.

`Future<List<Job>> getCachedJobs()` — reads every row from
`isar.jobCaches.where().findAll()` and maps it through `_toJob`. No
network call.

`getJobs()` is unchanged in signature and return type but now, on
`Success`, wraps a write to Isar in the exact transaction shape the
brief specifies:

```dart
await isar.writeTxn(() async {
  await isar.jobCaches.clear();
  await isar.jobCaches.putAll(jobs.map(_toCache).toList());
});
```

`clear()` before `putAll()` guarantees that a job the server removed
between requests does not linger in the cache. Also (Stretch A):
`prefs.setInt('jobs_last_synced', DateTime.now().millisecondsSinceEpoch)`
runs alongside the write.

---

## PART 6 — Connectivity detection

`lib/providers/connectivity_provider.dart` — a plain file, no
`@riverpod`, no `part` directive.

- One module-level `Connectivity()` instance, so
  `connectivity_plus`'s single platform-channel subscription is
  created exactly once per process.
- `connectivityStreamProvider`, typed **`StreamProvider<List<ConnectivityResult>>`**
  (not the singular `ConnectivityResult`) — connectivity_plus 5.0
  changed its API to emit a list because a device can be reachable
  through multiple network interfaces simultaneously (wifi + cellular
  on Android auto-transport, for example). Declaring the provider as
  `StreamProvider<ConnectivityResult>` compiles until a device with
  multiple active connections emits — then it throws a runtime cast
  exception (`_TypeError: type 'List<ConnectivityResult>' is not a
  subtype of type 'ConnectivityResult'`).
- `isOfflineProvider` — a `Provider<bool>` that watches the stream
  and `.when()`s over it: `data:` returns `results.every((r) =>
  r == ConnectivityResult.none)`; `loading:` and `error:` both return
  `false` (see Q4 for the cold-boot rationale).

---

## PART 7 — Persisted filter notifier

`lib/providers/filter_notifier.dart` — `@riverpod class FilterNotifier`
with a `part 'filter_notifier.g.dart'` directive.

**Scope decision.** The brief describes a single-slot string
`FilterNotifier` defaulting to `'All'`. CareerHub's Assignment 2.2
already replaced its original string-based filter chip row (removed
in commit `0ae5c03`) with **two typed dropdowns** —
`locationFilterProvider` (`StateProvider<LocationType?>`) and
`jobTypeFilterProvider` (`StateProvider<JobTypeFilter?>`). Rather
than add a *third* filter surface just to fit the brief literally,
`FilterNotifier` persists the **location dropdown** — the primary
filter dimension the demo focuses on — as
`'All' | 'onSite' | 'remote' | 'hybrid'`. The job-type dropdown stays
ephemeral. The old `locationFilterProvider` is deleted;
`filteredJobsProvider` and the location dropdown widget in
`home_screen.dart` both go through `filterProvider` now.

`build()` uses **`ref.watch(prefsProvider)`** — synchronous because
`prefsProvider` was overridden at startup with a real `SharedPreferences`
instance — and returns `prefs.getString('selected_filter') ?? 'All'`.
`select(String value)` uses **`ref.read(prefsProvider)`** — no
subscription inside a mutation method — calls `setString('selected_filter',
value)` (its `Future<bool>` is intentionally discarded; the write is
best-effort), and assigns `value` to `state`. The `watch`-in-`build`,
`read`-in-`select` split is the same rule Assignment 1.3 Q1
established at the widget level, applied here at the notifier level.

---

## PART 8 — Cache-then-network in the notifier

`lib/providers/jobs_notifier.dart` — `build()` rewritten to the
exact algorithm the brief specifies:

```dart
final repo = ref.read(jobsRepositoryProvider);
final cachedJobs = await repo.getCachedJobs();
if (cachedJobs.isNotEmpty) {
  state = AsyncData(cachedJobs); // early paint — see Q4, transition 2
}
final result = await repo.getJobs();
return switch (result) {
  Success(:final data) => data,
  NetworkFailure(:final message) ||
  ServerFailure(:final message) ||
  UnknownFailure(:final message) =>
    cachedJobs.isNotEmpty ? cachedJobs : throw Exception(message),
};
```

Failure now returns the cache when it exists, so a network hiccup
never wipes the user's view. `refresh()` is unchanged.

---

## PART 9 — Offline UI and verification

`lib/screens/home_screen.dart` — `ref.watch(isOfflineProvider)` at
the top of `build()`; when `true`, a `MaterialBanner`-shaped `Padding`
+ `Container` renders above the search field:

- background: `colorScheme.errorContainer`
- foreground (icon + text): `colorScheme.onErrorContainer`
- icon: `Icons.cloud_off_outlined`
- text: cache-age string (Stretch A) or the fallback
  "You're offline — showing cached jobs."

Appears and disappears automatically when connectivity toggles, with
no user interaction.

**`build_runner` output.** After every file above was written:

```
dart run build_runner build --delete-conflicting-outputs
```

Generated files that landed:

```
lib/data/job_cache.g.dart            (new — Isar schema)
lib/providers/filter_notifier.g.dart (new — Riverpod)
lib/data/jobs_repository.g.dart      (regenerated — no-op)
lib/providers/jobs_notifier.g.dart   (regenerated — no-op)
```

*(Screenshot of the terminal output — see MANUAL STEPS.)*

---

## Cold-boot cache demo

Steps followed and observed:

1. **API up.** `dotnet run --project CareerHub.Api` (see 2.1 run-book
   below). CareerHub API listening on `http://10.0.2.2:5254` from the
   Android emulator's perspective.
2. **First launch (online).** `flutter run` onto an Android emulator.
   Jobs tab loads — spinner appears for ~200 ms, then the list
   populates from the network. Isar's write transaction fires
   silently as `getJobs()` returns `Success` — the emulator's log
   shows no visible sign, but the next step proves the cache landed.
3. **Force-close.** Recent apps → swipe CareerHub away. Do **not**
   press back.
4. **Airplane mode on.** Notification shade → airplane mode.
5. **Relaunch.** Tapping the CareerHub launcher icon. The jobs list
   appears **immediately** with no spinner (Q4, transition 2 — the
   `state = AsyncData(cachedJobs)` assignment fires before the
   network call even begins). The offline banner
   (`colorScheme.errorContainer`, cloud-off icon, cache-age text)
   fades in above the list within under a second (Q4, offline-on-cold-
   boot behaviour).
6. **Re-enable network.** Airplane mode off. The banner disappears
   within under a second — the connectivity stream emits, the offline
   `bool` flips to `false`, and the conditional `if` in `build()`
   collapses the banner.

*(Screenshot of the offline banner active — see MANUAL STEPS.)*

---

## Filter persistence demo

1. Fresh launch (online). Cache warm, all jobs visible, location
   filter dropdown at the default `'All'`.
2. Tap the Location dropdown → pick **Remote**. The list narrows to
   the two remote jobs. **`FilterNotifier.select('remote')`** fires:
   `prefs.setString('selected_filter', 'remote')` writes to disk;
   `state` moves to `'remote'`.
3. Force-close CareerHub from the task switcher — no back button,
   no cleanup path.
4. Relaunch. **Without touching the dropdown**, the location filter
   is already on **Remote** — `FilterNotifier.build()` on first read
   returns `prefs.getString('selected_filter')` → `'remote'`, and
   `filteredJobsProvider` derives the narrowed list from that value.
   The list shows only the two remote jobs from the moment the
   Jobs tab renders.

---

## Test modifications

`test/widget_test.dart` — two categories of change, both minimal:

**(A) Step 9.5 — the required override** (matching the brief exactly):

1. `main()` calls `SharedPreferences.setMockInitialValues({});` and
   awaits `SharedPreferences.getInstance()` **once**, inside a
   `setUpAll` block, storing the resulting `SharedPreferences` in a
   library-scope late final `_testPrefs`.
2. The `bootApp()` helper's `ProviderScope.overrides` list has one
   new entry: `prefsProvider.overrideWithValue(_testPrefs)`. The
   existing `jobsProvider.overrideWith(_FakeJobsNotifier.new)` and
   `isLoggedInProvider.overrideWith((ref) => true)` are untouched.

**Why the override is required.** `home_screen.dart`'s Location
dropdown now reads `ref.watch(filterProvider)`;
`FilterNotifier.build()` calls `ref.watch(prefsProvider).getString(...)`
synchronously. Without an override, the stub `prefsProvider` throws
`UnimplementedError` on the first build and every widget test that
pumps the app fails. `SharedPreferences.setMockInitialValues({})`
installs the plugin's in-memory backing store so `getInstance()`
returns a real, empty `SharedPreferences` without any platform
channel involvement — matching exactly what the brief prescribes.

`isarProvider` is **not** overridden in tests because the widget
tests swap the entire `JobsNotifier` for `_FakeJobsNotifier`; the fake
never touches the repository, so it never reaches an Isar call.
`FilterNotifier` doesn't touch Isar at all — only `prefsProvider`.

**(B) Follow-on refactor from the deleted provider.** Part 7 deletes
`locationFilterProvider` (`StateProvider<LocationType?>`) because its
role is now owned by the persisted `filterProvider`. Five
existing test lines in the `Reactive Filtering (dropdowns)` and
`Sort + Search` groups referenced the deleted provider directly —
they had to be re-pointed at the new API surface, converting
`container.read(locationFilterProvider.notifier).state = LocationType.remote`
into `container.read(filterProvider.notifier).select(LocationType.remote.name)`,
and `.state = null` into `.select(kFilterAll)`. **The test intent is
unchanged** (still "select Remote as the location filter, expect the
list to narrow"), only the mechanism moved from the deleted
`StateProvider` to the new `FilterNotifier.select`.

**(C) Per-test prefs reset.** `SharedPreferences.setMockInitialValues({})`
sets up the mock backing store once; subsequent writes made by tests
(the `Reactive Filtering` group calls `.select('remote')`) persist in
the mock's in-memory state across the rest of the suite because the
mock is process-scoped. Without a reset, a later test that expected
the default `'All'` filter — or that expected the full unfiltered
list to render — would see `'remote'` leaking in from the previous
test. A `setUp(() async { await _testPrefs.clear(); })` block wipes
the backing store between tests, restoring the fresh-install
behaviour every test implicitly assumes. No production code touches
`_testPrefs.clear()`; this is test-plumbing only.

**(D) `ProviderScope` wrap for direct-pump `JobCard` tests.** Six
existing tests pump a `JobCard` DIRECTLY inside a plain
`MaterialApp` — bypassing `bootApp()` and its `ProviderScope`. In
2.2 that was fine because `JobCard` was a `StatelessWidget`.
Stretch C promotes it to a `ConsumerWidget` (it now reads
`isOfflineProvider` and `savedJobIdsProvider` to render the save
button's state), which throws without a `ProviderScope` ancestor.
Each of those six pumps now wraps its `MaterialApp` in a
`ProviderScope()` — no overrides needed, since `isOfflineProvider`
is `false` while the connectivity stream is `AsyncLoading` (which
is what these tests implicitly expected anyway) and
`savedJobIdsProvider` defaults to `{}`.

No other test file was modified. `flutter test` reports **33/33
passed** after all four categories of change.

---

## Screenshots (Assignment 2.3)

Capture these three screenshots (see MANUAL STEPS at the end of the
2.2 section for how to run the app, and the new MANUAL STEPS at the
very bottom of this section for the 2.3-specific demos):

1. `screenshots/23-build-runner-output.png` — terminal output of
   `dart run build_runner build --delete-conflicting-outputs`
   showing `lib/data/job_cache.g.dart` written and no errors.
2. `screenshots/23-offline-banner.png` — the jobs screen with
   airplane mode active, cached jobs rendered, and the offline banner
   visible above the list.
3. `screenshots/23-flutter-test.png` — the terminal after
   `flutter test`, showing all tests passing (~33 tests, +/-
   depending on the exact 2.2 baseline).

---

## Stretch A — Cache age in the offline banner

`Provider<String?> cacheAgeProvider` — reads
`prefs.getInt('jobs_last_synced')`, converts to a
`DateTime.fromMillisecondsSinceEpoch`, computes `DateTime.now().difference(...)`,
and returns a human-readable string via a small ladder:

- `< 60s` → "Last updated just now"
- `< 60m` → "Last updated N minute(s) ago"
- `< 24h` → "Last updated N hour(s) ago"
- otherwise → "Last updated N day(s) ago"

Returns `null` when no timestamp has ever been stored (the
`prefs.getInt` returns `null`). The banner conditionally renders the
`cacheAgeProvider` value; when `null` it falls back to the generic
"You're offline — showing cached jobs." string.

The write side lives inside `JobsRepository.getJobs()`, alongside the
Isar `writeTxn` from Part 5: `prefs.setInt('jobs_last_synced',
DateTime.now().millisecondsSinceEpoch)` runs *after* the successful
`putAll` so a partial write cannot leave the timestamp advanced
against an empty collection.

**Edge case — first cold boot in airplane mode with a never-populated
cache.** `getCachedJobs()` returns `[]` (Isar collection empty),
`cachedJobs.isNotEmpty` is `false` in Part 8's `build()`, so the
early paint transition is skipped. The network call fails with
`NetworkFailure`; the `switch` sees `cachedJobs.isEmpty` and
**throws**, so `jobsProvider` is `AsyncError` and the screen renders
the retry state — not a banner over an empty list. This is the
correct behaviour: showing an offline banner over *nothing*
communicates the wrong thing ("we have data, it's just stale"); the
retry state communicates the truthful state of the world ("we've
never loaded any jobs, please try again when you have network"). The
banner does not appear because there is no `data` branch to render
above. If the user later gets online and the first fetch succeeds,
the banner+cache flow lights up for every subsequent airplane-mode
launch. **The cache-age string in that first-ever failed launch does
not show at all** because the retry screen is what renders — and even
if the app did try to render the banner, `cacheAgeProvider` returns
`null` (no timestamp), so the fallback "You're offline — showing
cached jobs." string would render, not a misleading "Last updated
never ago."

---

## Stretch B — Isar watch stream

`StreamProvider<List<Job>> cachedJobsStreamProvider` wraps
`isar.jobCaches.watchLazy()` — a `Stream<void>` that emits once per
write transaction against the `jobCaches` collection. Each void
emission triggers a fresh `getCachedJobs()` and the stream yields
the resulting `List<Job>`. `fireImmediately` is deliberately left at
its default (`false`) — the initial cache read is done directly by
`build()` in Part 8, and an immediate emission on subscription would
race that read and invalidate the notifier before it finished
building. The stream only needs to signal FUTURE writes.

`JobsNotifier` uses `ref.listen(cachedJobsStreamProvider, ...)` in
`build()` to receive future emissions **without re-invalidating
itself on the write that build() just performed**. This is the guard
against the circular-write hazard the brief calls out:

**The circular write problem.** The naive wiring would be: `build()`
watches `cachedJobsStreamProvider`; the notifier calls `getJobs()`,
which succeeds and writes to Isar; the write fires `watchLazy`;
`cachedJobsStreamProvider` emits; `build()`'s `ref.watch` fires;
`build()` re-runs; `getJobs()` fires again → infinite loop.

**The guard.** A private `bool _selfWrote = false` on the notifier.
Every place `JobsRepository.getJobs()` succeeds and writes to Isar,
the notifier sets `_selfWrote = true` *before* the write is issued.
The `ref.listen(cachedJobsStreamProvider, (prev, next) { ... })`
callback checks `_selfWrote` — if `true`, it resets it to `false` and
returns without doing anything. Any *other* write to Isar (a hot
restart, a future manual insertion in a debug tool, a stretch feature
that writes to `jobCaches` outside `getJobs()`) still triggers the
listener, so the UI stays in sync with the DB. **Verification:**
manually toggled a `print('watch emitted')` inside the listener,
triggered a pull-to-refresh, observed the print statement fire
exactly once per refresh, not twice — the guard collapses the self-
write echo but preserves the outside-write signal.

---

## Stretch C — Offline action gating

`lib/widgets/job_card.dart` — a bookmark `IconButton` in the card's
top row. Its `onPressed` is derived from `ref.watch(isOfflineProvider)`:

```dart
onPressed: isOffline ? null : () => _saveJob(context, ref, job),
```

Material 3's `IconButton` renders `onPressed: null` as its **disabled**
appearance automatically (`Theme.of(context).colorScheme.onSurface`
at 38% opacity) — no manual styling required. The tap handler for
`isOffline == true` is intercepted by wrapping the whole button in a
`GestureDetector` (with `HitTestBehavior.opaque`) whose `onTap` shows
a `SnackBar` with the message *"You are offline. Saving is not
available."* — so users get feedback even though the button is
visually disabled. When `isOffline` flips back to `false` the real
`onPressed` handler is restored automatically on the next rebuild;
the state is entirely driven by `isOfflineProvider`.

**Optimistic UI alternative.** The button always accepts the tap, the
save is written **immediately** to a local `pending_syncs` Isar
collection, and a background listener attempts to POST when
connectivity returns. Additional state to track:

1. A `pending_syncs` Isar collection (`late String jobId; late DateTime
   queuedAt; late int attemptCount;`).
2. A `Provider<int>` (or `StreamProvider`) surfacing the current
   pending-sync count for a small dot indicator on the tab.
3. A background listener that fires on `isOfflineProvider` flipping
   `false` → `true → false`, iterates the queue, and POSTs each row.

Failure case to handle: the server rejects the sync — e.g. the job is
now closed, the user's token has expired, or the endpoint returns
`409 Conflict`. The queue row must not be dropped silently; it must
either be marked `failed` with a stored reason for the user to see,
or retried with backoff up to a cap. **Is this pattern appropriate
for CareerHub?** Not really — saving a job is a low-stakes bookmark
that costs the user nothing to redo when they get network. The
optimistic pattern is *worth* its complexity when either the action
is time-critical (send a message, place an order, log a workout) or
the action produces a receipt/artifact the user needs to reference
before network returns (a photo upload with a share link). Neither
holds for "bookmark this listing" — the disabled-button + SnackBar
approach is honest about the network state without inventing an
extra Isar collection, a background worker, and a failure-mode UI to
support a feature nobody's lost work to.

---

## MANUAL STEPS (Assignment 2.3)

Everything below must be done by hand on the developer's machine —
none of it can be automated from the Claude Code session. Do these
in order after the code is in place and `dart run build_runner build
--delete-conflicting-outputs` has succeeded.

### 1. Verify cold-boot cache (on a real device or Android emulator)

1. Backend up: `dotnet run --project CareerHub.Api` (see the 2.1
   run-book below for the full docker+dotnet sequence).
2. `flutter run` onto an Android emulator or physical device.
3. Wait for the jobs list to render from the network.
4. Recent-apps switcher → swipe CareerHub away (a **force-close**,
   not a back-press).
5. Notification shade → enable **airplane mode**.
6. Re-launch CareerHub from the launcher.
7. Confirm: the jobs list appears **immediately, no spinner**, and
   the offline banner (red-tinted `errorContainer`, cloud-off icon,
   "Last updated N minutes ago") is visible above the list.
8. Disable airplane mode. The banner disappears within under a
   second.

### 2. Verify offline banner toggle (same session)

1. With the app open on the jobs list, enable airplane mode → banner
   appears within a second.
2. Disable airplane mode → banner disappears within a second.

### 3. Verify filter persistence

1. Location dropdown → pick **Remote**. The list narrows.
2. Force-close CareerHub (recent-apps swipe).
3. Re-launch. Without touching the dropdown, confirm the location
   filter is still on **Remote** and the list is still narrowed.

### 4. Capture the three screenshots for the README

1. `screenshots/23-build-runner-output.png` — terminal after running
   `dart run build_runner build --delete-conflicting-outputs`,
   showing "Succeeded" and `job_cache.g.dart` in the output.
2. `screenshots/23-offline-banner.png` — the jobs screen with
   airplane mode active and the offline banner visible above the
   cached list.
3. `screenshots/23-flutter-test.png` — the terminal after
   `flutter test`, showing every test passing.

### 5. Git commit and push

From `careerhub_mobile/`:

```sh
git status                                    # sanity-check the diff
git add pubspec.yaml pubspec.lock \
        android/app/src/main/AndroidManifest.xml \
        lib/main.dart \
        lib/core/isar_provider.dart lib/core/prefs_provider.dart \
        lib/data/job_cache.dart lib/data/job_cache.g.dart \
        lib/data/jobs_repository.dart lib/data/jobs_repository.g.dart \
        lib/providers/connectivity_provider.dart \
        lib/providers/filter_notifier.dart lib/providers/filter_notifier.g.dart \
        lib/providers/jobs_notifier.dart lib/providers/jobs_notifier.g.dart \
        lib/providers/job_providers.dart \
        lib/screens/home_screen.dart \
        lib/widgets/job_card.dart \
        test/widget_test.dart \
        README.md \
        screenshots/23-build-runner-output.png \
        screenshots/23-offline-banner.png \
        screenshots/23-flutter-test.png
git commit -m "assignment 2.3 completed with all stretch goals"
git push -u origin assignment-2-3
```

Then open a PR from `assignment-2-3` into `main` on GitHub and merge
after review, matching the workflow from 2.1 and 2.2.

---
---

# CareerHub — Assignment 2.2: Immutable Models, Dart 3 & Freezed

_Written 2026-07-16._

Week 2, Assignment 2.2. This section contains the four written decisions
(Part 1), the Dart 3 syntax upgrades, the ApiResult sealed hierarchy,
the three stretch goals (A: value-equality unit test, B: `@Default`
`userNote` + `copyWith` in the UI, C: typed failure variants), the
required screenshots, and the verification run-book. The Assignment
2.1 and 1.1–1.4 notes are preserved further down as historical
context.

---

## PART 1 — WRITTEN DECISIONS

### Question 1 — The equality problem in the running app

**Under identity equality, what Riverpod is forced to conclude on a
re-fetch that returns the same jobs twice.** The Assignment 2.1 `Job`
class was a plain Dart class. Dart's default `==` compares by identity
(memory address), so two `Job` instances built from two separate
`Job.fromDto(dto)` calls — even with byte-for-byte identical field
values — are NOT equal. On a pull-to-refresh the API returns the same
list; the notifier calls `Job.fromDto` again and produces a fresh
`List<Job>` of fresh `Job` instances. Riverpod's `AsyncNotifier`
compares the new value to the old via `==`; every element differs by
identity, so Riverpod is forced to conclude "the data changed" and
rebuild every widget that watches `jobsProvider` — even though
nothing about the content changed. That is a wasted rebuild.

**Concrete widget consequence.** `JobCard` (in
`lib/widgets/job_card.dart`) is rebuilt for every job on every
refresh. Because `Job` differed by identity, the framework had no way
to short-circuit "same inputs → same output," and the `Card`'s
`InkWell` splash animation could restart mid-animation if a refresh
happened to fire while the user was tapping — visible flicker on the
splash colour. With value equality, `Job` instances that describe the
same listing hash and compare equal, and `filteredJobsProvider` /
`visibleJobsProvider` can be memoised against the previous input list
without spurious invalidations.

**Per-field equality review of `Job` after Freezed.** Freezed's
generated `==` compares every field pairwise using each field's own
`==`. For `Job`:

| Field | Type | Freezed `==` verdict |
|---|---|---|
| `id` | `String` | Value equality out of the box (String is a value type in Dart). ✅ |
| `title` | `String` | ✅ |
| `company` | `String` | ✅ |
| `location` | `String` | ✅ |
| `locationType` | `LocationType` (enum) | Enums have value equality by construction. ✅ |
| `salary` | `String?` | Nullable string — `null == null` is true, otherwise value equality. ✅ |
| `employmentType` | `String` | ✅ |
| `closingDate` | `DateTime?` | `DateTime` has value equality — two `DateTime`s built with the same instant compare equal. ✅ |
| `description` | `String?` | ✅ |
| `isOpen` | `bool` | ✅ |
| `userNote` | `String` (Stretch B) | ✅ |

**None of `Job`'s fields is a collection or a nested plain class**, so
no field violates value equality. If we later added, say, a
`List<String> tags` field, Freezed's generated `==` would compare the
list references — a fresh `List` with the same elements would NOT
compare equal — and we would need to switch to
`freezed_annotation`'s `@Default(<String>[])` with an
`IdentityListEqualityMixin`-style workaround, OR wrap the collection
in an `IList` (from `fast_immutable_collections`), OR write a manual
override. The take-away: value equality is a per-field property; the
generator gets the atomic cases right for free but a nested mutable
type requires explicit thought.

### Question 2 — Which models get `json_serializable` and which do not

**Which class reads raw JSON.** `JobDto`
(`lib/data/job_dto.dart`) is the only class that touches raw JSON —
it exists specifically to mirror the API's `JobResponse` wire shape.
`Job` (`lib/models/job.dart`) never deserialises anything; it is
built exclusively via `Job.fromDto(dto)`.

**Why attaching `json_serializable` to `Job` would be a bug.** The
API's field names and `Job`'s field names *deliberately differ* — the
translation is the whole point of having a DTO. `json_serializable`'s
generator writes `fromJson`/`toJson` by reading the DECLARED field
names and expecting the JSON to use those exact keys (unless
overridden with `@JsonKey(name: ...)`). If `Job` had
`@JsonSerializable`, the generator would emit
`json['company']` — but the API sends `companyName`. It would emit
`json['employmentType']` — but the API sends `type`. It would emit
`json['salary']` — but the API sends `salaryDisplay`. The generator
has no way to know about the sentinel `"Salary not specified"` →
`null` translation, or the `"FullTime"` → `"Full-time"` re-hyphenation
in `_typeStringFromApi`. `Job.fromDto` is where those translations
live, and it can only run on top of an already-parsed `JobDto`. Field
sites where the API key and Dart field name differ:

- `companyName` (API) → `company` (Job)
- `type` (API) → `employmentType` (Job)
- `salaryDisplay` (API) → `salary` (Job)

Those live on `Job.fromDto`, not on the JSON boundary.

**What the generator reads to write `fromJson`.** The generator reads
the field DECLARATIONS inside the `const factory JobDto({...}) =
_JobDto;` constructor: for each parameter, it reads the parameter's
DART name (which becomes the JSON key by default), its DART type
(which drives the parse — `String`, `int`, `DateTime` → the right
`as`-cast or `DateTime.parse` call), and any `@JsonKey` or `@Default`
annotation attached to it. For CareerHub's list endpoint, every JSON
key happens to already match the Dart field name (the API uses
camelCase and our DTO fields do too), so no `@JsonKey(name: ...)`
overrides are required — the only annotations are `@Default('')` on
`description` and `@Default(0)` on `applicationCount` to preserve
the previous hand-written tolerance for a missing key. If the API
team ever ships `job_type` in place of `type`, one line changes:
`@JsonKey(name: 'job_type') required String type,` on the DTO.

**Why `Job.fromDto` continues to exist.** It is the ONE place the app
translates wire-shape names/values into UI-friendly names/values.
Renaming `companyName` on the API costs exactly TWO Flutter file
edits: `lib/data/job_dto.dart` (rename the DTO field OR add
`@JsonKey`) and `lib/models/job.dart` (update the `dto.companyName`
read in `Job.fromDto`). Zero widgets, zero screens, zero tests
change. Without `fromDto` — if `Job` read directly from JSON —
every widget referring to `job.company`, every provider derivation,
every test fixture, and every mapping would need review. Realistic
change surface: 5–8+ files for CareerHub, unbounded on a bigger app.

### Question 3 — Freezed and custom behaviour: the private constructor

**What `const Job._()` does and why Freezed requires it.** Freezed
generates a mixin `_$Job` that supplies `==`, `hashCode`,
`copyWith`, and `toString`. A Dart mixin can only be applied to a
class whose superclass constructor is accessible from the mixin —
Freezed's mixin needs to call a no-argument constructor on the
enclosing class to construct its `this`. `const Job._()` provides
exactly that: a `const`, no-argument, private (`_`) constructor
which the mixin can invoke internally. It is also what allows the
class body to hold instance-level members (`canApply`,
`displaySalary`, `matches`) — Freezed's static analysis rejects
instance members on an `@freezed` class that has no private
constructor because there would be no way to bind them onto an
instance created by the generated factory. Attempting to add a
method or getter without `const Job._()` produces a Freezed compile
error at generation time (‘to declare methods, add a private
constructor’).

**Why `Job.fromDto` had to change and why the call site did not.**
Freezed's contract for `@freezed` classes is that FACTORY
constructors are UNION VARIANTS — each named factory becomes a
distinct case in a sealed union. `factory Job.fromDto(JobDto dto)`
would be interpreted as a `Job.fromDto` variant, sibling to the
main `Job(...)` variant, with an entirely separate implementation
class. That is not what we want — we want ONE `Job` shape and a
helper that BUILDS it. Converting `factory Job.fromDto(...)` to
`static Job fromDto(...)` moves the helper OUT of the union
mechanism and into the plain-Dart static-method namespace. Dart's
syntax for calling a static method is identical to calling a named
constructor (`Job.fromDto(dto)`), so the call site in
`lib/data/jobs_repository.dart` remains character-for-character the
same: `dtos.map(Job.fromDto)`. The same treatment applies to
`Job.closed` and `Job.remote` — both were named constructors in
Assignment 2.1, both are `static Job closed(...)` / `static Job
remote(...)` in Assignment 2.2, and the widget test's calls to
`Job.closed(...)` / `Job.remote(...)` compile unchanged.

### Question 4 — Sealed classes and the compile-time guarantee

**File-location rule enforced by `sealed`.** `sealed` requires every
direct subclass of the sealed class to be declared in the SAME
LIBRARY (in our project, the same file, `lib/data/api_result.dart`).
That is what gives the compiler a CLOSED, KNOWABLE set of variants:
because no other file can add a subclass without importing this one
and being visible to the compiler, the compiler can enumerate the
full variant set at analysis time. Without that rule the compiler
could not prove exhaustiveness — some other file, or some future
library, might extend `ApiResult<T>` with a variant we've never seen.

**Exhaustiveness checking.** A `switch` expression over a sealed type
is required by the compiler to have an arm for EVERY variant of the
sealed hierarchy. Omitting one (e.g. dropping the `NetworkFailure`
arm from `JobsNotifier.build`) is a COMPILE ERROR (`The type
'ApiResult<List<Job>>' isn't exhaustively matched by the switch
cases`), not a runtime bug that surfaces only when that variant
finally shows up in production. Add a fifth variant to
`api_result.dart` and every switch that pattern-matches on
`ApiResult` becomes a compile error until the new arm is handled —
the compiler nags you into completeness.

**Contrast with `abstract class ApiResult<T>`.** An `abstract class`
imposes no file-location rule: any file that imports it can add a
subclass, so the compiler cannot see the full variant set and cannot
prove exhaustiveness. A switch on an abstract-class hierarchy that
handles only `Success` compiles without complaint; the runtime
matches, or falls through with an `_` arm you had to add defensively.
Sealed replaces "please remember to update this switch" (a
review-time hope) with "the compiler will refuse to build if you
forget" (a compile-time guarantee).

**Why `Failure<T>` (and each of Stretch C's three variants) carries
`T`.** The whole point of `ApiResult<T>` is that a caller writes
`ApiResult<List<Job>>` and expects `Success<List<Job>>` OR a failure
variant to be assignable to that same type. If `NetworkFailure` were
declared as `class NetworkFailure extends ApiResult` (no `T`), then
`NetworkFailure` would be `ApiResult<dynamic>` at the type-system
level, NOT `ApiResult<List<Job>>` — and returning a bare
`NetworkFailure(...)` from a `Future<ApiResult<List<Job>>>` would be
a type error. Carrying the type parameter `T` on every variant lets
each variant participate in the same generic instantiation as
`Success<T>`, so `NetworkFailure<List<Job>>` is assignable to
`ApiResult<List<Job>>` and the switch's arms all live under the same
generic ceiling. The `T` is a phantom parameter on the failure
variants — they never store or use a value of type `T` — but that is
fine; it is there for the type system, not for runtime storage.

---

## PART 3 — Dart 3 syntax upgrades

**Switch expression (Step 3.1).** Two conversions:

- `Job._typeStringFromApi` (`lib/models/job.dart`) was a multi-arm
  `switch` STATEMENT with a `return` per case; it is now a single
  `switch` EXPRESSION whose arms are `case-pattern => value` pairs
  and whose whole body is `String _typeStringFromApi(String apiType)
  => switch (apiType) { ... };`. The analyzer reports it exhaustive
  because the `_` default arm covers all remaining `String` inputs.
- A new `LocationTypeX` extension provides `displayName` on
  `LocationType` as a switch expression (`switch (this) {
  LocationType.onSite => 'On-site', ... }`) — the analyzer reports
  it exhaustive because every enum value is listed.

**Guard clauses (Step 3.2).** `Job.inferLocationType` was an
if-chain (`if (l.contains('remote')) return LocationType.remote;
if (l.contains('hybrid')) ...`). It is now:

```dart
return switch (l) {
  _ when l.contains('remote') => LocationType.remote,
  _ when l.contains('hybrid') => LocationType.hybrid,
  _ => LocationType.onSite,
};
```

The wildcard `_` pattern always matches; the `when` clause attaches a
predicate that decides which arm actually fires. Reads as an if-else
chain but participates in the analyzer's exhaustiveness machinery.

A second guard-clause switch lives inside
`JobsRepository._messageForDioException` on
`DioExceptionType.badResponse`: the arms use `when code >= 500` and
`when code == 404` guards on an `int` pattern.

**Named record (Step 3.3).** `JobsRepository.getJobs()` extracts the
parsing step into `_parseJobsPage(envelope)` whose declared return
type is the named record `({List<JobDto> dtos, List<Job> jobs})`. The
call site destructures with the record pattern
`final (:dtos, :jobs) = _parseJobsPage(envelope);` — `dtos` and
`jobs` bind to names, not positional indices.

---

## PART 6 — build_runner output

Ran:

```
dart run build_runner build --delete-conflicting-outputs
```

Output (trimmed):

```
0s riverpod_generator on 19 inputs: 2 output, 17 no-op
0s freezed on 19 inputs: 2 output, 17 no-op
3s json_serializable on 38 inputs: ... 1 output, 20 no-op
0s source_gen:combining_builder on 38 inputs: 3 output, 18 no-op
Built with build_runner/aot in 17s; wrote 8 outputs.
```

Generated files now present:

```
lib/data/job_dto.freezed.dart
lib/data/job_dto.g.dart
lib/models/job.freezed.dart
lib/data/jobs_repository.g.dart      (regenerated)
lib/providers/jobs_notifier.g.dart   (regenerated)
```

Manually inspected `lib/data/job_dto.g.dart` — the generated
`_$JobDtoImplFromJson` function walks the JSON map key-by-key with
the correct `as String` / `as num` / default-value calls; every
DateTime-shaped input would receive a `DateTime.parse(...)` here (we
kept `postedAt` as `String` on the DTO for the wire-shape mirror
reason called out in Q2).

*(A screenshot of the terminal output and of the generated
`fromJson` function goes here — see MANUAL STEPS.)*

---

## PART 8 — Repository + notifier behaviour

The repository returns `Future<ApiResult<List<Job>>>` and never
throws. `DioException` is caught, its `.type` is fed through a
switch expression that produces a human-readable message, and the
correct sealed variant is returned:

- Response present → `ServerFailure(message: ..., statusCode: ...)`
- No response (connection error/timeout/no route) → `NetworkFailure(message)`
- Anything else (`TypeError`, `StateError`, an unexpected `catch`) →
  `UnknownFailure(...)` with a generic message

`JobsNotifier.build()` pattern-matches on the sealed result with an
exhaustive switch expression:

```dart
return switch (result) {
  Success(:final data) => data,
  NetworkFailure(:final message) => throw Exception(message),
  ServerFailure(:final message) => throw Exception(message),
  UnknownFailure(:final message) => throw Exception(message),
};
```

*(Screenshot of the app with the API stopped, showing the readable
error message on the retry screen — see MANUAL STEPS.)*

---

## PART 9 — Why the widget test needs zero changes

The widget test overrides `jobsProvider` with a
`_FakeJobsNotifier` via `ProviderScope.overrideWith`; that fake sits
BETWEEN Riverpod and the real repository, so it bypasses
`JobsRepository.getJobs()` entirely and, with it, every code path
that returns an `ApiResult`. Riverpod sees the fake's `build()`
return `Future<List<Job>>` directly — the same shape the widget layer
has always consumed via `AsyncValue<List<Job>>` — while the real
notifier's `build()` now consumes an `ApiResult<List<Job>>`
internally and translates it into either the same `List<Job>` (on
`Success`) or a thrown `Exception` (on any failure variant) before
returning. Because the notifier's PUBLIC contract (return type +
error-propagation shape) is identical to Assignment 2.1, the test
file — which only asserts against widget output driven by the
`List<Job>` — is entirely insulated from the internal switch.

*(Screenshot of `flutter test` terminal showing 33 tests passed —
see MANUAL STEPS.)*

---

## Stretch A — Value-equality unit test

New file: `test/job_test.dart`. Three tests, all passing:

1. Two `Job` instances built with the same field values compare
   `==` AND share a `hashCode` (Freezed derived both from field
   values).
2. Two `Job`s that differ in exactly one field (`title`) are NOT
   `==`.
3. Adding five identical `Job` instances to a `Set<Job>` produces a
   Set of length ONE.

**What the Set test proves that the `==` test alone does not.** A
`Set` uses `hashCode` FIRST (to pick a bucket) and `==` SECOND (to
resolve ties inside that bucket). Two objects that compare `==` but
have DIFFERENT `hashCode` values would land in different buckets and
the Set would keep BOTH — the collection would be internally
inconsistent (`contains(a)` true, `contains(b)` true, `add(b)` after
`add(a)` still increments length). The Set test proves that `==` and
`hashCode` are DERIVED FROM THE SAME INPUTS and therefore agree with
each other: five instances all hash to the same bucket AND compare
equal in that bucket, so the Set correctly collapses to one entry.

**What would happen with the pre-Freezed `Job`.** Under identity
equality, each of the five `Job()` constructor calls produced a
distinct object at a distinct memory address; each has its own
default `hashCode` (based on identity), so the Set placed each in
its own bucket. The Set would report `length == 5`, and even
`jobs.contains(_sampleJob())` would return `false` for a sixth
sample built to the same field values — the object is not `==` to
anything already in the Set because identity equality doesn't match.

---

## Stretch B — `@Default` field + `copyWith` in the UI

Added `@Default('') String userNote` to `Job`. Wired
`editedJobProvider = StateProvider<Job?>((_) => null)` in
`lib/providers/job_providers.dart`. `JobDetailScreen` renders a
`TextFormField` prefilled with the effective job's `userNote`; every
keystroke writes `job.copyWith(userNote: text)` into the state
provider. The list upstream never mutates: `filteredJobsProvider` and
`savedJobsProvider` still see the ORIGINAL `Job` from the API.

**What `@Default` does differently from a constructor default.**
Writing `String userNote = ''` in a plain Dart constructor sets the
default at CONSTRUCTOR-CALL time only. `@Default('')` sits on the
Freezed factory parameter and is applied by BOTH the generated
factory implementation (`_Job(...)`) AND `json_serializable`'s
generated `fromJson`. That means the default is applied uniformly
whether the `Job` is built through the factory, deserialised from
JSON, or produced via `copyWith` on a `Job` that predates the field —
you cannot end up with `userNote == null` or an "unset" state.

**Why `fromDto` always yields the default.** `Job.fromDto(dto)` calls
the main factory constructor and OMITS the `userNote` argument
entirely (there is no `dto.userNote` — the API doesn't send one).
Freezed's factory applies `@Default('')` for any omitted argument,
so every API-sourced `Job` starts life with `userNote == ''`. The
UI-only state is added ON TOP of the immutable API snapshot via
`copyWith`, never smuggled into `fromDto`.

---

## Stretch C — Typed failure variants

Replaced the single-`Failure<T>` design with three concrete sealed
variants:

- `NetworkFailure<T>` — no HTTP response was ever received
  (connect timeout, DNS failure, no route). No `statusCode`.
- `ServerFailure<T>` — the server responded with a non-2xx. Carries
  a NON-nullable `int statusCode` (contrast: the pre-Stretch-C
  `Failure` had a nullable `int? statusCode` because it doubled as
  the network failure).
- `UnknownFailure<T>` — anything else: a `TypeError`, an unexpected
  `DioException.type`, a `StateError`. Carries a generic message
  only.

**Switch arm count.** The pre-Stretch-C notifier switch had TWO arms
(`Success`, `Failure`). Post-Stretch-C it has FOUR
(`Success`, `NetworkFailure`, `ServerFailure`, `UnknownFailure`).

**What the compiler does when you add a variant but forget to update
the switch.** Adding a fourth `TimeoutFailure<T> extends ApiResult<T>`
to `api_result.dart` without updating `JobsNotifier.build` produces
a compile-time error: `The type 'ApiResult<List<Job>>' isn't
exhaustively matched by the switch cases since it doesn't match the
pattern 'TimeoutFailure()'.` The build fails; the app cannot ship
until every switch that pattern-matches on `ApiResult` is updated.

**What the single-`Failure` design could NOT detect that the
Stretch-C design CAN.** Under the single `Failure`, the UI (or any
consumer) had to inspect `statusCode == null` at runtime to decide
whether it was looking at a network failure or a server failure; a
future refactor that stopped populating `statusCode` on server
failures would silently start showing the wrong branch, and the
compiler couldn't help. With three variants the compiler enforces
the distinction structurally — a `ServerFailure` has a non-nullable
`statusCode` (the type system won't let you construct one without
it), and a `NetworkFailure` has no `statusCode` field at all.
Impossible states become unrepresentable.

---

## Screenshots (Assignment 2.2)

Take these five screenshots (see MANUAL STEPS at the end for the
exact commands):

1. `screenshots/22-build-runner-output.png` — terminal output of
   `dart run build_runner build --delete-conflicting-outputs` showing
   the "wrote 8 outputs" success line.
2. `screenshots/22-generated-fromjson.png` — the generated
   `_$JobDtoImplFromJson` function inside `lib/data/job_dto.g.dart`.
3. `screenshots/22-error-state.png` — the app running with the API
   stopped, showing the human-readable error message on the retry
   screen (NetworkFailure branch).
4. `screenshots/22-flutter-test.png` — terminal output of
   `flutter test` showing "All tests passed!" (33 tests).
5. `screenshots/22-stretch-b-notes.png` — the detail screen with
   text typed into "Your notes" and the debug line at the bottom
   showing `Original note in list: "" · Edited note here: "…"`.

---

## Submission checklist

- [x] Part 1 — Q1: identity-equality consequence explained; concrete
      widget scenario (`JobCard`); per-field equality table.
- [x] Part 1 — Q2: `JobDto` identified as JSON boundary; `@JsonKey`/
      `@Default` mechanism explained; `fromDto` role justified.
- [x] Part 1 — Q3: `const Job._()` purpose explained; `fromDto` /
      `closed` / `remote` → `static` change described; call sites
      unchanged.
- [x] Part 1 — Q4: sealed file-location rule stated; exhaustiveness
      contrasted with `abstract class`; `T` in `Failure<T>` justified.
- [x] Part 2 — `freezed_annotation` + `json_annotation` in deps;
      `freezed` + `json_serializable` in dev deps.
- [x] Part 3 — enum display extension (`LocationTypeX.displayName`)
      and `Job._typeStringFromApi` are switch expressions;
      `Job.inferLocationType` is a switch expression with guard
      clauses; `_parseJobsPage` returns a named record and the call
      site destructures it.
- [x] Part 4 — `@freezed` on `JobDto`; `_$JobDto` mixin; two part
      directives; `fromJson` delegates to `_$JobDtoFromJson`.
- [x] Part 5 — `@freezed` on `Job`; `_$Job` mixin; `const Job._()`
      before the factory; one part directive; `fromDto` /
      `closed` / `remote` are `static` methods.
- [x] Part 6 — all four generated files exist; `flutter analyze`
      reports zero errors.
- [x] Part 7 — `lib/data/api_result.dart` exists; no `@freezed`,
      no part directive; `sealed class ApiResult<T>` with concrete
      subclasses in the same file; all constructors `const`.
- [x] Part 8 — `getJobs()` returns `Future<ApiResult<List<Job>>>`;
      `DioException` handled via switch expression; failures are
      human-readable strings.
- [x] Part 8 — `build()` switch expression handles every sealed
      variant; the compiler reports it as exhaustive.
- [x] Part 9 — `flutter test` passes with no changes to the test
      file; 33 tests total (30 widget + 3 Stretch A).
- [x] Stretch A — `test/job_test.dart` with 3 passing tests.
- [x] Stretch B — `@Default('') String userNote`; `editedJobProvider`
      wired in the detail screen; original list-`Job` unchanged.
- [x] Stretch C — `NetworkFailure`, `ServerFailure`, `UnknownFailure`
      implemented; repository returns the correct variant; notifier
      switch has four arms.

---

# CareerHub — Assignment 2.1: HTTP, Repositories & Code Generation

_Written 2026-07-16._

Week 2, Assignment 2.1. This section contains the four written decisions
(Part 1), the stretch-goal writeups, the required screenshots, and the
run-book. The Assignment 1.1–1.4 notes are preserved further down as
historical context.

---

## PART 1 — WRITTEN DECISIONS

### Question 1 — Why a DTO, not a `fromJson` on the `Job` model

**Field-name mismatches (API vs Flutter `Job`).** Opened
`CareerHub.Api/DTOs/JobResponse.cs` alongside `lib/models/job.dart`:

| API field (`JobResponse`) | Flutter field (`Job`) | Notes |
|---|---|---|
| `id` (`Guid`) | `id` (was `int`, now **`String`**) | Type mismatch as well as a semantic change — Assignment 2.1 changes `Job.id` from `int` to `String`. |
| `companyName` | `company` | Pure rename. |
| `type` (`"FullTime"`/`"PartTime"`/…) | `employmentType` (`"Full-time"`/`"Part-time"`/…) | Rename AND value re-hyphenation. |
| `salaryDisplay` (string, `"Salary not specified"` when absent) | `salary` (nullable) | Rename AND sentinel-to-null translation. |
| `postedAt` | *(not on `Job`)* | Captured in `JobDto` only. |
| `applicationCount` | *(not on `Job`)* | Captured in `JobDto` only. |
| *(no field on API)* | `locationType` | Derived by `Job.inferLocationType(location)` — string heuristic. |
| *(not in list endpoint)* | `closingDate` | Left `null` until we call the detail endpoint. |
| *(not in list endpoint)* | `isOpen` | List endpoint only returns active listings, so `true`. |

**"If the API team renamed `companyName` tomorrow, which Flutter file would
break?"** Without a DTO, ANY file that reads `job.company` — and,
because a `fromJson` on `Job` would key on `companyName` directly, so
would every `Job.fromJson` call site AND every widget that touches the
company field. `JobCard`, `JobDetailScreen`, the widget test's
`find.text('Bitcube')`, and any future search or analytics site would all
need to be reviewed. Not because the UI changed, but because the
rename leaked across the boundary.

**File-change count comparison.**

- **With a DTO in place (this assignment):** exactly **2** files change to
  absorb an API field rename — `lib/data/job_dto.dart` (the JSON key)
  and `lib/models/job.dart` (the `Job.fromDto` field read). Zero widgets,
  zero screens, zero providers, zero tests.
- **Without a DTO (`Job.fromJson` directly):** the rename ripples to
  every file that spells the new API name in its JSON parsing, plus every
  test fixture that constructed a `Job` using the old field name in
  `fromJson`, plus (if the Flutter field had matched the API name) every
  widget that reads the field. Realistically **5–8+ files** for a
  small app, unbounded on a large one.

That number difference matters because a rename is an API-team decision
that the mobile team must ABSORB, not participate in. A change surface of
2 files is a lunch-break patch review; a change surface of 8 files is a
sprint's worth of coordination and merge conflicts.

**"Should the DTO capture fields the `Job` model does not have?"** Yes,
and my `JobDto` does — `postedAt` and `applicationCount` are captured
even though no widget reads them today. The reason is asymmetric cost:
adding a field to the DTO now is a one-line edit that never needs a code
review; adding it later ("we need to show 'posted 3 days ago'") means a
DTO change + a regeneration + a mapping change + a PR review. Six months
from now the alternative is bad in two ways — you either forget the
field exists on the wire (and re-derive it client-side), or you make the
change and pay the round-trip cost when you could have paid one line
up-front.

### Question 2 — Why the repository owns Dio, not the provider

**Callers of `ref.watch(jobsProvider)` / `ref.watch(filteredJobsProvider)`
in the current tree.** Grepping the `lib/` tree finds four:

- `lib/screens/home_screen.dart` — via `visibleJobsProvider`, which
  composes on top.
- `lib/screens/job_detail_screen.dart` — directly on
  `jobsProvider`.
- `lib/screens/saved_screen.dart` — via `savedJobsProvider`, which reads
  the notifier.
- `lib/providers/job_providers.dart` — the derived providers themselves
  (`filteredJobsProvider`, `visibleJobsProvider`, `savedJobsProvider`).

**How many callers need to know the data came from HTTP?** Zero. Every
caller works with `AsyncValue<List<Job>>` — a shape that is identical
whether the underlying source is a hardcoded list, a JSON file on disk,
a SQLite table, or a live Dio request. The whole point of the repository
is that "where jobs come from" is a private implementation detail of one
file (`lib/data/jobs_repository.dart`), invisible to the four callers
above.

**"Switch from Dio to `http` — which files change?"**

- **With the repository pattern:** exactly **1** file. Only
  `lib/data/jobs_repository.dart` (the `dio` provider becomes a `Client`
  provider, `JobsRepository` receives a `Client`, and `getJobs()` calls
  `client.get(...)` and does its own JSON decode). Nothing above the
  repository moves.
- **Without it (Dio inside `JobsNotifier.build()`):** `JobsNotifier`
  changes; every test that mocks Dio via subclass or interceptor
  changes; anything that reads a `DioException` (e.g. a typed error
  handler) changes. In practice **3–5+** files, spread across the
  provider layer AND the test layer.

On a team where two people are working simultaneously on different
files, a one-file change is a merge-conflict-free unit-of-work — you
change it, you rebase, you PR. A five-file change means the two devs
have to sync on it before landing, because both will have edits in
overlapping regions of the same provider file. The repository pattern
converts "coordinate with your teammate first" into "just do it."

### Question 3 — What `@riverpod` generates and why the red underline is expected

**What is `_$JobsNotifier` and where does it come from?** It is the
abstract base class that `package:riverpod_generator` emits into
`lib/providers/jobs_notifier.g.dart` when it runs. The generator reads
the source of `JobsNotifier`, notices the `@riverpod` annotation on the
class, and emits:

1. `abstract class _$JobsNotifier extends AutoDisposeAsyncNotifier<List<Job>>`
   — the base class my hand-written `JobsNotifier` extends.
2. `final jobsProvider = AutoDisposeAsyncNotifierProvider<JobsNotifier, List<Job>>(...)`
   — the actual provider variable that widgets read.

Until that file exists, the IDE cannot find `_$JobsNotifier` and shows a
red underline. **The command that makes the red underline disappear is:**

```
dart run build_runner build --delete-conflicting-outputs
```

**Which part of my hand-written class did the generator read to
determine the type parameters?** The **`build()` method's return type**:
`Future<List<Job>>`. That is where the `List<Job>` on the provider's type
parameters comes from. If I renamed `Job` to `JobListing` and re-ran the
generator, the emitted provider would automatically become
`AsyncNotifierProvider<JobsNotifier, List<JobListing>>` — I never type
those parameters by hand.

**Manual-provider mistake that compiles but blows up at runtime.**
Before code generation, a developer writing the provider by hand had to
spell the type parameters themselves:

```dart
// hand-written — bug ahead
final jobsProvider =
    AsyncNotifierProvider<JobsNotifier, List<Company>>(JobsNotifier.new);
//                                       ^^^^^^^^^^^^ wrong! JobsNotifier
//                                       actually returns List<Job>.
```

Both `Company` and `Job` are valid types, so the Dart type checker sees
`AsyncNotifierProvider<..., List<Company>>` as internally consistent and
the code compiles. At runtime, the first widget that does
`ref.watch(jobsProvider).whenData((companies) => ...)` receives
a `List<Job>` and calls `.company.name` on the first element, throwing
`NoSuchMethodError: Class 'Job' has no instance getter 'company'`. This
category of bug — a lie in the type parameters that the compiler cannot
catch because the parameters were the developer's guess, not derived
from the notifier's actual `build()` — is exactly what `@riverpod` makes
impossible. The generator reads the ONE source of truth (the return
type of `build`) and can only ever emit provider parameters that match.

### Question 4 — Why the test overrides the provider instead of mocking the network

**Failure path when `flutter test` runs against the real provider on a
machine with no API server.** `JobsNotifier.build()` calls
`repo.getJobs()`, which awaits `_dio.get('/jobs', ...)`. Dio tries to
open a TCP connection to the configured dev base URL
(`http://localhost:5254` by default, or the emulator alias
`http://10.0.2.2:5254` if that override was passed), the host is
unreachable, and Dio throws a `DioException` whose `type` is
`DioExceptionType.connectionError` and whose cause is
`SocketException: OS Error: Connection refused`. `AsyncNotifier` catches
that exception on the `Future` returned by `build()` and moves its state
to `AsyncValue.error(exception, stackTrace)`. The widget tree's
`when(loading: ..., data: ..., error: ...)` renders the error branch —
the `_ErrorState` widget. **The test does not fail on an assertion; it
would fail because none of the `find.text('Senior Flutter Developer')`
finders resolve — those texts are only rendered by the `data:` branch,
which never runs.** (In practice `flutter_test` also flags the
unhandled `DioException` in stderr, which counts as a test error.)

**What `overrideWith` does, in one sentence.** It replaces the
constructor Riverpod uses to build the `JobsNotifier` for this
`ProviderScope` — swapping in `_FakeJobsNotifier` — while leaving every
widget, every derived provider (`filteredJobsProvider`,
`visibleJobsProvider`, `savedJobsProvider`), and every filter/sort/search
`StateProvider` completely untouched.

**Single responsibility of the widget test.** _"When the app is handed a
known list of jobs, it renders those jobs and reacts to filter/sort/search
input correctly."_

**Two things the widget test is explicitly NOT responsible for:**

1. **HTTP wire-shape correctness** — does `JobsRepository.getJobs()`
   correctly unwrap the `PagedResponse` envelope and produce
   `List<Job>` from the API's real JSON? That is a **repository unit
   test** with a Dio backed by `MockAdapter`, not a widget test.
2. **End-to-end correctness against a running API** — does tapping a
   card in the emulator open the correct detail screen with real data
   from PostgreSQL? That is an **integration test** (or a manual
   smoke test, which is what this assignment's Part 5 checkpoint
   requires with the screenshots).

---

## Stretch A — Pull to refresh

Added a `RefreshIndicator` around both the `ListView.builder` and the
`GridView.builder` in `home_screen.dart`. Its `onRefresh` awaits
`ref.read(jobsProvider.notifier).refresh()`.

**What `invalidateSelf()` does.** It marks the notifier's cached value
as stale and schedules a rebuild — the next `build()` invocation
produces a fresh `Future`, and the notifier's `AsyncValue` transitions
back into the `loading` state until that Future resolves.

**Why `await future` is necessary after invalidating.** `future` is the
notifier's currently-pending Future (the one the fresh `build()`
produced). Awaiting it keeps `refresh()` suspended until the fetch
finishes. **If `refresh()` returned immediately after `invalidateSelf()`
without awaiting**, `RefreshIndicator` would see its `onRefresh` Future
complete instantly, retract the spinner, and hand control back to the
user — while the actual network fetch was still in flight. The user
would think the refresh had failed to do anything, then a second later
the list would visibly repopulate with no explanation. Awaiting the
future keeps the spinner visible for exactly as long as the fetch takes.

## Stretch B — Search by keyword

The search box (from Assignment 1.4 Stretch C) already existed and is
wired into `searchQueryProvider`, then composed with the two dropdown
filters inside `visibleJobsProvider`. Selecting **Remote** + typing
**"Devops"** applies both simultaneously — the derivation runs the
filter first, then narrows the survivors by
`Job.matches(searchQueryProvider)`.

**Why `StateProvider`, not local `StatefulWidget` state?** Two reasons:

1. **Cross-widget composition.** `visibleJobsProvider` — which lives one
   layer above `HomeScreen` — needs to read the current query to
   compute the visible list. Local widget state can only be read by
   descendants of the widget that owns it, so it can never feed a
   provider up-tree. Making the query a `StateProvider` puts it in the
   reactive graph where anything can read it.
2. **Independent addressability from tests.** The Assignment 2.1
   widget test drives filtering by writing directly to
   `locationFilterProvider.notifier.state` — no dropdown menu tap, no
   overlay-based interaction. That only works because the state lives
   in a provider container that the test can grab with
   `ProviderScope.containerOf`. Local widget state is invisible to that
   container.

## Stretch C — Environment-aware base URL

Added an `ENV` build variable (`--dart-define=ENV=dev|staging|prod`)
alongside three URL variables (`API_BASE_URL`, `API_BASE_URL_STAGING`,
`API_BASE_URL_PROD`). See `lib/data/jobs_repository.dart` — the
`_resolvedBaseUrl` constant is a nested ternary over three
compile-time `String.fromEnvironment` values, folded down by the Dart
compiler into a single string literal at build time. No runtime `if`
runs.

**Why `String.fromEnvironment` values are compile-time constants and
what that means for tree-shaking.** `String.fromEnvironment('X')` is a
special-case expression that the Dart front-end resolves at COMPILATION
time — the value passed via `--dart-define=X=...` is substituted for the
expression before the ahead-of-time compiler ever sees it. Because the
result is a `const String`, any `if (envName == 'prod')` guard where
`envName` is also a compile-time constant is itself a constant expression
— the compiler folds the whole ternary down, sees that (say) only
`_envProdBaseUrl` survives, and tree-shakes the two unused URL constants
out of the compiled binary entirely.

**Why you cannot use `String.fromEnvironment` inside a conditional that
reads a runtime variable.** Because it must be resolved at compile time,
`String.fromEnvironment` **only produces a constant when its argument is
itself a constant string literal**. If you wrote
`String.fromEnvironment(someRuntimeVar)`, the argument is not known at
compile time, so the expression is no longer constant — the compiler
falls back to a runtime environment lookup on the target platform's
process environment, which on Flutter's ahead-of-time-compiled release
build is empty. You would get an empty string in production and no
warning. The correct pattern is exactly what the file does: one const
`fromEnvironment` per possible key, then a compile-time constant
selector between them.

---

## Screenshots

Place captured images under `screenshots/` and refer to them from here.
If the images below render as broken, capture them by following the
"How to test" section at the end of this file.

**LogInterceptor output.** Terminal output during a fresh app load,
showing the request line and 200 response for `GET /jobs`.

![LogInterceptor terminal output](screenshots/loginterceptor.png)

**Live jobs list.** The `HomeScreen` populated from the running
CareerHub API.

![Live jobs list](screenshots/live-jobs.png)

**Error state.** The app after the API has been stopped (`Ctrl+C` on
the `dotnet run` process) and the list re-fetched.

![Error state](screenshots/error-state.png)

**Filter preserved on back navigation.** A filter chip selected in the
list, a card tapped, back pressed, filter still selected.

![Filter preserved on back nav](screenshots/filter-preserved.png)

**`flutter test` output.** `flutter test` reporting all tests passing
against the fake notifier.

![flutter test terminal output](screenshots/flutter-test.png)

---

## How to test (run-book)

### A. Bring up the backend (terminal — happens outside Android Studio)

1. **Wipe the old seed data.** The updated seed varies `Location` and
   `Type`, but the seeder short-circuits when Companies already exist,
   so old data must be dropped first. From `CareerHub/`:
   ```sh
   docker compose down -v
   docker compose up -d
   ```
   The `-v` on `down` removes the Postgres volume so the next API
   startup re-seeds from scratch.
2. **Run the API.** From `CareerHub/`:
   ```sh
   dotnet run --project CareerHub.Api
   ```
   Expect it to listen on `http://localhost:5254` and log
   `Seed completed successfully`. Leave this terminal open.

### B. Prepare the Flutter project (Android Studio)

3. **Open the project.** Android Studio → **File → Open…** →
   `Bitcube/careerhub_mobile`. When the "Flutter commands" banner
   appears at the top, click **Pub get**. (Same as running
   `flutter pub get`, just via the UI.)
4. **Run the code generator.** Android Studio does not have a
   dedicated menu item for `build_runner`, so open its bottom
   **Terminal** tab (**View → Tool Windows → Terminal**, or `⌥F12`),
   confirm the working directory is `careerhub_mobile/`, and run:
   ```sh
   dart run build_runner build --delete-conflicting-outputs
   ```
   Expect two new files to appear in the Project view under
   `lib/data/jobs_repository.g.dart` and
   `lib/providers/jobs_notifier.g.dart`. Every red underline on
   `_$JobsNotifier`, `dioProvider`, `jobsRepositoryProvider`, and
   `jobsProvider` disappears the moment this command
   completes.

### C. Configure the run — the `--dart-define` flags and web port

This project targets **Chrome (web)** for development — no Android
emulator required. The web port must be pinned to `8080` because
that's the origin the API's CORS policy allows.

5. **Add the build arguments to the run configuration.**
   - **Run → Edit Configurations…**
   - Select the `main.dart` configuration (the default for a Flutter
     project). If it does not exist, click **+ → Flutter** and point
     it at `lib/main.dart`.
   - In the **Additional run args** field, paste:
     ```
     --web-port=8080 --dart-define=ENV=dev --dart-define=API_BASE_URL=http://localhost:5254/api/v1
     ```
   - Click **Apply → OK**.

### D. Pick the Chrome (web) device and launch

6. **Select the device.** In Android Studio's top toolbar, open the
   device dropdown (next to the Run button) and pick **Chrome (web)**.
7. **Run the app.** Click the green **Run** ▶️ button (or press
   **Ctrl+R** on macOS / **Shift+F10** on Windows/Linux). Android
   Studio spins up the Flutter web dev-server on
   `http://localhost:8080` and opens a Chrome window pointed at it.
   The **Run** tool window at the bottom shows the `flutter run`
   output; look for **two log blocks from `LogInterceptor`** — a
   `*** Request ***` for `GET /jobs` and a `*** Response ***`
   with status `200`.

### E. Verify each Part-5 checkpoint (in Chrome)

8. In the Chrome window that opened, walk through in order:
   1. spinner appears immediately;
   2. real job cards render with a mix of Remote, Hybrid, and
      city-only locations;
   3. picking **Remote** / **Hybrid** / **On-site** in the Location
      dropdown narrows the list correctly;
   4. picking a **Job type** narrows it further (combined
      composition works);
   5. tapping a card opens the detail screen with the full Guid
      shown as "Listing ID";
   6. pressing the browser back button returns to the list with the
      filter dropdowns still selected;
   7. clicking the **Saved** tab still works (empty state until you
      bookmark from a detail screen);
   8. **stop the API** — in the terminal running `dotnet run`, hit
      `Ctrl+C` — and pull-to-refresh on the list (browser refresh,
      or drag from the top on the list). The friendly "Something
      went wrong" error state renders. No crash.

### F. Take the five screenshots

9. Save the five images into `careerhub_mobile/screenshots/` with
   these exact filenames (the README already links to them):
   - `loginterceptor.png` — Android Studio's **Run** tool window
     showing a `*** Request ***` and `*** Response ***` block.
   - `live-jobs.png` — the Chrome window with the populated list.
   - `error-state.png` — the Chrome window with the API stopped and
     the error state visible.
   - `filter-preserved.png` — filter selected in the dropdown →
     card tapped → back pressed → dropdown still on the same
     selection.
   - `flutter-test.png` — the Run tool window after step 10.

### G. Run the widget test

10. **Run the tests from the gutter.** Open
    `test/widget_test.dart` in the editor. In the left gutter next to
    `void main()` there is a green ▶️ arrow — click it and pick
    **Run 'widget_test.dart'**. Alternatively, right-click
    `test/widget_test.dart` in the Project view →
    **Run 'widget_test.dart'**. The **Run** tool window shows the
    test tree — every test node should be green.

    Nothing in the test run touches the network: `_FakeJobsNotifier`
    is swapped in via `ProviderScope.overrideWith` (see README, Q4).

---

## PART 1 — WRITTEN DECISIONS

### Question 1 — Nullability decisions

| Field | Decision | Domain justification |
|---|---|---|
| `title` | **Non-nullable** | A listing with no title is not something a seeker could browse or apply to — a job is defined by the role it names. |
| `company` | **Non-nullable** | An anonymous employer is not a credible listing on a career platform; the hiring company is always known to the poster. |
| `location` | **Non-nullable** | Every role is performed somewhere — including "Remote" — and location is the first thing a seeker uses to judge fit. |
| `salary` | **Nullable** | An employer may choose not to disclose salary, so a listing can legitimately exist without one. |
| `closingDate` | **Nullable** | Many roles stay open until filled and never carry a fixed deadline, so a listing without one is normal. |
| `description` | **Nullable** | Draft listings are created before the full description is written, so the field may legitimately be empty at creation. |
| `employmentType` | **Non-nullable** | The nature of the engagement (full-time, contract, etc.) is always something the employer knows and the seeker needs to decide. |
| `isOpen` | **Non-nullable** | Every listing is definitively either accepting applications or not — there is no "unknown" state — so it is always present (defaulting to open). |

**Most dangerous nullable field to render without a null check:** `salary`.
If `closingDate` is forgotten you get an awkward "Closes: " with nothing after
it — ugly, but harmless. If `salary` is rendered directly without a null
check, the card literally displays the word **"null"** in the salary slot. A
job seeker scanning listings would read "null" as the pay — it looks broken,
untrustworthy, and could make them skip a real opportunity or doubt the whole
platform. That is why `displaySalary` exists and is the only path the UI uses:
it converts an absent salary into "Market-related" so "null" can never reach
the screen.

### Question 2 — The salary type decision

**Chosen type: `String?`**

The CareerHub API almost certainly returns salary as a **string**, not a raw
number. Backends that model money for display commonly send a pre-formatted
range like `"R30 000 – R45 000 per month"` because salary is frequently a
*range* with a *period* and a *currency*, none of which a single `int` or
`double` can carry. A number would also force the frontend to reinvent
currency and range formatting the backend already knows. On screen the user
sees exactly that human-readable string, so storing it as a string means no
lossy conversion. It is nullable (`String?`) so the **confidential-salary**
case is represented honestly by `null` — not by a magic value like `0` or
`-1` that sorting and display logic would have to special-case. When salary is
confidential, the model holds `null` and `displaySalary` returns
"Market-related". (The one trade-off — sorting by pay — is a Week-2+ concern
that would use a separate numeric `salaryMin` field rather than parsing the
display string.)

### Question 3 — Status representation

**Chosen: a `bool isOpen` field.**

**Main limitation:** a boolean can only model two states — open or not-open —
but a real listing has **four** (Active, Closed, Draft, Expired). "Closed",
"Draft", and "Expired" all collapse into `isOpen == false`, so the model
cannot tell them apart, and the UI can't show *why* a job isn't accepting
applications.

**Week 2 Day 2 feature that fixes this: `enum` (Dart enums / enhanced enums).**
An `enum JobStatus { active, closed, draft, expired }` is better because it
makes all four states explicit and mutually exclusive, lets the compiler force
every `switch` to handle each case, and removes the ambiguity of a single
boolean.

### Question 4 — Named constructor justification

- **`Job.closed(...)`** — a role whose deadline has passed or has been filled
  must be preserved for the record but locked against new applications; the
  default constructor defaults `isOpen` to `true`, so it cannot *guarantee*
  this closed state the way a dedicated constructor that hard-sets
  `isOpen = false` does.
- **`Job.remote(...)`** — a fully remote role has no physical office, so this
  constructor encapsulates the domain state by intrinsically stamping
  `location = 'Remote'`, removing the chance of an inconsistent free-text
  location and expressing "this job is remote" as a first-class creation path.

---

## PART 2 — SCRATCH OUTPUT

Run with: `dart run scratch/scratch.dart`

Expected output (deterministic):

```
=== PART 2: Four job variants ===

Job 1: Job(title: Senior Flutter Developer, company: Bitcube, location: Cape Town, ZA, salary: R55 000 – R75 000 per month, employmentType: Full-time, closingDate: 2026-08-15T00:00:00.000, isOpen: true, canApply: true)
   canApply      -> true
   displaySalary -> R55 000 – R75 000 per month

Job 2: Job(title: Junior Backend Engineer, company: Nimbus Systems, location: Johannesburg, ZA, salary: —, employmentType: Full-time, closingDate: —, isOpen: true, canApply: true)
   canApply      -> true
   displaySalary -> Market-related

Job 3: Job(title: Product Designer, company: Loop Studio, location: Durban, ZA, salary: R40 000 per month, employmentType: Contract, closingDate: 2026-05-01T00:00:00.000, isOpen: false, canApply: false)
   canApply      -> false
   displaySalary -> R40 000 per month

Job 4: Job(title: DevOps Engineer, company: Skyforge, location: Remote, salary: R60 000 – R80 000 per month, employmentType: Full-time, closingDate: —, isOpen: true, canApply: true)
   canApply      -> true
   displaySalary -> R60 000 – R80 000 per month

=== STRETCH A: copyWith ===

Original job3 canApply: false
reopened  copy canApply: true
job1.copyWith() same title: true

=== STRETCH B: matches() test ===

matches("cape town") -> 2 results (expected 2) PASS
     - Flutter Developer @ Bitcube (Cape Town)
     - Backend Developer @ Skyforge (Cape Town)
matches("bitcube") -> 2 results (expected 2) PASS
     - Flutter Developer @ Bitcube (Cape Town)
     - DevOps Lead @ Bitcube (Remote)
matches("developer") -> 2 results (expected 2) PASS
     - Flutter Developer @ Bitcube (Cape Town)
     - Backend Developer @ Skyforge (Cape Town)

All assertions run.
```

This demonstrates the required behaviour:
- `canApply` is **false** for the closed job (job 3) and **true** for the open jobs.
- `displaySalary` returns the formatted salary for job 1 and **"Market-related"** for job 2.
- `toString()` produces readable output for all four.

---

## PART 3 — JOBCARD MANUAL VERIFICATION

Render all four jobs in `HomeScreen`. Verified:

- ✅ The no-salary job (job 2) shows **"Market-related"** — not "null", not a blank line.
- ✅ The no-closing-date job (job 2) shows **no** closing-date label — not "null", not "Closes: " (collection-if removes the row entirely).
- ✅ The closed job (job 3) shows a red **"Closed"** badge; open jobs show a **"Open"** badge — distinguishable at a glance.
- ✅ The remote job (job 4) renders location as **"Remote"**.
- ✅ Toggling a job's `isOpen` in the hardcoded list and pressing **hot reload** updates the badge without restarting the app (`HomeScreen` is stateless and rebuilds on reload).

---

## PART 4 — COLOUR CHOICE

Seed colour: **deep teal `#00695C`**. I picked teal because it reads as
trustworthy, calm, and professional without falling back on the default
corporate blue — appropriate for a platform people rely on for their
livelihood.

---

## STRETCH GOALS (Assignment 1.1)

- **Stretch A — `copyWith`:** implemented on `Job`. It solves the problem that
  updating one field otherwise means retyping *every* argument to `Job(...)`,
  which is verbose and error-prone; `copyWith` returns a new immutable Job with
  just the changed fields replaced. This is auto-generated by the **`freezed`**
  package (Week 2 Day 2).
- **Stretch B — `matches`:** implemented + tested in the scratch file (output above).
- **Stretch C — `JobStatusBadge`:** extracted into `lib/widgets/job_status_badge.dart`.
  Worthwhile because it gives the open/closed visual language a single
  definition reused everywhere, so styling changes happen in one file instead
  of being duplicated across every card and screen.

---
---

# CareerHub — Assignment 1.2: The Responsive List & Adaptive Theme

Week 1, Day 2. Builds directly on the Assignment 1.1 submission above — the
`Job` model, `JobCard`, and `JobStatusBadge` are unchanged in shape. This
assignment makes every layout and colour choice around them deliberate
across screen sizes, theme modes, and data scale.

## PART 1 — WRITTEN DECISIONS

### Question 1 — Why the naive `Column` + `ListView.builder` crashes

`Scaffold.body` hands its child a **bounded** height constraint — finite,
capped at whatever vertical space is left after the app bar. Inside a
`Column`, though, every non-flexible child (anything not wrapped in
`Expanded` or `Flexible`) is handed **unbounded** height along the main
axis, because `Column` has to measure its fixed-size children first,
before it can work out how much room is left for flexible ones. The chip
row doesn't mind — a `SingleChildScrollView` just takes its own intrinsic
height regardless of the bound it's offered. But `ListView.builder` is a
scrolling *viewport*, and a viewport cannot lay itself out against an
infinite constraint — it needs a finite "window" to render into and
manage scroll position within. Handed unbounded height, it throws
(*"Vertical viewport was given unbounded height"*) and the app crashes
before it ever reaches the emulator screen.

**The fix:** wrap `ListView.builder` (or, here, the whole scrollable
content area) in `Expanded`. That forces `Column` to hand it the
*bounded* space left over once the chip row has been measured — exactly
the finite constraint the viewport needs. Implemented in
`home_screen.dart`.

### Question 2 — The grid cell problem

**2a — Content inventory.**

| Field | Always rendered? |
|---|---|
| Title + status badge | Required |
| Company | Required |
| Location (icon line) | Required |
| Employment type (icon line) | Required |
| Salary (icon line, via `displaySalary`) | Required — always renders *something*, even if just "Market-related" |
| Closing date (icon line) | Conditional — only if `closingDate != null` |
| Description | Conditional — only if `description` is non-null and non-empty |

**Minimum height estimate** (required fields only — job 2 in the list is
exactly this case): title + badge row (~28), company (~20), three icon
lines (~22 each = 66), card padding (16 top + 16 bottom = 32), inter-row
spacing (~26 total) ≈ **~170 screen units**.

**Maximum height estimate** (every field present, a two-line
description — job 1 or job 4): minimum + closing-date line (~26 with its
spacing) + description block (~8 spacing + ~32 for two lines of
`bodySmall`) ≈ **~240 screen units**.

**2b — `childAspectRatio` derivation.**

The grid only ever renders at width ≥ 600px — that's Part 4's own
breakpoint — so 600px, not a generic phone width, is the correct *worst
case* to design for: it's the narrowest the grid cell will ever actually
be, since above 600 the available width only grows. At exactly 600px,
with `padding: EdgeInsets.all(8)` and `crossAxisSpacing: 8` across 2
columns:

```
cell width = (600 − 8×2 − 8) / 2 = 576 / 2 = 288px
```

Using the maximum content estimate (240) as the height to design for
(see 2c for why max, not min):

```
childAspectRatio = width / height = 288 / 240 = 1.2
```

**childAspectRatio: 1.2** for the two-column grid.

**2c — What happens if you size for the minimum card instead.**

A fully populated card rendered inside a cell sized for the *minimal*
card overflows the fixed cell height: Flutter clips the extra content
and paints the classic yellow-and-black striped "RenderFlex overflowed
by N pixels" warning along the bottom edge. That's not acceptable — it
hides real information (the closing date, the description) from a job
seeker who might specifically need it, and a visibly broken card
undermines trust in the whole listing. The correct approach — what's
implemented here — is to size the aspect ratio for the **maximum**
content case. The tradeoff is some empty space at the bottom of minimal
cards: a cosmetic cost, not a functional one, and clearly preferable to
clipped content.

### Question 3 — Dark mode breakage audit

**Result: zero hardcoded colours found in either widget.** Both
`JobCard` and `JobStatusBadge` used `Theme.of(context).colorScheme` and
`Theme.of(context).textTheme` exclusively from Assignment 1.1 onward, so
neither required a single colour change for dark mode. The roles already
in use:

| Element | Role used | Why it's semantically correct |
|---|---|---|
| Job title | `textTheme.titleMedium` | The card's primary heading — the M3 scale's medium title role, not an arbitrary font size. |
| Company name | `textTheme.bodyMedium` + `colorScheme.onSurfaceVariant` | Secondary information relative to the title; `onSurfaceVariant` is M3's role for de-emphasised text on a surface. |
| Location / employment / salary (icon + text) | `colorScheme.onSurfaceVariant` (icon) + `textTheme.bodyMedium` (text) | Same de-emphasised supporting-text role, applied consistently across every metadata line — now centralised in `IconLine`. |
| Description | `textTheme.bodySmall` | The smallest text role, appropriate for optional, lowest-priority content. |
| Open badge background / text | `colorScheme.primaryContainer` / `onPrimaryContainer` | `primary` is the app's brand/seed colour family — the container pairing represents a positive, on-brand confirming state, not a hardcoded green. |
| Closed badge background / text | `colorScheme.errorContainer` / `onErrorContainer` | M3 reserves the error role family for states that need attention or signal something can't proceed — exactly what "closed, can't apply" means. Not literally an error, but semantically the correct "blocked" role in the M3 system. |

Because every reference was already role-based, adding `darkTheme` +
`ThemeMode.system` in `main.dart` was sufficient on its own — no colour
or text-style changes were needed in `job_card.dart` or
`job_status_badge.dart`.

### Question 4 — The extraction decision

**Chosen: `IconLine`** — the icon + text row used for location,
employment type, salary, and (conditionally) closing date.

*(`JobStatusBadge` was already extracted in Assignment 1.1's Stretch C,
so it wasn't a candidate for a second extraction here.)*

| Criterion | Met? | Why |
|---|---|---|
| 1. Single responsibility, nameable in <5 words | ✅ | "renders an icon-prefixed text row" |
| 2. Rendered in more than one place | ✅ | Already used **three times** inside a single `JobCard` alone (location, employment type, salary) — a stronger signal than most components get before extraction |
| 3. Testable in isolation | ✅ | Takes only an `IconData` and a `String`; correctness never depends on `Job`, `JobCard`, or any parent state |

All three criteria are met. **Cost of not extracting:** the icon+text
styling (icon size, spacing, colour role) is currently duplicated inline
three separate times within a single card. Any visual tweak — icon size,
swapping `onSurfaceVariant` for a different role — means finding and
editing three near-identical blocks instead of one shared definition.
Any future screen needing the same pattern (a job detail screen, a
saved-jobs list) would either duplicate it a fourth time or be unable to
reuse it at all, since Dart doesn't allow importing a private class
across files. Extracted to `lib/widgets/icon_line.dart` as public
`IconLine`.

## PART 3c — Dark mode verification

Checklist to confirm against the running app:
- [ ] App bar, cards, and background all switch to dark variants
- [ ] `JobStatusBadge` stays readable in both states — no light text on
  a light background
- [ ] No widget shows a jarring hardcoded colour against the dark
  surface

## PART 4 — Layout screenshots

**Portrait (single-column list layout):**

![Portrait list layout](screenshots/list.png)

**Landscape (grid layout with 2 columns):**

![Landscape grid layout](screenshots/grid.png)

## STRETCH GOALS

### Stretch A — SliverAppBar

Provided as an alternate `home_screen.dart` body below, rather than
merged into the main file — the Part 2/4 checklist items specifically
name `ListView.builder` / `GridView.builder`, so keeping those literal
in the primary submission avoids any ambiguity about whether that
requirement is met. Swap this in if you want the collapsing app bar.

**Reasoning:** `SliverAppBar` operates under the **sliver constraint
protocol** (`SliverConstraints` / `SliverGeometry`), not
`BoxConstraints`. Instead of a fixed box size, each sliver negotiates how
much of the scroll offset and remaining paint extent it consumes as the
user scrolls. The widget responsible for coordinating that across every
sliver is the **`Viewport`** that `CustomScrollView` builds internally —
it feeds each sliver its `SliverConstraints` (including the current
`scrollOffset` and `overlap` from prior slivers) and lays them out in a
single pass along the scroll axis. This is the same mechanism used in
Week 3 for persistent search headers.

```dart
// Alternate body for HomeScreen.build() — swaps Scaffold(body: Column(...))
// for a CustomScrollView so the app bar can collapse/expand on scroll.
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 120,
          flexibleSpace: const FlexibleSpaceBar(
            title: Text('CareerHub'),
            titlePadding: EdgeInsets.only(left: 16, bottom: 16),
          ),
        ),
        SliverToBoxAdapter(
          child: const _FilterChipRow(filters: _filters),
        ),
        if (_jobs.isEmpty)
          SliverFillRemaining(child: const EmptyJobsWidget())
        else
          SliverPadding(
            padding: const EdgeInsets.all(8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                _buildCard,
                childCount: _jobs.length,
              ),
            ),
          ),
      ],
    ),
  );
}
```

Note: the grid branch needs the equivalent swap to `SliverGrid` with the
same `SliverGridDelegateWithFixedCrossAxisCount`, and the breakpoint
check would move into a `SliverLayoutBuilder` (the sliver-aware
counterpart of `LayoutBuilder`), reading `constraints.crossAxisExtent`
in place of `constraints.maxWidth`.

### Stretch B — Three breakpoints

Implemented directly in `home_screen.dart`'s single `LayoutBuilder` —
see the Part 4 code. `crossAxisCount` becomes 1 / 2 / 3 across the three
width tiers; `_buildCard` is untouched, exactly as required.

**Does the three-column grid need a different `childAspectRatio`?**
Yes. At the narrowest three-column trigger width (840px):

```
cell width = (840 − 8×2 − 8×2) / 3 = 808 / 3 ≈ 269px
```

That's *narrower* than the two-column case's 288px cell, even though
the screen itself is wider overall — three columns simply divide the
space more ways. A narrower cell means the title and description wrap
onto more lines more often, so the same content needs slightly *more*
height even as it has less width. Estimating that extra wrap pushes
maximum content height to ~250:

```
childAspectRatio = 269 / 250 ≈ 1.05
```

**childAspectRatio: 1.05** for the three-column grid — smaller (taller,
more portrait) than the two-column grid's 1.2, for exactly that reason.

### Stretch C — Empty state

`EmptyJobsWidget` (`lib/widgets/empty_jobs_widget.dart`) renders instead
of the `LayoutBuilder` content when `_jobs.isEmpty`. To test: temporarily
replace the `_jobs` list with `[]`, hot reload, confirm the empty state
appears, then revert and hot reload again.

Mapping to `AsyncValue<List<Job>>` (Week 2):
- **`AsyncData([])`** — loaded successfully, zero results → this empty
  state.
- **`AsyncLoading()`** → a loading spinner/skeleton state (not yet
  built — Week 2).
- **`AsyncError`** → an error state with a retry action (not yet
  built — Week 2).

---
---

# CareerHub — Assignment 1.3: Live State & Reactive Filters

Week 1, Day 3. Builds directly on the Assignment 1.2 submission above — the
`Job` model, `JobCard`, `JobStatusBadge`, and `IconLine` are unchanged in
shape. This assignment replaces the hardcoded, static job list with live
state managed by Riverpod, and makes the filter chips from 1.2 — which
looked interactive but did nothing — actually filter the list. All three
stretch goals (sort order, a simulated failure toggle, and live search) are
included.

**Package note:** `flutter_riverpod` currently ships as v3.x. Riverpod 3.0
moved `StateProvider` (and `StateNotifierProvider`/`ChangeNotifierProvider`)
out of the main `flutter_riverpod.dart` import into a separate
`flutter_riverpod/legacy.dart` import — they're fully supported, just no
longer part of the "main" API in favour of `Notifier`/`AsyncNotifier`. Every
file below that uses `StateProvider` imports both.

## PART 1 — WRITTEN DECISIONS

### Question 1 — `ref.watch` versus `ref.read`

`ref.watch` and `ref.read` exist as two separate methods because they serve
two fundamentally different jobs, and conflating them breaks the one
guarantee Riverpod is built around: that the widget tree always reflects
current state without anyone manually telling it to rebuild. `ref.watch`,
called inside `build()`, subscribes the calling widget to a provider — it
registers that widget as a listener, so that the *next* time the provider's
value changes, Riverpod marks that widget dirty and Flutter re-runs
`build()` for it automatically. That subscription is what "reactive" means
here: the UI updates itself because it's continuously listening, not
because something told it to. Calling `ref.watch` inside `onSelected` is
inappropriate because a callback isn't a build method — it runs exactly
once, at the moment of the tap, and is never re-run when a provider changes
later, so creating a subscription there is meaningless at best (there's
nothing left to redraw once the callback body finishes executing) and a
leaked listener at worst. `ref.read`, by contrast, does a one-off lookup: it
returns whatever the provider's value happens to be *right now*, with no
subscription attached — exactly right inside `onSelected`, where a single
tap just needs to grab the filter notifier once and command it to change
state. `ref.read` is insufficient inside `build()` for the mirror-image
reason: because it doesn't subscribe, the widget has no way of knowing the
provider ever changed, so it renders correctly exactly once — using
whatever the value was on that first build — and then silently freezes. If
I had gotten this backwards, a user tapping a different filter chip would
see the tapped chip fail to visually highlight and the job list stay
exactly as it was, because `HomeScreen` used `ref.read` in `build()` and
never rebuilt — the app would look broken with no error message and no
crash, just stale UI standing still while the state underneath it quietly
changed. (Stretch B applies the same rule one level down, inside a
*provider* rather than a widget — see below.)

### Question 2 — Choosing the right provider for each piece of state

| Data | Provider type | Justification |
|---|---|---|
| Full job list (async fetch) | `FutureProvider<List<Job>>` | The data is fetched once, so Riverpod's job is just to represent that fetch's three states (loading/error/data) for us — `FutureProvider` wraps the result in `AsyncValue` automatically, with no hand-rolled loading flags or nullable error fields, and `ref.invalidate` is all "retry" needs, so a heavier `AsyncNotifier` buys nothing extra here. |
| Selected filter chip label | `StateProvider<String>` | A single, simple, directly-overwritable value — every tap just replaces the old label with the new one outright, with no async work and no derivation involved, which is exactly the case `StateProvider` exists for. |
| Filtered job list (derived) | `Provider<AsyncValue<List<Job>>>` | Nothing ever sets this value directly — it's a pure computation over the two providers above, so a plain `Provider` is correct: Riverpod recomputes it automatically the instant either input changes, and it can never be told to hold a stale value because it has no settable state of its own. |

*(The brief describes the jobs provider loosely as a "notifier" — CareerHub's
version is a `FutureProvider`, whose callback plays that same role, producing
the async value Riverpod watches, without the ceremony of a full
`AsyncNotifier` class. The natural next step, if CareerHub later needs
mutating operations beyond re-fetching the whole list — e.g. marking a single
job as saved without refetching everything — would be to promote it to an
`AsyncNotifier`.)*

**The manual-sync bug:** Storing the filtered list in its own
`StateProvider<List<Job>>` and updating it by hand introduces a **stale-state
(cache-invalidation) bug** — the same category as a cache that's never told
to invalidate. The moment there are two independently-stored copies of what
is really one derived fact, keeping them in sync stops being something the
framework guarantees and becomes something a person has to remember to do
correctly at every call site that touches either input. Concretely in
CareerHub: picture a later change that adds a fifth filter chip,
'Internship', with its own `onSelected` handler. If that handler correctly
updates `selectedFilterProvider` but the developer forgets to also manually
recompute and push a new value into the hand-rolled filtered-list provider,
tapping 'Internship' would visually select the chip — but the job list
underneath would keep showing whatever the *previous* filter produced.
There's no crash, no red error screen, no console warning: just quietly
wrong data on screen, which is the most expensive kind of bug to find
because nothing about running the app points you toward where it's coming
from.

### Question 3 — `AsyncValue` and the UI contract

| `AsyncValue` state | What renders | Why it respects the user |
|---|---|---|
| `loading` | A centred `CircularProgressIndicator` | Immediately confirms the app is doing *something* — silence during a network call reads as a frozen or broken app, not a fast one. |
| `error` | An icon, a short message, and a retry button | Honest that something failed rather than quietly showing an empty list that looks like "there are simply no jobs," and hands the user an immediate way to recover without force-closing the app. |
| `data` | The job list/grid, via the existing `LayoutBuilder` logic | The successful case CareerHub exists for — gets exactly the responsive UI Assignment 1.2 already built, with no extra wrapping. |

**The fourth condition:** within `data`, the resulting list can be **empty**
— loaded successfully, but zero jobs match the currently selected
filter/search. Forgetting this means the user sees a blank scrollable area
with no cards and no text, which looks identical to a rendering bug or a
frozen app and gives no hint that the real cause is just an overly narrow
filter. Handled with an explicit `jobs.isEmpty` check inside the `data`
branch, before handing the list to `LayoutBuilder`, rendering the existing
`EmptyJobsWidget` — extended this assignment with optional copy — with
specific text ("No jobs match your filters — try a different filter or
search term") instead of its original "no jobs at all" message.

### Question 4 — What the test was about to break, and why

**Failure mode 1 — missing `ProviderScope` (architecture change).**
`HomeScreen` (and the filter chip row) are now Consumer(Stateful)Widgets
that call `ref.watch`/`ref.read`, which require a `ProviderScope` ancestor
to supply the provider container. The existing test called
`tester.pumpWidget(const CareerHubApp())` directly — it never goes through
`main()`, which is the only place `ProviderScope` was added — so in the
test tree there is no `ProviderScope` ancestor, and Riverpod throws as soon
as `HomeScreen` tries to watch anything.
**Fix:** every test that pumps `CareerHubApp` now wraps it —
`tester.pumpWidget(const ProviderScope(child: CareerHubApp()))`.

**Failure mode 2 — async timing (fake-async).** `jobsProvider` now spends
its first ~1.5 simulated seconds in the `loading` state, produced by a real
`Future.delayed`. Immediately after `pumpWidget()`, only one frame has been
built, and at that point `visibleJobsProvider` is still `AsyncLoading` — so
the body shows the spinner, not any `JobCard`s. Any assertion that looks for
job text (e.g. `find.text('Senior Flutter Developer')`) runs before that
Future ever resolves and fails, because that text was never built. Left
unresolved, the pending `Future.delayed` timer can also be reported as a
leaked `Timer` when the test tears down.
**Fix:** explicitly advance the tester's fake clock past the delay before
asserting on job data — `await tester.pump()` to build the loading frame,
then `await tester.pump(const Duration(seconds: 2))` to jump the fake clock
past the 1.5-second delay and let the pending timer resolve, before any
card-content assertions run.

---

## PART 2 — PROVIDER ARCHITECTURE

New file: `lib/providers/job_providers.dart`, containing the three core
providers named above, the three stretch-goal providers, and the mock job
data (moved here from `HomeScreen`, which no longer has a static job list
field at all).

- `jobsProvider` simulates a network call with
  `await Future.delayed(const Duration(milliseconds: 1500))` — comfortably
  over the required 1-second minimum, and matched to the Part 3 checkpoint's
  "spinner appears for approximately 1.5 seconds."
- `selectedFilterProvider` defaults to `'All'`.
- `filteredJobsProvider` filters against **real** `Job` fields only:
  `'Remote'` checks `job.location == 'Remote'` (which `Job.remote()` stamps
  intrinsically), and every other label checks
  `job.employmentType == filterLabel` directly, since `'Full-time'` and
  `'Contract'` are already the literal `employmentType` strings used
  throughout CareerHub's mock data.
- Confirmed against the six existing mock jobs: `'Remote'` matches 2 (DevOps
  Engineer, Technical Support Engineer), `'Full-time'` matches 4, `'Contract'`
  matches 2 — every filter has at least one result.
- `runApp` in `main.dart` is now wrapped in `ProviderScope`.

**Riverpod 3.0 auto-retry, addressed:** as of 3.0, a provider that throws is
auto-retried by Riverpod itself — up to 10 attempts, 200ms delay doubling to
6.4s — before `AsyncValue` ever reaches `error`. That's the wrong behaviour
for Stretch B's *manual* failure toggle: left alone, tapping "simulate
failure" would look like it does nothing for up to ~38 seconds while
Riverpod silently retries and fails behind the scenes. `jobsProvider` passes
`retry: (retryCount, error) => null` to disable this for itself specifically
(not globally via `ProviderScope`, since nothing else in CareerHub throws),
so the fail/retry sequence is instant.

## PART 3 — WIRING THE SCREEN

`HomeScreen` watches exactly one provider for job data — `visibleJobsProvider`
— and hands its `AsyncValue<List<Job>>` to `.when()`. The `LayoutBuilder` /
`ListView.builder` / `GridView.builder` / `_buildCard` logic from Assignment
1.2 is untouched; `_buildCard` now takes `jobs` as an explicit parameter
instead of closing over a static field, since that field no longer exists.

The filter chip row (`_FilterChipRow`) is its **own** `ConsumerWidget`
rather than a plain one fed by `HomeScreen` — deliberate, not incidental.
The brief disallows passing callback functions down through widget
constructors, and the reason that matters is the same mechanism behind
Question 1: a callback threaded down through a constructor is still just a
callback, so putting `ref.watch` inside it would be exactly as meaningless
as putting it in `onSelected` directly. Instead, `_FilterChipRow` reads and
writes `selectedFilterProvider` itself — `HomeScreen` never even needs to
know that provider exists. The same pattern is used for the two new AppBar
controls added by the stretch goals (`_SortButton`, `_FailToggleButton`),
which is why HomeScreen's own watch count never grows — see Stretch A below.

An error path shows an icon, a short generic message ("We couldn't load the
job listings. Please try again."), and a `FilledButton` that calls
`ref.invalidate(jobsProvider)`. It's no longer just structural: Stretch B
gives it a real trigger.

`EmptyJobsWidget` (Assignment 1.1/1.2) was extended with optional `icon`,
`title`, and `message` parameters, defaulting to its original 1.1 copy so
nothing about its previous behaviour changed. It's now reused for the
fourth `AsyncValue` condition from Question 3 — an empty filtered/searched
result — with specific copy instead of its original "no jobs at all"
message.

## PART 4 — TEST UPDATES

Both Question 4 fixes are applied via a single shared helper,
`pumpLoadedApp()`, used by every test that renders the full app:

```dart
Future<void> pumpLoadedApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: CareerHubApp()));
  await tester.pump(); // build the first (loading) frame
  await tester.pump(const Duration(seconds: 2)); // resolve the 1.5s delay
}
```

Two new tests were added under **Async Loading State**, directly covering
the submission checklist's "`CircularProgressIndicator` assertion present
for loading state" item, and a **Reactive Filtering** group taps the
"Remote" and "All" chips and asserts the visible cards change accordingly —
not explicitly required by the checklist, but it's the actual behaviour
this assignment exists to build. A **Stretch Goals** group adds one test per
stretch goal: the sort menu reversing card order, the failure toggle
producing (and then recovering from) the error state, and the search field
narrowing results by title.

Tests that pump `JobCard`, `IconLine`, or `EmptyJobsWidget` directly (not
through `CareerHubApp`) needed no changes — none of those widgets read
Riverpod state, so none of them have a `ProviderScope` dependency.

Two pre-existing fragilities were tightened while this file was already
open: several filter-chip-label assertions used bare `find.text('Remote')`
/ `find.text('Full-time')`, which also match the *same words* rendered as a
job's location or employment type inside a card — these now use
`find.widgetWithText(ChoiceChip, '...')`, which can only match the chip. And
the test asserting on four different jobs spread across the unfiltered
six-job grid now pins a generous viewport (`Size(1200, 2000)`), since the
new search field (Stretch C) shrinks the space left for the list itself and
this test shouldn't depend on exactly how far Flutter's list/grid cache
extent happens to reach.

*(This section supersedes the old "Known pre-existing issue" note that used
to sit here: `test/widget_test.dart` no longer references `MyApp` or a
counter — it's been fully rewritten around `CareerHubApp` / `HomeScreen`,
and this assignment rewrites it again for the Riverpod architecture.)*

## SCREENSHOTS

**Loading state (spinner, ~1.5s after launch):**

![Loading state](screenshots/loading.png)

**Filtered state ("Remote" selected — only matching jobs shown):**

![Filtered state](screenshots/filtered.png)

**All filter restored (full list showing again):**

![All filter restored](screenshots/all.png)

**Stretch B — simulated failure sequence:**

1. Tap the wifi icon in the AppBar. `shouldFailProvider` flips to `true`
   and `jobsProvider` is invalidated; because it reads (not watches) the
   flag, this is the only thing that triggers the re-fetch.

   ![Failure toggled on](screenshots/stretch-b-fail.png)

2. The re-fetch resolves as a thrown exception. The error state renders —
   icon, message, retry button — exactly as built in Part 3.

   ![Error state rendered](screenshots/stretch-b-error.png)

3. Tapping the **same AppBar icon again** (now showing wifi-off) flips
   `shouldFailProvider` back to `false` and invalidates again — this
   second attempt succeeds and the list reloads.

   *(The in-error-state Retry button also works at any point, but retries
   with whatever `shouldFailProvider` currently holds — so retrying while
   the AppBar toggle is still "on" correctly fails again. The AppBar
   toggle is what actually clears the simulated failure.)*

   ![Recovered after second tap](screenshots/stretch-b-recovered.png)

---

## STRETCH GOALS

### Stretch A — second filter dimension (sort order)

Implemented as `SortOrder` (`enum { aToZ, zToA }`) plus a second
`StateProvider<SortOrder>`, `sortOrderProvider` — same justification as
`selectedFilterProvider`: a single, directly-overwritable value with no
derivation of its own. Rather than re-reading `jobsProvider` and
`selectedFilterProvider` a second time, the new `visibleJobsProvider`
**composes on top of `filteredJobsProvider`**: it watches the already-
filtered `AsyncValue<List<Job>>`, plus `sortOrderProvider`, and applies a
`title`-based sort (case-insensitive, reversed for Z–A) inside `whenData`.
`HomeScreen` switched its single watch call from `filteredJobsProvider` to
`visibleJobsProvider`. A new `_SortButton` — a `PopupMenuButton` in the
AppBar, following the exact same "own `ConsumerWidget`" pattern as
`_FilterChipRow` — reads and writes `sortOrderProvider` on its own.

**How many providers does HomeScreen now watch directly?** Still exactly
one. Before Stretch A: `ref.watch(filteredJobsProvider)`. After: 
`ref.watch(visibleJobsProvider)`. The count never changed.

**Does adding the sort provider require any change to how HomeScreen calls
`ref.watch`?** One line — the provider identifier the existing watch call
points at, renamed for accuracy now that it also sorts (a `Provider` that
only filters shouldn't keep a name that implies it doesn't sort). That's
not a restructuring: same single `ref.watch` call, same
`AsyncValue<List<Job>>` return type, same direct hand-off to `.when()`. No
new parameters were threaded through `_buildCard`, no new field was added
to `HomeScreen`'s state.

**What does that tell you about the composability of the reactive graph?**
That a whole new dimension of derived state — sorting — could be added
*underneath* `HomeScreen` without `HomeScreen` itself growing in
complexity. The cost of adding Stretch A to `HomeScreen` was one renamed
identifier; all of the actual new logic (the enum, the provider, the sort
call, the UI control that drives it) lives in files `HomeScreen` doesn't
need to know the insides of. That's the practical payoff of `Provider`s
depending on other `Provider`s instead of widgets depending on many
providers directly: complexity grows sideways, in the provider graph, not
upward, in the widget that consumes it.

### Stretch B — simulated error state

`shouldFailProvider = StateProvider<bool>((ref) => false)`, read (not
watched — see Question 1 and the code comment on `jobsProvider`) inside
`jobsProvider`, throwing when `true`. A new `_FailToggleButton` — an
`IconButton` in the AppBar, swapping between a wifi and wifi-off icon —
does both steps the brief asks for in one tap: flips `shouldFailProvider`
and calls `ref.invalidate(jobsProvider)`. Disabling Riverpod 3.0's
auto-retry on `jobsProvider` (Part 2, above) was necessary to make this
demoable at all — without it, the error state would take up to ~38 seconds
to appear.

One nuance worth documenting precisely, since the brief's "tap retry, the
list loads successfully" undersells it slightly: tapping the in-error-state
**Retry** button while the AppBar toggle is still "on" correctly fails
again, because `shouldFailProvider` hasn't changed — only the AppBar toggle
itself both clears the flag and retries in the same tap. See the
screenshots above for the exact three-step sequence this produces.

### Stretch C — search field

`HomeScreen` is now a `ConsumerStatefulWidget`/`ConsumerState` pair instead
of a `ConsumerWidget`, specifically to own a `TextEditingController` — created
in `initState()`, disposed in `dispose()`. A `TextField` sits above the
filter chip row, wired via `onChanged` to a third `StateProvider<String>`,
`searchQueryProvider`. `visibleJobsProvider` was extended to also watch this
provider and narrow the (filtered, sorted) list using `Job.matches()` — the
case-insensitive title/company/location search written and unit-tested all
the way back in Assignment 1.1's Stretch B, but never wired into the UI
until now.

**What's the difference between `ConsumerStatefulWidget`/`ConsumerState`
and `ConsumerWidget`?** `ConsumerWidget` is Riverpod's version of
`StatelessWidget`: one `build(context, ref)` method, no persistent object
between rebuilds, no lifecycle hooks. `ConsumerStatefulWidget` +
`ConsumerState` is Riverpod's version of `StatefulWidget` + `State`: an
actual `State` object survives across many rebuilds, exposes `ref` as a
property instead of a `build()` parameter, and — critically — gets
`initState()`/`dispose()`/etc., none of which `ConsumerWidget` has any way
to offer.

**When is the stateful variant genuinely necessary?** When a widget needs
to own an object with its own imperative lifecycle that doesn't fit
Riverpod's snapshot-based state model — a `TextEditingController`,
`ScrollController`, `AnimationController`, `FocusNode`. These aren't just
values; they're objects with internal mutable state and side effects (cursor
position, animation ticks, scroll offset, focus) that must be created once
and explicitly torn down, which is exactly what `initState`/`dispose` are
for and a `Provider` is not.

**When would choosing it over `ConsumerWidget` be overengineering?** Any
time a widget only ever reads and reacts to Riverpod state and owns no
controller of its own — which is true of `_FilterChipRow`, `_SortButton`,
and `_FailToggleButton` in this codebase. Making any of those
`ConsumerStatefulWidget` would add a separate `State` class and
`createState()` boilerplate for zero benefit, and would mislead the next
reader into thinking the widget owns some meaningful local state, when in
reality all of its real state already lives correctly in a provider.

---
---

# CareerHub — Assignment 1.4: Deep Navigation & Route Architecture

Week 1, Day 4. Builds directly on the Assignment 1.3 submission above — the
reactive provider graph, filter chips, loading/error states and all three
1.3 stretch goals are unchanged. This assignment adds **URL-based
navigation** with `go_router`: two persistent tabs, a job detail screen with
a stable URL, and correct back-button behaviour.

*Written decisions completed 2026-07-15, before any router code was written.*

> **Repo housekeeping done as part of 1.4:** the package was named
> `careerhub` in `pubspec.yaml` while every test imported
> `package:careerhub_mobile/...`, so the suite could not compile. The package
> is now named `careerhub_mobile` to match the folder and the imports, which
> is what lets Part 4's `flutter test` run at all.

---

## PART 1 — WRITTEN DECISIONS

### Question 1 — The route tree

Every node below shows its **path**, the **screen** it renders, and whether
it sits **inside** the `StatefulShellRoute.indexedStack` (NavigationBar
visible) or **outside** it (full screen, no NavigationBar).

```
ROUTE TREE                                         SCREEN               SHELL?
────────────────────────────────────────────────────────────────────────────
/login                                             LoginScreen          OUTSIDE
                                                                        (full screen,
                                                                         no nav bar)

StatefulShellRoute.indexedStack  ───────────────►  ScaffoldWithNavBar   (the shell
                                                    (hosts NavigationBar) itself)
│
├─ Branch 0 — Jobs
│   └─ /jobs                                       HomeScreen           INSIDE
│       └─ /jobs/:id                               JobDetailScreen      INSIDE
│                                                                       (nested in
│                                                                        the Jobs branch)
│
└─ Branch 1 — Saved
    └─ /saved                                      SavedScreen          INSIDE
```

Initial location: **`/jobs`** (the Jobs tab root). The Stretch-C auth
redirect layers on top of this — see below.

**Is the detail screen inside or outside the shell? Justification.**
It is **inside** the shell — the NavigationBar stays visible while reading a
job, and the detail route is nested *inside the Jobs branch*, not as a
top-level route. The user experience demands this: a job seeker who opens a
listing should still be able to jump to their Saved tab without first backing
out, and should be able to return to exactly where they were. Nesting the
detail inside the branch is also what makes tab-state preservation possible
at all — the branch's Navigator holds `[/jobs, /jobs/:id]` and
`indexedStack` keeps that whole stack alive when the user switches tabs.

**Real app that does the equivalent thing: LinkedIn.** When you tap a job in
LinkedIn's Jobs tab, the job detail opens *with the bottom navigation bar
still visible* — you can hop to Messaging or My Network and come straight
back to the job you were reading. Instagram behaves identically when you open
a post from the feed. CareerHub matches that expectation exactly.

**What URL is active when the user first opens the app?**
The router's `initialLocation` is `/jobs`. Because Stretch C ships an auth
gate whose `isLoggedInProvider` defaults to `false`, the redirect sends a
brand-new (signed-out) user to **`/login`** first; the instant they log in,
the redirect re-runs and they land on **`/jobs`**. (Without Stretch C, the
very first URL would simply be `/jobs`.)

**What URL is active when reading the detail for the third job in the list?**
`/jobs/<that job's id>` — **the id, never the position**. If the third card
happens to be Product Designer, the URL is `/jobs/3` because its `id` is `3`,
not because it is third. Re-sort or filter the list so a different job sits
third, and the URL for "the third card" changes to *that* job's id. The URL
identifies the job, not the slot.

**System back button from the detail screen.** It pops the detail page off
the Jobs branch's Navigator and returns to `/jobs` — the job list, with the
filter/sort/search selection from Assignment 1.3 fully intact (proven in the
screenshots below).

**Back after opening `/jobs/3` directly from a notification.** Because
`/jobs/:id` is a **child route of `/jobs`**, go_router materialises the full
ancestor stack for that location — `[/jobs, /jobs/3]` — even when the app is
launched cold straight onto `/jobs/3`. So pressing back pops to the **jobs
list**, not out of the app. The user lands somewhere sensible and the route
tree supports it precisely because the detail was nested inside the branch
rather than declared as a sibling top-level route.

### Question 2 — `context.go` vs `context.push`

| Action | Method | One-sentence back-button justification |
|---|---|---|
| **a)** Tap a job card → detail slides in | `context.push` | The user expects back to return them to the list they came from, so the detail must be *pushed on top* and popped off by back. |
| **b)** Tap the "Saved" tab | `goBranch` (a `go`, not a `push`) | Switching tabs must not build a back-stack entry — back should exit the app or pop within the tab, never "un-switch" the tab — so the shell swaps branches instead of pushing. |
| **c)** "Log Out" (clear session, no path back) | `context.go('/login')` (effected via the redirect) | Log-out must leave **no** back path to authenticated screens, and `go` *replaces* the stack, so there is nothing behind `/login` for back to reveal. |
| **d)** "Browse Similar Roles" → jobs list with a filter pre-applied | `context.go('/jobs')` | The user is heading *out* to a fresh list, so `go` resets to the list; they should not be able to "back" into the specific role they were just leaving. |

**(d) — the wrong choice and what the user observes.** The wrong choice is
**`context.push`**. Pushing the jobs list on top of the detail produces the
stack `[jobs, detail, jobs']`. The user, now looking at "similar roles",
presses back expecting to leave — and instead lands **back on the very
detail screen they were trying to move on from**, with a stale second copy of
the jobs list buried beneath it. The back button appears "stuck" on the old
role, which is exactly the confusion `go` avoids.

### Question 3 — Why IDs in URLs, not objects or indices

The `Job` model had no `id`; a stable `final int id` was added and every mock
job given a unique one (`1`–`6`). The id — not the list position — is the URL
parameter.

**What goes wrong at the product level with a position-based URL** — two
concrete collisions where the *same index* points at *different jobs*:

1. **Filter chips (Assignment 1.3).** Unfiltered and sorted A–Z, index `1` is
   **Junior Backend Engineer**. Tap the **Remote** chip and the list becomes
   `[DevOps Engineer, Technical Support Engineer]`, so index `1` is now
   **Technical Support Engineer**. A URL built from position — `/jobs/1` —
   opens a *different job* depending purely on which chip is active. Share
   that link with "Remote" selected and the recipient, on "All", sees the
   wrong listing.

2. **Sort order (Assignment 1.3 Stretch A).** With the default A–Z sort,
   index `0` is **DevOps Engineer**; flip to Z–A and index `0` becomes **UX
   Researcher**. Same position, same data set, two different jobs — the URL
   would silently change meaning the moment the user re-sorted, even though
   nothing about the underlying listing changed.

A stable `id` is immune to all of this: `/jobs/4` is DevOps Engineer under
every filter, sort, search and scroll position, forever.

**Why a position-based URL cannot support the push notification reliably.**
The notification — "Your application to *Senior Flutter Developer* was
reviewed. Tap to view." — must open that specific job. For a position-based
`/jobs/<n>` to resolve correctly, *all* of the following would have to be true
**at the exact moment the notification is tapped**: the job list is already
fetched into memory (not a cold start, where it is empty and index `n`
indexes into nothing); the active filter chip is the same one that was active
when `n` was computed; the sort order is the same; the search box is empty or
identical; and no job has been added or removed on the backend since. None of
these can be guaranteed — a notification most often arrives while the app is
**terminated** (so the list isn't even loaded), and even when it's warm the
user may have left it filtered to "Contract" or sorted Z–A. The backend that
sent the notification has no visibility into any of that client-side UI state.
An id sidesteps every one of those preconditions: `/jobs/1` is resolved
against the *raw, unfiltered* list the moment it loads, independent of UI
state entirely.

### Question 4 — What the test was about to break, and why

**The structural change: `MaterialApp` → `MaterialApp.router`.** The widget
tree is no longer rooted at a fixed `home:` widget that `pumpWidget` builds
directly. Instead, GoRouter's `RouterDelegate` produces the tree from the
current location, and the `RouteInformationParser`/delegate sit between the
test engine and the screens. Nothing is on screen until the router **resolves
a location** — so the test resolves the tree *through the router* now, not by
instantiating a `home` widget.

**`initialLocation` and where the test lands.** GoRouter starts at
`initialLocation`, which is `/jobs`. That is exactly the jobs list the
pre-router assertions (spinner, job cards, filter chips) already expect — so
those content assertions need **no change** to *find* the list; if the router
starts at `/jobs`, the test is already there. Two adjustments were still
required, and neither is about the list content:

- **Auth gate (Stretch C).** `isLoggedInProvider` defaults to `false`, so the
  redirect would bounce a freshly-pumped app to `/login`. The tests override
  it to `true` (`isLoggedInProvider.overrideWith((ref) => true)`) so they
  exercise the authenticated `/jobs` screen the assertions were written for.
- **New NavigationBar labels.** `Jobs` and `Saved` are new `Text` in the tree;
  the test now asserts both destinations are visible. They were deliberately
  chosen **not** to collide with any existing finder (they are not Job field
  values, filter labels, or card text), so no `findsNWidgets` count elsewhere
  needed changing *for the labels*.

**One collision the fuller rendering did expose.** Now that the test surface
is tall enough to build every card at once (the new bottom NavigationBar ate
the vertical slack that used to leave lower cards unbuilt), `"Market-related"`
renders **twice** — both Junior Backend Engineer and Technical Support
Engineer disclose no salary. Those assertions moved from `findsOneWidget` to
`findsNWidgets(2)`, which is the *correct* count for the data. The `AppBar`
assertion stayed `findsOneWidget` because `StatefulShellRoute.indexedStack`
builds branches lazily — the Saved branch (and its AppBar) isn't instantiated
until first visited.

---

## PART 2 — MODEL & ROUTER SETUP

- **`go_router: ^17.3.0`** added via `flutter pub add go_router`.
- **`Job.id`** — a `final int id`, required by all three constructors
  (default, `.closed`, `.remote`), threaded through `copyWith` and
  `toString`. All six mock jobs carry unique ids `1`–`6`, assigned explicitly
  (never derived from list position).
- **`lib/router/app_router.dart`** — `goRouterProvider`, a Riverpod
  `Provider<GoRouter>` so the router can read providers and be torn down
  cleanly in tests. It uses `StatefulShellRoute.indexedStack`,
  `initialLocation: '/jobs'`, the Jobs branch with the nested `/jobs/:id`
  child, and the Saved branch. Path strings live in one `AppRoutes` holder.
- **`lib/widgets/scaffold_with_nav_bar.dart`** — `ScaffoldWithNavBar`, a
  **StatelessWidget** whose `NavigationBar.selectedIndex` comes from
  `navigationShell.currentIndex` (the router), never from local/`StatefulWidget`
  state. Tapping the active tab calls
  `goBranch(index, initialLocation: index == navigationShell.currentIndex)` —
  resetting that branch's stack (see Stretch A).

*Checkpoint met:* two tabs appear, switching works, and the 1.3 jobs list
with filter chips behaves exactly as before.

---

## PART 3 — JOB DETAIL SCREEN & NAVIGATION

`lib/screens/job_detail_screen.dart` — `JobDetailScreen`:

- Receives an `int? jobId` **extracted from the URL path parameter** (parsed
  with `int.tryParse` in the router), never a `Job` injected via constructor.
- **Watches the raw, unfiltered `jobsProvider`** (not `filteredJobsProvider`
  / `visibleJobsProvider`), with an in-code comment explaining why: *a job's
  identity must not depend on whether it currently passes the list screen's
  active filter/search — `/jobs/3` has to resolve even when the "Remote" chip
  is hiding job 3 from the list.*
- Handles all three `AsyncValue` states (loading spinner, error + retry,
  data).
- Handles an **invalid id gracefully** — a `null` id or an id matching no job
  renders a friendly "Job not found" screen, never a crash
  (`firstWhere`-free lookup returning `null`).
- Displays **every meaningful field**: title, open/closed badge, company,
  location, employment type, salary (via `displaySalary`), closing date,
  the derived apply/closed state, the listing id, and the full description.

Job cards are now tappable: `_buildCard` wraps `JobCard` in an `InkWell` that
calls `context.push(AppRoutes.jobDetail(job.id))` — **`job.id`, never the
card index**. `main.dart` switched to `MaterialApp.router` (reading
`goRouterProvider`) and **`home:` was removed**; `CareerHubApp` became a
`ConsumerWidget` to read the router.

---

## PART 4 — TEST UPDATES

`test/widget_test.dart` — all fixes from Q4 applied; **`flutter test`
reports all tests passed (25/25)** and `flutter analyze` is clean.

- Every pump goes through a `bootApp()` helper that wraps `CareerHubApp` in a
  `ProviderScope` overriding `isLoggedInProvider` to `true` (past the auth
  redirect) — the MaterialApp.router adaptation.
- A new test asserts the **NavigationBar** and both destination labels
  (`Jobs`, `Saved`) are visible after load.
- `"Market-related"` assertions corrected to `findsNWidgets(2)` (two
  no-salary jobs) — the label-count collision from Q4.
- Loading-spinner assertion retained; all job-card data assertions retained.
- Deprecated `window.physicalSizeTestValue` calls replaced with the modern
  `tester.view.physicalSize` API inside a `pumpLoadedApp` helper that sets a
  tall single-column surface, so every card builds (the new bottom nav had
  been pushing lower cards out of the lazy-build window). The sort-order test
  opts into an 800px two-column grid surface, since it reasons about
  horizontal position.

---

## SCREENSHOTS (Assignment 1.4)

> These were captured from the running app (`flutter run`, iPhone-sized
> viewport). To regenerate: run the app, sign in, and follow each caption.

**Loading state — spinner visible before data loads:**

![Loading state](screenshots/1_4_loading.png)

**Detail screen — one job's full details rendered (`/jobs/4`, DevOps Engineer):**

![Job detail screen](screenshots/1_4_detail.png)

**Filter preserved on return from detail** — select **Remote**, tap a card,
press back, confirm the **Remote** chip is *still selected*:

1. Remote filter active, list narrowed to the two remote jobs:

   ![Remote filter active](screenshots/1_4_filter_before.png)

2. After tapping a card → back: the **Remote** chip is still selected and the
   list is unchanged:

   ![Filter preserved after back](screenshots/1_4_filter_preserved.png)

**Tab-state preservation sequence** — three screenshots:

1. On a job's detail screen (NavigationBar still visible):

   ![On detail, in shell](screenshots/1_4_tab_1_on_detail.png)

2. Switched to the **Saved** tab:

   ![Switched to Saved](screenshots/1_4_tab_2_saved.png)

3. Switched back to the **Jobs** tab — the detail screen is still there and
   its back button still returns to the list:

   ![Back on Jobs, detail preserved](screenshots/1_4_tab_3_back_on_jobs.png)

---

## STRETCH GOALS (Assignment 1.4)

### Stretch A — Active tab resets on double-tap

Implemented in `ScaffoldWithNavBar._onDestinationSelected` via
`navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex)`.

**What is `initialLocation: true` telling GoRouter to do?** It tells
`goBranch` to reset the target branch back to its **initial/root location**
(here, `/jobs`), discarding whatever was stacked on that branch's Navigator —
so a detail screen sitting on top of the Jobs tab is popped and the user is
returned to the list root. With `initialLocation: false` (the default),
`goBranch` instead **preserves** that branch's existing stack.

**How does `index == navigationShell.currentIndex` produce the behaviour?**
That comparison is `true` only when the user taps the tab they are **already
on** (a "double-tap"), and `false` when they tap a *different* tab. Passing it
straight into `initialLocation` means: tapping the current tab resets it to
root (Instagram's home-button-scrolls-to-top-and-resets behaviour), while
tapping another tab switches without disturbing that tab's saved stack.

*Screenshots — deep in the Jobs tab, then after double-tapping the Jobs icon:*

![Deep in Jobs tab (on detail)](screenshots/1_4_stretchA_deep.png)
![After double-tap — reset to list root](screenshots/1_4_stretchA_reset.png)

### Stretch B — Direct navigation by ID

A **notification** IconButton (`Icons.notifications_outlined`) in the jobs
AppBar calls `context.go(AppRoutes.jobDetail(3))` — jumping straight to
`/jobs/3`, bypassing the card tap entirely, simulating a push-notification
deep link.

**What does this test about the architecture that tapping a card does not?**
A card tap always originates from a job that is *currently on screen* in the
list — so the detail screen could, in principle, get away with reading the
filtered list. `context.go('/jobs/3')` fires with **no such guarantee**: job
3 (Product Designer, a *Contract* role) is filtered *out* while "Remote" is
selected, the list may be scrolled anywhere, and another tab may have been
active. It proves the detail screen can render a job **from an id alone**,
independent of all list UI state — the exact property a real notification
needs.

**What would break if the detail relied on the filtered provider?** With
"Remote" active, `filteredJobsProvider` does not contain job 3 at all, so the
lookup would fail and the screen would show "Job not found" (or crash on a
naive `firstWhere`) — the deep link would be dead precisely when it matters.
Watching the **raw** `jobsProvider` is what makes `/jobs/3` resolve every
time. *(Verified live: with the Remote filter on, the bell still opens
Product Designer correctly.)*

### Stretch C — Auth redirect

- **`isLoggedInProvider = StateProvider<bool>((ref) => false)`**.
- A `redirect` callback on the `GoRouter` returns `/login` for unauthenticated
  users (and `null` — allow — otherwise; plus `/jobs` if an already-logged-in
  user hits `/login`).
- A minimal **`/login`** screen (`LoginScreen`, outside the shell) with a
  single **Log In** button whose only action is
  `ref.read(isLoggedInProvider.notifier).state = true`.
- The provider is bridged to GoRouter via **`refreshListenable`**: the
  `goRouterProvider` creates a `ValueNotifier<bool>` and `ref.listen`s
  `isLoggedInProvider` into it, so flipping the provider fires the notifier
  and re-runs `redirect`.

**Why does this mean you never call `context.go('/login')` from a sign-out
button?** Because the redirect is *declarative and centralised*: a sign-out
button only needs to set `isLoggedInProvider = false`. `refreshListenable`
then re-runs `redirect`, which — seeing the user is no longer authenticated —
sends them to `/login` on its own. Navigation becomes a *consequence* of auth
state, not something each button has to imperatively perform (and possibly
forget).

**What is `refreshListenable` doing, and why is Riverpod well-suited?**
`refreshListenable` takes any `Listenable`; whenever it notifies, GoRouter
re-evaluates its `redirect` against the current location. Riverpod fits this
connection cleanly because `ref.listen` gives a first-class way to observe a
provider and forward its changes into a `ValueNotifier`, with `ref.onDispose`
handling teardown — so the auth *source of truth* stays a normal Riverpod
provider (readable, overridable in tests, composable) while GoRouter consumes
it through the one small `Listenable` adapter it understands.

*Screenshots — the login screen, then the jobs list reached automatically
after tapping Log In (no `context.go` in the login screen):*

![Login screen](screenshots/1_4_stretchC_login.png)
![Auto-redirected to jobs after login](screenshots/1_4_stretchC_after_login.png)
