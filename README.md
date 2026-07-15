# CareerHub — Assignment 1.1: The Job Model & First Widget

Week 1, Day 1. This README contains all written decisions (Part 1), the
scratch output (Part 2), manual verification notes (Part 3), and the colour
justification (Part 4).

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
