// import 'package:flutter/material.dart';

// import '../../core/utils/app_sizes.dart';

// class SchoolCard extends StatelessWidget {
//   const SchoolCard({
//     super.key,
//     required this.schoolName,
//     required this.numberOfReports,
//     required this.status,
//     required this.onTap,
//   });

//   final String schoolName;
//   final int numberOfReports;
//   final String status;
//   final void Function() onTap;

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     AppSizes.init(context);

//     // Determine status colors and icon based on emergency status
//     final bool isEmergency = status == 'يوجد طوارئ';
//     final Color statusColor =
//         isEmergency ? colorScheme.error : theme.primaryColor;
//     final Color statusBackgroundColor = isEmergency
//         ? colorScheme.error.withValues(alpha: 0.1)
//         : theme.primaryColor.withValues(alpha: 0.1);
//     final IconData statusIcon =
//         isEmergency ? Icons.warning_rounded : Icons.info_rounded;

//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Card(
//         color: theme.canvasColor.withValues(alpha: 0.9),
//         elevation: 0,
//         margin: EdgeInsets.symmetric(
//           horizontal: AppPadding.medium,
//           vertical: AppPadding.small,
//         ),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//           side: BorderSide(
//             color: theme.primaryColor.withValues(alpha: 0.2),
//             width: 1,
//           ),
//         ),
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(16),
//           child: Padding(
//             padding: EdgeInsets.all(AppPadding.medium),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // School name and reports count
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         schoolName,
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: AppPadding.small),
//                     Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: AppPadding.small,
//                         vertical: AppPadding.small,
//                       ),
//                       decoration: BoxDecoration(
//                         color: theme.canvasColor.withValues(alpha: 0.1),
//                         borderRadius:
//                             BorderRadius.circular(AppSizes.blockWidth * 2),
//                       ),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             Icons.description_outlined,
//                             color: theme.primaryColor,
//                             size: AppSizes.blockWidth * 4,
//                           ),
//                           SizedBox(width: AppPadding.small),
//                           Text(
//                             numberOfReports.toString(),
//                             style: theme.textTheme.bodyMedium?.copyWith(
//                               color: theme.primaryColor,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: AppPadding.small),
//                 // Status row
//                 Row(
//                   children: [
//                     Icon(
//                       statusIcon,
//                       color: statusColor,
//                       size: AppSizes.blockWidth * 6,
//                     ),
//                     SizedBox(width: AppPadding.small),
//                     Container(
//                       padding: EdgeInsets.symmetric(
//                         horizontal: AppPadding.small,
//                         vertical: AppPadding.small,
//                       ),
//                       decoration: BoxDecoration(
//                         color: statusBackgroundColor,
//                         borderRadius:
//                             BorderRadius.circular(AppSizes.blockWidth * 2),
//                       ),
//                       child: Text(
//                         status,
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           color: statusColor,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
