import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientWrapper {
  static final SupabaseClientWrapper _instance =
      SupabaseClientWrapper._internal();
  late final SupabaseClient _client;

  factory SupabaseClientWrapper() {
    return _instance;
  }

  SupabaseClientWrapper._internal();

  Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://sskgxpvyhdvlphoyrbft.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNza2d4cHZ5aGR2bHBob3lyYmZ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk3MDIxMTIsImV4cCI6MjA1NTI3ODExMn0.bueTQnA3LoMDnQGnA3nr2vCtQeeta18nnGvjXr-vVo4',
    );
    _client = Supabase.instance.client;
  }

  SupabaseClient get client => _client;
}

final supabaseClient = SupabaseClientWrapper();

