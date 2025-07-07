import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:supervisor_wo/core/utils/app_sizes.dart';

class ReportImagesScreen extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ReportImagesScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<ReportImagesScreen> createState() => _ReportImagesScreenState();
}

class _ReportImagesScreenState extends State<ReportImagesScreen> {
  late int currentIndex;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void onPageChanged(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    AppSizes.init(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(
            '${currentIndex + 1}/${widget.images.length}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Main photo view gallery
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(widget.images[index]),
                  initialScale: PhotoViewComputedScale.contained,
                  minScale: PhotoViewComputedScale.contained * 0.8,
                  maxScale: PhotoViewComputedScale.covered * 2,
                  heroAttributes:
                      PhotoViewHeroAttributes(tag: widget.images[index]),
                );
              },
              itemCount: widget.images.length,
              loadingBuilder: (context, event) => Center(
                child: SizedBox(
                  width: AppSizes.blockWidth * 5,
                  height: AppSizes.blockWidth * 5,
                  child: CircularProgressIndicator(
                    value: event == null
                        ? 0
                        : event.cumulativeBytesLoaded /
                            event.expectedTotalBytes!,
                  ),
                ),
              ),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
              pageController: pageController,
              onPageChanged: onPageChanged,
            ),
            // Thumbnail preview
            Container(
              height: AppSizes.blockHeight * 10,
              padding: EdgeInsets.symmetric(horizontal: AppPadding.small),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.images.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(
                        horizontal: AppPadding.small * 0.3,
                        vertical: AppPadding.small,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: currentIndex == index
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white,
                          width: 2,
                        ),
                        borderRadius:
                            BorderRadius.circular(AppSizes.blockWidth * 2),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSizes.blockWidth * 1.5),
                        child: Image.network(
                          widget.images[index],
                          width: AppSizes.blockWidth * 15,
                          height: AppSizes.blockWidth * 15,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: AppSizes.blockWidth * 15,
                              height: AppSizes.blockWidth * 15,
                              color: Colors.grey[800],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
