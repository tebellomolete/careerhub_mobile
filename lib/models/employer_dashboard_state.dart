/// Assignment 3.3, Stretch C — the Employer dashboard state.
///
/// Two counts, both non-negative ints. Kept as a plain class rather
/// than a Freezed record because the only mutation the notifier
/// performs is `copyWith(totalApplications: n + 1)` on the
/// `NewApplicationReceived` event, and a hand-rolled `copyWith` is
/// simpler than adding another build_runner input for a two-field
/// class.
class EmployerDashboardState {
  final int activeListings;
  final int totalApplications;

  const EmployerDashboardState({
    required this.activeListings,
    required this.totalApplications,
  });

  const EmployerDashboardState.empty()
      : activeListings = 0,
        totalApplications = 0;

  EmployerDashboardState copyWith({
    int? activeListings,
    int? totalApplications,
  }) {
    return EmployerDashboardState(
      activeListings: activeListings ?? this.activeListings,
      totalApplications: totalApplications ?? this.totalApplications,
    );
  }
}
