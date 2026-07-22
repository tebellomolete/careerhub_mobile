import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/saved_jobs_repository.dart';
import 'connectivity_provider.dart';

/// Assignment 2.4 Stretch C — the background listener that
/// drains the pending-sync queue when connectivity returns.
///
/// It is a `keepAlive` provider that is spun up once in `main()`
/// (see `container.read(pendingSyncServiceProvider)`) so the
/// listener lives for the lifetime of the app container without
/// needing a widget to hydrate it. The listener transitions from
/// `offline → online` are what trigger a drain; a device that is
/// online at cold boot also triggers one immediately.
final Provider<PendingSyncService> pendingSyncServiceProvider =
    Provider<PendingSyncService>((ref) {
  final service = PendingSyncService(ref);
  ref.onDispose(service.dispose);
  return service;
});

class PendingSyncService {
  final Ref _ref;
  ProviderSubscription<AsyncValue<List<ConnectivityResult>>>? _sub;
  bool _wasOffline = false;

  PendingSyncService(this._ref) {
    // Initial drain — a fresh launch that's online should sync
    // any leftover pending rows from the previous session.
    _drainSoon();

    _sub = _ref.listen<AsyncValue<List<ConnectivityResult>>>(
      connectivityStreamProvider,
      (previous, next) {
        next.whenData((results) {
          final offline =
              results.every((result) => result == ConnectivityResult.none);
          if (_wasOffline && !offline) {
            _drainSoon();
          }
          _wasOffline = offline;
        });
      },
    );
  }

  void _drainSoon() {
    // Fire-and-forget; the repository owns error handling.
    () async {
      try {
        final repo = _ref.read(savedJobsRepositoryProvider);
        await repo.syncPending();
      } catch (_) {
        // Any unexpected error — swallow. Next connectivity
        // event triggers another attempt.
      }
    }();
  }

  void dispose() {
    _sub?.close();
    _sub = null;
  }
}
