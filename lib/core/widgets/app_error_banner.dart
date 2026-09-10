import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// User-friendly error banner — never shows raw exceptions/stack traces.
class AppErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorBanner({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.charcoal)),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Maps low-level errors to safe, friendly copy shown to users.
String friendlyErrorMessage(Object error) {
  final text = error.toString().toLowerCase();
  if (text.contains('socket') || text.contains('network') || text.contains('timeout')) {
    return "We couldn't connect to Stylish right now. Check your connection and try again.";
  }
  if (text.contains('image') || text.contains('upload')) {
    return "We couldn't upload that photo. Check your connection and try again.";
  }
  return 'Something went wrong. Please try again.';
}
