import 'package:supervisor_wo/core/services/supabase_client_wrapper.dart';
import 'package:supervisor_wo/models/user_profile.dart';

/// Repository for handling authentication operations
class AuthRepository {
  /// Ensures that the necessary tables exist in the database
  Future<void> ensureTablesExist() async {
    const debug = true;
    void debugLog(String message) {
      if (debug) {
        print('[AuthRepository:ensureTablesExist] $message');
      }
    }

    try {
      // Check if supervisors table exists
      try {
        await SupabaseClientWrapper.client
            .from('supervisors')
            .select('id')
            .limit(1);
        debugLog('supervisors table exists');
      } catch (e) {
        if (e.toString().contains('does not exist')) {
          debugLog('Creating supervisors table...');
          try {
            // Create the supervisors table
            await SupabaseClientWrapper.client.rpc('create_supervisors_table');
            debugLog('supervisors table created successfully');
          } catch (createError) {
            debugLog('Failed to create supervisors table: $createError');
            // Try direct SQL approach
            try {
              final sql = '''
              CREATE TABLE IF NOT EXISTS public.supervisors (
                id UUID PRIMARY KEY REFERENCES auth.users(id),
                username TEXT NOT NULL,
                email TEXT NOT NULL,
                phone TEXT NOT NULL,
                created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
                updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
                iqama_id TEXT,
                plate_numbers TEXT,
                plate_english_letters TEXT,
                plate_arabic_letters TEXT,
                work_id TEXT
              );
              ''';
              await SupabaseClientWrapper.client
                  .rpc('run_sql', params: {'sql': sql});
              debugLog('supervisors table created via direct SQL');
            } catch (sqlError) {
              debugLog('Failed to create table via SQL: $sqlError');
            }
          }
        }
      }
    } catch (e) {
      debugLog('Error in ensureTablesExist: $e');
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await SupabaseClientWrapper.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Sign up a new user with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String phone,
    String? plateNumbers,
    String? plateLetters,
    String? plateArabicLetters,
    String? iqamaId,
    String? workId,
  }) async {
    // Debug flag to print detailed information
    const bool debug = true;

    void debugLog(String message) {
      if (debug) {
        print('[AuthRepository] $message');
      }
    }

    // First, ensure that all necessary tables exist
    debugLog('Ensuring required tables exist before signup...');
    await ensureTablesExist();
    try {
      // Sign up the user
      final response = await SupabaseClientWrapper.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Failed to create user account');
      }

      final userId = response.user!.id;
      final timestamp = DateTime.now().toIso8601String();
      bool profileCreated = false;

      // Create a complete user profile data map matching exact column names
      final profileData = {
        'id': userId,
        'username': username,
        'email': email,
        'phone': phone,
        'created_at': timestamp,
        'updated_at': timestamp,
        'plate_numbers': plateNumbers ?? '',
        'plate_english_letters': plateLetters ?? '',
        'plate_arabic_letters': plateArabicLetters ?? '',
        'iqama_id': iqamaId ?? '',
        'work_id': workId ?? '',
      };

      // First attempt: Check if supervisors table exists
      try {
        // First check if the table exists by trying to select from it
        debugLog('Checking if supervisors table exists...');
        try {
          await SupabaseClientWrapper.client
              .from('supervisors')
              .select('id')
              .limit(1);
          debugLog('supervisors table exists, proceeding with insert');
        } catch (tableError) {
          debugLog('Error checking supervisors table: $tableError');
          debugLog('The supervisors table may not exist in the database');
          // Continue to try insert anyway
        }

        // Now try the insert
        debugLog(
            'Attempting to insert into supervisors table with data: $profileData');
        final response = await SupabaseClientWrapper.client
            .from('supervisors')
            .insert(profileData)
            .select();
        profileCreated = true;
        debugLog('Successfully created supervisor record: $response');
      } catch (e) {
        debugLog('Failed to create supervisor record: $e');
        // Print the full error details
        debugLog('Error details: ${e.toString()}');

        // Try to get more specific error information
        if (e.toString().contains('does not exist')) {
          debugLog(
              'ERROR: The supervisors table does not exist in the database');
        } else if (e.toString().contains('duplicate key')) {
          debugLog('ERROR: Duplicate key violation - user may already exist');
        } else if (e.toString().contains('permission denied')) {
          debugLog('ERROR: Permission denied - check RLS policies');
        }
      }

      // Second attempt: Try supervisor_profiles table
      if (!profileCreated) {
        try {
          // Check if table exists
          debugLog('Checking if supervisor_profiles table exists...');
          try {
            await SupabaseClientWrapper.client
                .from('supervisor_profiles')
                .select('id')
                .limit(1);
            debugLog(
                'supervisor_profiles table exists, proceeding with insert');
          } catch (tableError) {
            debugLog('Error checking supervisor_profiles table: $tableError');
          }

          debugLog('Attempting to insert into supervisor_profiles table');
          final response = await SupabaseClientWrapper.client
              .from('supervisor_profiles')
              .insert(profileData)
              .select();
          profileCreated = true;
          debugLog('Successfully created supervisor_profile record: $response');
        } catch (e) {
          debugLog('Failed to create supervisor_profile record: $e');
          if (e.toString().contains('does not exist')) {
            debugLog('ERROR: The supervisor_profiles table does not exist');
          }
        }
      }

      // Third attempt: Try profiles table
      if (!profileCreated) {
        try {
          // Check if table exists
          debugLog('Checking if profiles table exists...');
          try {
            await SupabaseClientWrapper.client
                .from('profiles')
                .select('id')
                .limit(1);
            debugLog('profiles table exists, proceeding with insert');
          } catch (tableError) {
            debugLog('Error checking profiles table: $tableError');
          }

          debugLog('Attempting to insert into profiles table');
          final response = await SupabaseClientWrapper.client
              .from('profiles')
              .insert(profileData)
              .select();
          profileCreated = true;
          debugLog('Successfully created profile record: $response');
        } catch (e) {
          debugLog('Failed to create profile record: $e');
          if (e.toString().contains('does not exist')) {
            debugLog('ERROR: The profiles table does not exist');
          }
        }
      }

      // Fourth attempt: Try users table
      if (!profileCreated) {
        try {
          // Check if table exists
          debugLog('Checking if users table exists...');
          try {
            await SupabaseClientWrapper.client
                .from('users')
                .select('id')
                .limit(1);
            debugLog('users table exists, proceeding with insert');
          } catch (tableError) {
            debugLog('Error checking users table: $tableError');
          }

          debugLog('Attempting to insert into users table');
          final response = await SupabaseClientWrapper.client
              .from('users')
              .insert(profileData)
              .select();
          profileCreated = true;
          debugLog('Successfully created user record: $response');
        } catch (e) {
          debugLog('Failed to create user record: $e');
          if (e.toString().contains('does not exist')) {
            debugLog('ERROR: The users table does not exist');
          }
        }
      }

      // If all attempts failed, we'll still allow the user to sign up
      // but log the error for debugging
      if (!profileCreated) {
        debugLog('CRITICAL: Failed to create user profile after all attempts');
        debugLog(
            'Available tables in the database may not match the expected schema');
        debugLog(
            'Please check the Supabase database schema and ensure tables exist');

        // Try a simpler approach - just try to query each expected table directly
        debugLog('Checking for existence of expected tables...');

        // Check supervisors table
        try {
          final result = await SupabaseClientWrapper.client
              .from('supervisors')
              .select('id')
              .limit(1);
          debugLog('supervisors table exists and returned: $result');
        } catch (e) {
          debugLog('supervisors table check failed: $e');
        }

        // Check supervisor_profiles table
        try {
          final result = await SupabaseClientWrapper.client
              .from('supervisor_profiles')
              .select('id')
              .limit(1);
          debugLog('supervisor_profiles table exists and returned: $result');
        } catch (e) {
          debugLog('supervisor_profiles table check failed: $e');
        }

        // Check profiles table
        try {
          final result = await SupabaseClientWrapper.client
              .from('profiles')
              .select('id')
              .limit(1);
          debugLog('profiles table exists and returned: $result');
        } catch (e) {
          debugLog('profiles table check failed: $e');
        }

        // Check users table
        try {
          final result = await SupabaseClientWrapper.client
              .from('users')
              .select('id')
              .limit(1);
          debugLog('users table exists and returned: $result');
        } catch (e) {
          debugLog('users table check failed: $e');
        }
      } else {
        debugLog('Profile created successfully in at least one table');
      }
    } catch (e) {
      debugLog('SIGNUP ERROR: $e');
      throw Exception('Failed to sign up: $e');
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await SupabaseClientWrapper.client.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Get the current user's profile
  Future<UserProfile> getUserProfile() async {
    // Debug flag to print detailed information
    const bool debug = true;

    void debugLog(String message) {
      if (debug) {
        print('[AuthRepository:getUserProfile] $message');
      }
    }

    try {
      final userId = SupabaseClientWrapper.client.auth.currentUser?.id;
      if (userId == null) {
        debugLog('No authenticated user found');
        throw Exception('No authenticated user');
      }

      debugLog('Fetching profile for user ID: $userId');

      // Try multiple tables to find the user profile
      // First attempt: Try supervisors table (primary target)
      try {
        debugLog('Attempting to fetch from supervisors table...');
        final response = await SupabaseClientWrapper.client
            .from('supervisors')
            .select()
            .eq('id', userId)
            .single();

        debugLog(
            'Successfully retrieved profile from supervisors table: $response');
        return UserProfile.fromJson(response);
      } catch (e) {
        debugLog('Failed to get profile from supervisors: $e');
        if (e.toString().contains('does not exist')) {
          debugLog('ERROR: The supervisors table does not exist');
        } else if (e.toString().contains('no rows')) {
          debugLog('No profile found in supervisors table for this user');
        }
      }

      // Second attempt: Try supervisor_profiles table
      try {
        debugLog('Attempting to fetch from supervisor_profiles table...');
        final response = await SupabaseClientWrapper.client
            .from('supervisor_profiles')
            .select()
            .eq('id', userId)
            .single();

        debugLog(
            'Successfully retrieved profile from supervisor_profiles table: $response');
        return UserProfile.fromJson(response);
      } catch (e) {
        debugLog('Failed to get profile from supervisor_profiles: $e');
        if (e.toString().contains('does not exist')) {
          debugLog('ERROR: The supervisor_profiles table does not exist');
        }
      }

      // Third attempt: Try profiles table
      try {
        debugLog('Attempting to fetch from profiles table...');
        final response = await SupabaseClientWrapper.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();

        debugLog(
            'Successfully retrieved profile from profiles table: $response');
        return UserProfile.fromJson(response);
      } catch (e) {
        debugLog('Failed to get profile from profiles: $e');
        if (e.toString().contains('does not exist')) {
          debugLog('ERROR: The profiles table does not exist');
        }
      }

      // Fourth attempt: Try users table
      try {
        debugLog('Attempting to fetch from users table...');
        final response = await SupabaseClientWrapper.client
            .from('users')
            .select()
            .eq('id', userId)
            .single();

        debugLog('Successfully retrieved profile from users table: $response');
        return UserProfile.fromJson(response);
      } catch (e) {
        debugLog('Failed to get profile from users: $e');
        if (e.toString().contains('does not exist')) {
          debugLog('ERROR: The users table does not exist');
        }
      }

      // If all attempts failed, create a minimal profile with available data
      debugLog(
          'All table attempts failed, creating minimal profile from auth data');
      final user = SupabaseClientWrapper.client.auth.currentUser!;
      debugLog('Auth user data: ID=${user.id}, Email=${user.email}');
      return UserProfile(
        id: user.id,
        username: user.email?.split('@').first ?? 'User',
        email: user.email ?? '',
        phone: '',
        createdAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Check if a user is currently authenticated
  bool isAuthenticated() {
    return SupabaseClientWrapper.client.auth.currentUser != null;
  }
}
