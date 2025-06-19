import 'package:flutter/material.dart';

import '../../core/utils/app_sizes.dart';

class SaudiLicensePlate extends StatelessWidget {
  final String englishNumbers;
  final String arabicLetters;
  final String englishLetters;

  const SaudiLicensePlate({
    Key? key,
    this.englishNumbers = '7356',
    this.arabicLetters = 'ج ن ط',
    this.englishLetters = 'T N J',
  }) : super(key: key);

  String _translateToArabicNumbers(String englishNumbers) {
    const Map<String, String> numberMap = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };

    String result = '';
    for (int i = 0; i < englishNumbers.length; i++) {
      String char = englishNumbers[i];
      result += numberMap[char] ?? char;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    String arabicNumbers = _translateToArabicNumbers(englishNumbers);
    final theme = Theme.of(context);
    AppSizes.init(context);

    return Container(
      width: AppSizes.screenWidth * 0.7,
      height: AppSizes.blockHeight * 8,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Left section - Arabic numbers
          Expanded(
            flex: 3,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: Column(
                children: [
                  // Top part - Arabic numbers
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          arabicNumbers,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: AppSizes.blockHeight * 2,
                            color: Colors.black,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                  ),
                  // Bottom part - English numbers
                  Expanded(
                    child: Center(
                      child: Text(
                        englishNumbers,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: AppSizes.blockHeight * 2,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Middle section - KSA emblem
          Container(
            width: AppSizes.blockWidth * 10,
            decoration: const BoxDecoration(
              color: Color(0xFF1E88E5), // Blue background
              border: Border(
                right: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Saudi emblem (simplified representation)
                Image.asset(
                  'assets/images/ksa_logo.png',
                  // width: AppSizes.blockWidth * 5,
                  height: AppSizes.blockHeight * 3,
                  color: Colors.black,
                ),
                const SizedBox(height: 5),
                // KSA text
                Text(
                  'KSA',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: AppSizes.blockHeight,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                // Small icons/symbols
              ],
            ),
          ),
          // Right section - Arabic letters
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // Top part - Arabic letters
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        arabicLetters,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: AppSizes.blockHeight * 1.5,
                          color: Colors.black,
                          letterSpacing: 3,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                  ),
                ),
                // Bottom part - English letters
                Expanded(
                  child: Center(
                    child: Text(
                      englishLetters,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: AppSizes.blockHeight * 1.5,
                        color: Colors.black,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
