import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supervisor_wo/core/blocs/damage_count/damage_count.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';
import 'package:supervisor_wo/core/services/theme.dart';
import 'package:supervisor_wo/core/services/cache_service.dart';
import 'package:supervisor_wo/models/damage_count_model.dart';
import 'package:supervisor_wo/presentation/widgets/gradient_app_bar.dart';
import 'package:supervisor_wo/presentation/widgets/app_button.dart';
import 'package:supervisor_wo/presentation/widgets/section_photo_widget.dart';
import 'package:uuid/uuid.dart';

/// Screen for damage count form with categorized damaged items
class DamageCountFormScreen extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final bool isEdit;
  final DamageCountModel? existingCount;

  const DamageCountFormScreen({
    super.key,
    required this.schoolId,
    required this.schoolName,
    this.isEdit = false,
    this.existingCount,
  });

  @override
  State<DamageCountFormScreen> createState() => _DamageCountFormScreenState();
}

class _DamageCountFormScreenState extends State<DamageCountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Data storage - simplified to only item counts
  final Map<String, int> _itemCounts = {};

  // Section photos storage
  final Map<String, List<String>> _sectionPhotos = {
    'mechanical_plumbing': [],
    'electrical': [],
    'civil': [],
    'safety_security': [],
    'air_conditioning': [],
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadExistingDraft();
  }

  void _initializeData() {
    // Initialize item counts for all categories
    for (final category in DamageCategories.allCategories.entries) {
      for (final key in category.value.keys) {
        _itemCounts[key] = 0;
      }
    }
  }

  /// Load existing draft data if available or existing count data for editing
  Future<void> _loadExistingDraft() async {
    try {
      // If in edit mode, use existing count data
      if (widget.isEdit && widget.existingCount != null) {
        _loadFromExistingCount(widget.existingCount!);
        return;
      }

      // Otherwise, try to load draft data
      final draftData = await DraftCountPersistenceService.getDraftDamageCount(
          widget.schoolId);

      if (draftData != null && draftData['draftData'] != null) {
        final draft = draftData['draftData'] as Map<String, dynamic>;
        _loadFromDraftData(draft);
      } else {
        // No existing draft, save initial empty draft to show in "قيد التنفيذ" tab
        await _saveDraftData();
      }
    } catch (e) {
      print('Error loading draft: $e');
      // Save initial draft even if loading fails
      await _saveDraftData();
    }
  }

  /// Load data from existing damage count for editing
  void _loadFromExistingCount(DamageCountModel count) {
    setState(() {
      // Load item counts
      count.itemCounts.forEach((key, value) {
        _itemCounts[key] = value;
      });

      // Load section photos
      count.sectionPhotos.forEach((key, value) {
        _sectionPhotos[key] = List<String>.from(value);
      });
    });
  }

  /// Load data from draft data
  void _loadFromDraftData(Map<String, dynamic> draft) {
    setState(() {
      // Load item counts
      if (draft['itemCounts'] != null) {
        final itemCounts = Map<String, dynamic>.from(draft['itemCounts']);
        itemCounts.forEach((key, value) {
          if (value is int) {
            _itemCounts[key] = value;
          }
        });
      }

      // Load section photos
      if (draft['sectionPhotos'] != null) {
        final sectionPhotos = Map<String, dynamic>.from(draft['sectionPhotos']);
        sectionPhotos.forEach((key, value) {
          if (value is List) {
            _sectionPhotos[key] = List<String>.from(value);
          }
        });
      }
    });
  }

  /// Save current form data as draft
  Future<void> _saveDraftData() async {
    try {
      final draftData = {
        'itemCounts': _itemCounts,
        'sectionPhotos': _sectionPhotos,
      };

      await DraftCountPersistenceService.saveDraftDamageCount(
        schoolId: widget.schoolId,
        schoolName: widget.schoolName,
        draftData: draftData,
      );
    } catch (e) {
      print('Error saving draft: $e');
    }
  }

  /// Auto-save draft when data changes
  void _onDataChanged() {
    // Debounce the save operation to avoid too frequent saves
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _saveDraftData();
      }
    });
  }

  Widget _buildCategorySection(String categoryKey, Map<String, String> items) {
    final categoryName = DamageCategories.getCategoryName(categoryKey);
    final categoryIcon = DamageCategories.getCategoryIcon(categoryKey);
    final categoryColor = DamageCategories.getCategoryColor(categoryKey);

    return Column(
      children: [
        SizedBox(height: AppPadding.medium),
        // Category Header
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppPadding.small),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                categoryColor,
                categoryColor.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  categoryIcon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: AppPadding.medium),
              Expanded(
                child: Text(
                  categoryName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_getTotalCountForCategory(categoryKey)} قطعة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Items List
        Padding(
          padding: EdgeInsets.all(AppPadding.medium),
          child: Column(
            children: items.entries.map((entry) {
              return _buildModernCounterItem(entry.key, entry.value);
            }).toList(),
          ),
        ),

        // Photos Section
        Padding(
          padding: EdgeInsets.all(AppPadding.medium),
          child: SectionPhotoWidget(
            sectionKey: categoryKey,
            sectionTitle: categoryName,
            photos: _sectionPhotos[categoryKey] ?? [],
            onPhotosChanged: (photos) {
              setState(() {
                _sectionPhotos[categoryKey] = photos;
              });
              _onDataChanged();
            },
          ),
        ),
      ],
    );
  }

  int _getTotalCountForCategory(String categoryKey) {
    final items = DamageCategories.allCategories[categoryKey] ?? {};
    int total = 0;
    for (final key in items.keys) {
      total += _itemCounts[key] ?? 0;
    }
    return total;
  }

  Widget _buildModernCounterItem(String key, String label) {
    final theme = Theme.of(context);
    final count = _itemCounts[key] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: AppPadding.medium),
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: count > 0
              ? Colors.orange.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.1),
          width: count > 0 ? 2 : 1,
        ),
        boxShadow: [
          if (count > 0) ...[
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item Label
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (count > 0) ...[
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'تالف',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Modern Counter Controls
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Decrease Button
                _buildCounterButton(
                  icon: Icons.remove_rounded,
                  onPressed: count > 0
                      ? () {
                          setState(() {
                            _itemCounts[key] = count - 1;
                          });
                          _onDataChanged();
                        }
                      : null,
                  isEnabled: count > 0,
                ),

                // Count Display
                Container(
                  constraints:
                      BoxConstraints(minWidth: AppSizes.blockWidth * 15),
                  padding: EdgeInsets.symmetric(
                      horizontal: AppPadding.medium,
                      vertical: AppPadding.small),
                  decoration: BoxDecoration(
                    color: count > 0
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                  child: Text(
                    count.toString(),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: count > 0
                          ? Colors.orange
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),

                // Increase Button
                _buildCounterButton(
                  icon: Icons.add_rounded,
                  onPressed: () {
                    setState(() {
                      _itemCounts[key] = count + 1;
                    });
                    _onDataChanged();
                  },
                  isEnabled: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isEnabled,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSizes.blockWidth * 2),
        child: Container(
          padding: EdgeInsets.all(AppPadding.small),
          child: Icon(
            icon,
            size: AppSizes.blockWidth * 5,
            color: isEnabled
                ? (onPressed != null ? Colors.orange : Colors.grey)
                : Colors.grey.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final damageCount = DamageCountModel(
        id: const Uuid().v4(),
        schoolId: widget.schoolId,
        schoolName: widget.schoolName,
        itemCounts: Map.from(_itemCounts),
        sectionPhotos: Map.from(_sectionPhotos),
        createdAt: DateTime.now(),
        supervisorId: '', // Will be set in repository
        status: 'submitted',
      );

      context.read<DamageCountBloc>().add(
            DamageCountSubmittedWithPhotos(
              damageCount,
              _sectionPhotos,
            ),
          );
    }
  }

  int _getTotalDamageCount() {
    return _itemCounts.values.fold(0, (sum, count) => sum + count);
  }

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    final totalCount = _getTotalDamageCount();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocListener<DamageCountBloc, DamageCountState>(
        listener: (context, state) {
          if (state.status == DamageCountStatus.success) {
            setState(() => _isLoading = false);
            // Remove draft when successfully submitted
            DraftCountPersistenceService.removeDraftDamageCount(
                widget.schoolId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم حفظ حصر التوالف بنجاح'),
                backgroundColor: AppColors.secondary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.pop();
          } else if (state.status == DamageCountStatus.failure) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(state.errorMessage ?? 'حدث خطأ أثناء حفظ البيانات'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state.status == DamageCountStatus.saving) {
            setState(() => _isLoading = true);
          }
        },
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: AppColors.surfaceLight,
            appBar: GradientAppBar(
              title: widget.schoolName,
              subtitle: totalCount > 0
                  ? 'حصر التوالف - المجموع: $totalCount قطعة'
                  : 'حصر التوالف',
            ),
            body: SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Summary Header
                    if (totalCount > 0)
                      Container(
                        margin: EdgeInsets.all(AppPadding.medium),
                        padding: EdgeInsets.all(AppPadding.medium),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.orange,
                              Colors.orange.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_rounded,
                              color: Colors.white,
                              size: AppSizes.blockWidth * 8,
                            ),
                            SizedBox(width: AppPadding.medium),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'إجمالي التوالف',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: AppSizes.blockHeight * 2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '$totalCount قطعة تالفة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: AppSizes.blockHeight * 3,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            EdgeInsets.symmetric(horizontal: AppPadding.medium),
                        child: Column(
                          children: [
                            _buildCategorySection(
                              'mechanical_plumbing',
                              DamageCategories.mechanicalPlumbingItems,
                            ),
                            _buildCategorySection(
                              'electrical',
                              DamageCategories.electricalItems,
                            ),
                            _buildCategorySection(
                              'civil',
                              DamageCategories.civilItems,
                            ),
                            _buildCategorySection(
                              'safety_security',
                              DamageCategories.safetySecurityItems,
                            ),
                            _buildCategorySection(
                              'air_conditioning',
                              DamageCategories.airConditioningItems,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(AppPadding.medium),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: AppButton(
                        onPressed: _isLoading ? null : _submitForm,
                        text: _isLoading
                            ? 'جاري الحفظ...'
                            : totalCount > 0
                                ? 'حفظ حصر التوالف ($totalCount قطعة)'
                                : 'حفظ حصر التوالف',
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
