import 'package:flutter/material.dart';
import '../login/branding.dart';

class StepProgress extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  StepProgress({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step $currentStep of $totalSteps',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: WNColors.navy,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: currentStep / totalSteps,
            backgroundColor: WNColors.blue.withOpacity(0.15),
            valueColor: const AlwaysStoppedAnimation<Color>(WNColors.blue),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
