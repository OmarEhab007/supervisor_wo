import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supervisor_wo/core/blocs/report_details/report_details_event.dart';
import 'package:supervisor_wo/core/blocs/report_details/report_details_state.dart';
import 'package:supervisor_wo/core/extensions/report_extensions.dart';
import 'package:supervisor_wo/core/repositories/report_repository.dart';

/// Bloc for managing the report details screen state
class ReportDetailsBloc extends Bloc<ReportDetailsEvent, ReportDetailsState> {
  final ReportRepository _reportRepository;

  ReportDetailsBloc({required ReportRepository reportRepository})
      : _reportRepository = reportRepository,
        super(const ReportDetailsState()) {
    on<ReportDetailsLoaded>(_onReportDetailsLoaded);
    on<ReportApproved>(_onReportApproved);
    on<ReportFeedbackSent>(_onReportFeedbackSent);
    on<ReportShared>(_onReportShared);
    on<ReportStatusUpdated>(_onReportStatusUpdated);
  }

  /// Handle the ReportDetailsLoaded event
  Future<void> _onReportDetailsLoaded(
    ReportDetailsLoaded event,
    Emitter<ReportDetailsState> emit,
  ) async {
    emit(state.copyWith(status: ReportDetailsStatus.loading));
    
    try {
      final report = await _reportRepository.getReportById(event.reportId);
      
      emit(state.copyWith(
        status: ReportDetailsStatus.success,
        report: report,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportDetailsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Handle the ReportApproved event
  Future<void> _onReportApproved(
    ReportApproved event,
    Emitter<ReportDetailsState> emit,
  ) async {
    emit(state.copyWith(isApproving: true));
    
    try {
      // In a real app, this would call the repository to update the report status
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      
      // Update the local report state
      final updatedReport = state.report?.copyWith(
        status: 'Completed',
      );
      
      emit(state.copyWith(
        status: ReportDetailsStatus.success,
        report: updatedReport,
        isApproving: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportDetailsStatus.failure,
        errorMessage: e.toString(),
        isApproving: false,
      ));
    }
  }

  /// Handle the ReportFeedbackSent event
  Future<void> _onReportFeedbackSent(
    ReportFeedbackSent event,
    Emitter<ReportDetailsState> emit,
  ) async {
    emit(state.copyWith(isSendingFeedback: true));
    
    try {
      // In a real app, this would call the repository to send feedback
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      
      emit(state.copyWith(
        status: ReportDetailsStatus.success,
        isSendingFeedback: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportDetailsStatus.failure,
        errorMessage: e.toString(),
        isSendingFeedback: false,
      ));
    }
  }

  /// Handle the ReportShared event
  Future<void> _onReportShared(
    ReportShared event,
    Emitter<ReportDetailsState> emit,
  ) async {
    try {
      // In a real app, this would call a sharing service
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate delay
      
      // No state change needed for sharing
    } catch (e) {
      emit(state.copyWith(
        status: ReportDetailsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
  
  /// Handle the ReportStatusUpdated event
  Future<void> _onReportStatusUpdated(
    ReportStatusUpdated event,
    Emitter<ReportDetailsState> emit,
  ) async {
    emit(state.copyWith(status: ReportDetailsStatus.loading));
    
    try {
      // In a real app, this would call the repository to update the report status
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      
      // Update the local report state
      final updatedReport = state.report?.copyWith(
        status: event.status,
      );
      
      emit(state.copyWith(
        status: ReportDetailsStatus.success,
        report: updatedReport,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ReportDetailsStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}
