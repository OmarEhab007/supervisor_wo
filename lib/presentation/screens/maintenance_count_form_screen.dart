import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supervisor_wo/core/blocs/maintenance_count/maintenance_count.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';
import 'package:supervisor_wo/core/services/theme.dart';
import 'package:supervisor_wo/core/services/cache_service.dart';
import 'package:supervisor_wo/models/maintenance_count_model.dart';
import 'package:supervisor_wo/presentation/widgets/gradient_app_bar.dart';
import 'package:supervisor_wo/presentation/widgets/app_button.dart';
import 'package:supervisor_wo/presentation/widgets/section_photo_widget.dart';
import 'package:uuid/uuid.dart';

/// Screen for maintenance survey form with categorized questions
class MaintenanceCountFormScreen extends StatefulWidget {
  final String schoolId;
  final String schoolName;
  final bool isEdit;
  final MaintenanceCountModel? existingCount;

  const MaintenanceCountFormScreen({
    super.key,
    required this.schoolId,
    required this.schoolName,
    this.isEdit = false,
    this.existingCount,
  });

  @override
  State<MaintenanceCountFormScreen> createState() =>
      _MaintenanceCountFormScreenState();
}

class _MaintenanceCountFormScreenState
    extends State<MaintenanceCountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Data storage
  final Map<String, int> _itemCounts = {};
  final Map<String, String> _textAnswers = {};
  final Map<String, bool> _yesNoAnswers = {};
  final Map<String, int> _yesNoWithCounts = {};
  final Map<String, String> _surveyAnswers = {};
  final Map<String, String> _maintenanceNotes = {};

  // Section photos storage
  final Map<String, List<String>> _sectionPhotos = {
    'fire_safety': [],
    'electrical': [],
    'mechanical': [],
    'civil': [],
    'air_conditioning': [],
  };

  // Controllers
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
    _loadExistingDraft();
  }

  void _initializeData() {
    // Initialize item counts
    MaintenanceCategories.fireSafetyItems.keys.forEach((key) {
      _itemCounts[key] = 0;
      _controllers[key] = TextEditingController(text: '0');
    });
    MaintenanceCategories.electricalItems.keys.forEach((key) {
      _itemCounts[key] = 0;
      _controllers[key] = TextEditingController(text: '0');
    });
    MaintenanceCategories.mechanicalItems.keys.forEach((key) {
      _itemCounts[key] = 0;
      _controllers[key] = TextEditingController(text: '0');
    });
    MaintenanceCategories.airConditioningItems.keys.forEach((key) {
      _itemCounts[key] = 0;
      _controllers[key] = TextEditingController(text: '0');
    });

    // Initialize text answers
    MaintenanceCategories.electricalTextFields.keys.forEach((key) {
      _textAnswers[key] = '';
      _controllers[key] = TextEditingController();
    });
    MaintenanceCategories.mechanicalTextFields.keys.forEach((key) {
      _textAnswers[key] = '';
      _controllers[key] = TextEditingController();
    });

    // Initialize yes/no answers
    MaintenanceCategories.mechanicalYesNo.keys.forEach((key) {
      _yesNoAnswers[key] = false;
      _yesNoWithCounts[key] = 0;
      _controllers['${key}_count'] = TextEditingController(text: '0');
    });
    MaintenanceCategories.civilYesNo.keys.forEach((key) {
      _yesNoAnswers[key] = false;
      _yesNoWithCounts[key] = 0;
      _controllers['${key}_count'] = TextEditingController(text: '0');
    });

    // Initialize survey answers with condition system
    MaintenanceCategories.fireSafetySurvey.keys.forEach((key) {
      _surveyAnswers[key] =
          MaintenanceCategories.alarmPanelConditionOptions.first;
      _maintenanceNotes['${key}_note'] = '';
      _controllers['${key}_note'] = TextEditingController();
    });

    // Initialize fire safety condition answers
    MaintenanceCategories.fireSafetyConditions.keys.forEach((key) {
      _surveyAnswers[key] =
          MaintenanceCategories.alarmPanelConditionOptions.first;
    });

    // Initialize fire safety expiry date fields
    MaintenanceCategories.fireSafetyExpiryDates.keys.forEach((key) {
      _textAnswers['${key}_month'] = '';
      _textAnswers['${key}_day'] = '';
      _textAnswers['${key}_year'] = '';
      _controllers['${key}_month'] = TextEditingController();
      _controllers['${key}_day'] = TextEditingController();
      _controllers['${key}_year'] = TextEditingController();
    });

    // Initialize alarm panel data
    MaintenanceCategories.fireSafetyAlarmPanel.keys.forEach((key) {
      _surveyAnswers['${key}_type'] =
          MaintenanceCategories.firePanelTypeOptions.first;
      _itemCounts['${key}_count'] = 0;
      _surveyAnswers['${key}_condition'] =
          MaintenanceCategories.alarmPanelConditionOptions.first;
      _controllers['${key}_count'] = TextEditingController(text: '0');
      _maintenanceNotes['${key}_note'] = '';
      _controllers['${key}_note'] = TextEditingController();
    });

    // Initialize condition-only items
    MaintenanceCategories.fireSafetyConditionOnly.keys.forEach((key) {
      _surveyAnswers['${key}_condition'] =
          MaintenanceCategories.alarmPanelConditionOptions.first;
      _maintenanceNotes['${key}_note'] = '';
      _controllers['${key}_note'] = TextEditingController();
    });
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
      final draftData =
          await DraftCountPersistenceService.getDraftMaintenanceCount(
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

  /// Load data from existing maintenance count for editing
  void _loadFromExistingCount(MaintenanceCountModel count) {
    setState(() {
      // Load item counts
      count.itemCounts.forEach((key, value) {
        _itemCounts[key] = value;
        if (_controllers.containsKey(key)) {
          _controllers[key]?.text = value.toString();
        }
      });

      // Load text answers
      count.textAnswers.forEach((key, value) {
        _textAnswers[key] = value;
        if (_controllers.containsKey(key)) {
          _controllers[key]?.text = value;
        }
      });

      // Load yes/no answers
      count.yesNoAnswers.forEach((key, value) {
        _yesNoAnswers[key] = value;
      });

      // Load yes/no with counts
      count.yesNoWithCounts.forEach((key, value) {
        _yesNoWithCounts[key] = value;
        if (_controllers.containsKey('${key}_count')) {
          _controllers['${key}_count']?.text = value.toString();
        }
      });

      // Load survey answers
      count.surveyAnswers.forEach((key, value) {
        _surveyAnswers[key] = value;
      });

      // Load maintenance notes
      count.maintenanceNotes.forEach((key, value) {
        _maintenanceNotes[key] = value;
        if (_controllers.containsKey(key)) {
          _controllers[key]?.text = value;
        }
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
            if (_controllers.containsKey(key)) {
              _controllers[key]?.text = value.toString();
            }
          }
        });
      }

      // Load text answers
      if (draft['textAnswers'] != null) {
        final textAnswers = Map<String, dynamic>.from(draft['textAnswers']);
        textAnswers.forEach((key, value) {
          if (value is String) {
            _textAnswers[key] = value;
            if (_controllers.containsKey(key)) {
              _controllers[key]?.text = value;
            }
          }
        });
      }

      // Load yes/no answers
      if (draft['yesNoAnswers'] != null) {
        final yesNoAnswers = Map<String, dynamic>.from(draft['yesNoAnswers']);
        yesNoAnswers.forEach((key, value) {
          if (value is bool) {
            _yesNoAnswers[key] = value;
          }
        });
      }

      // Load yes/no with counts
      if (draft['yesNoWithCounts'] != null) {
        final yesNoWithCounts =
            Map<String, dynamic>.from(draft['yesNoWithCounts']);
        yesNoWithCounts.forEach((key, value) {
          if (value is int) {
            _yesNoWithCounts[key] = value;
            if (_controllers.containsKey('${key}_count')) {
              _controllers['${key}_count']?.text = value.toString();
            }
          }
        });
      }

      // Load survey answers
      if (draft['surveyAnswers'] != null) {
        final surveyAnswers = Map<String, dynamic>.from(draft['surveyAnswers']);
        surveyAnswers.forEach((key, value) {
          if (value is String) {
            _surveyAnswers[key] = value;
          }
        });
      }

      // Load maintenance notes
      if (draft['maintenanceNotes'] != null) {
        final maintenanceNotes =
            Map<String, dynamic>.from(draft['maintenanceNotes']);
        maintenanceNotes.forEach((key, value) {
          if (value is String) {
            _maintenanceNotes[key] = value;
            if (_controllers.containsKey(key)) {
              _controllers[key]?.text = value;
            }
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
        'textAnswers': _textAnswers,
        'yesNoAnswers': _yesNoAnswers,
        'yesNoWithCounts': _yesNoWithCounts,
        'surveyAnswers': _surveyAnswers,
        'maintenanceNotes': _maintenanceNotes,
        'sectionPhotos': _sectionPhotos,
      };

      await DraftCountPersistenceService.saveDraftMaintenanceCount(
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

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: BlocListener<MaintenanceCountBloc, MaintenanceCountState>(
        listener: (context, state) {
          if (state.status == MaintenanceCountStatus.success) {
            setState(() => _isLoading = false);
            // Remove draft when successfully submitted
            DraftCountPersistenceService.removeDraftMaintenanceCount(
                widget.schoolId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم حفظ البيانات بنجاح'),
                backgroundColor: AppColors.secondary,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.pop();
          } else if (state.status == MaintenanceCountStatus.failure) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(state.errorMessage ?? 'حدث خطأ أثناء حفظ البيانات'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state.status == MaintenanceCountStatus.saving) {
            setState(() => _isLoading = true);
          }
        },
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: AppColors.surfaceLight,
            appBar: GradientAppBar(
              title: widget.schoolName,
              subtitle: 'نموذج الصيانة الدورية',
            ),
            body: SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(AppPadding.medium),
                        child: Column(
                          children: [
                            _buildFireSafetySection(),
                            SizedBox(height: AppPadding.large),
                            _buildElectricalSection(),
                            SizedBox(height: AppPadding.large),
                            _buildMechanicalSection(),
                            SizedBox(height: AppPadding.large),
                            _buildCivilSection(),
                            SizedBox(height: AppPadding.large),
                            _buildAirConditioningSection(),
                          ],
                        ),
                      ),
                    ),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(String title, String category) {
    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color:
            MaintenanceCategories.getCategoryColor(category).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              MaintenanceCategories.getCategoryColor(category).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppPadding.small),
            decoration: BoxDecoration(
              color: MaintenanceCategories.getCategoryColor(category)
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              MaintenanceCategories.getCategoryIcon(category),
              color: MaintenanceCategories.getCategoryColor(category),
              size: 24,
            ),
          ),
          SizedBox(width: AppPadding.medium),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MaintenanceCategories.getCategoryColor(category),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFireSafetySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryHeader('الحرائق والأمان', 'fire_safety'),
        SizedBox(height: AppPadding.medium),

        // Items count with conditions
        ...MaintenanceCategories.fireSafetyItems.entries.map((entry) {
          // Check if this item has expiry date fields
          final hasExpiryDate = MaintenanceCategories.fireSafetyExpiryDates
              .containsKey('${entry.key}_expiry');
          if (hasExpiryDate) {
            return _buildItemCountWithExpiryCard(entry.key, entry.value);
          }

          // Check if this item has a condition dropdown
          final hasCondition = MaintenanceCategories.fireSafetyConditions
              .containsKey('${entry.key}_condition');
          if (hasCondition) {
            return _buildItemCountWithConditionCard(entry.key, entry.value);
          } else {
            return _buildItemCountCard(entry.key, entry.value);
          }
        }),

        SizedBox(height: AppPadding.medium),

        // Alarm panel with type, count, and condition
        ...MaintenanceCategories.fireSafetyAlarmPanel.entries
            .map((entry) => _buildAlarmPanelCard(entry.key, entry.value)),

        SizedBox(height: AppPadding.medium),

        // Condition-only items
        ...MaintenanceCategories.fireSafetyConditionOnly.entries
            .map((entry) => _buildConditionOnlyCard(entry.key, entry.value)),

        SizedBox(height: AppPadding.medium),

        // Survey questions with condition system
        ...MaintenanceCategories.fireSafetySurvey.entries
            .map((entry) => _buildConditionOnlyCard(entry.key, entry.value)),

        // Photos section
        SectionPhotoWidget(
          sectionKey: 'fire_safety',
          sectionTitle: 'الحرائق والأمان',
          photos: _sectionPhotos['fire_safety'] ?? [],
          onPhotosChanged: (photos) {
            setState(() {
              _sectionPhotos['fire_safety'] = photos;
            });
            _onDataChanged();
          },
          // maxPhotos removed to use unlimited default
        ),
      ],
    );
  }

  Widget _buildElectricalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryHeader('الكهرباء', 'electrical'),
        SizedBox(height: AppPadding.medium),

        // Items count
        ...MaintenanceCategories.electricalItems.entries
            .map((entry) => _buildItemCountCard(entry.key, entry.value)),

        SizedBox(height: AppPadding.medium),

        // Text fields
        ...MaintenanceCategories.electricalTextFields.entries
            .map((entry) => _buildTextFieldCard(entry.key, entry.value)),

        // Photos section
        SectionPhotoWidget(
          sectionKey: 'electrical',
          sectionTitle: 'الكهرباء',
          photos: _sectionPhotos['electrical'] ?? [],
          onPhotosChanged: (photos) {
            setState(() {
              _sectionPhotos['electrical'] = photos;
            });
            _onDataChanged();
          },
          // maxPhotos removed to use unlimited default
        ),
      ],
    );
  }

  Widget _buildMechanicalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryHeader('الميكانيكية', 'mechanical'),
        SizedBox(height: AppPadding.medium),

        // Items count
        ...MaintenanceCategories.mechanicalItems.entries
            .map((entry) => _buildItemCountCard(entry.key, entry.value)),

        SizedBox(height: AppPadding.medium),

        // Text fields
        ...MaintenanceCategories.mechanicalTextFields.entries
            .map((entry) => _buildTextFieldCard(entry.key, entry.value)),

        SizedBox(height: AppPadding.medium),

        // Yes/No questions
        ...MaintenanceCategories.mechanicalYesNo.entries
            .map((entry) => _buildYesNoWithCountCard(entry.key, entry.value)),

        // Photos section
        SectionPhotoWidget(
          sectionKey: 'mechanical',
          sectionTitle: 'الميكانيكية',
          photos: _sectionPhotos['mechanical'] ?? [],
          onPhotosChanged: (photos) {
            setState(() {
              _sectionPhotos['mechanical'] = photos;
            });
            _onDataChanged();
          },
          // maxPhotos removed to use unlimited default
        ),
      ],
    );
  }

  Widget _buildCivilSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryHeader('المدنية', 'civil'),
        SizedBox(height: AppPadding.medium),

        // Yes/No questions
        ...MaintenanceCategories.civilYesNo.entries
            .map((entry) => _buildYesNoWithCountCard(entry.key, entry.value)),

        // Photos section
        SectionPhotoWidget(
          sectionKey: 'civil',
          sectionTitle: 'المدنية',
          photos: _sectionPhotos['civil'] ?? [],
          onPhotosChanged: (photos) {
            setState(() {
              _sectionPhotos['civil'] = photos;
            });
            _onDataChanged();
          },
          // maxPhotos removed to use unlimited default
        ),
      ],
    );
  }

  Widget _buildAirConditioningSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCategoryHeader(
          MaintenanceCategories.getCategoryName('air_conditioning'),
          'air_conditioning',
        ),
        SizedBox(height: AppPadding.medium),

        // Items count
        ...MaintenanceCategories.airConditioningItems.entries
            .map((entry) => _buildItemCountCard(entry.key, entry.value)),

        // Photos section
        SectionPhotoWidget(
          sectionKey: 'air_conditioning',
          sectionTitle:
              MaintenanceCategories.getCategoryName('air_conditioning'),
          photos: _sectionPhotos['air_conditioning'] ?? [],
          onPhotosChanged: (photos) {
            setState(() {
              _sectionPhotos['air_conditioning'] = photos;
            });
            _onDataChanged();
          },
          // maxPhotos removed to use unlimited default
        ),
      ],
    );
  }

  Widget _buildItemCountCard(String key, String label) {
    final controller = _controllers[key]!;
    return Container(
      margin: EdgeInsets.only(bottom: AppPadding.medium),
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _updateItemCount(key, -1),
                icon: Icon(Icons.remove_circle_outline),
                color: AppColors.error,
              ),
              SizedBox(
                width: 60,
                child: TextFormField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (value) {
                    final count = int.tryParse(value) ?? 0;
                    setState(() => _itemCounts[key] = count);
                    _onDataChanged();
                  },
                ),
              ),
              IconButton(
                onPressed: () => _updateItemCount(key, 1),
                icon: Icon(Icons.add_circle_outline),
                color: AppColors.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCountWithConditionCard(String key, String label) {
    final controller = _controllers[key]!;
    final conditionKey = '${key}_condition';
    final conditionLabel =
        MaintenanceCategories.fireSafetyConditions[conditionKey] ?? 'الحالة';

    return Container(
      margin: EdgeInsets.only(bottom: AppPadding.medium),
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item count section
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _updateItemCount(key, -1),
                    icon: Icon(Icons.remove_circle_outline),
                    color: AppColors.error,
                  ),
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      controller: controller,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (value) {
                        final count = int.tryParse(value) ?? 0;
                        setState(() => _itemCounts[key] = count);
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () => _updateItemCount(key, 1),
                    icon: Icon(Icons.add_circle_outline),
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: AppPadding.medium),

          // Condition dropdown section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conditionLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryDark.withOpacity(0.8),
                ),
              ),
              SizedBox(height: AppPadding.small),
              DropdownButtonFormField<String>(
                value: _surveyAnswers[conditionKey],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: MaintenanceCategories.alarmPanelConditionOptions
                    .map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option, style: TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _surveyAnswers[conditionKey] = newValue);
                    _onDataChanged();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemCountWithExpiryCard(String key, String label) {
    final controller = _controllers[key]!;
    final expiryKey = '${key}_expiry';
    final dayController =
        _controllers['${expiryKey}_month']!; // This is actually day controller
    final monthController =
        _controllers['${expiryKey}_day']!; // This is actually month controller
    final yearController = _controllers['${expiryKey}_year']!;

    return Container(
      margin: EdgeInsets.only(bottom: AppPadding.medium),
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item count section
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _updateItemCount(key, -1),
                    icon: Icon(Icons.remove_circle_outline),
                    color: AppColors.error,
                  ),
                  SizedBox(
                    width: 60,
                    child: TextFormField(
                      controller: controller,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (value) {
                        final count = int.tryParse(value) ?? 0;
                        setState(() => _itemCounts[key] = count);
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () => _updateItemCount(key, 1),
                    icon: Icon(Icons.add_circle_outline),
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: AppPadding.medium),

          // Expiry date section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تاريخ انتهاء الصلاحية',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryDark.withOpacity(0.8),
                ),
              ),
              SizedBox(height: AppPadding.small),
              Row(
                children: [
                  // Month field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'اليوم',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryDark.withOpacity(0.6),
                          ),
                        ),
                        SizedBox(height: 4),
                        TextFormField(
                          controller: dayController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            hintText: 'DD',
                            hintStyle: TextStyle(fontSize: 12),
                          ),
                          onChanged: (value) {
                            setState(
                                () => _textAnswers['${expiryKey}_day'] = value);
                          },
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final day = int.tryParse(value);
                              if (day == null || day < 1 || day > 31) {
                                return 'يوم غير صحيح';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppPadding.small),

                  // Day field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الشهر',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryDark.withOpacity(0.6),
                          ),
                        ),
                        SizedBox(height: 4),
                        TextFormField(
                          controller: monthController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(2),
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            hintText: 'MM',
                            hintStyle: TextStyle(fontSize: 12),
                          ),
                          onChanged: (value) {
                            setState(() =>
                                _textAnswers['${expiryKey}_month'] = value);
                          },
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final month = int.tryParse(value);
                              if (month == null || month < 1 || month > 12) {
                                return 'شهر غير صحيح';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppPadding.small),

                  // Year field
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'السنة',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryDark.withOpacity(0.6),
                          ),
                        ),
                        SizedBox(height: 4),
                        TextFormField(
                          controller: yearController,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                          ],
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                            hintText: 'YYYY',
                            hintStyle: TextStyle(fontSize: 12),
                          ),
                          onChanged: (value) {
                            setState(() =>
                                _textAnswers['${expiryKey}_year'] = value);
                          },
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final year = int.tryParse(value);
                              final currentYear = DateTime.now().year;
                              if (year == null ||
                                  year < currentYear ||
                                  year > currentYear + 50) {
                                return 'سنة غير صحيحة';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldCard(String key, String label) {
    final controller = _controllers[key]!;
    return Container(
      margin: EdgeInsets.only(bottom: AppPadding.medium),
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: AppPadding.small),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              hintText: 'أدخل $label',
            ),
            onChanged: (value) {
              setState(() => _textAnswers[key] = value);
              _onDataChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildYesNoWithCountCard(String key, String question) {
    final countController = _controllers['${key}_count']!;
    return Container(
      margin: EdgeInsets.only(bottom: AppPadding.medium),
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: AppPadding.small),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Radio<bool>(
                      value: true,
                      groupValue: _yesNoAnswers[key],
                      onChanged: (value) =>
                          setState(() => _yesNoAnswers[key] = value!),
                    ),
                    Text('نعم'),
                    SizedBox(width: AppPadding.medium),
                    Radio<bool>(
                      value: false,
                      groupValue: _yesNoAnswers[key],
                      onChanged: (value) =>
                          setState(() => _yesNoAnswers[key] = value!),
                    ),
                    Text('لا'),
                  ],
                ),
              ),
              if (_yesNoAnswers[key] == true) ...[
                Text('العدد:'),
                SizedBox(width: AppPadding.small),
                SizedBox(
                  width: 60,
                  child: TextFormField(
                    controller: countController,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onChanged: (value) {
                      final count = int.tryParse(value) ?? 0;
                      setState(() => _yesNoWithCounts[key] = count);
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyQuestion(String key, String question) {
    return Container(
      margin: EdgeInsets.only(bottom: AppPadding.medium),
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: AppPadding.small),
          DropdownButtonFormField<String>(
            value: _surveyAnswers[key],
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: MaintenanceCategories.alarmPanelConditionOptions
                .map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _surveyAnswers[key] = newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmPanelCard(String key, String label) {
    final countController = _controllers['${key}_count']!;
    final noteController = _controllers['${key}_note']!;
    final typeKey = '${key}_type';
    final conditionKey = '${key}_condition';

    return Container(
      margin: EdgeInsets.only(bottom: AppPadding.medium),
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: AppPadding.medium),

          // Type field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'النوع',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryDark.withOpacity(0.8),
                ),
              ),
              SizedBox(height: AppPadding.small),
              DropdownButtonFormField<String>(
                value: _surveyAnswers[typeKey],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: MaintenanceCategories.firePanelTypeOptions
                    .map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option, style: TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _surveyAnswers[typeKey] = newValue);
                  }
                },
              ),
            ],
          ),

          SizedBox(height: AppPadding.medium),

          // Count field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'العدد',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryDark.withOpacity(0.8),
                ),
              ),
              SizedBox(height: AppPadding.small),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _updateAlarmPanelCount(key, -1),
                    icon: Icon(Icons.remove_circle_outline),
                    color: AppColors.error,
                  ),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      controller: countController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (value) {
                        final count = int.tryParse(value) ?? 0;
                        setState(() => _itemCounts['${key}_count'] = count);
                        _onDataChanged();
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () => _updateAlarmPanelCount(key, 1),
                    icon: Icon(Icons.add_circle_outline),
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: AppPadding.medium),

          // Condition field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الحالة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryDark.withOpacity(0.8),
                ),
              ),
              SizedBox(height: AppPadding.small),
              DropdownButtonFormField<String>(
                value: _surveyAnswers[conditionKey],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: MaintenanceCategories.alarmPanelConditionOptions
                    .map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option, style: TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _surveyAnswers[conditionKey] = newValue);
                  }
                },
              ),
            ],
          ),

          // Note field (only show if condition is "يحتاج صيانة")
          if (_surveyAnswers[conditionKey] == 'يحتاج صيانة') ...[
            SizedBox(height: AppPadding.medium),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملاحظة',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryDark.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: AppPadding.small),
                TextFormField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    hintText: 'أدخل ملاحظة...',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() => _maintenanceNotes['${key}_note'] = value);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionOnlyCard(String key, String label) {
    final noteController = _controllers['${key}_note']!;
    final conditionKey = '${key}_condition';

    return Container(
      margin: EdgeInsets.only(bottom: AppPadding.medium),
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: AppPadding.medium),

          // Condition field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الحالة',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryDark.withOpacity(0.8),
                ),
              ),
              SizedBox(height: AppPadding.small),
              DropdownButtonFormField<String>(
                value: _surveyAnswers[conditionKey],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: MaintenanceCategories.alarmPanelConditionOptions
                    .map((String option) {
                  return DropdownMenuItem<String>(
                    value: option,
                    child: Text(option, style: TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _surveyAnswers[conditionKey] = newValue);
                  }
                },
              ),
            ],
          ),

          // Note field (only show if condition is "يحتاج صيانة")
          if (_surveyAnswers[conditionKey] == 'يحتاج صيانة') ...[
            SizedBox(height: AppPadding.medium),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ملاحظة',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryDark.withOpacity(0.8),
                  ),
                ),
                SizedBox(height: AppPadding.small),
                TextFormField(
                  controller: noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    hintText: 'أدخل ملاحظة...',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() => _maintenanceNotes['${key}_note'] = value);
                    _onDataChanged();
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: AppButton(
          text: 'حفظ البيانات',
          onPressed: _isLoading ? null : _submitForm,
          isLoading: _isLoading,
          icon: Icons.save_rounded,
        ),
      ),
    );
  }

  void _updateItemCount(String key, int delta) {
    final controller = _controllers[key]!;
    final currentCount = int.tryParse(controller.text) ?? 0;
    final newCount = (currentCount + delta).clamp(0, 999);

    setState(() {
      _itemCounts[key] = newCount;
      controller.text = newCount.toString();
    });

    HapticFeedback.lightImpact();
    _onDataChanged();
  }

  void _updateAlarmPanelCount(String key, int delta) {
    final countKey = '${key}_count';
    final controller = _controllers[countKey]!;
    final currentCount = int.tryParse(controller.text) ?? 0;
    final newCount = (currentCount + delta).clamp(0, 999);

    setState(() {
      _itemCounts[countKey] = newCount;
      controller.text = newCount.toString();
    });

    HapticFeedback.lightImpact();
    _onDataChanged();
  }

  /// Helper method to build fire safety alarm panel data
  Map<String, String> _getFireSafetyAlarmPanelData() {
    final Map<String, String> data = {};

    for (final key in MaintenanceCategories.fireSafetyAlarmPanel.keys) {
      // Get type, count, and condition data
      final typeKey = '${key}_type';
      final countKey = '${key}_count';
      final conditionKey = '${key}_condition';

      if (_surveyAnswers.containsKey(typeKey)) {
        data[typeKey] = _surveyAnswers[typeKey] ??
            MaintenanceCategories.firePanelTypeOptions.first;
      }
      if (_itemCounts.containsKey(countKey)) {
        data[countKey] = _itemCounts[countKey].toString();
      }
      if (_surveyAnswers.containsKey(conditionKey)) {
        data[conditionKey] = _surveyAnswers[conditionKey] ??
            MaintenanceCategories.alarmPanelConditionOptions.first;
      }
    }

    return data;
  }

  /// Helper method to build fire safety condition only data
  Map<String, String> _getFireSafetyConditionOnlyData() {
    final Map<String, String> data = {};

    for (final key in MaintenanceCategories.fireSafetyConditionOnly.keys) {
      final conditionKey = '${key}_condition';

      if (_surveyAnswers.containsKey(conditionKey)) {
        data[conditionKey] = _surveyAnswers[conditionKey] ??
            MaintenanceCategories.alarmPanelConditionOptions.first;
      }
    }

    return data;
  }

  /// Helper method to build fire safety expiry dates data
  Map<String, String> _getFireSafetyExpiryDates() {
    final Map<String, String> data = {};

    for (final key in MaintenanceCategories.fireSafetyExpiryDates.keys) {
      final monthKey = '${key}_month';
      final dayKey = '${key}_day';
      final yearKey = '${key}_year';

      if (_textAnswers.containsKey(monthKey)) {
        data[monthKey] = _textAnswers[monthKey] ?? '';
      }
      if (_textAnswers.containsKey(dayKey)) {
        data[dayKey] = _textAnswers[dayKey] ?? '';
      }
      if (_textAnswers.containsKey(yearKey)) {
        data[yearKey] = _textAnswers[yearKey] ?? '';
      }
    }

    return data;
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Debug: Print survey answers to verify default values
      print('DEBUG: Survey Answers: $_surveyAnswers');
      print(
          'DEBUG: Default value should be: ${MaintenanceCategories.alarmPanelConditionOptions.first}');

      // Create maintenance count model
      final uuid = const Uuid();
      final maintenanceCount = MaintenanceCountModel(
        id: uuid.v4(),
        schoolId: widget.schoolId,
        schoolName: widget.schoolName,
        itemCounts: _itemCounts,
        textAnswers: _textAnswers,
        yesNoAnswers: _yesNoAnswers,
        yesNoWithCounts: _yesNoWithCounts,
        surveyAnswers: _surveyAnswers,
        maintenanceNotes: _maintenanceNotes,
        fireSafetyAlarmPanelData: _getFireSafetyAlarmPanelData(),
        fireSafetyConditionOnlyData: _getFireSafetyConditionOnlyData(),
        fireSafetyExpiryDates: _getFireSafetyExpiryDates(),
        createdAt: DateTime.now(),
        supervisorId: '', // Will be set by repository
        status: 'submitted',
      );

      // Save using BLoC with photos
      if (mounted) {
        context.read<MaintenanceCountBloc>().add(
              MaintenanceCountSubmittedWithPhotos(
                maintenanceCount: maintenanceCount,
                sectionPhotos: _sectionPhotos,
              ),
            );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إعداد البيانات: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
