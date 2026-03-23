/// Supabase project configuration.
///
/// These are safe to include in client code — RLS policies protect data.
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = 'https://vggkpywjriwqmheatzqa.supabase.co';

  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZnZ2tweXdqcml3cW1oZWF0enFhIiwi'
      'cm9sZSI6ImFub24iLCJpYXQiOjE3NzQyNDg4MTksImV4cCI6MjA4OTgyNDgxOX0.'
      'zV8xe8MXdAK_ZYY51DqfyJlSLZA7EjtcO17Q2LM1wTk';

  /// Supabase Storage bucket for user avatars.
  static const String avatarsBucket = 'avatars';
}
