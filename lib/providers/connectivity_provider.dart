import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Part 6.6 — the raw connectivity stream from `connectivity_plus`.
///
/// StreamProvider (not FutureProvider, not a Timer) so the offline
/// banner reacts the instant the OS delivers a new connectivity event.
/// Wrapping the stream is deliberate: the plugin's stream drops events
/// if the first listener attaches late, so the provider prepends the
/// current value via `Stream.fromFuture(checkConnectivity())`
/// followed by the live stream.
final connectivityStreamProvider =
    StreamProvider<List<ConnectivityResult>>((ref) async* {
  final connectivity = Connectivity();
  // Prime the stream with the current value so the derived `isOffline`
  // provider has a real answer on the first frame — otherwise it
  // stays `AsyncLoading` and the banner would flicker in a beat late.
  yield await connectivity.checkConnectivity();
  yield* connectivity.onConnectivityChanged;
});

/// Part 6.6 — the derived `Provider<bool>` the banner watches.
///
/// True whenever the device reports no active transport. `.none` is
/// the sentinel `connectivity_plus` uses for airplane-mode /
/// no-signal; any other entry (wifi, mobile, ethernet, vpn) counts
/// as online. During the very first frame — before the plugin has
/// yielded — we default to `false` (assume online) so the banner
/// doesn't flash on cold start under a working connection.
final isOfflineProvider = Provider<bool>((ref) {
  final async = ref.watch(connectivityStreamProvider);
  return async.when(
    data: (results) =>
        results.isEmpty || results.every((r) => r == ConnectivityResult.none),
    loading: () => false,
    error: (_, __) => false,
  );
});
