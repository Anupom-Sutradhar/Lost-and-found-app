/// App-wide constants for UniFind.
class AppConstants {
  static const String appName = 'UniFind';
  static const String appTagline = 'Find what matters, on campus';

  /// University email domain — students must register with this domain only.
  /// Change this to your university's actual domain.
  static const String universityEmailDomain = 'lus.ac.bd';

  // ─── Supabase ─────────────────────────────────────────────────────────────
  // Replace these with your own Supabase project values.
  // Found in your Supabase dashboard: Project Settings → API.
  static const String supabaseUrl = 'https://aieydavsopesnktmolyo.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpZXlkYXZzb3Blc25rdG1vbHlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE1MjQ1MDksImV4cCI6MjA5NzEwMDUwOX0.48DwKNIMlBdva4CQZ3VxVtvnESV5WDN6Sw2oviXeBuA';

  // Supabase table names
  static const String usersTable = 'profiles';
  static const String postsTable = 'posts';
  static const String conversationsTable = 'conversations';
  static const String messagesTable = 'messages';

  // Supabase Storage buckets
  static const String postImagesBucket = 'post-images';
  static const String profileImagesBucket = 'profile-images';

  // Email redirect deeplink (used after email verification)
  // Format: io.supabase.unifind://login-callback/
  static const String emailRedirectScheme = 'io.supabase.unifind';
  static const String emailRedirectUrl = '$emailRedirectScheme://login-callback/';

  // Pagination
  static const int postsPerPage = 20;
}

/// Post type enum — Lost or Found.
enum PostType { lost, found }

extension PostTypeX on PostType {
  String get label => this == PostType.lost ? 'Lost' : 'Found';
  String get value => this == PostType.lost ? 'lost' : 'found';

  static PostType fromString(String value) =>
      value == 'lost' ? PostType.lost : PostType.found;
}

/// Post status — Active or Resolved.
enum PostStatus { active, resolved }

extension PostStatusX on PostStatus {
  String get label => this == PostStatus.active ? 'Active' : 'Resolved';
  String get value => this == PostStatus.active ? 'active' : 'resolved';

  static PostStatus fromString(String value) =>
      value == 'resolved' ? PostStatus.resolved : PostStatus.active;
}
