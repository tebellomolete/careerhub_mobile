// Assignment 2.4, Part 3.1 — the domain-level `User` model.
//
// This class is deliberately **plain Dart**:
//   - no `@freezed`, no `part` directive, no code generation;
//   - no `fromJson` / `toJson`, because the app never serialises
//     a User to or from JSON. The values are populated by
//     decoding a JWT payload (the `sub`, `email`, `name` claims —
//     see `AuthRepository.decodeUser`), and consumed inside the
//     `Authenticated` variant of `AuthState`.
//   - no `@collection`, because the User is never written to
//     Isar — the token in secure storage is the source of truth
//     for who is signed in.
//
// The three fields are all `final String`, required, and the
// constructor is `const` so instances are canonicalisable — two
// `User` instances built from the same JWT compare equal by
// reference identity, which matches how Riverpod detects state
// changes on the AsyncNotifier's `state`.
class User {
  final String id;
  final String email;
  final String displayName;

  const User({
    required this.id,
    required this.email,
    required this.displayName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          displayName == other.displayName;

  @override
  int get hashCode => Object.hash(id, email, displayName);

  @override
  String toString() => 'User(id: $id, email: $email, displayName: $displayName)';
}
