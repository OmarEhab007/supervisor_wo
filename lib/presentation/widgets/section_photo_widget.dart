import 'package:flutter/material.dart';
import 'package:supervisor_wo/presentation/widgets/image_picker_widget.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';
import 'package:supervisor_wo/core/services/theme.dart';

class SectionPhotoWidget extends StatelessWidget {
  final String sectionKey;
  final String sectionTitle;
  final List<String> photos;
  final Function(List<String>) onPhotosChanged;
  final int maxPhotos;

  const SectionPhotoWidget({
    super.key,
    required this.sectionKey,
    required this.sectionTitle,
    required this.photos,
    required this.onPhotosChanged,
    this.maxPhotos = 999,
  });

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return Container(
      margin: EdgeInsets.only(top: AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(AppSizes.blockWidth * 3),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: ExpansionTileThemeData(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            iconColor: AppColors.primary,
            collapsedIconColor: AppColors.primary,
            textColor: AppColors.primaryDark,
            collapsedTextColor: AppColors.primaryDark,
          ),
        ),
        child: ExpansionTile(
          leading: Container(
            padding: EdgeInsets.all(AppSizes.blockWidth * 2),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(26),
              borderRadius: BorderRadius.circular(AppSizes.blockWidth * 2),
            ),
            child: Icon(
              Icons.photo_camera_outlined,
              color: AppColors.primary,
              size: AppSizes.blockWidth * 5,
            ),
          ),
          title: Text(
            'صور $sectionTitle',
            style: TextStyle(
              fontSize: AppSizes.blockHeight * 2,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: AppPadding.small * 0.3),
            child: Text(
              'اختياري - يمكن إضافة عدد غير محدود من الصور',
              style: TextStyle(
                fontSize: AppSizes.blockHeight * 1.5,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          children: [
            Container(
              margin: EdgeInsets.only(
                left: AppPadding.medium,
                right: AppPadding.medium,
                bottom: AppPadding.medium,
              ),
              padding: EdgeInsets.all(AppPadding.small),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSizes.blockWidth * 2),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: ImagePickerWidget(
                images: photos,
                onImagesChanged: onPhotosChanged,
                maxImages: maxPhotos,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
