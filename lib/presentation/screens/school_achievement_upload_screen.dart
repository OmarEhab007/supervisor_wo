import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supervisor_wo/core/services/optimized_cloudinary_service.dart';
import 'package:supervisor_wo/core/repositories/school_achievement_repository.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';
import 'package:supervisor_wo/core/services/theme.dart';
import 'package:supervisor_wo/models/school_achievement_model.dart';
import 'package:supervisor_wo/models/school_model.dart';
import 'package:supervisor_wo/presentation/widgets/gradient_app_bar.dart';

class SchoolAchievementUploadScreen extends StatefulWidget {
  final School school;
  final AchievementType achievementType;

  const SchoolAchievementUploadScreen({
    super.key,
    required this.school,
    required this.achievementType,
  });

  @override
  State<SchoolAchievementUploadScreen> createState() =>
      _SchoolAchievementUploadScreenState();
}

class _SchoolAchievementUploadScreenState
    extends State<SchoolAchievementUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  final SchoolAchievementRepository _repository = SchoolAchievementRepository();
  List<File> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadStatus;
  List<SchoolAchievementModel> _history = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await _repository.getSchoolAchievementsByType(
        widget.school.id,
        widget.achievementType,
      );
      debugPrint('Loaded ${history.length} total achievements');
      final submittedHistory = history.where((h) => h.isSubmitted).toList();
      debugPrint('Found ${submittedHistory.length} submitted achievements');

      for (final achievement in submittedHistory) {
        debugPrint(
            'Achievement: ${achievement.id}, Status: ${achievement.status.value}, SubmittedAt: ${achievement.submittedAt}');
      }

      setState(() {
        _history = submittedHistory;
        _isLoadingHistory = false;
      });
    } catch (e) {
      debugPrint('Error loading history: $e');
      setState(() => _isLoadingHistory = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في تحميل التاريخ: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التقاط الصورة: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار صورة واحدة على الأقل')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'جاري تحضير الصور...';
    });

    try {
      _uploadedImageUrls.clear();

      for (int i = 0; i < _selectedImages.length; i++) {
        setState(() {
          _uploadProgress = (i / _selectedImages.length) * 0.8;
          _uploadStatus =
              'جاري رفع الصورة ${i + 1} من ${_selectedImages.length}...';
        });

        final imageUrl = await OptimizedCloudinaryService.uploadImageOptimized(
          _selectedImages[i].path,
        );

        if (imageUrl != null) {
          _uploadedImageUrls.add(imageUrl);
        } else {
          throw Exception('فشل في رفع الصورة ${i + 1}');
        }
      }

      setState(() {
        _uploadProgress = 0.9;
        _uploadStatus = 'جاري حفظ البيانات...';
      });

      // Create achievement model with submitted status
      final achievement = SchoolAchievementModel.create(
        schoolId: widget.school.id,
        schoolName: widget.school.name,
        supervisorId: '',
        achievementType: widget.achievementType,
        photos: _uploadedImageUrls,
      ).copyWith(
        status: AchievementStatus.submitted,
        // Don't set submittedAt manually - database trigger will handle it
      );

      // Save to database
      final success = await _repository.saveAchievement(achievement);
      debugPrint('Achievement save result: $success');
      debugPrint('Achievement data: ${achievement.toMap()}');

      if (success) {
        setState(() {
          _uploadProgress = 1.0;
          _uploadStatus = 'تم الرفع بنجاح!';
        });

        // Clear form
        _selectedImages.clear();
        _uploadedImageUrls.clear();

        // Reload history
        _loadHistory();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الصور بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );

        HapticFeedback.lightImpact();
      } else {
        throw Exception('فشل في حفظ البيانات');
      }
    } catch (e) {
      setState(() {
        _uploadStatus = 'خطأ في الرفع: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في رفع الصور: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadStatus = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.surfaceLight,
        appBar: GradientAppBar(
          title: widget.achievementType.arabicName,
          subtitle: widget.school.name,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(AppPadding.large),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUploadSection(),
                      if (_selectedImages.isNotEmpty) ...[
                        SizedBox(height: AppPadding.large),
                        _buildSelectedImagesSection(),
                      ],
                      if (_isUploading) ...[
                        SizedBox(height: AppPadding.large),
                        _buildUploadProgressSection(),
                      ],
                      SizedBox(height: AppPadding.large),
                      _buildHistorySection(),
                    ],
                  ),
                ),
              ),
              if (_selectedImages.isNotEmpty && !_isUploading)
                Container(
                  padding: EdgeInsets.all(AppPadding.large),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _uploadImages,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding:
                            EdgeInsets.symmetric(vertical: AppPadding.medium),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'رفع الصور (${_selectedImages.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'رفع الصور',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppPadding.medium),
          Center(
            child: _buildUploadButton(
              icon: Icons.camera_alt_rounded,
              title: 'التقط صورة',
              onTap: _takePhoto,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(AppPadding.medium),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 32,
              ),
              SizedBox(height: AppPadding.small),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedImagesSection() {
    return Container(
      padding: EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'الصور المختارة (${_selectedImages.length})',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedImages.clear();
                  });
                },
                child: const Text('مسح الكل'),
              ),
            ],
          ),
          SizedBox(height: AppPadding.medium),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selectedImages[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgressSection() {
    return Container(
      padding: EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'جاري رفع الصور',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppPadding.medium),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 8,
          ),
          SizedBox(height: AppPadding.small),
          if (_uploadStatus != null)
            Text(
              _uploadStatus!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          SizedBox(height: AppPadding.small),
          Text(
            '${(_uploadProgress * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      padding: EdgeInsets.all(AppPadding.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سجل الإنجازات السابقة',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: AppPadding.medium),
          if (_isLoadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (_history.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: AppPadding.small),
                  Text(
                    'لا توجد إنجازات سابقة',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              separatorBuilder: (context, index) =>
                  SizedBox(height: AppPadding.medium),
              itemBuilder: (context, index) {
                final achievement = _history[index];
                return _buildHistoryItem(achievement);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(SchoolAchievementModel achievement) {
    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                achievement.formattedSubmissionDate,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppPadding.small,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${achievement.photoCount} صورة',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          if (achievement.notes != null) ...[
            SizedBox(height: AppPadding.small),
            Text(
              achievement.notes!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
