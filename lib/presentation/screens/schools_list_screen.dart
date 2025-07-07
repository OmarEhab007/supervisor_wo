import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../core/repositories/school_repository.dart';
import '../../core/services/theme.dart';
import '../../core/utils/app_sizes.dart';
import '../../models/school_model.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/modern_school_card.dart';
import '../widgets/connectivity_banner.dart';

class SchoolsListScreen extends StatefulWidget {
  const SchoolsListScreen({super.key});

  @override
  State<SchoolsListScreen> createState() => _SchoolsListScreenState();
}

class _SchoolsListScreenState extends State<SchoolsListScreen> {
  final SchoolRepository _schoolRepository = SchoolRepository();
  List<School> _schools = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSchools();
  }

  Future<void> _loadSchools() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final schools = await _schoolRepository.getSupervisorSchools();
      setState(() {
        _schools = schools;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surfaceLight,
        appBar: GradientAppBar(
          title: 'إجمالي مدارسي',
          actions: [
            IconButton(
              onPressed: _loadSchools,
              icon: const Icon(Icons.refresh, color: Colors.white),
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadSchools,
          child: Column(
            children: [
              const ConnectivityBanner(),
              Expanded(
                child: _buildSchoolsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSchoolsList() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            SizedBox(height: AppPadding.medium),
            Text(
              'حدث خطأ في تحميل المدارس',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.error,
                  ),
            ),
            SizedBox(height: AppPadding.small),
            Text(
              _errorMessage ?? 'خطأ غير معروف',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xff6B7280),
                  ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppPadding.large),
            ElevatedButton.icon(
              onPressed: _loadSchools,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (!_isLoading && _schools.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64,
              color: const Color(0xff6B7280),
            ),
            SizedBox(height: AppPadding.medium),
            Text(
              'لا توجد مدارس مسندة',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xff6B7280),
                  ),
            ),
            SizedBox(height: AppPadding.small),
            Text(
              'لم يتم العثور على أي مدارس مسندة لحسابك',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xff6B7280),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Skeletonizer(
      enabled: _isLoading,
      child: ListView.builder(
        padding: EdgeInsets.all(AppPadding.medium),
        itemCount: _isLoading ? 5 : _schools.length,
        itemBuilder: (context, index) {
          final school = _isLoading
              ? const School(
                  id: 'loading',
                  name: 'مدرسة تحميل البيانات',
                  address: 'عنوان المدرسة',
                  reportsCount: 0,
                  lastVisitDate: null,
                )
              : _schools[index];

          return buildSchoolCardWithLastVisit(
            context,
            school.name,
            school.lastVisitDate,
            school.lastVisitSource,
            Theme.of(context).colorScheme,
            onTap: () {
              if (!_isLoading) {
                context.pushNamed(
                  'school_options',
                  extra: school,
                );
              }
            },
          );
        },
      ),
    );
  }
}
