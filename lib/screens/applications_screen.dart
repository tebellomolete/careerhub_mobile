import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/job_providers.dart';
import '../router/app_router.dart';
import '../widgets/empty_jobs_widget.dart';
import '../widgets/job_card.dart';

/// Assignment 1.4 — the second NavigationBar tab.
///
/// Lives in its own StatefulShellBranch, so its navigation stack and scroll
/// position are preserved independently of the Jobs tab. It shows the jobs
/// the user has saved (via the Save button on the detail screen), resolved
/// against the raw job list through savedJobsProvider.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedJobsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved jobs'),
        centerTitle: false,
      ),
      body: savedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(
          child: Text("Couldn't load saved jobs."),
        ),
        data: (jobs) {
          if (jobs.isEmpty) {
            return const EmptyJobsWidget(
              icon: Icons.bookmark_border,
              title: 'No saved jobs yet',
              message: 'Tap the bookmark on a job to save it for later.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: jobs.length,
            itemBuilder: (context, index) {
              final job = jobs[index];
              // Same id-based navigation as the Jobs tab — a saved card is
              // still just a link to /jobs/:id.
              return InkWell(
                onTap: () => context.push(AppRoutes.jobDetail(job.id)),
                child: JobCard(job: job),
              );
            },
          );
        },
      ),
    );
  }
}
