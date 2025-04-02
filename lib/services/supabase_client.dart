import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientWrapper {
  static final SupabaseClientWrapper _instance = SupabaseClientWrapper._internal();
  late final SupabaseClient _client;

  factory SupabaseClientWrapper() {
    return _instance;
  }

  SupabaseClientWrapper._internal();

  Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://sskgxpvyhdvlphoyrbft.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNza2d4cHZ5aGR2bHBob3lyYmZ0Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTczOTcwMjExMiwiZXhwIjoyMDU1Mjc4MTEyfQ.g_LKqO5rzqVX156XyY0u-9bumbnqTGIQD4-nut-K34g',
    );
    _client = Supabase.instance.client;
  }

  SupabaseClient get client => _client;
}

