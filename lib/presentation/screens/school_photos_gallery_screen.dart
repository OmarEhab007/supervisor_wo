import 'package:flutter/material.dart';
import 'package:supervisor_wo/core/repositories/school_achievement_repository.dart';
import 'package:supervisor_wo/models/school_achievement_model.dart';
import 'package:supervisor_wo/models/school_model.dart';

import 'package:supervisor_wo/presentation/widgets/gradient_app_bar.dart';
import 'package:supervisor_wo/utils/app_sizes.dart';

class SchoolPhotosGalleryScreen extends StatefulWidget {
  final School school;

  const SchoolPhotosGalleryScreen({
    super.key,
    required this.school,
  });

  @override
  State<SchoolPhotosGalleryScreen> createState() =>
      _SchoolPhotosGalleryScreenState();
}

class _SchoolPhotosGalleryScreenState extends State<SchoolPhotosGalleryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SchoolAchievementRepository _repository = SchoolAchievementRepository();

  Map<String, List<Map<String, dynamic>>> _photosByType = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPhotos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load all photos for this school
      final allPhotos = await _repository.getSchoolPhotos(widget.school.id);

      // Load photos by specific types
      final maintenancePhotos = await _repository.getSchoolPhotosByType(
        widget.school.id,
        AchievementType.maintenanceAchievement,
      );

      final acPhotos = await _repository.getSchoolPhotosByType(
        widget.school.id,
        AchievementType.acAchievement,
      );

      final checklistPhotos = await _repository.getSchoolPhotosByType(
        widget.school.id,
        AchievementType.checklist,
      );

      setState(() {
        _photosByType = {
          'all': allPhotos,
          'maintenance_achievement': maintenancePhotos,
          'ac_achievement': acPhotos,
          'checklist': checklistPhotos,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getTabTitle(String type) {
    switch (type) {
      case 'all':
        return 'جميع الصور';
      case 'maintenance_achievement':
        return 'مشهد صيانة';
      case 'ac_achievement':
        return 'مشهد تكييف';
      case 'checklist':
        return 'تشيك ليست';
      default:
        return type;
    }
  }

  Widget _buildPhotoGrid(List<Map<String, dynamic>> photos) {
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: AppSizes.paddingMedium),
            Text(
              'لا توجد صور',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(AppSizes.paddingMedium),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return _buildPhotoCard(photo);
      },
    );
  }

  Widget _buildPhotoCard(Map<String, dynamic> photo) {
    final photoUrl = photo['photo_url'] as String;
    final uploadTime = DateTime.parse(photo['upload_timestamp'] as String);
    final achievementType = photo['achievement_type'] as String?;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showPhotoDetails(photo),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.error,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
            // Info
            Padding(
              padding: EdgeInsets.all(AppSizes.paddingSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (achievementType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getTypeColor(achievementType),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getTypeLabel(achievementType),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  SizedBox(height: AppSizes.paddingSmall),
                  Text(
                    _formatDate(uploadTime),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'maintenance_achievement':
        return Colors.blue;
      case 'ac_achievement':
        return Colors.green;
      case 'checklist':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'maintenance_achievement':
        return 'صيانة';
      case 'ac_achievement':
        return 'تكييف';
      case 'checklist':
        return 'تشيك';
      default:
        return type;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showPhotoDetails(Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Photo
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                photo['photo_url'] as String,
                fit: BoxFit.cover,
                height: 300,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 48,
                  ),
                ),
              ),
            ),
            // Details
            Padding(
              padding: EdgeInsets.all(AppSizes.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo['photo_description'] as String? ?? 'بدون وصف',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: AppSizes.paddingSmall),
                  Text(
                    'تاريخ الرفع: ${_formatDate(DateTime.parse(photo['upload_timestamp'] as String))}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (photo['file_size'] != null) ...[
                    SizedBox(height: AppSizes.paddingSmall),
                    Text(
                      'حجم الملف: ${_formatFileSize(photo['file_size'] as int)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            // Close button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'صور ${widget.school.name}',
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: _getTabTitle('all')),
            Tab(text: _getTabTitle('maintenance_achievement')),
            Tab(text: _getTabTitle('ac_achievement')),
            Tab(text: _getTabTitle('checklist')),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      SizedBox(height: AppSizes.paddingMedium),
                      Text(
                        'خطأ في تحميل الصور',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.red[600],
                                ),
                      ),
                      SizedBox(height: AppSizes.paddingSmall),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppSizes.paddingMedium),
                      ElevatedButton(
                        onPressed: _loadPhotos,
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPhotoGrid(_photosByType['all'] ?? []),
                    _buildPhotoGrid(
                        _photosByType['maintenance_achievement'] ?? []),
                    _buildPhotoGrid(_photosByType['ac_achievement'] ?? []),
                    _buildPhotoGrid(_photosByType['checklist'] ?? []),
                  ],
                ),
    );
  }
}
