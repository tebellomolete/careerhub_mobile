import 'package:flutter/material.dart';
import '../models/job.dart';
import '../widgets/job_card.dart';
import '../widgets/empty_jobs_widget.dart';

/// CareerHub's main screen.
///
/// Assignment 1.2 changes from 1.1:
/// - HomeScreen moved out of main.dart into its own file.
/// - Jobs moved to a `static final` list (Part 2) instead of being
///   rebuilt inside build() on every frame.
/// - A pinned, horizontally-scrolling filter chip row sits above the
///   list — visual only for now; Day 3 wires up real filtering via
///   Job.matches().
/// - A LayoutBuilder switches between a single-column ListView.builder
///   and a two- or three-column GridView.builder depending on available
///   width (Part 4's 600px breakpoint, extended to a third 840px tier
///   for Stretch B).
/// - An empty state renders instead of the list/grid when there are no
///   jobs (Stretch C).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  /// Part 2 requirement: static final at class level. Built once per
  /// app run, not recreated on every rebuild the way a list declared
  /// inside build() would be.
  ///
  /// Six entries, not four: the original four cover every Job edge case
  /// from Assignment 1.1 (fully populated, no salary/no closing date,
  /// closed, remote). The two extra exist purely so the three-column
  /// grid (Stretch B) shows two full rows instead of one row plus a
  /// single spillover item.
  static final List<Job> _jobs = [
    // 1. Fully populated, open job — every field set, salary present.
    Job(
      title: 'Senior Flutter Developer',
      company: 'Bitcube',
      location: 'Cape Town, ZA',
      salary: 'R55 000 – R75 000 per month',
      employmentType: 'Full-time',
      closingDate: DateTime(2026, 8, 15),
      description:
          'Build production-ready cross-platform apps with a mentoring '
          'team and a real project backlog.',
      isOpen: true,
    ),

    // 2. Open job with NO salary and NO closing date — the "minimal
    //    card" case used to derive the grid's childAspectRatio.
    Job(
      title: 'Junior Backend Engineer',
      company: 'Nimbus Systems',
      location: 'Johannesburg, ZA',
      employmentType: 'Full-time',
      isOpen: true,
    ),

    // 3. Closed job — via the named constructor.
    Job.closed(
      title: 'Product Designer',
      company: 'Loop Studio',
      location: 'Durban, ZA',
      salary: 'R40 000 per month',
      employmentType: 'Contract',
      closingDate: DateTime(2026, 5, 1),
      description: 'This role has closed for new applications.',
    ),

    // 4. Remote job — via the named constructor.
    Job.remote(
      title: 'DevOps Engineer',
      company: 'Skyforge',
      salary: 'R60 000 – R80 000 per month',
      employmentType: 'Full-time',
      closingDate: DateTime(2026, 9, 30),
      description:
          'Fully remote infrastructure role across CI/CD pipelines.',
      isOpen: true,
    ),

    // 5 & 6. Added for Stretch B's three-column grid demo.
    Job(
      title: 'UX Researcher',
      company: 'Meridian Labs',
      location: 'Pretoria, ZA',
      salary: 'R48 000 – R58 000 per month',
      employmentType: 'Full-time',
      closingDate: DateTime(2026, 10, 1),
      description:
          'Lead user research sessions and translate findings into '
          'product decisions.',
      isOpen: true,
    ),
    Job.remote(
      title: 'Technical Support Engineer',
      company: 'Fathom Analytics',
      employmentType: 'Contract',
      closingDate: DateTime(2026, 8, 20),
      isOpen: true,
    ),
  ];

  /// Visual only for this assignment — Day 3 wires these to real
  /// filtering.
  static const List<String> _filters = [
    'All',
    'Remote',
    'Full-time',
    'Contract',
  ];

  // Stretch B extends Part 4's single 600px breakpoint to three tiers.
  static const double _gridBreakpoint = 600;
  static const double _threeColumnBreakpoint = 840;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CareerHub'),
        centerTitle: false,
      ),
      body: Column(
        children: [
          const _FilterChipRow(filters: _filters),

          // Question 1's fix, applied: Expanded hands the scrollable
          // content the Column's *remaining bounded* height, instead of
          // the unbounded height a bare Column child receives. Without
          // this, ListView.builder / GridView.builder crash with
          // "Vertical viewport was given unbounded height".
          Expanded(
            child: _jobs.isEmpty
                ? const EmptyJobsWidget()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;

                      // Tier 1: single column below 600px.
                      if (width < _gridBreakpoint) {
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _jobs.length,
                          itemBuilder: _buildCard,
                        );
                      }

                      // Tier 2 (600–839px): two columns.
                      // Tier 3 (≥840px): three columns.
                      final crossAxisCount =
                          width >= _threeColumnBreakpoint ? 3 : 2;

                      // Narrower cells (3 columns) wrap title/description
                      // text onto more lines, so they need a taller —
                      // i.e. numerically smaller — ratio than the
                      // 2-column case. See README Question 2 / Stretch B.
                      final childAspectRatio =
                          width >= _threeColumnBreakpoint ? 1.05 : 1.2;

                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: childAspectRatio,
                        ),
                        itemCount: _jobs.length,
                        itemBuilder: _buildCard,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Part 4 requirement: one shared builder so ListView.builder and
  /// GridView.builder never duplicate itemBuilder logic.
  static Widget _buildCard(BuildContext context, int index) {
    return JobCard(job: _jobs[index]);
  }
}

/// The pinned, horizontally-scrolling filter row above the job
/// list/grid. Chips are visual only for this assignment.
class _FilterChipRow extends StatelessWidget {
  final List<String> filters;

  const _FilterChipRow({required this.filters});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(filter),
                selected: filter == 'All',
                onSelected: (_) {}, // Visual only — Day 3 wires this up.
              ),
            ),
        ],
      ),
    );
  }
}
