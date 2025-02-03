import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase;

  AuthService({required this.supabase});

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final List<dynamic> usernameCheck =
          await supabase.from('profiles').select().eq('username', username);

      if (usernameCheck.isNotEmpty) {
        throw 'Username already taken';
      }

      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (response.user != null) {
        await supabase.from('profiles').insert({
          'id': response.user!.id,
          'username': username,
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return response;
    } on PostgrestException catch (e) {
      throw 'Database error: ${e.message}';
    } on AuthException catch (e) {
      throw 'Authentication error: ${e.message}';
    } catch (e) {
      throw 'Unexpected error: $e';
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw 'Authentication error: ${e.message}';
    } catch (e) {
      throw 'Unexpected error: $e';
    }
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      throw 'Error signing out: $e';
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw 'Error resetting password: $e';
    }
  }

  Future<String?> getUserUsername() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await supabase
          .from('profiles')
          .select('username')
          .eq('id', userId)
          .single();

      return response['username'] as String?;
    } on PostgrestException catch (e) {
      print('Error getting username: ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error getting username: $e');
      return null;
    }
  }
}
