import 'package:get/get.dart';

// controller/rules_controller.dart

class RulesController extends GetxController {
  var currentStep = 0.obs;

  // Observables
  var selectedSegment = "".obs;
  var tradingCapital = "".obs;
  var maxLossPerDay = "".obs;
  var maxTradesPerDay = "".obs;
  var minCapitalRange = "".obs;
  var maxCapitalRange = "".obs;

  // Field Validation Logic
  bool canProceed() {
    switch (currentStep.value) {
      case 0:
        return selectedSegment.value.isNotEmpty;
      case 1:
        return tradingCapital.value.isNotEmpty;
      case 2:
        return maxLossPerDay.value.isNotEmpty;
      case 3:
        return maxTradesPerDay.value.isNotEmpty;
      case 4:
        // Check if not empty AND if it meets your 7-18% logic
        return minCapitalRange.value.isNotEmpty &&
            maxCapitalRange.value.isNotEmpty &&
            isCapitalRangeValid;
      default:
        return false;
    }
  }

  // Capital Range Logic (from previous step)
  bool get isCapitalRangeValid {
    double? min = double.tryParse(minCapitalRange.value);
    double? max = double.tryParse(maxCapitalRange.value);
    if (min == null || max == null) return false;
    return (min >= 7 && max <= 18 && min < max);
  }

  void nextStep() => currentStep.value++;
  void prevStep() => currentStep.value--;
}
