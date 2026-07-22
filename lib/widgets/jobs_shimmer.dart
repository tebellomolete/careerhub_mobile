import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Assignment 3.1, Part 6 — the shimmer skeleton that replaces the
/// jobs list's loading arm.
///
/// This file is deliberately pure UI: no Riverpod imports, no
/// provider references, no reads of application state. A shimmer's
/// only job is to convey "content is coming, its shape looks like
/// this" — coupling it to providers would be an invitation for
/// future readers to sneak logic into what should be a leaf widget.
///
/// Structure — mirrors `JobCard` closely enough that the transition
/// from skeleton → real card is visually calm (no reflow that
/// would look like a layout glitch):
///
///   Shimmer.fromColors(base, highlight)
///   └── ListView.builder(itemCount: 6, itemBuilder: _ShimmerCard())
///       └── Card(margin=16h/8v, child: Padding(all=16, child: Column(
///             ├── Container(16h × 200w, radius 4)      — title bar
///             ├── SizedBox(8)
///             ├── Container(12h × 120w, radius 4)      — company
///             ├── SizedBox(8)
///             ├── Container(12h × 160w, radius 4)      — location
///             ├── SizedBox(12)
///             └── Row([
///                   Container(28h × 88w, radius 16),   — chip 1
///                   SizedBox(8),
///                   Container(28h × 96w, radius 16),   — chip 2
///                 ])
///           )))
///
/// **Colour choice.** `Shimmer.fromColors` takes a `baseColor` and
/// `highlightColor` and animates a linear-gradient `ShaderMask`
/// horizontally across the child. Reading brightness from
/// `Theme.of(context)` and switching between two grey pairs makes
/// the skeleton work in both light and dark themes — light shows
/// darker greys sweeping to a near-white highlight; dark shows a
/// slightly-lighter grey sweeping to a lighter one, which reads as
/// a subtle sheen without blinding the user.
///
/// **Colors.white on the children.** The children are the mask's
/// "canvas" — the shader replaces their alpha with the gradient's
/// alpha and their colour with the gradient's colours. Painting
/// them `Colors.white` keeps the alpha at 100% so the mask has the
/// full silhouette to work with.
class JobsShimmer extends StatelessWidget {
  const JobsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // Cast the material greys with `!` because we know the shade
    // constants are defined.
    final Color baseColor = brightness == Brightness.dark
        ? Colors.grey[700]!
        : Colors.grey[300]!;
    final Color highlightColor = brightness == Brightness.dark
        ? Colors.grey[600]!
        : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        // Non-const because ListView.builder's constructor is not
        // const. All children below are const so the builder-level
        // allocation is the only per-frame cost.
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        itemBuilder: (context, index) => const _ShimmerCard(),
      ),
    );
  }
}

/// One shimmer placeholder card. Private and const — a fresh instance
/// per index inside the ListView.builder is cheap because Dart
/// canonicalises the const literal.
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar — ~16 high, 200 wide.
            _Bar(height: 16, width: 200, radius: 4),
            SizedBox(height: 8),
            // Company line — ~12 high, 120 wide.
            _Bar(height: 12, width: 120, radius: 4),
            SizedBox(height: 8),
            // Location/salary line — ~12 high, 160 wide.
            _Bar(height: 12, width: 160, radius: 4),
            SizedBox(height: 12),
            // Two chip-shaped bars in a row — mirrors the tag/chip
            // area on the real JobCard.
            Row(
              children: [
                _Bar(height: 28, width: 88, radius: 16),
                SizedBox(width: 8),
                _Bar(height: 28, width: 96, radius: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A single rectangular shimmer bar. `Container` fill is
/// `Colors.white` so the ShaderMask has a full-alpha shape to sweep
/// its gradient across. Every `EdgeInsets`, `SizedBox`, and
/// `BorderRadius` in this file is `const`.
class _Bar extends StatelessWidget {
  final double height;
  final double width;
  final double radius;

  const _Bar({
    required this.height,
    required this.width,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
      ),
    );
  }
}
