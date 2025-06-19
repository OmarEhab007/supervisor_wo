import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:supervisor_wo/models/school_model.dart';

/// Status enum for SchoolsState
enum SchoolsStatus {
  /// Initial state
  initial,

  /// Loading state
  loading,

  /// Success state
  success,

  /// Failure state
  failure,
}

/// State for the SchoolsBloc
@immutable
class SchoolsState extends Equatable {
  /// The current status of the schools data
  final SchoolsStatus status;

  /// The list of schools
  final List<School> schools;

  /// The ID of the currently selected school
  final String? selectedSchoolId;

  /// The current search query
  final String searchQuery;

  /// Whether to show only schools with emergency reports
  final bool showOnlyEmergency;

  /// Error message if any
  final String? errorMessage;

  /// Creates a new SchoolsState
  const SchoolsState({
    this.status = SchoolsStatus.initial,
    this.schools = const [],
    this.selectedSchoolId,
    this.searchQuery = '',
    this.showOnlyEmergency = false,
    this.errorMessage,
  });

  /// Returns the currently selected school
  School? get selectedSchool => schools.isEmpty 
      ? null 
      : schools.firstWhere(
          (school) => school.id == selectedSchoolId,
          orElse: () => schools.first,
        );

  /// Returns the filtered schools based on search query and emergency filter
  List<School> get filteredSchools {
    if (schools.isEmpty) return [];

    return schools.where((school) {
      // Apply emergency filter
      if (showOnlyEmergency && !school.hasEmergencyReports) {
        return false;
      }

      // Apply search filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        return school.name.toLowerCase().contains(query) ||
            school.location.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  /// Creates a copy of this SchoolsState with the given fields replaced with new values
  SchoolsState copyWith({
    SchoolsStatus? status,
    List<School>? schools,
    String? selectedSchoolId,
    String? searchQuery,
    bool? showOnlyEmergency,
    String? errorMessage,
  }) {
    return SchoolsState(
      status: status ?? this.status,
      schools: schools ?? this.schools,
      selectedSchoolId: selectedSchoolId ?? this.selectedSchoolId,
      searchQuery: searchQuery ?? this.searchQuery,
      showOnlyEmergency: showOnlyEmergency ?? this.showOnlyEmergency,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    schools,
    selectedSchoolId,
    searchQuery,
    showOnlyEmergency,
    errorMessage,
  ];
}
