import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supervisor_wo/utils/app_sizes.dart';
import 'package:supervisor_wo/utils/permission_utils.dart';

/// A modern widget for picking and displaying images with enhanced UI
class ImagePickerWidget extends StatelessWidget {
  final List<String> images;
  final Function(List<String>) onImagesChanged;
  final int maxImages;

  const ImagePickerWidget({
    super.key,
    required this.images,
    required this.onImagesChanged,
    this.maxImages = 999,
  });

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    final bool isUnlimited = maxImages >= 999;

    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff1A1A1A).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xff3B82F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.photo_camera_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SizedBox(width: AppPadding.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الصور المرفقة',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff1E293B),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      isUnlimited
                          ? '${images.length} صورة'
                          : '${images.length} من $maxImages صور',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xff64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isUnlimited)
                Container(
                  width: 60,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xffF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: images.length / maxImages,
                    child: Container(
                      decoration: BoxDecoration(
                        color: images.length == maxImages
                            ? const Color(0xff10B981)
                            : const Color(0xff3B82F6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          if (images.isNotEmpty) ...[
            SizedBox(height: AppPadding.medium),
            _buildImageGrid(context),
          ],

          if (isUnlimited || images.length < maxImages) ...[
            SizedBox(height: AppPadding.medium),
            _buildAddImageSection(context),
          ],

          if (!isUnlimited && images.length == maxImages) ...[
            SizedBox(height: AppPadding.medium),
            _buildCompletionIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return _buildImageTile(context, images[index], index);
      },
    );
  }

  Widget _buildImageTile(BuildContext context, String imagePath, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xffE2E8F0),
          width: 1,
        ),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: _buildImageWidget(context, imagePath),
            ),
          ),

          // Delete button
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xffEF4444),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          ),

          // Index indicator
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddImageSection(BuildContext context) {
    return Column(
      children: [
        // Quick add button
        if (images.isNotEmpty) ...[
          GestureDetector(
            onTap: () => _pickImage(context),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppPadding.medium),
              decoration: BoxDecoration(
                color: const Color(0xff3B82F6).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xff3B82F6).withOpacity(0.2),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xff3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      color: const Color(0xff3B82F6),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppPadding.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'إضافة صورة جديدة',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff3B82F6),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'اضغط لاختيار صورة من الكاميرا أو المعرض',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xff64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: const Color(0xff3B82F6),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],

        if (images.isEmpty) ...[
          SizedBox(height: AppPadding.small),
          // Alternative options when no images
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  'كاميرا',
                  Icons.camera_alt,
                  () => _pickImageFromSource(context, ImageSource.camera),
                ),
              ),
              SizedBox(width: AppPadding.small),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  'معرض',
                  Icons.photo_library,
                  () => _pickImageFromSource(context, ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppPadding.small,
          horizontal: AppPadding.small,
        ),
        decoration: BoxDecoration(
          color: const Color(0xffF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xffE2E8F0),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xff64748B),
              size: 16,
            ),
            SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xff64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionIndicator() {
    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: const Color(0xff10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xff10B981).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xff10B981),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check,
              color: Colors.white,
              size: 18,
            ),
          ),
          SizedBox(width: AppPadding.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تم إكمال رفع الصور',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff10B981),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'تم الوصول للحد الأقصى من الصور المسموح بها',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xff059669),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context, String imagePath) {
    if (imagePath.startsWith('data:image') || imagePath.startsWith('http')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xffF8FAFC),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xff3B82F6),
                  ),
                ),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else {
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xffFEF2F2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              color: const Color(0xffEF4444),
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              'خطأ',
              style: TextStyle(
                fontSize: 10,
                color: const Color(0xffEF4444),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final ImageSource? source = await _showImageSourceDialog(context);
    if (source != null) {
      await _pickImageFromSource(context, source);
    }
  }

  Future<void> _pickImageFromSource(
      BuildContext context, ImageSource source) async {
    try {
      final bool isUnlimited = maxImages >= 999;

      if (!isUnlimited && images.length >= maxImages) {
        _showSnackBar(
          context,
          'لقد وصلت للحد الأقصى من الصور ($maxImages صور)',
          const Color(0xffF59E0B),
          Icons.warning,
        );
        return;
      }

      bool permissionGranted = false;
      if (source == ImageSource.camera) {
        permissionGranted =
            await PermissionUtils.requestCameraPermission(context);
      } else {
        permissionGranted =
            await PermissionUtils.requestStoragePermission(context);
      }

      if (!permissionGranted) {
        _showSnackBar(
          context,
          'يرجى منح الأذونات المطلوبة للمتابعة',
          const Color(0xffF59E0B),
          Icons.warning,
        );
        return;
      }

      final ImagePicker picker = ImagePicker();
      List<XFile> pickedFiles = [];

      if (source == ImageSource.gallery) {
        final files = await picker.pickMultiImage(imageQuality: 80);
        pickedFiles = files;
      } else {
        final file = await picker.pickImage(source: source, imageQuality: 80);
        if (file != null) pickedFiles = [file];
      }

      if (pickedFiles.isNotEmpty) {
        final newImages = List<String>.from(images);
        int actuallyAdded = 0;

        for (var file in pickedFiles) {
          if (isUnlimited || newImages.length < maxImages) {
            newImages.add(file.path);
            actuallyAdded++;
          }
        }

        onImagesChanged(newImages);

        if (!isUnlimited && pickedFiles.length > (maxImages - images.length)) {
          final ignored = pickedFiles.length - actuallyAdded;
          _showSnackBar(
            context,
            'تم إضافة $actuallyAdded صورة. تم تجاهل $ignored صورة (الحد الأقصى $maxImages صور)',
            const Color(0xffF59E0B),
            Icons.info,
          );
        } else {
          _showSnackBar(
            context,
            actuallyAdded == 1
                ? 'تم إضافة صورة واحدة بنجاح'
                : 'تم إضافة $actuallyAdded صورة بنجاح',
            const Color(0xff10B981),
            Icons.check_circle,
          );
        }
      }
    } catch (e) {
      _showSnackBar(
        context,
        'خطأ في اختيار الصورة',
        const Color(0xffEF4444),
        Icons.error,
      );
    }
  }

  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xff3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.photo_camera,
                    color: const Color(0xff3B82F6),
                    size: 28,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'اختر مصدر الصورة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff1E293B),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildSourceButton(
                        context,
                        'الكاميرا',
                        Icons.camera_alt,
                        ImageSource.camera,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildSourceButton(
                        context,
                        'المعرض',
                        Icons.photo_library,
                        ImageSource.gallery,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceButton(
    BuildContext context,
    String title,
    IconData icon,
    ImageSource source,
  ) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(source),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xffE2E8F0),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xffF8FAFC),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: const Color(0xff3B82F6),
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: const Color(0xff1E293B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(
      BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _removeImage(int index) {
    final newImages = List<String>.from(images);
    newImages.removeAt(index);
    onImagesChanged(newImages);
  }
}
