import 'package:flutter/material.dart';
import 'models/job.dart';
import 'widgets/job_card.dart';

void main() {
  runApp(const CareerHubApp());
}

class CareerHubApp extends StatelessWidget {
  const CareerHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareerHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Deep teal seed: it reads as trustworthy and professional without
        // the corporate-cliché of default blue — right for a platform people
        // rely on for their livelihood.
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00695C),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Hardcoded list covering every required edge case. In Week 2 this is
    // replaced by live API data — the Job shape will not change.
    final List<Job> jobs = [
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

      // 2. Open job with NO salary and NO closing date (nullable fields
      //    omitted) — must show "Market-related" and no closing-date line.
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
        description: 'Fully remote infrastructure role across CI/CD pipelines.',
        isOpen: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CareerHub'),
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: jobs.length,
        itemBuilder: (context, index) => JobCard(job: jobs[index]),
      ),
    );
  }
}
