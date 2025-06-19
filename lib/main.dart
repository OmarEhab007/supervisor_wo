import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:supervisor_wo/core/blocs/auth/auth.dart';
import 'package:supervisor_wo/core/blocs/home/home_bloc.dart';
import 'package:supervisor_wo/core/blocs/home/home_event.dart';
import 'package:supervisor_wo/core/blocs/maintenance/maintenance_bloc.dart';
import 'package:supervisor_wo/core/blocs/maintenance/maintenance_event.dart';
import 'package:supervisor_wo/core/blocs/report_details/report_details_bloc.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_bloc.dart';
import 'package:supervisor_wo/core/blocs/reports/reports_event.dart';
import 'package:supervisor_wo/core/blocs/schools/schools_bloc.dart';
import 'package:supervisor_wo/core/blocs/schools/schools_event.dart';
import 'package:supervisor_wo/core/blocs/supervisor/supervisor_bloc.dart';
import 'package:supervisor_wo/core/blocs/supervisor/supervisor_event.dart';
import 'package:supervisor_wo/core/repositories/report_repository.dart';
import 'package:supervisor_wo/core/repositories/school_repository.dart';
import 'package:supervisor_wo/core/repositories/auth_repository.dart';
import 'package:supervisor_wo/core/services/app_initializer.dart';
import 'package:supervisor_wo/core/services/theme.dart';
import 'package:supervisor_wo/core/services/late_reports_checker.dart';
import 'package:supervisor_wo/core/blocs/connectivity/connectivity.dart';
import 'package:supervisor_wo/routes/app_router.dart';

/// Background message handler - MUST be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background context
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  debugPrint('🔔 [Background] Handling message: ${message.messageId}');
  debugPrint('🔔 [Background] Title: ${message.notification?.title}');
  debugPrint('🔔 [Background] Body: ${message.notification?.body}');
  debugPrint('🔔 [Background] Data: ${message.data}');

  // The local notification will be shown by the FCM service
  // This handler is mainly for data processing and logging
}

/// The entry point of the application
void main() async {
  try {
    // Ensure Flutter bindings are initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase FIRST
    debugPrint('🔥 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized successfully');

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('✅ Background message handler set up');

    // Initialize the entire application
    final repositories = await AppInitializer.initializeApp();

    // Validate initialization
    await AppInitializer.validateInitialization();

    // Start the app
    runApp(SupervisorApp(
      reportRepository: repositories.reportRepository,
      schoolRepository: repositories.schoolRepository,
      authRepository: repositories.authRepository,
    ));
  } catch (error, stackTrace) {
    // Handle initialization errors gracefully
    debugPrint('Failed to initialize app: $error');
    debugPrint('Stack trace: $stackTrace');
    runApp(const ErrorApp());
  }
}

/// Error app widget shown when initialization fails
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Failed to initialize the application',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your internet connection and try again',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Restart the app
                  main();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The main application widget
class SupervisorApp extends StatefulWidget {
  final ReportRepository reportRepository;
  final SchoolRepository schoolRepository;
  final AuthRepository authRepository;

  const SupervisorApp({
    super.key,
    required this.reportRepository,
    required this.schoolRepository,
    required this.authRepository,
  });

  @override
  State<SupervisorApp> createState() => _SupervisorAppState();
}

class _SupervisorAppState extends State<SupervisorApp> {
  LateReportsChecker? _lateReportsChecker;

  @override
  void dispose() {
    _lateReportsChecker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ReportRepository>(
            create: (_) => widget.reportRepository),
        RepositoryProvider<SchoolRepository>(
            create: (_) => widget.schoolRepository),
        RepositoryProvider<AuthRepository>(
            create: (_) => widget.authRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ConnectivityBloc>(
            create: (context) => ConnectivityBloc()
              ..add(const ConnectivityStarted()),
          ),
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: widget.authRepository,
            )..add(const AuthStatusChecked()),
          ),
          BlocProvider<HomeBloc>(
            create: (context) => HomeBloc(
              reportRepository: widget.reportRepository,
            )..add(const HomeStarted()),
          ),
          BlocProvider<ReportsBloc>(
            create: (context) {
              final bloc = ReportsBloc(
                reportRepository: widget.reportRepository,
              )..add(const ReportsStarted());

              // Initialize the late reports checker
              _lateReportsChecker = LateReportsChecker(
                reportsBloc: bloc,
                checkInterval: const Duration(minutes: 30),
              );

              return bloc;
            },
          ),
          BlocProvider<ReportDetailsBloc>(
            create: (context) => ReportDetailsBloc(
              reportRepository: widget.reportRepository,
            ),
          ),
          BlocProvider<MaintenanceBloc>(
            create: (context) => MaintenanceBloc(
              reportRepository: widget.reportRepository,
            )..add(const MaintenanceStarted()),
          ),
          BlocProvider<SupervisorBloc>(
            create: (context) => SupervisorBloc(
              reportRepository: widget.reportRepository,
            )..add(const SupervisorStarted()),
          ),
          BlocProvider<SchoolsBloc>(
            create: (context) => SchoolsBloc(
              schoolRepository: widget.schoolRepository,
            )..add(const SchoolsStarted()),
          ),
        ],
        child: MaterialApp.router(
          title: 'Supervisor App',
          theme: theme(context),
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
