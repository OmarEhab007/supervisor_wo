import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supervisor_wo/core/blocs/maintenance/maintenance_event.dart';
import 'package:supervisor_wo/core/blocs/maintenance/maintenance_state.dart';
import 'package:supervisor_wo/core/repositories/report_repository.dart';
import 'package:supervisor_wo/core/services/supabase_client_wrapper.dart';

/// Bloc for handling maintenance reports
class MaintenanceBloc extends Bloc<MaintenanceEvent, MaintenanceState> {
  final ReportRepository reportRepository;

  MaintenanceBloc({
    required this.reportRepository,
  }) : super(const MaintenanceState()) {
    on<MaintenanceStarted>(_onMaintenanceStarted);
    on<MaintenanceRefreshed>(_onMaintenanceRefreshed);
    on<MaintenanceFilterChanged>(_onMaintenanceFilterChanged);
    on<MaintenanceSearchQueryChanged>(_onMaintenanceSearchQueryChanged);
    on<MaintenanceReportUpdated>(_onMaintenanceReportUpdated);
    on<MaintenanceReportCreated>(_onMaintenanceReportCreated);
    on<MaintenanceReportCompleted>(_onMaintenanceReportCompleted);
  }

  /// Handle MaintenanceStarted event
  Future<void> _onMaintenanceStarted(
    MaintenanceStarted event,
    Emitter<MaintenanceState> emit,
  ) async {
    emit(state.copyWith(status: MaintenanceStatus.loading));

    try {
      // Fetch maintenance reports from the maintenance_reports table
      final reports = await reportRepository.getMaintenanceReports();
      emit(state.copyWith(
        status: MaintenanceStatus.success,
        reports: reports,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MaintenanceStatus.failure,
        errorMessage: 'Failed to load maintenance reports: $e',
      ));
    }
  }

  /// Handle MaintenanceRefreshed event
  Future<void> _onMaintenanceRefreshed(
    MaintenanceRefreshed event,
    Emitter<MaintenanceState> emit,
  ) async {
    emit(state.copyWith(status: MaintenanceStatus.loading));

    try {
      // Refresh maintenance reports with the current filter
      final reports = await reportRepository.getMaintenanceReports(
        status: state.filter,
      );
      emit(state.copyWith(
        status: MaintenanceStatus.success,
        reports: reports,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MaintenanceStatus.failure,
        errorMessage: 'Failed to refresh maintenance reports: $e',
      ));
    }
  }

  /// Handle MaintenanceFilterChanged event
  Future<void> _onMaintenanceFilterChanged(
    MaintenanceFilterChanged event,
    Emitter<MaintenanceState> emit,
  ) async {
    emit(state.copyWith(
      status: MaintenanceStatus.loading,
      filter: event.filter,
    ));

    try {
      // Fetch maintenance reports with the new filter
      final reports = await reportRepository.getMaintenanceReports(
        status: event.filter,
      );
      emit(state.copyWith(
        status: MaintenanceStatus.success,
        reports: reports,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MaintenanceStatus.failure,
        errorMessage: 'Failed to filter maintenance reports: $e',
      ));
    }
  }

  /// Handle MaintenanceSearchQueryChanged event
  void _onMaintenanceSearchQueryChanged(
    MaintenanceSearchQueryChanged event,
    Emitter<MaintenanceState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
  }

  /// Handle MaintenanceReportUpdated event
  Future<void> _onMaintenanceReportUpdated(
    MaintenanceReportUpdated event,
    Emitter<MaintenanceState> emit,
  ) async {
    emit(state.copyWith(status: MaintenanceStatus.loading));

    try {
      // Update the maintenance report in Supabase
      await SupabaseClientWrapper.client.from('maintenance_reports').update({
        'status': event.status,
        'completion_note': event.completionNote,
        'completion_photos': event.completionPhotos,
        'closed_at': event.status == 'completed'
            ? DateTime.now().toIso8601String()
            : null,
      }).eq('id', event.reportId);

      // Refresh the reports list
      final reports = await reportRepository.getMaintenanceReports(
        status: state.filter,
      );
      emit(state.copyWith(
        status: MaintenanceStatus.success,
        reports: reports,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MaintenanceStatus.failure,
        errorMessage: 'Failed to update maintenance report: $e',
      ));
    }
  }

  Future<void> _onMaintenanceReportCompleted(
    MaintenanceReportCompleted event,
    Emitter<MaintenanceState> emit,
  ) async {
    emit(state.copyWith(status: MaintenanceStatus.loading));
    try {
      print('=== MaintenanceBloc: Starting completion process ===');
      print('Report ID: ${event.reportId}');
      print('Completion note: ${event.completionNote}');
      print('Completion photos count: ${event.completionPhotos.length}');
      print('Completion photos: ${event.completionPhotos}');

      print('=== MaintenanceBloc: About to call repository method ===');

      final success = await reportRepository.completeMaintenanceReport(
        reportId: event.reportId,
        completionNote: event.completionNote,
        completionPhotos: event.completionPhotos,
      );

      print('=== MaintenanceBloc: Repository call completed ===');
      print('Success result: $success');

      if (success) {
        print('=== MaintenanceBloc: Success - refreshing reports ===');
        // Refresh reports after completion
        final reports =
            await reportRepository.getMaintenanceReports(status: state.filter);
        print('=== MaintenanceBloc: Reports refreshed, emitting success ===');
        emit(state.copyWith(
          status: MaintenanceStatus.success,
          reports: reports,
        ));
      } else {
        print(
            '=== MaintenanceBloc: Repository returned false - emitting failure ===');
        emit(state.copyWith(
          status: MaintenanceStatus.failure,
          errorMessage:
              'فشل في إكمال بلاغ الصيانة - تحقق من الاتصال بالإنترنت والمحاولة مرة أخرى',
        ));
      }
    } catch (e) {
      print('=== MaintenanceBloc: Exception caught ===');
      print('Exception: $e');
      print('Exception type: ${e.runtimeType}');
      print('Stack trace: ${StackTrace.current}');
      emit(state.copyWith(
        status: MaintenanceStatus.failure,
        errorMessage: 'فشل في إكمال بلاغ الصيانة: $e',
      ));
    }
  }

  /// Handle MaintenanceReportCreated event
  Future<void> _onMaintenanceReportCreated(
    MaintenanceReportCreated event,
    Emitter<MaintenanceState> emit,
  ) async {
    emit(state.copyWith(status: MaintenanceStatus.loading));

    try {
      // Get current user ID
      final currentUser = SupabaseClientWrapper.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create a new maintenance report in Supabase
      await SupabaseClientWrapper.client.from('maintenance_reports').insert({
        'supervisor_id': currentUser.id,
        'school_name': event.schoolId,
        'description': event.description,
        'status': 'pending',
        'images': event.images,
        'created_at': DateTime.now().toIso8601String(),
        'completion_photos': [],
      });

      // Refresh the reports list
      final reports = await reportRepository.getMaintenanceReports(
        status: state.filter,
      );
      emit(state.copyWith(
        status: MaintenanceStatus.success,
        reports: reports,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MaintenanceStatus.failure,
        errorMessage: 'Failed to create maintenance report: $e',
      ));
    }
  }
}
