/// Supabase project configuration.
///
/// The anon key is safe to embed in client code — RLS policies protect data.
/// In production, supply values via --dart-define:
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vggkpywjriwqmheatzqa.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZnZ2tweXdqcml3cW1oZWF0enFhIiwi'
        'cm9sZSI6ImFub24iLCJpYXQiOjE3NzQyNDg4MTksImV4cCI6MjA4OTgyNDgxOX0.'
        'zV8xe8MXdAK_ZYY51DqfyJlSLZA7EjtcO17Q2LM1wTk',
  );

  /// Supabase Storage bucket for user avatars.
  static const String avatarsBucket = 'avatars';
}
