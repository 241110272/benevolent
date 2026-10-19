class AppConfig {
  static const developer = 'Benelovent';
  static const supportEmail = 'sastraxez@gmail.com';
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const privacyUrl = String.fromEnvironment('PRIVACY_URL');
  static const deletionUrl = String.fromEnvironment('DELETION_URL');
  static bool get backendConfigured =>
      Uri.tryParse(supabaseUrl)?.scheme == 'https' && supabaseKey.isNotEmpty;
}
